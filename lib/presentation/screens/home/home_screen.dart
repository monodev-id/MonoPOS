import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/services/sync/sync_service.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../domain/entities/app_update_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/product_tier_entity.dart';
import '../../../domain/entities/product_unit_entity.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../../providers/account/app_update_notifier.dart';
import '../../providers/auth/auth_notifier.dart';
import '../../providers/home/home_notifier.dart';
import '../../providers/main/main_notifier.dart';
import '../../providers/products/products_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading_more_indicator.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';
import '../../../generated/app_localizations.dart';
import '../products/components/products_card.dart';
import 'components/barcode_hid_listener.dart';
import 'components/barcode_scanner_screen.dart';
import 'components/cart_panel_body.dart';
import 'components/cart_panel_footer.dart';
import 'components/cart_panel_header.dart';
import 'components/order_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final scrollController = ScrollController();
  final searchFieldController = TextEditingController();
  final panelController = PanelController();

  @override
  void initState() {
    scrollController.addListener(scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onRefresh();
      maybeCheckForUpdate();
    });
    super.initState();
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    searchFieldController.dispose();
    super.dispose();
  }

  void scrollListener() {
    if (!scrollController.hasClients) return;

    final productsState = ref.read(berandaProductsNotifierProvider);

    if (productsState.isLoadingMore || !productsState.hasMore) return;

    final position = scrollController.position;

    if (position.pixels >= position.maxScrollExtent - 50) {
      ref.read(berandaProductsNotifierProvider.notifier).getAllProducts(offset: productsState.allProducts?.length);
    }
  }

  void maybeLoadMore() {
    if (!mounted || !scrollController.hasClients) return;

    final productsState = ref.read(berandaProductsNotifierProvider);

    if (productsState.isLoadingMore || !productsState.hasMore) return;
    if (productsState.allProducts == null) return;

    if (scrollController.position.maxScrollExtent <= 0) {
      ref.read(berandaProductsNotifierProvider.notifier).getAllProducts(offset: productsState.allProducts?.length);
    }
  }

  Future<void> onRefresh() async {
    await ref.read(berandaProductsNotifierProvider.notifier).getAllProducts();
  }

  void maybeCheckForUpdate() {
    final authState = ref.read(authNotifierProvider);
    final isAdmin = authState.user?.role?.value == 'admin';

    if (!isAdmin) return;

    final updateState = ref.read(appUpdateNotifierProvider);

    if (updateState.status != AppUpdateStatus.idle) return;

    ref.read(appUpdateNotifierProvider.notifier).checkForUpdate();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => maybeLoadMore());

    final isWide = AppSizes.isTablet(context) || AppSizes.isDesktop(context);

    if (isWide) {
      return Scaffold(
        appBar: _AppBar(searchFieldController: searchFieldController),
        body: Column(
          children: [
            const _UpdateBanner(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _ProductGrid(
                      scrollController: scrollController,
                      searchFieldController: searchFieldController,
                      onRefresh: onRefresh,
                    ),
                  ),
                  SizedBox(
                    width: 380,
                    child: _CartPanel(
                      panelController: panelController,
                      onRefresh: onRefresh,
                      isPanelUsed: false,
                    ),
                  ),
                ],
              ),
            ),
            const BarcodeHidListener(),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SlidingUpPanel(
              controller: panelController,
              minHeight: 88,
              maxHeight: AppSizes.screenHeight(context) - AppSizes.appBarHeight() - AppSizes.viewPadding(context).top,
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
                  offset: const Offset(0, -4),
                  blurRadius: 12,
                ),
              ],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radius * 2),
                topRight: Radius.circular(AppSizes.radius * 2),
              ),
              body: Scaffold(
                appBar: _AppBar(searchFieldController: searchFieldController),
                body: Column(
                  children: [
                    const _UpdateBanner(),
                    Expanded(
                      child: _ProductGrid(
                        scrollController: scrollController,
                        searchFieldController: searchFieldController,
                        onRefresh: onRefresh,
                      ),
                    ),
                  ],
                ),
              ),
              header: CartPanelHeader(panelController: panelController),
              panel: CartPanelBody(panelController: panelController),
              footer: CartPanelFooter(panelController: panelController),
              onPanelOpened: () => ref.read(homeNotifierProvider.notifier).onChangedIsPanelExpanded(true),
              onPanelClosed: () => ref.read(homeNotifierProvider.notifier).onChangedIsPanelExpanded(false),
            ),
          ),
          const BarcodeHidListener(),
        ],
      ),
    );
  }
}

