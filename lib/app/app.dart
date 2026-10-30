import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale/app_locale.dart';
import '../presentation/providers/language/language_notifier.dart';
import '../presentation/providers/payment/dana_listener_notifier.dart';
import '../presentation/providers/theme/theme_notifier.dart';
import 'di/app_providers.dart';
import 'error/error_handler_builder.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // Listener mungkin belum siap (mis. DB belum selesai init), jadi aman
    // untuk dipanggil ulang saat aplikasi kembali aktif. Status izin juga
    // disegarkan supaya perubahan dari halaman Settings langsung terpakai.
    final listener = ref.read(danaListenerProvider.notifier);
    final snapshot = ref.read(danaListenerProvider);

    if (snapshot.isStarted) {
      listener.syncAfterResume();
      listener.drainQueue();
    } else {
      listener.ensureStarted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeNotifierProvider.select((s) => s.themeData));
    final locale = ref.watch(languageNotifierProvider.select((s) => s.locale));
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Mono POS',
      theme: theme,
      debugShowCheckedModeBanner: kDebugMode,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocale.supportedLocales,
      localizationsDelegates: AppLocale.localizationsDelegates,
      builder: (context, child) => ErrorHandlerBuilder(child: child),
    );
  }
}
