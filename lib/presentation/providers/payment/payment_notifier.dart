import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../core/services/payment/klik_qris_payment_service.dart';
import '../../../core/utilities/console_logger.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/transaction_usecases.dart';
import 'payment_state.dart';

final klikQrisPaymentNotifierProvider = NotifierProvider<KlikQrisPaymentNotifier, KlikQrisPaymentState>(
  KlikQrisPaymentNotifier.new,
);

class KlikQrisPaymentNotifier extends Notifier<KlikQrisPaymentState> {
  Timer? _pollTimer;
  Timer? _elapsedTimer;

  @override
  KlikQrisPaymentState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
      _elapsedTimer?.cancel();
    });
    return const KlikQrisPaymentState();
  }

  Future<Result<int>> startKlikQrisPayment({
    required TransactionEntity transaction,
    required int totalAmount,
    String? description,
    bool isDirect = false,
  }) async {
    final klikQrisService = ref.read(klikQrisPaymentServiceProvider);

    if (!klikQrisService.isConfigured) {
      const message = 'KlikQRIS belum dikonfigurasi. Atur API Key dan ID Merchant terlebih dahulu.';
      state = state.copyWith(isPolling: false, errorMessage: message);
      return Result.failure(error: message);
    }

    if (totalAmount <= 0) {
      const message = 'Nominal pembayaran tidak valid.';
      state = state.copyWith(isPolling: false, errorMessage: message);
      return Result.failure(error: message);
    }

    state = state.copyWith(
      isPolling: true,
      isDirect: isDirect,
      clearError: true,
      manualCheckPending: false,
    );

    try {
      final transactionRepo = ref.read(transactionRepositoryProvider);
      final saveResult = await CreateTransactionUsecase(transactionRepo).call(
        transaction.copyWith(paymentStatus: 'pending'),
      );

      if (saveResult.isFailure) {
        return Result.failure(error: saveResult.error ?? 'Failed to save transaction');
      }

      final transactionId = saveResult.data!;
      final orderId = transactionId.toString();

      final qrisResult = await klikQrisService.generateQris(
        orderId: orderId,
        grossAmount: totalAmount,
        description: description ?? transaction.description,
      );

      if (qrisResult.isFailure) {
        await DeleteTransactionUsecase(transactionRepo).call(transactionId);
        state = state.copyWith(isPolling: false, errorMessage: qrisResult.error?.toString());
        return Result.failure(error: qrisResult.error ?? 'Failed to create KlikQRIS invoice');
      }

      final qrisData = qrisResult.data!;
      final paymentQR = qrisData.qrImageBase64.isNotEmpty ? qrisData.qrImageBase64 : qrisData.qrUrl;
      final paymentTimeout = qrisData.expiredMinutes * 60;

      cl(
        '[KlikQRIS] paymentQR: len=${paymentQR.length} prefix=${paymentQR.length > 20 ? paymentQR.substring(0, 20) : paymentQR}',
      );

      await UpdatePaymentStatusUsecase(transactionRepo).call(
        transactionId,
        'pending',
        paymentQR: paymentQR,
        paymentExternalId: qrisData.orderId,
      );

      state = state.copyWith(
        transaction: transaction.copyWith(
          id: transactionId,
          paymentStatus: 'pending',
          paymentQR: paymentQR,
          paymentExternalId: qrisData.orderId,
        ),
        qrCode: paymentQR,
        paymentStatus: 'pending',
        isPolling: false,
        elapsedSeconds: 0,
        orderId: qrisData.orderId,
        signature: qrisData.signature,
        totalAmount: qrisData.totalAmount,
        isDirect: isDirect,
        clearError: true,
        manualCheckPending: false,
      );

      _startPolling(transactionId, paymentTimeout);

      return Result.success(data: transactionId);
    } catch (e) {
      state = state.copyWith(isPolling: false, errorMessage: e.toString());
      return Result.failure(error: e.toString());
    }
  }

  void _startPolling(int transactionId, int timeoutSeconds) {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.elapsedSeconds >= timeoutSeconds) {
        _onPaymentExpired(transactionId, message: 'Waktu pembayaran habis');
        return;
      }
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });

    _autoPollStatus(transactionId);
  }

  Future<void> _autoPollStatus(int transactionId) async {
    final klikQrisService = ref.read(klikQrisPaymentServiceProvider);
    int attempts = 0;

    if (state.orderId.isEmpty) return;

    while (state.paymentStatus == 'pending' && attempts < 3) {
      await Future.delayed(const Duration(seconds: 15));
      attempts++;

      if (state.orderId.isEmpty || state.paymentStatus != 'pending') return;

      final result = await klikQrisService.queryQrisStatus(
        orderId: state.orderId,
        expectedTotalAmount: state.totalAmount > 0 ? state.totalAmount : null,
      );

      if (result.isFailure) {
        cl('[KlikQRIS] auto poll failed: ${result.error}');
        continue;
      }

      switch (result.data!) {
        case KlikQrisPaymentStatus.paid:
          await _onPaymentSuccess(transactionId);
          return;
        case KlikQrisPaymentStatus.expired:
          await _onPaymentExpired(transactionId);
          return;
        case KlikQrisPaymentStatus.pending:
          break;
      }
    }

    if (state.paymentStatus == 'pending') {
      state = state.copyWith(autoCheckDone: true);
    }
  }

  Future<void> checkPaymentManually() async {
    if (state.transaction == null || state.paymentStatus != 'pending' || state.orderId.isEmpty) {
      return;
    }

    state = state.copyWith(
      isManualChecking: true,
      manualCheckPending: false,
      clearError: true,
    );

    final klikQrisService = ref.read(klikQrisPaymentServiceProvider);
    final result = await klikQrisService.queryQrisStatus(
      orderId: state.orderId,
      expectedTotalAmount: state.totalAmount > 0 ? state.totalAmount : null,
    );

    if (result.isFailure) {
      cl('[KlikQRIS] manual check failed: ${result.error}');
      state = state.copyWith(
        isManualChecking: false,
        errorMessage: result.error?.toString() ?? 'Gagal cek status pembayaran',
      );
      return;
    }

    switch (result.data!) {
      case KlikQrisPaymentStatus.paid:
        await _onPaymentSuccess(state.transaction!.id!);
      case KlikQrisPaymentStatus.expired:
        await _onPaymentExpired(state.transaction!.id!);
      case KlikQrisPaymentStatus.pending:
        state = state.copyWith(
          isManualChecking: false,
          manualCheckPending: true,
        );
    }
  }

  Future<void> _onPaymentSuccess(int transactionId) async {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();

    state = state.copyWith(
      paymentStatus: 'paid',
      clearError: true,
      manualCheckPending: false,
    );

    final transactionRepo = ref.read(transactionRepositoryProvider);
    await UpdatePaymentStatusUsecase(transactionRepo).call(transactionId, 'paid');

    final transactionResult = await GetTransactionUsecase(transactionRepo).call(transactionId);
    if (transactionResult.isSuccess && transactionResult.data != null) {
      final tts = ref.read(ttsServiceProvider);
      await tts.playCashRegister();
      final spokenAmount = state.totalAmount > 0 ? state.totalAmount : transactionResult.data!.totalAmount;
      await tts.speakAmount(spokenAmount);
    }
  }

  Future<void> _onPaymentExpired(int transactionId, {String? message}) async {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();

    state = state.copyWith(
      paymentStatus: 'expired',
      errorMessage: message ?? 'Pembayaran kedaluwarsa',
      isManualChecking: false,
      manualCheckPending: false,
    );

    final transactionRepo = ref.read(transactionRepositoryProvider);
    await UpdatePaymentStatusUsecase(transactionRepo).call(transactionId, 'expired');
  }

  void cancelPolling() {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
  }

  void reset() {
    _pollTimer?.cancel();
    _elapsedTimer?.cancel();
    state = const KlikQrisPaymentState();
  }
}
