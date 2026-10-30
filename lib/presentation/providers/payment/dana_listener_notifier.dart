import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/payment/dana_notification_parser.dart';
import '../../../core/services/payment/dana_notification_service.dart';
import '../../../core/services/payment/dana_payment_store.dart';
import '../../../core/utilities/console_logger.dart';
import '../../../domain/usecases/transaction_usecases.dart';
import 'payment_notifier.dart';

class DanaListenerState {
  final bool isEnabled;
  final bool isStarted;
  final bool isPermissionGranted;
  final bool isServiceConnected;
  final int processedCount;
  final String? lastError;
  final List<DanaNotificationRecord> recentNotifications;

  const DanaListenerState({
    this.isEnabled = true,
    this.isStarted = false,
    this.isPermissionGranted = false,
    this.isServiceConnected = false,
    this.processedCount = 0,
    this.lastError,
    this.recentNotifications = const [],
  });

  DanaListenerState copyWith({
    bool? isEnabled,
    bool? isStarted,
    bool? isPermissionGranted,
    bool? isServiceConnected,
    int? processedCount,
    String? lastError,
    List<DanaNotificationRecord>? recentNotifications,
    bool clearError = false,
  }) {
    return DanaListenerState(
      isEnabled: isEnabled ?? this.isEnabled,
      isStarted: isStarted ?? this.isStarted,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isServiceConnected: isServiceConnected ?? this.isServiceConnected,
      processedCount: processedCount ?? this.processedCount,
      lastError: clearError ? null : (lastError ?? this.lastError),
      recentNotifications: recentNotifications ?? this.recentNotifications,
    );
  }
}

final danaListenerProvider = NotifierProvider<DanaListenerNotifier, DanaListenerState>(
  DanaListenerNotifier.new,
);

/// Selalu mendengarkan notifikasi aplikasi DANA dan menandai transaksi lunas.
class DanaListenerNotifier extends Notifier<DanaListenerState> {
  StreamSubscription<DanaNotificationEvent>? _subscription;
  bool _starting = false;

