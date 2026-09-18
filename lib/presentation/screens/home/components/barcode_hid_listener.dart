import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../domain/entities/product_unit_entity.dart';
import '../../../../domain/usecases/product_usecases.dart';
import '../../../providers/home/home_notifier.dart';
import '../../../providers/products/products_notifier.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/app_snack_bar.dart';

class BarcodeHidListener extends ConsumerStatefulWidget {
  const BarcodeHidListener({super.key});

  @override
  ConsumerState<BarcodeHidListener> createState() => _BarcodeHidListenerState();
}

class _BarcodeHidListenerState extends ConsumerState<BarcodeHidListener> {
  final _focusNode = FocusNode();
  final _controller = TextEditingController();
  bool _isProcessing = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  List<ProductUnitEntity> _effectiveUnits(ProductEntity product) {
    if (product.units.isNotEmpty) return product.units;
    return [
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

  void _onSubmitted(String value) async {
    final trimmed = value.trim();
    _controller.clear();

    if (trimmed.isEmpty || _isProcessing) return;

    _isProcessing = true;

    final products = ref.read(berandaProductsNotifierProvider).allProducts;
    final product = products?.where((p) => p.barcode == trimmed).firstOrNull;

    if (product == null) {
      final repo = ref.read(productRepositoryProvider);
      final result = await GetProductByBarcodeUsecase(repo).call(trimmed);

      if (result.isSuccess && result.data != null) {
        if (mounted) {
          await ref.read(berandaProductsNotifierProvider.notifier).getAllProducts();
        }
        final refreshedProducts = ref.read(berandaProductsNotifierProvider).allProducts;
        final foundProduct = refreshedProducts?.where((p) => p.id == result.data!.id).firstOrNull;

        if (foundProduct != null && mounted) {
          _addToCart(foundProduct);
        } else if (mounted) {
          _onProductNotFound(trimmed);
        }
      } else if (mounted) {
        _onProductNotFound(trimmed);
      }
    } else {
      _addToCart(product);
    }

    _isProcessing = false;
    _focusNode.requestFocus();
  }

  void _addToCart(ProductEntity product) {
    _showUnitPicker(product, _effectiveUnits(product));
  }

  void _showUnitPicker(ProductEntity product, List<ProductUnitEntity> effectiveUnits) {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;

    final isGrosir = ref.read(homeNotifierProvider).selectedPriceType == 'grosir';

    AppDialog.show(
      title: 'Pilih Satuan - ${product.name}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final unit in effectiveUnits)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(unit.unitName),
              trailing: Text(
                CurrencyFormatter.withoutSymbol(
                  isGrosir && unit.wholesalePrice != null ? unit.wholesalePrice! : unit.price,
                  decimalDigits: 0,
                ),
              ),
              onTap: () => _onPickUnit(product, unit),
            ),
        ],
      ),
      showButtons: false,
    ).whenComplete(() {
      _dialogOpen = false;
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onPickUnit(ProductEntity product, ProductUnitEntity unit) {
    AppRoutes.rootNavigatorKey.currentState?.pop();

    final homeState = ref.read(homeNotifierProvider);
    final currentQty =
        homeState.orderedProducts
            .where((e) => e.productId == product.id && e.unit == unit.unitName)
            .firstOrNull
            ?.quantity ??
        0;
    final isGrosir = homeState.selectedPriceType == 'grosir';
    final price = isGrosir && unit.wholesalePrice != null ? unit.wholesalePrice! : unit.price;

    ref
        .read(homeNotifierProvider.notifier)
        .onAddOrderedProduct(
          product,
          currentQty + 1,
          unitName: unit.unitName,
          conversionValue: unit.conversionValue,
          overridePrice: price,
        );

    SystemSound.play(SystemSoundType.click);

    if (mounted) {
      final totalQty = (currentQty + 1).toInt();
      AppSnackBar.show('${product.name} ($totalQty ${unit.unitName})');
    }
  }

  void _onProductNotFound(String barcode) {
    AppSnackBar.showError('Produk "$barcode" tidak ditemukan');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 0,
      height: 0,
      child: TextField(
        autofocus: true,
        focusNode: _focusNode,
        controller: _controller,
        onSubmitted: _onSubmitted,
        showCursor: false,
        decoration: const InputDecoration.collapsed(hintText: ''),
      ),
    );
  }
}