class _AppBar extends ConsumerWidget implements PreferredSizeWidget {
  final TextEditingController searchFieldController;

  const _AppBar({required this.searchFieldController});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const _Title(),
      elevation: 0,
      shadowColor: Colors.transparent,
      actions: const [
        _ScanButton(),
        _SyncButton(),
        _NetworkInfo(),
      ],
    );
  }
}

class _UpdateBanner extends ConsumerStatefulWidget {
  const _UpdateBanner();

  @override
  ConsumerState<_UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<_UpdateBanner> {
  var _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));

    if (!isAdmin) return const SizedBox.shrink();

    final updateState = ref.watch(appUpdateNotifierProvider);
    final info = updateState.info;

    if (updateState.status != AppUpdateStatus.available || info == null || !info.isUpdateAvailable) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.padding, 8, AppSizes.padding, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radius + 8),
        onTap: () => context.push('/account/app-update'),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.padding / 1.5),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppSizes.radius + 8),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.system_update_rounded, color: scheme.onPrimary, size: 22),
              ),
              const SizedBox(width: AppSizes.padding / 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.update_available,
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'v${info.currentVersion} → v${info.latestVersion}',
                      style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: scheme.primary),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                iconSize: 18,
                onPressed: () => setState(() => _dismissed = true),
                icon: Icon(Icons.close_rounded, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  final PanelController panelController;
  final Future<void> Function() onRefresh;
  final bool isPanelUsed;

  const _CartPanel({
    required this.panelController,
    required this.onRefresh,
    this.isPanelUsed = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      child: Column(
        children: [
          CartPanelHeader(panelController: panelController),
          Expanded(
            child: CartPanelBody(panelController: panelController, isPanelUsed: isPanelUsed),
          ),
          CartPanelFooter(panelController: panelController, isPanelUsed: isPanelUsed),
        ],
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  final ScrollController scrollController;
  final TextEditingController searchFieldController;
  final Future<void> Function() onRefresh;

  const _ProductGrid({
    required this.scrollController,
    required this.searchFieldController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProducts = ref.watch(berandaProductsNotifierProvider.select((p) => p.allProducts));
    final isLoadingMore = ref.watch(berandaProductsNotifierProvider.select((p) => p.isLoadingMore));

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Scrollbar(
        child: CustomScrollView(
          controller: scrollController,
          physics: (allProducts?.isEmpty ?? true)
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              collapsedHeight: 70,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                child: _SearchField(controller: searchFieldController),
              ),
            ),

            SliverLayoutBuilder(
              builder: (context, constraint) {
                if (allProducts == null) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: true,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 140),
                      child: AppProgressIndicator(),
                    ),
                  );
                }

                if (allProducts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: true,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 140),
                      child: AppEmptyState(
                        subtitle: 'No products available, add product to continue',
                        buttonText: 'Add Product',
                        onTapButton: () => context.push('/products/product-create'),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.padding, 2, AppSizes.padding, AppSizes.padding),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 1 / 1.5,
                      crossAxisSpacing: AppSizes.padding / 2,
                      mainAxisSpacing: AppSizes.padding / 2,
                    ),
                    itemCount: allProducts.length,
                    itemBuilder: (context, i) {
                      return _ProductCard(product: allProducts[i]);
                    },
                  ),
                );
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 140),
              sliver: SliverToBoxAdapter(
                child: AppLoadingMoreIndicator(isLoading: isLoadingMore),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends ConsumerWidget {
  const _Title();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(mainNotifierProvider.select((p) => p.user));

    return Row(
      children: [
        AppImage(
          image: user?.imageUrl ?? '',
          borderRadius: BorderRadius.circular(100),
          width: 30,
          height: 30,
          backgroundColor: Theme.of(context).colorScheme.surface,
          errorWidget: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                height: 0,
              ),
            ),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScanButton extends ConsumerWidget {
  const _ScanButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 0),
      child: AppButton(
        height: 26,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
        buttonColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
        child: Icon(
          Icons.qr_code_scanner_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () async {
          final barcode = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => const BarcodeScannerScreen(),
            ),
          );

          if (barcode == null || barcode.isEmpty) return;

          final products = ref.read(berandaProductsNotifierProvider).allProducts;
          final product = products?.where((p) => p.barcode == barcode).firstOrNull;

          if (product == null) {
            if (!context.mounted) return;
            AppSnackBar.showError('Produk dengan barcode "$barcode" tidak ditemukan');
            return;
          }

          final homeState = ref.read(homeNotifierProvider);
          double currentQty =
              homeState.orderedProducts.where((e) => e.productId == product.id).firstOrNull?.quantity ?? 0.0;
          bool isGrosir = homeState.selectedPriceType == 'grosir';

          List<ProductUnitEntity> scanEffectiveUnits;
          if (product.units.isNotEmpty) {
            scanEffectiveUnits = product.units;
          } else {
            scanEffectiveUnits = [
              ProductUnitEntity(
                unitName: product.unit,
                conversionValue: 1,
                price: product.price,
                wholesalePrice: product.wholesalePrice,
                isBase: true,
                productId: product.id ?? 0,
              ),
            ];
          }

          if (!context.mounted) return;

          final scanDialogKey = GlobalKey<_AddToCartDialogState>();

          AppDialog.show(
            title: 'Enter Amount',
            child: _AddToCartDialog(
              key: scanDialogKey,
              product: product,
              initialQuantity: currentQty,
              isGrosir: isGrosir,
              effectiveUnits: scanEffectiveUnits,
            ),
            rightButtonText: AppLocalizations.of(context)!.home_addToCart,
            leftButtonText: AppLocalizations.of(context)!.home_cancel,
            onTapLeftButton: (context) {
              context.pop();
            },
            onTapRightButton: (context) {
              var state = scanDialogKey.currentState;
              if (state == null) return;

              ref
                  .read(homeNotifierProvider.notifier)
                  .onAddOrderedProduct(
                    product,
                    state.quantity == 0 ? 1.0 : state.quantity,
                    unitName: state.selectedUnit,
                    conversionValue: state.conversionValue,
                    overridePrice: state.price,
                    priceType: state.priceType,
                  );
              context.pop();
            },
          );
        },
      ),
    );
  }
}

