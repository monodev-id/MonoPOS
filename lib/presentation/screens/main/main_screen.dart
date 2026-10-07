import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/main/main_notifier.dart';
import '../splash/splash_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(mainNotifierProvider.notifier).initMainProvider();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    ref.read(mainNotifierProvider.notifier).reconnectPrinterIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final isLoaded = ref.watch(mainNotifierProvider.select((p) => p.isLoaded));
    final isWide = AppSizes.isTablet(context) || AppSizes.isDesktop(context);

    if (!isLoaded) {
      return const SplashScreen();
    }

    if (isWide) {
      return _WideLayout(child: widget.child);
    }

    return _NarrowLayout(child: widget.child);
  }
}

class _NarrowLayout extends StatelessWidget {
  final Widget child;

  const _NarrowLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final Widget child;

  const _WideLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _NavRail(),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(Icons.maps_home_work_outlined),
          label: AppLocalizations.of(context)!.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: AppLocalizations.of(context)!.products,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.receipt_long_rounded),
          label: AppLocalizations.of(context)!.transactions,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_circle_outlined),
          label: AppLocalizations.of(context)!.settings,
        ),
      ],
      currentIndex: _calculateSelectedIndex(ref),
      onTap: (int idx) => _onItemTapped(ref, idx),
    );
  }
}

class _NavRail extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationRail(
      selectedIndex: _calculateSelectedIndex(ref),
      onDestinationSelected: (int idx) => _onItemTapped(ref, idx),
      labelType: AppSizes.isTablet(context) ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: AppImage(
          image: 'assets/images/logomonopos-removebg-preview.png',
          width: 72,
          height: 72,
          imgProvider: ImgProvider.assetImage,
        ),
      ),
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.maps_home_work_outlined),
          selectedIcon: const Icon(Icons.maps_home_work),
          label: Text(AppLocalizations.of(context)!.home),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.dashboard_customize_outlined),
          selectedIcon: const Icon(Icons.dashboard_customize),
          label: Text(AppLocalizations.of(context)!.products),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.receipt_long_rounded),
          selectedIcon: const Icon(Icons.receipt_long),
          label: Text(AppLocalizations.of(context)!.transactions),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.account_circle_outlined),
          selectedIcon: const Icon(Icons.account_circle),
          label: Text(AppLocalizations.of(context)!.settings),
        ),
      ],
    );
  }
}

int _calculateSelectedIndex(WidgetRef ref) {
  final String location = ref.read(goRouterProvider).state.uri.path;

  if (location.startsWith('/home')) return 0;
  if (location.startsWith('/products')) return 1;
  if (location.startsWith('/transactions')) return 2;
  if (location.startsWith('/account')) return 3;

  return 0;
}

void _onItemTapped(WidgetRef ref, int index) {
  final router = ref.read(goRouterProvider);

  switch (index) {
    case 0:
      router.go('/home');
    case 1:
      router.go('/products');
    case 2:
      router.go('/transactions');
    case 3:
      router.go('/account');
  }
}
