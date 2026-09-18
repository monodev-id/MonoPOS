import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../core/utilities/console_logger.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/product_tier_entity.dart';
import '../../../domain/entities/product_unit_entity.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../auth/auth_notifier.dart';
import 'product_form_state.dart';
import 'products_notifier.dart';

final productFormNotifierProvider = NotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>(
  ProductFormNotifier.new,
);

class ProductFormNotifier extends AutoDisposeNotifier<ProductFormState> {
  @override
  ProductFormState build() {
    return const ProductFormState();
  }

  String _requireUserId() {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated) return authState.user!.id;
    throw 'Unauthenticated!';
  }

  int _unitIdCounter = 0;
  bool _isSaving = false;

  int _nextUnitId() => DateTime.now().millisecondsSinceEpoch + (++_unitIdCounter);

  Future<void> initProductForm(int? productId) async {
    if (productId == null) {
      state = state.copyWith(isLoaded: true);
      _syncManagedUnits();
      return;
    }

    final productRepository = ref.read(productRepositoryProvider);
    var res = await GetProductUsecase(productRepository).call(productId);

    if (res.isSuccess) {
      var product = res.data;
      final defaultUnit = product?.unit;

      state = state.copyWith(
        imageUrl: product?.imageUrl,
        name: product?.name,
        price: product?.price,
        wholesalePrice: product?.wholesalePrice,
        stock: product?.stock,
        unit: defaultUnit,
        barcode: product?.barcode,
        description: product?.description,
        units: product?.units ?? [],
        isLoaded: true,
      );

      _syncManagedUnits();

      // Load existing tiered prices for each unit
      final units = state.units;
      final tierMap = <int, List<ProductTierEntity>>{};
      for (int i = 0; i < units.length; i++) {
        final unit = units[i];
        if (unit.id != null && unit.id! > 0) {
          final tierRes = await GetProductTiersUsecase(
            productRepository,
          ).call(unit.id!);
          if (tierRes.isSuccess && tierRes.data!.isNotEmpty) {
            tierMap[i] = tierRes.data!;
          }
        }
      }
      if (tierMap.isNotEmpty) {
        state = state.copyWith(tieredPrices: tierMap);
      }
    } else {
      throw res.error ?? 'Failed to load data';
    }
  }

  Future<String?> _saveImageLocally(
    File source,
    String subDir,
    String fileName,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDir.path}/$subDir');
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final ext = p.extension(source.path);
      final targetPath = '${targetDir.path}/$fileName$ext';
      await source.copy(targetPath);
      return targetPath;
    } catch (e) {
      cl('Gagal simpan gambar lokal: $e');
      return null;
    }
  }

  Future<Result<int>> createProduct() async {
    if (_isSaving) return Result.success(data: 0);
    _isSaving = true;
    state = state.copyWith(isSaving: true);

    try {
      final userId = _requireUserId();
      final productRepository = ref.read(productRepositoryProvider);

      // Cek duplikat nama
      final nameCheck = await productRepository.getProductByName(state.name ?? '');
      if (nameCheck.isSuccess && nameCheck.data != null) {
        return Result.failure(error: 'Produk dengan nama "${state.name}" sudah ada');
      }

      // Cek duplikat barcode (jika diisi, dinormalisasi trim)
      final normalizedBarcode = state.barcode?.trim();
      if (normalizedBarcode != null && normalizedBarcode.isNotEmpty) {
        state = state.copyWith(barcode: normalizedBarcode);
        final barcodeCheck = await productRepository.getProductByBarcode(normalizedBarcode);
        if (barcodeCheck.isSuccess && barcodeCheck.data != null) {
          return Result.failure(error: 'Produk dengan barcode "$normalizedBarcode" sudah ada');
        }
      } else {
        state = state.copyWith(barcode: null);
      }

      var imageUrl = state.imageUrl;

      if (state.imageFile != null) {
        final savedPath = await _saveImageLocally(
          state.imageFile!,
          'products',
          '${DateTime.now().millisecondsSinceEpoch}',
        );
        if (savedPath != null) imageUrl = savedPath;
      }

      final id = DateTime.now().millisecondsSinceEpoch;
      var product = ProductEntity(
        id: id,
        createdById: userId,
        name: state.name ?? '',
        imageUrl: imageUrl ?? '',
        stock: state.stock ?? 0,
        price: state.price ?? 0,
        wholesalePrice: state.wholesalePrice,
        unit: state.unit ?? 'pcs',
        barcode: state.barcode,
        description: state.description ?? '',
        units: state.units,
      );

      var res = await CreateProductUsecase(productRepository).call(product);

      // Save tiered prices for each unit
      if (res.isSuccess) {
        await _saveAllTieredPrices(productRepository);
      }

      ref.read(productsNotifierProvider.notifier).getAllProducts();
      ref.read(berandaProductsNotifierProvider.notifier).getAllProducts();

      return res;
    } catch (e) {
      return Result.failure(error: e);
    } finally {
      _isSaving = false;
      state = state.copyWith(isSaving: false);
    }
  }

  Future<Result<void>> updatedProduct(int id) async {
    if (_isSaving) return Result.success(data: null);
    _isSaving = true;
    state = state.copyWith(isSaving: true);

    try {
      final userId = _requireUserId();
      final productRepository = ref.read(productRepositoryProvider);

      final normalizedBarcode = state.barcode?.trim();
      state = state.copyWith(
        barcode: normalizedBarcode == null || normalizedBarcode.isEmpty ? null : normalizedBarcode,
      );

      if (state.barcode != null && state.barcode!.isNotEmpty) {
        final barcodeCheck = await productRepository.getProductByBarcode(state.barcode!);
        if (barcodeCheck.isSuccess && barcodeCheck.data != null && barcodeCheck.data!.id != id) {
          return Result.failure(error: 'Produk dengan barcode "${state.barcode}" sudah ada');
        }
      }

      var imageUrl = state.imageUrl;

      if (state.imageFile != null) {
        final savedPath = await _saveImageLocally(
          state.imageFile!,
          'products',
          'product_$id',
        );
        if (savedPath != null) imageUrl = savedPath;
      }

      var product = ProductEntity(
        id: id,
        createdById: userId,
        name: state.name!,
        imageUrl: imageUrl ?? '',
        stock: state.stock ?? 0,
        price: state.price ?? 0,
        wholesalePrice: state.wholesalePrice,
        unit: state.unit ?? 'pcs',
        barcode: state.barcode,
        description: state.description ?? '',
        units: state.units,
      );

      var res = await UpdateProductUsecase(productRepository).call(product);

      // Save tiered prices for each unit
      if (res.isSuccess) {
        await _saveAllTieredPrices(productRepository);
      }

      ref.read(productsNotifierProvider.notifier).getAllProducts();
      ref.read(berandaProductsNotifierProvider.notifier).getAllProducts();

      return res;
    } catch (e) {
      return Result.failure(error: e);
    } finally {
      _isSaving = false;
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> _saveAllTieredPrices(ProductRepository productRepository) async {
    for (final entry in state.tieredPrices.entries) {
      final unitIndex = entry.key;
      final tiers = entry.value;
      if (tiers.isEmpty) continue;

      final unit = state.units[unitIndex];
      if (unit.id == null || unit.id! <= 0) continue;

      await SaveProductTiersUsecase(productRepository).call((
        productUnitId: unit.id!,
        tiers: tiers,
      ));
    }
  }

  Future<Result<void>> deleteProduct(int id) async {
    try {
      final productRepository = ref.read(productRepositoryProvider);
      var res = await DeleteProductUsecase(productRepository).call(id);

      // Refresh products
      ref.read(productsNotifierProvider.notifier).getAllProducts();
      ref.read(berandaProductsNotifierProvider.notifier).getAllProducts();

      return res;
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  void onChangedImage(File value) {
    state = state.copyWith(imageFile: value);
  }

  void onChangedName(String value) {
    state = state.copyWith(name: value);
  }

  void onChangedPrice(String value) {
    state = state.copyWith(price: int.tryParse(value.replaceAll('.', '')));
    _syncManagedUnits();
  }

  void onChangedWholesalePrice(String value) {
    state = state.copyWith(wholesalePrice: int.tryParse(value.replaceAll('.', '')));
    _syncManagedUnits();
  }

  void onChangedStock(String value) {
    state = state.copyWith(stock: int.tryParse(value));
  }

  void onChangedUnit(String value) {
    state = state.copyWith(unit: value);
    _syncManagedUnits();
  }

  void addCustomUnitName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (state.customUnitNames.contains(trimmed)) {
      state = state.copyWith(unit: trimmed);
      _syncManagedUnits();
      return;
    }
    state = state.copyWith(
      customUnitNames: [...state.customUnitNames, trimmed],
      unit: trimmed,
    );
    _syncManagedUnits();
  }

  void _syncManagedUnits() {
    final price = state.price ?? 0;
    final wholesalePrice = state.wholesalePrice;
    final defaultUnit = state.unit;
    final units = [...state.units];

    int baseIdx = units.indexWhere((u) => u.isBase);
    if (baseIdx < 0) {
      final defaultIdx = units.indexWhere((u) => u.unitName == defaultUnit);
      if (defaultIdx >= 0) {
        units[defaultIdx] = units[defaultIdx].copyWith(isBase: true);
        baseIdx = defaultIdx;
      } else if (defaultUnit != null) {
        baseIdx = 0;
        units.insert(
          0,
          ProductUnitEntity(
            unitName: defaultUnit,
            conversionValue: 1,
            price: price,
            wholesalePrice: wholesalePrice,
            isBase: true,
            productId: 0,
            id: _nextUnitId(),
          ),
        );
      }
    }

    if (baseIdx < 0) {
      state = state.copyWith(units: units);
      return;
    }

    for (int i = 0; i < units.length; i++) {
      if (i != baseIdx && units[i].isBase) units[i] = units[i].copyWith(isBase: false);
    }
    units[baseIdx] = units[baseIdx].copyWith(
      price: price,
      wholesalePrice: wholesalePrice,
      conversionValue: 1,
    );

    if (defaultUnit != null && defaultUnit != units[baseIdx].unitName) {
      final defIdx = units.indexWhere((u) => !u.isBase && u.unitName == defaultUnit);
      final defUnit = ProductUnitEntity(
        unitName: defaultUnit,
        conversionValue: 1,
        price: price,
        wholesalePrice: wholesalePrice,
        productId: 0,
        id: defIdx >= 0 ? units[defIdx].id : _nextUnitId(),
      );
      if (defIdx >= 0) {
        units[defIdx] = defUnit;
      } else {
        units.add(defUnit);
      }
    }

    state = state.copyWith(units: units);
  }

  void onChangedBarcode(String value) {
    final normalized = value.trim();
    state = state.copyWith(barcode: normalized.isEmpty ? null : normalized);
  }

  void onChangedDesc(String value) {
    state = state.copyWith(description: value);
  }

  void addUnit(ProductUnitEntity unit) {
    final units = [...state.units];
    if (unit.isBase) {
      for (int i = 0; i < units.length; i++) {
        if (units[i].isBase) units[i] = units[i].copyWith(isBase: false);
      }
    }
    final idx = units.indexWhere((u) => u.unitName == unit.unitName);
    final newUnit = unit.copyWith(id: unit.id ?? _nextUnitId());
    if (idx >= 0) {
      units[idx] = newUnit;
    } else {
      units.add(newUnit);
    }
    state = state.copyWith(units: units);
    _syncManagedUnits();
  }

  void updateUnit(int index, ProductUnitEntity unit) {
    final units = [...state.units];
    if (unit.isBase) {
      for (int i = 0; i < units.length; i++) {
        if (i != index && units[i].isBase) units[i] = units[i].copyWith(isBase: false);
      }
    }
    final merged = unit.id != null ? unit : unit.copyWith(id: units[index].id);
    units[index] = merged;
    state = state.copyWith(units: units);
    _syncManagedUnits();
  }

  void removeUnit(int index) {
    final units = [...state.units];
    units.removeAt(index);
    final newTieredPrices = <int, List<ProductTierEntity>>{};
    for (final entry in state.tieredPrices.entries) {
      if (entry.key == index) continue;
      if (entry.key > index) {
        newTieredPrices[entry.key - 1] = entry.value;
      } else {
        newTieredPrices[entry.key] = entry.value;
      }
    }
    state = state.copyWith(units: units, tieredPrices: newTieredPrices);
    _syncManagedUnits();
  }

  void addTier(int unitIndex, ProductTierEntity tier) {
    final tieredPrices = Map<int, List<ProductTierEntity>>.from(
      state.tieredPrices,
    );
    final tiers = <ProductTierEntity>[...(tieredPrices[unitIndex] ?? [])];
    tiers.add(tier);
    tieredPrices[unitIndex] = tiers;
    state = state.copyWith(tieredPrices: tieredPrices);
  }

  void updateTier(int unitIndex, int tierIndex, ProductTierEntity tier) {
    final tieredPrices = Map<int, List<ProductTierEntity>>.from(
      state.tieredPrices,
    );
    final tiers = <ProductTierEntity>[...(tieredPrices[unitIndex] ?? [])];
    if (tierIndex < tiers.length) {
      tiers[tierIndex] = tier;
      tieredPrices[unitIndex] = tiers;
      state = state.copyWith(tieredPrices: tieredPrices);
    }
  }

  void removeTier(int unitIndex, int tierIndex) {
    final tieredPrices = Map<int, List<ProductTierEntity>>.from(
      state.tieredPrices,
    );
    final tiers = <ProductTierEntity>[...(tieredPrices[unitIndex] ?? [])];
    if (tierIndex < tiers.length) {
      tiers.removeAt(tierIndex);
      tieredPrices[unitIndex] = tiers;
      state = state.copyWith(tieredPrices: tieredPrices);
    }
  }

  List<ProductTierEntity> getTiersForUnit(int unitIndex) {
    return state.tieredPrices[unitIndex] ?? [];
  }
}
