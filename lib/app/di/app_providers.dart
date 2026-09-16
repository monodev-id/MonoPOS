import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/connectivity/ping_service.dart';
import '../../core/services/database/database_service.dart';
import '../../core/services/info/device_info_service.dart';
import '../../core/services/logger/error_logger_service.dart';
import '../../core/services/payment/klik_qris_payment_service.dart';
import '../../core/services/printer/printer_service.dart';
import '../../core/services/supabase/supabase_config.dart';
import '../../core/services/tts/tts_service.dart';
import '../../core/services/supabase/supabase_service.dart';
import '../../core/services/sync/sync_service.dart';
import '../../data/datasources/interfaces/app_update_datasource.dart';
import '../../data/datasources/interfaces/auth_datasource.dart';
import '../../data/datasources/interfaces/customer_datasource.dart';
import '../../data/datasources/interfaces/product_datasource.dart';
import '../../data/datasources/interfaces/transaction_datasource.dart';
import '../../data/datasources/interfaces/user_datasource.dart';
import '../../data/datasources/local/auth_local_datasource_impl.dart';
import '../../data/datasources/local/customer_local_datasource_impl.dart';
import '../../data/datasources/local/product_local_datasource_impl.dart';
import '../../data/datasources/local/queued_action_local_datasource_impl.dart';
import '../../data/datasources/local/transaction_local_datasource_impl.dart';
import '../../data/datasources/local/user_local_datasource_impl.dart';
import '../../data/datasources/remote/app_update_remote_datasource_impl.dart';
import '../../data/datasources/remote/auth_remote_datasource_impl.dart';
import '../../data/datasources/remote/customer_remote_datasource_impl.dart';
import '../../data/datasources/remote/product_remote_datasource_impl.dart';
import '../../data/datasources/remote/transaction_remote_datasource_impl.dart';
import '../../data/datasources/remote/user_remote_datasource_impl.dart';
import '../../data/repositories/app_update_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/queued_action_repository_impl.dart';
import '../../data/repositories/storage_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/queued_action_repository.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../presentation/providers/auth/auth_notifier.dart';
import '../../presentation/providers/language/language_notifier.dart';
import '../routes/app_routes.dart';

// Startup overrides
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden at app startup.'),
);

// Third parties
final deviceInfoPluginProvider = Provider<DeviceInfoPlugin>((ref) => DeviceInfoPlugin());

// Routes
final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ChangeNotifier();
  ref.onDispose(refreshNotifier.dispose);

  ref.listen(authNotifierProvider, (_, __) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshNotifier.notifyListeners();
    });
  });

  return AppRoutes().build(ref: ref, refreshListenable: refreshNotifier);
});

// Services
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService.instance);
final pingServiceProvider = Provider<PingService>((ref) => PingService());
final deviceInfoServiceProvider = Provider<DeviceInfoService>(
  (ref) => DeviceInfoService(ref.watch(deviceInfoPluginProvider)),
);
final errorLoggerServiceProvider = Provider<ErrorLoggerService>(
  (ref) => ErrorLoggerService(),
);
final printerServiceProvider = Provider<PrinterService>((ref) {
  final service = PrinterService(ref.watch(sharedPreferencesProvider));
  final locale = ref.watch(languageNotifierProvider.select((s) => s.locale));
  service.setLocale(locale.languageCode);
  return service;
});

final klikQrisPaymentServiceProvider = Provider<KlikQrisPaymentService>(
  (ref) => KlikQrisPaymentService(ref.watch(sharedPreferencesProvider)),
);

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService(ref.watch(sharedPreferencesProvider));
  final locale = ref.watch(languageNotifierProvider.select((s) => s.locale));
  service.setLocale(locale.languageCode);
  return service;
});

// Sync
final syncServiceProvider = Provider<SyncService>((ref) {
  final pingService = ref.watch(pingServiceProvider);
  return SyncService(pingService);
});

// Supabase
final supabaseInitializedProvider = FutureProvider<bool>((ref) async {
  return SupabaseService.initialize();
});

