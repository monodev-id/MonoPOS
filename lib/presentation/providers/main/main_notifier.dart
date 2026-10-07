import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../domain/usecases/params/no_param.dart';
import '../../../domain/usecases/queued_action_usecases.dart';
import '../../../domain/usecases/user_usecases.dart';
import '../auth/auth_notifier.dart';
import '../products/products_notifier.dart';
import 'main_state.dart';

final mainNotifierProvider = NotifierProvider<MainNotifier, MainState>(
  MainNotifier.new,
);

class MainNotifier extends Notifier<MainState> {
  bool _listenerRegistered = false;

  @override
  MainState build() {
    return const MainState();
  }

  void _onConnectionChanged(bool isConnected) {
    state = state.copyWith(isHasInternet: isConnected);

    if (isConnected) {
      _processQueuedActions();
    }
  }

  String _requireUserId() {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated) return authState.user!.id;
    throw 'Unauthenticated!';
  }

  Future<void> initMainProvider() async {
    _listenSyncMode();
    unawaited(reconnectPrinterIfNeeded());
    await getUserData();
    _registerConnectivityListener();
    startPing();
  }

  Future<void> reconnectPrinterIfNeeded() async {
    final printerService = ref.read(printerServiceProvider);
    await printerService.reconnectSavedPrinter();
  }

  void _listenSyncMode() {
    final syncService = ref.read(syncServiceProvider);
    syncService.addListener(_onSyncModeChanged);
    state = state.copyWith(syncMode: syncService.mode);

    ref.onDispose(() {
      syncService.removeListener(_onSyncModeChanged);
    });
  }

  void _onSyncModeChanged() {
    final syncService = ref.read(syncServiceProvider);
    state = state.copyWith(syncMode: syncService.mode);

    if (syncService.isOnline) {
      _processQueuedActions();
    }

    _refreshSyncStatus();
  }

  void toggleSyncMode() {
    final syncService = ref.read(syncServiceProvider);
    syncService.toggleMode();
  }

  Future<void> syncNow() => _processQueuedActions();

  void _registerConnectivityListener() {
    if (_listenerRegistered) return;
    _listenerRegistered = true;

    final pingService = ref.read(pingServiceProvider);
    pingService.addConnectionStatusListener(_onConnectionChanged);

    ref.onDispose(() {
      pingService.removeConnectionStatusListener(_onConnectionChanged);
    });
  }

  Future<void> getUserData() async {
    final userId = _requireUserId();
    final userRepository = ref.read(userRepositoryProvider);

    var res = await GetUserUsecase(userRepository).call(userId);

    if (res.isSuccess) {
      state = state.copyWith(user: res.data);
    }

    ref.read(productsNotifierProvider.notifier).getAllProducts();
    ref.read(berandaProductsNotifierProvider.notifier).getAllProducts();

    state = state.copyWith(isLoaded: true);

    _refreshSyncStatus();
  }

  void startPing() {
    final pingService = ref.read(pingServiceProvider);
    pingService.startPing();
  }

  void stopPing() {
    final pingService = ref.read(pingServiceProvider);
    pingService.stopPing();
  }

  bool _isSyncing = false;

  Future<void> _processQueuedActions() async {
    if (_isSyncing) return;
    _isSyncing = true;

    state = state.copyWith(isSyncronizing: true);

    try {
      final repo = ref.read(queuedActionRepositoryProvider);
      final actions = await GetAllQueuedActionsUsecase(repo).call(NoParam());

      if (actions.isSuccess && actions.data != null) {
        for (final action in actions.data!) {
          final syncService = ref.read(syncServiceProvider);
          if (!syncService.isOnline) break;

          final process = ProcessQueuedActionUsecase(
            repo,
            productRemote: ref.read(productRemoteDatasourceProvider),
            userRemote: ref.read(userRemoteDatasourceProvider),
            transactionRemote: ref.read(transactionRemoteDatasourceProvider),
          );

          await process.call(action);
        }
      }
    } catch (_) {}

    _isSyncing = false;

    _refreshSyncStatus();
  }

  void _refreshSyncStatus() {
    final repo = ref.read(queuedActionRepositoryProvider);
    GetAllQueuedActionsUsecase(repo).call(NoParam()).then((res) {
      final hasPending = res.isSuccess && (res.data?.isNotEmpty ?? false);
      state = state.copyWith(
        isHasQueuedActions: hasPending,
        isSyncronizing: false,
      );
    });
  }
}
