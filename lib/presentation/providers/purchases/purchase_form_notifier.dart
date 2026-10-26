import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/purchase_entity.dart';
import '../../../domain/entities/purchase_item_entity.dart';
import '../../../domain/entities/supplier_entity.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../../../domain/usecases/purchase_usecases.dart';
import '../../../domain/usecases/supplier_usecases.dart';
import '../../../domain/usecases/params/base_params.dart';
import '../auth/auth_notifier.dart';
import 'purchase_form_state.dart';

final purchaseFormNotifierProvider =
    NotifierProvider.autoDispose<PurchaseFormNotifier, PurchaseFormState>(
      PurchaseFormNotifier.new,
    );

class PurchaseFormNotifier extends AutoDisposeNotifier<PurchaseFormState> {
  @override
  PurchaseFormState build() {
    return PurchaseFormState(purchaseDate: _today());
  }

  bool _isSaving = false;

  static String _today() {
    final now = DateTime.now();
    return _dateOnly(now);
  }

  static String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> initPurchaseForm({int? initialProductId}) async {
    final supplierRepository = ref.read(supplierRepositoryProvider);
    final suppliersRes = await GetAllSuppliersUsecase(
      supplierRepository,
    ).call(null);

    state = state.copyWith(
      suppliers: suppliersRes.data ?? const [],
      isLoaded: true,
    );

    if (initialProductId != null) {
      final productRes = await GetProductUsecase(
        ref.read(productRepositoryProvider),
      ).call(initialProductId);
      if (productRes.isSuccess && productRes.data != null) {
        await addProduct(productRes.data!);
      }
    }
  }

  Future<void> reloadSuppliers() async {
    final supplierRepository = ref.read(supplierRepositoryProvider);
    final res = await GetAllSuppliersUsecase(supplierRepository).call(null);
    if (res.isSuccess) {
      state = state.copyWith(suppliers: res.data!);
    }
  }