class _SyncButton extends ConsumerWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConfigured = SupabaseConfig.isConfigured;
    final isHasQueuedActions = ref.watch(mainNotifierProvider.select((p) => p.isHasQueuedActions));
    final isSyncronizing = ref.watch(mainNotifierProvider.select((p) => p.isSyncronizing));

    final (IconData icon, Color color, String label) = !isConfigured
        ? (Icons.cloud_off_sharp, Theme.of(context).colorScheme.error, 'Sync off')
        : isSyncronizing
        ? (Icons.sync, Theme.of(context).colorScheme.primary, 'Sync...')
        : isHasQueuedActions
        ? (Icons.sync_problem_sharp, Colors.orange, 'Pending')
        : (Icons.cloud_done_sharp, Theme.of(context).colorScheme.primary, 'Synced');

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.padding / 4),
      child: AppButton(
        height: 26,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
        buttonColor: isSyncronizing || isHasQueuedActions
            ? Theme.of(context).colorScheme.surfaceContainer
            : Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: AppSizes.padding / 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        onTap: () {
          if (!SupabaseConfig.isConfigured) {
            AppSnackBar.show('Sync nonaktif: build tanpa config.json (--dart-define-from-file config.json)');
            return;
          }

          final notifier = ref.read(mainNotifierProvider.notifier);
          notifier.syncNow();
          notifier.getUserData();
          final syncState = ref.read(mainNotifierProvider);
          final msg = syncState.isSyncronizing
              ? 'Sync: Mengirim data antrian...'
              : syncState.isHasQueuedActions
              ? 'Sync: ${syncState.isHasInternet ? "Ada antrian, mengirim..." : "Tidak ada koneksi, menunggu online"}'
              : 'Sync: Semua data sudah tersinkronisasi';
          AppSnackBar.show(msg);
        },
      ),
    );
  }
}