  @override
  DanaListenerState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });

    final enabled = ref.read(sharedPreferencesProvider).getBool(Constants.danaListenerEnabled) ?? true;

    return DanaListenerState(isEnabled: enabled);
  }

  DanaNotificationService get _service => ref.read(danaNotificationServiceProvider);

  DanaPaymentStore get _store => ref.read(danaPaymentStoreProvider);

  /// Mulai mendengarkan notifikasi DANA.
  ///
  /// Harus dipanggil setelah database siap (lihat `SplashNotifier`), karena
  /// queue notifikasi langsung diproses di sini.
  Future<void> ensureStarted() async {
    if (_starting) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final enabled = prefs.getBool(Constants.danaListenerEnabled) ?? true;

    if (!enabled) {
      await _stopListening();
      state = state.copyWith(isEnabled: false, isStarted: false);
      return;
    }

    if (state.isStarted) {
      try {
        await refreshStatus();
      } catch (e) {
        cl('[DANA] refresh status gagal: $e');
      }
      return;
    }

    _starting = true;

    try {
      final packages = (prefs.getString(Constants.danaListenerPackages) ?? 'id.dana,id.dana.kasir')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await _service.setAllowedPackages(packages);

      final permission = await _service.hasPermission();
      final connected = await _service.isConnected();

      _subscription ??= _service.events.listen(
        (event) => _processEvent(event),
        onError: (Object error) {
          cl('[DANA] event error: $error');
          state = state.copyWith(lastError: error.toString());
        },
      );

      state = state.copyWith(
        isEnabled: true,
        isStarted: true,
        isPermissionGranted: permission,
        isServiceConnected: connected,
      );
    } catch (e) {
      cl('[DANA] gagal memulai listener: $e');
      state = state.copyWith(lastError: e.toString());
      return;
    } finally {
      _starting = false;
    }

    try {
      await drainQueue();
      await _store.sweepExpired();
      await refreshStatus();
    } catch (e) {
      cl('[DANA] sinkronisasi awal listener gagal: $e');
      state = state.copyWith(lastError: e.toString());
    }
  }

  /// Nyalakan/matikan listener sesuai preferensi pengguna.
  Future<void> setEnabled(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(Constants.danaListenerEnabled, value);

    if (!value) {
      await _stopListening();
      state = state.copyWith(isEnabled: false, isStarted: false);
      return;
    }

    state = state.copyWith(isEnabled: true, isStarted: false);
    await ensureStarted();
  }

  Future<void> _stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> refreshStatus() async {
    final permission = await _service.hasPermission();
    final connected = await _service.isConnected();
    final recent = await _store.getRecentNotifications(limit: 20);

    state = state.copyWith(
      isPermissionGranted: permission,
      isServiceConnected: connected,
      recentNotifications: recent,
    );
  }

  Future<void> drainQueue() async {
    if (_starting) return;

    try {
      final events = await _service.getPendingEvents();
      if (events.isEmpty) return;

      for (final event in events) {
        await _processEvent(event, ack: false);
      }

      await _service.ackEvents(events.map((e) => e.key).toList());
      await refreshStatus();
    } catch (e) {
      cl('[DANA] drain queue gagal: $e');
      state = state.copyWith(lastError: e.toString());
    }
  }

  Future<void> _processEvent(DanaNotificationEvent event, {bool ack = true}) async {
    try {
      await _handleEvent(event, ack: ack);
    } catch (e) {
      cl('[DANA] gagal memproses notifikasi ${event.key}: $e');
      state = state.copyWith(lastError: e.toString());
    }
  }

  Future<void> _handleEvent(DanaNotificationEvent event, {required bool ack}) async {
    final parsed = parseDanaNotification(
      title: event.title,
      body: event.body,
      packageName: event.packageName,
    );

    final isNew = await _store.saveNotification(
      notifKey: event.key,
      packageName: event.packageName,
      title: event.title,
      body: event.body,
      amount: parsed.amount,
      postedAt: event.postedAt == 0 ? null : DateTime.fromMillisecondsSinceEpoch(event.postedAt).toIso8601String(),
      status: parsed.isIncomingPayment ? 'unmatched' : 'ignored',
    );

    if (ack) {
      await _service.ackEvents([event.key]);
    }

    if (!isNew) return;

    if (!parsed.isIncomingPayment) {
      cl('[DANA] notifikasi diabaikan: ${parsed.reason}');
      await refreshStatus();
      return;
    }

    await _store.sweepExpired();

    try {
      await _matchPayment(event, parsed.amount!);
    } catch (e) {
      cl('[DANA] matching gagal: $e');
      state = state.copyWith(lastError: e.toString());
    }

    await refreshStatus();
  }

  Future<void> _matchPayment(DanaNotificationEvent event, int amount) async {
    final pending = await _store.findPendingByAmount(amount);

    if (pending.length == 1) {
      await _markPaid(pending.single, amount, event, late: false);
      return;
    }

    if (pending.length > 1) {
      cl('[DANA] nominal $amount cocok dengan ${pending.length} transaksi, tidak ditandai otomatis');
      await _store.updateNotificationStatus(event.key, status: 'ambiguous');
      return;
    }

    final expired = await _store.findExpiredByAmount(amount);
    if (expired.length == 1) {
      await _markPaid(expired.single, amount, event, late: true);
      return;
    }

    cl('[DANA] notifikasi Rp$amount belum cocok dengan transaksi pending');
    await _store.updateNotificationStatus(event.key, status: 'unmatched');
  }

  Future<void> _markPaid(
    DanaPendingTransaction transaction,
    int amount,
    DanaNotificationEvent event, {
    required bool late,
  }) async {
    final repository = ref.read(transactionRepositoryProvider);
    final result = await UpdatePaymentStatusUsecase(repository).call(transaction.id, 'paid');

    if (result.isFailure) {
      cl('[DANA] gagal menandai transaksi ${transaction.id} lunas: ${result.error}');
      return;
    }

    await _store.updateNotificationStatus(
      event.key,
      status: late ? 'matched_late' : 'matched',
      matchedTransactionId: transaction.id,
    );

    final tts = ref.read(ttsServiceProvider);
    await tts.playCashRegister();
    await tts.speakAmount(amount);

    await ref.read(qrisPaymentNotifierProvider.notifier).handlePaidTransaction(transaction.id, amount: amount);

    state = state.copyWith(processedCount: state.processedCount + 1);
    cl('[DANA] transaksi ${transaction.id} lunas via notifikasi (Rp$amount)');
  }

  Future<void> clearHistory() async {
    await _store.clearNotifications();
    await refreshStatus();
  }
}
