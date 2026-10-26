import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../domain/usecases/product_usecases.dart';
import '../../../providers/home/home_notifier.dart';
import '../../../providers/products/products_notifier.dart';
import '../../../widgets/app_snack_bar.dart';

/// Focus node bersama untuk menangkap input scanner HID.
/// Dipakai juga oleh kolom pencarian agar fokus bisa dikembalikan setelah scan.
final barcodeScanFocusNodeProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'barcodeHidListener');
  ref.onDispose(node.dispose);
  return node;
});

void requestBarcodeScannerFocus(WidgetRef ref) {
  ref.read(barcodeScanFocusNodeProvider).requestFocus();
}

class BarcodeHidListener extends ConsumerStatefulWidget {
  const BarcodeHidListener({super.key});

  @override
  ConsumerState<BarcodeHidListener> createState() => _BarcodeHidListenerState();
}

class _BarcodeHidListenerState extends ConsumerState<BarcodeHidListener> with WidgetsBindingObserver {
  final _controller = TextEditingController();
  late final FocusNode _focusNode;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = ref.read(barcodeScanFocusNodeProvider);
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_onFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeListener(_onFocusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _focusNode.requestFocus();
    }
  }

  /// Kembalikan fokus ke listener saat tidak ada field lain yang fokus,
  /// supaya scan berikutnya tidak "nyangkut" di kolom pencarian.
  void _onFocusChanged() {
    if (!mounted) return;
    if (FocusManager.instance.primaryFocus == null) {
      _focusNode.requestFocus();
    }
  }

  static final _digitsOnly = RegExp(r'^[0-9]+$');

  void _onSubmitted(String value) async {
    final trimmed = value.trim();
    _controller.clear();

    if (trimmed.isEmpty || _isProcessing) return;

    if (!_digitsOnly.hasMatch(trimmed)) {
      _onProductNotFound('Bukan kode batang produk — hanya angka');
      _focusNode.requestFocus();
      return;
    }

    _isProcessing = true;

    try {
      final products = ref.read(berandaProductsNotifierProvider).allProducts;
      final cached = products?.where((p) => p.barcode?.trim() == trimmed).firstOrNull;

      if (cached != null) {
        await _addToCart(cached);
        return;
      }

      final repo = ref.read(productRepositoryProvider);
      final result = await GetProductByBarcodeUsecase(repo).call(trimmed);

      if (!mounted) return;

      if (result.isSuccess && result.data != null) {
        await _addToCart(result.data!);
      } else {
        _onProductNotFound(trimmed);
      }
    } finally {
      _isProcessing = false;
      if (mounted) _focusNode.requestFocus();
    }
  }

  Future<void> _addToCart(ProductEntity product) async {
    final added = await ref.read(homeNotifierProvider.notifier).addScannedProduct(product);

    SystemSound.play(SystemSoundType.click);

    if (mounted) {
      AppSnackBar.show('${product.name} (${added.quantity.toInt()} ${added.unit})');
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