class _NetworkInfo extends ConsumerWidget {
  const _NetworkInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainState = ref.watch(mainNotifierProvider);
    final isOnline = mainState.isHasInternet;
    final syncMode = mainState.syncMode;

    final (IconData icon, Color color, String label) = switch (syncMode) {
      SyncMode.online => (Icons.wifi_rounded, Colors.green, 'Online'),
      SyncMode.offline => (Icons.wifi_off_rounded, Colors.red, 'Offline'),
      SyncMode.auto =>
        isOnline
            ? (Icons.wifi_rounded, Theme.of(context).colorScheme.primary, 'Auto')
            : (Icons.wifi_off_rounded, Theme.of(context).colorScheme.outline, 'Auto'),
    };

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.padding),
      child: AppButton(
        height: 26,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
        buttonColor: syncMode == SyncMode.offline || (!isOnline && syncMode == SyncMode.auto)
            ? Theme.of(context).colorScheme.shadow.withValues(alpha: 0.06)
            : Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        onTap: () {
          ref.read(mainNotifierProvider.notifier).toggleSyncMode();
          final newMode = ref.read(mainNotifierProvider).syncMode;
          final newIsOnline = ref.read(mainNotifierProvider).isHasInternet;

          final msg = switch (newMode) {
            SyncMode.online => 'Mode Online — Semua data langsung sync ke server',
            SyncMode.offline => 'Mode Offline — Data hanya disimpan lokal',
            SyncMode.auto =>
              newIsOnline
                  ? 'Mode Auto (Online) — Sync otomatis saat ada koneksi'
                  : 'Mode Auto (Offline) — Data akan diantrekan, sync saat online',
          };

          AppSnackBar.show(msg);
        },
      ),
    );
  }
}

class _AddToCartDialog extends ConsumerStatefulWidget {
  final ProductEntity product;
  final double initialQuantity;
  final bool isGrosir;
  final List<ProductUnitEntity> effectiveUnits;

  const _AddToCartDialog({
    super.key,
    required this.product,
    required this.initialQuantity,
    required this.isGrosir,
    required this.effectiveUnits,
  });

  @override
  ConsumerState<_AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends ConsumerState<_AddToCartDialog> {
  late double _quantity;
  late String _selectedUnit;
  late int _conversionValue;
  late int _price;
  late String _priceType;
  bool _isTieredPrice = false;
  final Map<int, List<ProductTierEntity>> _unitTiers = {};

  double get quantity => _quantity;
  String get selectedUnit => _selectedUnit;
  int get conversionValue => _conversionValue;
  int get price => _price;
  String get priceType => _priceType;
  bool get isTieredPrice => _isTieredPrice;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity == 0 ? 1 : widget.initialQuantity;
    _priceType = widget.isGrosir ? 'grosir' : 'retail';

    var defaultUnit = widget.effectiveUnits.firstWhere(
      (u) => u.unitName == widget.product.unit,
      orElse: () => widget.effectiveUnits.first,
    );
    _selectedUnit = defaultUnit.unitName;
    _conversionValue = defaultUnit.conversionValue;
    _recomputePrice();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    final productRepository = ref.read(productRepositoryProvider);
    for (final unit in widget.effectiveUnits) {
      if (unit.id != null && unit.id! > 0 && !_unitTiers.containsKey(unit.id)) {
        final res = await GetProductTiersUsecase(productRepository).call(unit.id!);
        if (res.isSuccess && res.data != null && res.data!.isNotEmpty) {
          _unitTiers[unit.id!] = res.data!;
        }
      }
    }
    _recomputePrice();
    if (mounted) setState(() {});
  }

  void _recomputePrice() {
    final unit = widget.effectiveUnits.firstWhere((u) => u.unitName == _selectedUnit);
    final basePrice = _priceType == 'grosir' && unit.wholesalePrice != null ? unit.wholesalePrice! : unit.price;

    final tiers = unit.id != null ? _unitTiers[unit.id] : null;
    if (tiers != null && tiers.isNotEmpty) {
      final intQty = _quantity.round();
      for (final tier in tiers) {
        if (intQty >= tier.minQty && intQty % tier.minQty == 0) {
          final bundles = intQty ~/ tier.minQty;
          _price = bundles * tier.price;
          _isTieredPrice = true;
          return;
        }
      }
    }

    _price = basePrice;
    _isTieredPrice = false;
  }

