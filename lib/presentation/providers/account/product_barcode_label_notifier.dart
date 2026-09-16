import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/utilities/barcode_generator.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/usecases/params/base_params.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../auth/auth_notifier.dart';
import '../products/products_notifier.dart';
import 'product_barcode_label_state.dart';

final productBarcodeLabelNotifierProvider = NotifierProvider<ProductBarcodeLabelNotifier, ProductBarcodeLabelState>(
  ProductBarcodeLabelNotifier.new,
);

class ProductBarcodeLabelNotifier extends Notifier<ProductBarcodeLabelState> {
  @override
  ProductBarcodeLabelState build() {
    return const ProductBarcodeLabelState();
  }

  String _requireUserId() {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated) return authState.user!.id;
    throw 'Unauthenticated!';
  }

  Future<void> loadProducts() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = _requireUserId();
      final productRepository = ref.read(productRepositoryProvider);

      final res = await GetUserProductsUsecase(productRepository).call(
        BaseParams(param: userId, limit: 100000),
      );

      if (!res.isSuccess) {
        state = state.copyWith(isLoading: false, error: res.error?.toString());
        return;
      }

      final products = _applyFilter(res.data ?? [], state.query, state.filter);
      final copies = <int, int>{
        for (final p in res.data ?? [])
          if (p.id != null) p.id!: state.copies[p.id] ?? 1,
      };

      state = state.copyWith(isLoading: false, products: products, copies: copies, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setQuery(String value) {
    state = state.copyWith(query: value);
  }

  void applySearch() {
    _reloadFiltered();
  }

  void setFilter(BarcodeLabelFilter filter) {
    if (state.filter == filter) return;

    state = state.copyWith(filter: filter);
    _reloadFiltered();
  }

  Future<void> _reloadFiltered() async {
    try {
      final userId = _requireUserId();
      final productRepository = ref.read(productRepositoryProvider);

      final res = await GetUserProductsUsecase(productRepository).call(
        BaseParams(param: userId, limit: 100000),
      );

      if (!res.isSuccess) return;

      state = state.copyWith(
        products: _applyFilter(res.data ?? [], state.query, state.filter),
      );
    } catch (_) {
      return;
    }
  }

  List<ProductEntity> _applyFilter(List<ProductEntity> all, String query, BarcodeLabelFilter filter) {
    final q = query.trim().toLowerCase();

    return all.where((p) {
      final hasBarcode = p.barcode != null && p.barcode!.trim().isNotEmpty;

      if (filter == BarcodeLabelFilter.withBarcode && !hasBarcode) return false;
      if (filter == BarcodeLabelFilter.withoutBarcode && hasBarcode) return false;
      if (q.isEmpty) return true;

      return p.name.toLowerCase().contains(q) || (p.barcode?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void toggleSelected(int productId) {
    final selected = Set<int>.from(state.selected);

    if (selected.contains(productId)) {
      selected.remove(productId);
    } else {
      selected.add(productId);
    }

    state = state.copyWith(selected: selected);
  }

  void selectAllVisible() {
    final ids = state.products.map((p) => p.id!).toSet();

    state = state.copyWith(selected: ids);
  }

  void clearSelection() {
    state = state.copyWith(selected: {});
  }

  void setCopies(int productId, int value) {
    if (value < 1) return;

    final copies = Map<int, int>.from(state.copies);
    copies[productId] = value > 99 ? 99 : value;

    state = state.copyWith(copies: copies);
  }

  Future<void> generateForSelected() async {
    if (state.isGenerating) return;

    final targets = state.products.where((p) => state.selected.contains(p.id)).toList();

    if (targets.isEmpty) {
      state = state.copyWith(error: 'empty_selection');
      return;
    }

    state = state.copyWith(isGenerating: true, error: null);

    try {
      final productRepository = ref.read(productRepositoryProvider);
      final generated = Map<int, String>.from(state.generated);

      for (final product in targets) {
        if (product.barcode != null && product.barcode!.trim().isNotEmpty) continue;
        if (generated.containsKey(product.id)) continue;

        final code = await BarcodeGenerator.generateUniqueEan13(
          exists: (c) async {
            final res = await productRepository.getProductByBarcode(c);
            return res.isSuccess && res.data != null;
          },
        );

        generated[product.id!] = code;
      }

      state = state.copyWith(isGenerating: false, generated: generated);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  Future<void> regenerateSingle(ProductEntity product) async {
    if (state.isGenerating) return;

    state = state.copyWith(isGenerating: true, error: null);

    try {
      final productRepository = ref.read(productRepositoryProvider);

      final code = await BarcodeGenerator.generateUniqueEan13(
        exists: (c) async {
          final res = await productRepository.getProductByBarcode(c);
          return res.isSuccess && res.data != null;
        },
      );

      final generated = Map<int, String>.from(state.generated);
      generated[product.id!] = code;

      state = state.copyWith(isGenerating: false, generated: generated);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  Future<bool> saveGenerated() async {
    if (state.isSaving) return false;

    if (state.generated.isEmpty) {
      state = state.copyWith(error: 'empty_generated');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null, savedCount: null);

    try {
      final productRepository = ref.read(productRepositoryProvider);
      var saved = 0;

      for (final entry in state.generated.entries) {
        final match = state.products.where((p) => p.id == entry.key).firstOrNull;

        if (match == null) continue;
        if (match.barcode != null && match.barcode!.trim().isNotEmpty) continue;

        final duplicate = await productRepository.getProductByBarcode(entry.value);

        if (duplicate.isSuccess && duplicate.data != null) continue;

        final res = await UpdateProductUsecase(productRepository).call(
          match.copyWith(barcode: entry.value),
        );

        if (res.isSuccess) saved++;
      }

      state = state.copyWith(isSaving: false, savedCount: saved, generated: {});

      await loadProducts();
      ref.read(productsNotifierProvider.notifier).getAllProducts();
      ref.read(berandaProductsNotifierProvider.notifier).getAllProducts();

      return saved > 0;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Map<ProductEntity, int> printableItems() {
    final items = <ProductEntity, int>{};
    final skipped = <String>[];

    for (final product in state.products) {
      if (!state.selected.contains(product.id)) continue;

      final code = state.barcodeFor(product);

      if (code.isEmpty || !BarcodeGenerator.isValidEan13(code)) {
        skipped.add(product.name);
        continue;
      }

      items[product.copyWith(barcode: code)] = state.copies[product.id] ?? 1;
    }

    state = state.copyWith(skippedNoBarcode: skipped);

    return items;
  }

  Future<bool> printSelected() async {
    if (state.isPrinting) return false;

    final items = printableItems();

    if (items.isEmpty) {
      state = state.copyWith(error: 'empty_printable');
      return false;
    }

    state = state.copyWith(isPrinting: true, error: null);

    try {
      final printerService = ref.read(printerServiceProvider);
      final res = await printerService.printProductLabels(items);

      state = state.copyWith(isPrinting: false, error: res.isSuccess ? null : res.error?.toString());

      return res.isSuccess;
    } catch (e) {
      state = state.copyWith(isPrinting: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setNewName(String value) {
    state = state.copyWith(newName: value);
  }

  void setNewPrice(String value) {
    state = state.copyWith(newPrice: int.tryParse(value.replaceAll('.', '')));
  }

  void setNewWholesalePrice(String value) {
    final parsed = int.tryParse(value.replaceAll('.', ''));
    state = state.copyWith(newWholesalePrice: parsed);
  }

  void setNewStock(String value) {
    state = state.copyWith(newStock: int.tryParse(value));
  }

  void setNewUnit(String value) {
    state = state.copyWith(newUnit: value.isEmpty ? null : value);
  }

  void setNewDescription(String value) {
    state = state.copyWith(newDescription: value.isEmpty ? null : value);
  }

  void setNewCode(String value) {
    final code = value.trim();

    state = state.copyWith(newCode: code.isEmpty ? null : code, clearNewCode: code.isEmpty);
  }

  Future<void> generateNewCode() async {
    if (state.isGenerating) return;

    state = state.copyWith(isGenerating: true, error: null);

    try {
      final productRepository = ref.read(productRepositoryProvider);

      final code = await BarcodeGenerator.generateUniqueEan13(
        exists: (c) async {
          final res = await productRepository.getProductByBarcode(c);
          return res.isSuccess && res.data != null;
        },
      );

      state = state.copyWith(isGenerating: false, newCode: code);
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  Future<bool> saveNewProduct() async {
    if (state.isSaving) return false;

    final name = state.newName?.trim() ?? '';
    final code = state.newCode?.trim() ?? '';

    if (name.isEmpty) {
      state = state.copyWith(error: 'new_form_incomplete');
      return false;
    }

    if (code.isEmpty || !BarcodeGenerator.isValidEan13(code)) {
      state = state.copyWith(error: 'new_code_invalid');
      return false;
    }

    state = state.copyWith(isSaving: true, error: null, savedCount: null);

    try {
      final userId = _requireUserId();
      final productRepository = ref.read(productRepositoryProvider);

      final nameCheck = await productRepository.getProductByName(name);

      if (nameCheck.isSuccess && nameCheck.data != null) {
        state = state.copyWith(isSaving: false, error: 'duplicate_name');
        return false;
      }

      final barcodeCheck = await productRepository.getProductByBarcode(code);

      if (barcodeCheck.isSuccess && barcodeCheck.data != null) {
        state = state.copyWith(isSaving: false, error: 'duplicate_barcode');
        return false;
      }

      final id = DateTime.now().millisecondsSinceEpoch;
      final product = ProductEntity(
        id: id,
        createdById: userId,
        name: name,
        imageUrl: '',
        stock: 0,
        price: 0,
        unit: 'pcs',
        barcode: code,
        description: '',
      );

      final res = await CreateProductUsecase(productRepository).call(product);

      if (!res.isSuccess) {
        state = state.copyWith(isSaving: false, error: res.error?.toString());
        return false;
      }

      state = state.copyWith(isSaving: false, savedCount: 1, newProductId: id);

      await loadProducts();
      ref.read(productsNotifierProvider.notifier).getAllProducts();
      ref.read(berandaProductsNotifierProvider.notifier).getAllProducts();

      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> printNewProduct({int copies = 1}) async {
    if (state.isPrinting) return false;

    final name = state.newName?.trim() ?? '';
    final code = state.newCode?.trim() ?? '';

    if (name.isEmpty || code.isEmpty || !BarcodeGenerator.isValidEan13(code)) {
      state = state.copyWith(error: 'new_code_invalid');
      return false;
    }

    state = state.copyWith(isPrinting: true, error: null);

    try {
      final userId = _requireUserId();
      final product = ProductEntity(
        id: state.newProductId,
        createdById: userId,
        name: name,
        imageUrl: '',
        stock: 0,
        price: 0,
        unit: 'pcs',
        barcode: code,
        description: '',
      );

      final printerService = ref.read(printerServiceProvider);
      final res = await printerService.printProductLabels({product: copies});

      state = state.copyWith(isPrinting: false, error: res.isSuccess ? null : res.error?.toString());

      return res.isSuccess;
    } catch (e) {
      state = state.copyWith(isPrinting: false, error: e.toString());
      return false;
    }
  }

  void clearNewForm() {
    state = state.copyWith(clearNewFields: true);
  }
}