// Datasources
// Local Datasources
final authLocalDataSourceProvider = Provider<AuthLocalDataSourceImpl>(
  (ref) => AuthLocalDataSourceImpl(
    ref.watch(userLocalDatasourceProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);
final productLocalDatasourceProvider = Provider<ProductLocalDatasourceImpl>(
  (ref) => ProductLocalDatasourceImpl(ref.watch(databaseServiceProvider)),
);
final transactionLocalDatasourceProvider = Provider<TransactionLocalDatasourceImpl>(
  (ref) => TransactionLocalDatasourceImpl(ref.watch(databaseServiceProvider)),
);
final userLocalDatasourceProvider = Provider<UserLocalDatasourceImpl>(
  (ref) => UserLocalDatasourceImpl(ref.watch(databaseServiceProvider)),
);
final queuedActionLocalDatasourceProvider = Provider<QueuedActionLocalDatasourceImpl>(
  (ref) => QueuedActionLocalDatasourceImpl(ref.watch(databaseServiceProvider)),
);

// Remote Datasources
final authRemoteDataSourceProvider = Provider<AuthDataSource?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return AuthRemoteDataSourceImpl();
});
final productRemoteDatasourceProvider = Provider<ProductDatasource?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return ProductRemoteDatasourceImpl();
});
final transactionRemoteDatasourceProvider = Provider<TransactionDatasource?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return TransactionRemoteDatasourceImpl();
});
final userRemoteDatasourceProvider = Provider<UserDatasource?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return UserRemoteDatasourceImpl();
});

// Repositories
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    authLocalDataSource: ref.watch(authLocalDataSourceProvider),
    authRemoteDataSource: ref.watch(authRemoteDataSourceProvider),
  ),
);
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(
    productLocalDatasource: ref.watch(productLocalDatasourceProvider),
    productRemoteDatasource: ref.watch(productRemoteDatasourceProvider),
    syncService: ref.watch(syncServiceProvider),
    queuedActionRepository: ref.watch(queuedActionRepositoryProvider),
  ),
);
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepositoryImpl(
    transactionLocalDatasource: ref.watch(transactionLocalDatasourceProvider),
    transactionRemoteDatasource: ref.watch(transactionRemoteDatasourceProvider),
    syncService: ref.watch(syncServiceProvider),
    queuedActionRepository: ref.watch(queuedActionRepositoryProvider),
  ),
);
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(
    userLocalDatasource: ref.watch(userLocalDatasourceProvider),
    userRemoteDatasource: ref.watch(userRemoteDatasourceProvider),
    syncService: ref.watch(syncServiceProvider),
    queuedActionRepository: ref.watch(queuedActionRepositoryProvider),
  ),
);
final queuedActionRepositoryProvider = Provider<QueuedActionRepository>(
  (ref) => QueuedActionRepositoryImpl(
    localDatasource: ref.watch(queuedActionLocalDatasourceProvider),
  ),
);

// Customer Datasources
final customerLocalDatasourceProvider = Provider<CustomerLocalDatasourceImpl>(
  (ref) => CustomerLocalDatasourceImpl(ref.watch(databaseServiceProvider)),
);
final customerRemoteDatasourceProvider = Provider<CustomerDatasource?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  return CustomerRemoteDatasourceImpl();
});

// Customer Repository
final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepositoryImpl(
    customerLocalDatasource: ref.watch(customerLocalDatasourceProvider),
    customerRemoteDatasource: ref.watch(customerRemoteDatasourceProvider),
    syncService: ref.watch(syncServiceProvider),
    queuedActionRepository: ref.watch(queuedActionRepositoryProvider),
  ),
);

// Storage
final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => StorageRepositoryImpl(),
);

// App Update
final appUpdateDatasourceProvider = Provider<AppUpdateDatasource>(
  (ref) => AppUpdateRemoteDatasourceImpl(),
);
final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
  (ref) => AppUpdateRepositoryImpl(
    appUpdateDatasource: ref.watch(appUpdateDatasourceProvider),
  ),
);