  void _onChangedUnit(String? val) {
    if (val == null) return;
    var unit = widget.effectiveUnits.firstWhere((u) => u.unitName == val);
    setState(() {
      _selectedUnit = unit.unitName;
      _conversionValue = unit.conversionValue;
      _recomputePrice();
    });
  }

  void _onChangedPriceType(String value) {
    setState(() {
      _priceType = value;
      _recomputePrice();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrderCard(
      name: widget.product.name,
      imageUrl: widget.product.imageUrl,
      stock: widget.product.stock,
      price: _price,
      priceType: _priceType,
      unit: widget.product.unit,
      initialQuantity: _quantity,
      selectedUnit: _selectedUnit,
      availableUnits: widget.effectiveUnits.map((u) => u.unitName).toList(),
      conversionValue: _conversionValue,
      onChangedUnit: _onChangedUnit,
      onChangedPriceType: _onChangedPriceType,
      isTieredPrice: _isTieredPrice,
      onChangedQuantity: (val) async {
        _quantity = val;
        _recomputePrice();
        if (mounted) setState(() {});
      },
    );
  }
}

class _SearchField extends ConsumerWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppTextField(
      controller: controller,
      hintText: 'Search Products...',
      type: AppTextFieldType.search,
      textInputAction: TextInputAction.search,
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
        ref.read(berandaProductsNotifierProvider.notifier).resetProducts();
        ref.read(berandaProductsNotifierProvider.notifier).getAllProducts(contains: controller.text);
      },
      onTapClearButton: () {
        ref.read(berandaProductsNotifierProvider.notifier).getAllProducts(contains: controller.text);
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final ProductEntity product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);
    bool isGrosir = homeState.selectedPriceType == 'grosir';

    List<ProductUnitEntity> effectiveUnits;
    if (product.units.isNotEmpty) {
      effectiveUnits = product.units;
    } else {
      effectiveUnits = [
        ProductUnitEntity(
          unitName: product.unit,
          conversionValue: 1,
          price: product.price,
          wholesalePrice: product.wholesalePrice,
          isBase: true,
          productId: product.id ?? 0,
        ),
      ];
    }

    var defaultUnit = effectiveUnits.firstWhere(
      (u) => u.unitName == product.unit,
      orElse: () => effectiveUnits.first,
    );
    int displayPrice = isGrosir && defaultUnit.wholesalePrice != null ? defaultUnit.wholesalePrice! : defaultUnit.price;

    return ProductsCard(
      product: product,
      displayPrice: displayPrice,
      priceType: homeState.selectedPriceType,
      enabled: product.stock > 0 && (!isGrosir || defaultUnit.wholesalePrice != null),
      onTap: () {
        double currentQty =
            homeState.orderedProducts.where((e) => e.productId == product.id).firstOrNull?.quantity ?? 0;

        final dialogKey = GlobalKey<_AddToCartDialogState>();

        AppDialog.show(
          title: 'Enter Amount',
          child: _AddToCartDialog(
            key: dialogKey,
            product: product,
            initialQuantity: currentQty,
            isGrosir: isGrosir,
            effectiveUnits: effectiveUnits,
          ),
          rightButtonText: AppLocalizations.of(context)!.home_addToCart,
          leftButtonText: AppLocalizations.of(context)!.home_cancel,
          onTapLeftButton: (context) {
            context.pop();
          },
          onTapRightButton: (context) {
            var state = dialogKey.currentState;
            if (state == null) return;

            ref
                .read(homeNotifierProvider.notifier)
                .onAddOrderedProduct(
                  product,
                  state.quantity == 0 ? 1.0 : state.quantity,
                  unitName: state.selectedUnit,
                  conversionValue: state.conversionValue,
                  overridePrice: state.price,
                  priceType: state.priceType,
                );
            context.pop();
          },
        );
      },
    );
  }
}