  Future<Result<SupplierEntity>> createSupplierQuick(
    String name,
    String? phone,
  ) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Result.failure(error: 'Nama supplier wajib diisi');
    }

    final repository = ref.read(supplierRepositoryProvider);
    final duplicate = await GetSupplierByNameUsecase(repository).call(trimmed);
    if (duplicate.isSuccess && duplicate.data != null) {
      return Result.failure(error: 'Supplier "$trimmed" sudah ada');
    }

    final supplier = SupplierEntity(
      name: trimmed,
      phone: phone?.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    final res = await CreateSupplierUsecase(repository).call(supplier);
    if (res.isFailure) {
      return Result.failure(error: res.error ?? 'Gagal menambah supplier');
    }

    await reloadSuppliers();
    return Result.success(data: supplier.copyWith(id: res.data));
  }

  Future<void> onChangedSupplier(SupplierEntity? supplier) async {
    state = state.copyWith(supplier: supplier);
    for (final item in state.items) {
      await _refreshItemHints(item);
    }
  }

  void onChangedDate(DateTime date) {
    state = state.copyWith(purchaseDate: _dateOnly(date));
  }

  void onChangedNote(String value) => state = state.copyWith(note: value);

  void onChangedAddStock(bool value) => state = state.copyWith(addStock: value);

  Future<List<ProductEntity>> searchProducts(String query) async {
    final userId = ref.read(authNotifierProvider).user?.id ?? '';
    final res =
        await GetUserProductsUsecase(ref.read(productRepositoryProvider)).call(
          BaseParams(
            param: userId,
            contains: query,
            orderBy: 'name',
            sortBy: 'ASC',
            limit: 30,
          ),
        );

    return res.data ?? const [];
  }

  Future<void> addProduct(ProductEntity product) async {
    final unit =
        product.units.where((u) => u.unitName == product.unit).firstOrNull ??
        product.units.where((u) => u.isBase).firstOrNull ??
        product.units.firstOrNull;

    final unitName = unit?.unitName ?? product.unit;

    if (state.items.any(
      (item) => item.product.id == product.id && item.unitName == unitName,
    )) {
      return;
    }

    final draft = PurchaseDraftItem(
      product: product,
      unitName: unitName,
      conversionValue: unit?.conversionValue ?? 1,
    );

    state = state.copyWith(items: [...state.items, draft]);
    await _refreshItemHints(draft);
  }

  void removeItem(PurchaseDraftItem item) {
    state = state.copyWith(
      items: state.items.where((e) => !identical(e, item)).toList(),
    );
  }

  void onChangedUnit(PurchaseDraftItem item, String unitName) {
    final unit = item.product.units
        .where((u) => u.unitName == unitName)
        .firstOrNull;
    if (unit == null) return;

    final duplicate = state.items.any(
      (other) =>
          !identical(other, item) &&
          other.product.id == item.product.id &&
          other.unitName == unitName,
    );
    if (duplicate) return;

    item.unitName = unitName;
    item.conversionValue = unit.conversionValue;

    final hint = item.priceHint;
    if (hint != null) {
      item.unitPrice = _priceForUnit(hint, unit.conversionValue, unitName);
    }

    _notifyItemsChanged();
  }

  void onChangedQuantity(PurchaseDraftItem item, String value) {
    final normalized = value.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    item.quantity = parsed == null || parsed < 0 ? 0 : parsed;
    _notifyItemsChanged();
  }

  void onChangedUnitPrice(PurchaseDraftItem item, String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    item.unitPrice = int.tryParse(digits) ?? 0;
    _notifyItemsChanged();
  }

  void _notifyItemsChanged() {
    state = state.copyWith(items: [...state.items]);
  }

  int _priceForUnit(
    PurchaseItemEntity hint,
    int conversionValue,
    String unitName,
  ) {
    if (hint.unitName == unitName) return hint.unitPrice;
    if (hint.baseUnitPrice > 0) {
      return hint.baseUnitPrice * (conversionValue > 0 ? conversionValue : 1);
    }
    return hint.unitPrice;
  }

  Future<void> _refreshItemHints(PurchaseDraftItem item) async {
    if (item.product.id == null) return;

    final repository = ref.read(purchaseRepositoryProvider);
    final supplierId = state.supplier?.id;

    final previousHint = item.priceHint;
    final previousSuggested = previousHint == null
        ? null
        : _priceForUnit(previousHint, item.conversionValue, item.unitName);

    PurchaseItemEntity? fromSupplier;
    if (supplierId != null && supplierId.isNotEmpty) {
      final res = await GetLatestPurchaseItemUsecase(repository).call((
        productId: item.product.id!,
        supplierId: supplierId,
      ));
      fromSupplier = res.data;
    }

    final anyRes = await GetLatestPurchaseItemUsecase(repository).call((
      productId: item.product.id!,
      supplierId: null,
    ));

    final pricesRes = await GetLatestPurchaseItemsBySupplierUsecase(
      repository,
    ).call(item.product.id!);

    item.lastFromSupplier = fromSupplier;
    item.lastFromAnySupplier = anyRes.data;
    item.supplierPrices = pricesRes.data ?? const [];

    final hint = item.priceHint;
    final shouldFill =
        item.unitPrice == 0 ||
        (previousSuggested != null && item.unitPrice == previousSuggested);
    if (hint != null && shouldFill) {
      item.unitPrice = _priceForUnit(hint, item.conversionValue, item.unitName);
    }

    _notifyItemsChanged();
  }

  Future<Result<int>> createPurchase() async {
    if (_isSaving) return Result.failure(error: 'Sedang menyimpan');
    if (state.supplier == null) {
      return Result.failure(error: 'Pilih supplier terlebih dahulu');
    }
    if (state.items.isEmpty) {
      return Result.failure(error: 'Tambahkan minimal satu barang');
    }

    for (final item in state.items) {
      if (item.quantity <= 0) {
        return Result.failure(
          error: 'Qty ${item.product.name} harus lebih dari 0',
        );
      }
      if (item.unitPrice <= 0) {
        return Result.failure(
          error: 'Harga beli ${item.product.name} harus lebih dari 0',
        );
      }
    }

    _isSaving = true;
    state = state.copyWith(isSaving: true);

    try {
      final id = DateTime.now().millisecondsSinceEpoch;
      final userId = ref.read(authNotifierProvider).user?.id;

      final items = state.items
          .map(
            (item) => PurchaseItemEntity(
              purchaseId: id,
              productId: item.product.id!,
              productName: item.product.name,
              unitName: item.unitName,
              conversionValue: item.conversionValue,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              totalPrice: item.totalPrice,
              baseUnitPrice: item.baseUnitPrice,
            ),
          )
          .toList();

      final purchase = PurchaseEntity(
        id: id,
        supplierId: state.supplier!.id,
        supplierName: state.supplier!.name,
        purchaseDate: state.purchaseDate,
        note: state.note.trim(),
        totalAmount: state.totalAmount,
        totalItems: state.totalItems,
        addStock: state.addStock,
        createdById: userId,
        items: items,
      );

      final res = await CreatePurchaseUsecase(
        ref.read(purchaseRepositoryProvider),
      ).call(purchase);
      return res;
    } finally {
      _isSaving = false;
      state = state.copyWith(isSaving: false);
    }
  }
}
