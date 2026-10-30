import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/qris/qris_converter.dart';
import '../../../core/utilities/console_logger.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/transaction_usecases.dart';
import 'dana_listener_notifier.dart';
import 'payment_state.dart';

final qrisPaymentNotifierProvider = NotifierProvider<QrisPaymentNotifier, QrisPaymentState>(
  QrisPaymentNotifier.new,
);

/// Alur pembayaran QRIS DANA Bisnis.
///
/// Konversi statis → dinamis dilakukan di sini, sebelum transaksi disimpan,
/// sehingga checkout tidak pernah meninggalkan transaksi setengah jadi.
class QrisPaymentNotifier extends Notifier<QrisPaymentState> {
  Timer? _countdownTimer;

  @override
  QrisPaymentState build() {
    ref.onDispose(_cancelTimer);
    return const QrisPaymentState();
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<Result<int>> startQrisPayment({
    required TransactionEntity transaction,
    required int totalAmount,
    String? description,
    bool isDirect = false,
  }) async {
    final service = ref.read(danaQrisPaymentServiceProvider);

    if (!service.isConfigured) {
      const message = 'QRIS DANA Bisnis belum diatur. Upload QRIS statis di Pengaturan Pembayaran.';
      state = state.copyWith(isStarting: false, errorMessage: message);
      return Result.failure(error: message);
    }

    if (totalAmount <= 0) {
      const message = 'Nominal pembayaran tidak valid.';
      state = state.copyWith(isStarting: false, errorMessage: message);
      return Result.failure(error: message);
    }

    state = state.copyWith(isStarting: true, clearError: true);

    try {
      final store = ref.read(danaPaymentStoreProvider);
      final uniqueCode = service.uniqueCodeEnabled ? await store.allocateUniqueCode(baseAmount: totalAmount) : 0;
      final expectedAmount = totalAmount + uniqueCode;
      final payload = service.buildDynamicPayload(expectedAmount);
      final expiresAt = DateTime.now().add(Duration(minutes: service.expiryMinutes));

      final pending = transaction.copyWith(
        paymentStatus: 'pending',
        paymentQR: payload,
        paymentProvider: Constants.danaProviderStatic,
        paymentExpectedAmount: expectedAmount,
        paymentUniqueCode: uniqueCode,
        paymentExpiresAt: expiresAt.toIso8601String(),
      );

      final transactionRepo = ref.read(transactionRepositoryProvider);
      final saveResult = await CreateTransactionUsecase(transactionRepo).call(pending);

      if (saveResult.isFailure) {
        state = state.copyWith(isStarting: false, errorMessage: saveResult.error?.toString());
        return Result.failure(error: saveResult.error ?? 'Gagal menyimpan transaksi');
      }

      final transactionId = saveResult.data!;

      state = QrisPaymentState(
        transaction: pending.copyWith(id: transactionId),
        payload: payload,
        paymentStatus: 'pending',
        totalAmount: totalAmount,
        uniqueCode: uniqueCode,
        expectedAmount: expectedAmount,
        expiresAt: expiresAt,
        remainingSeconds: service.expiryMinutes * 60,
        isDirect: isDirect,
      );

      _startCountdown();
      cl(
        '[DANA] QRIS dinamis dibuat: base=$totalAmount code=$uniqueCode '
        'expected=$expectedAmount len=${payload.length}',
      );

      return Result.success(data: transactionId);
    } on QrisConvertException catch (e) {
      state = state.copyWith(isStarting: false, errorMessage: e.message);
      return Result.failure(error: e.message);
    } catch (e) {
      state = state.copyWith(isStarting: false, errorMessage: e.toString());
      return Result.failure(error: e.toString());
    }
  }

  void _startCountdown() {
    _cancelTimer();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final expiresAt = state.expiresAt;
      if (expiresAt == null) return;

      final remaining = expiresAt.difference(DateTime.now()).inSeconds;
      if (remaining <= 0) {
        _onExpired();
        return;
      }

      state = state.copyWith(remainingSeconds: remaining);
    });
  }

  Future<void> _onExpired() async {
    _cancelTimer();

    final transactionId = state.transaction?.id;
    state = state.copyWith(paymentStatus: 'expired', remainingSeconds: 0);

    if (transactionId == null) return;

    final transactionRepo = ref.read(transactionRepositoryProvider);
    await UpdatePaymentStatusUsecase(transactionRepo).call(transactionId, 'expired');
  }

  /// Dipanggil listener notifikasi DANA (atau tombol "Tandai Lunas").
  Future<void> handlePaidTransaction(int transactionId, {int? amount}) async {
    if (state.isPaid) return;

    final isCurrentTransaction = state.transaction?.id == transactionId;
    if (!isCurrentTransaction) return;

    _cancelTimer();

    state = state.copyWith(
      paymentStatus: 'paid',
      clearError: true,
      remainingSeconds: 0,
    );
  }

  Future<void> markPaidManually() async {
    final transactionId = state.transaction?.id;
    if (transactionId == null || state.isPaid) return;

    state = state.copyWith(isManualChecking: true, clearError: true);

    final transactionRepo = ref.read(transactionRepositoryProvider);
    final result = await UpdatePaymentStatusUsecase(transactionRepo).call(transactionId, 'paid');

    state = state.copyWith(isManualChecking: false);

    if (result.isFailure) {
      state = state.copyWith(errorMessage: result.error?.toString());
      return;
    }

    final tts = ref.read(ttsServiceProvider);
    await tts.playCashRegister();
    await tts.speakAmount(state.expectedAmount);

    await handlePaidTransaction(transactionId);
  }

  /// Drain queue notifikasi native lalu coba cocokkan ulang.
  Future<void> checkPaymentManually() async {
    if (state.isPaid) return;

    state = state.copyWith(isManualChecking: true, clearError: true);

    try {
      await ref.read(danaListenerProvider.notifier).drainQueue();
    } catch (e) {
      cl('[DANA] drain queue gagal: $e');
    }

    if (!state.isPaid) {
      state = state.copyWith(isManualChecking: false);
    }
  }

  /// Batalkan pembayaran: hapus transaksi supaya stok kembali.
  Future<Result<void>> cancelPayment() async {
    _cancelTimer();

    final transactionId = state.transaction?.id;

    // Reset state (bukan 'expired') supaya dialog kedaluwarsa tidak sempat
    // muncul saat layar ditutup setelah pembatalan.
    state = const QrisPaymentState();

    if (transactionId == null) return Result.success(data: null);

    final transactionRepo = ref.read(transactionRepositoryProvider);
    return DeleteTransactionUsecase(transactionRepo).call(transactionId);
  }

  void reset() {
    _cancelTimer();
    state = const QrisPaymentState();
  }
}
