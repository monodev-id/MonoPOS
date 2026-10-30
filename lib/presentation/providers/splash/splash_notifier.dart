import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../core/services/database/database_service.dart';
import '../../../core/utilities/console_logger.dart';
import '../auth/auth_notifier.dart';
import '../payment/dana_listener_notifier.dart';
import 'splash_state.dart';

final splashNotifierProvider = NotifierProvider<SplashNotifier, SplashState>(
  SplashNotifier.new,
);

class SplashNotifier extends Notifier<SplashState> {
  @override
  SplashState build() {
    return const SplashState();
  }

  Future<void> initializeApp() async {
    try {
      await DatabaseService.instance.init();
      await initializeDateFormatting();
      await ref.read(authNotifierProvider.notifier).restoreSession();
      state = state.copyWith(isInitializing: false, isInitialized: true);
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        errorMessage: e.toString(),
      );
      return;
    }

    // Listener notifikasi DANA baru boleh aktif setelah database siap,
    // karena queue notifikasi langsung diproses di sana.
    try {
      await ref.read(danaListenerProvider.notifier).ensureStarted();
    } catch (e) {
      cw('[DANA] gagal memulai listener saat startup: $e');
    }
  }
}
