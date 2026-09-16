import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/usecases/params/base_params.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../auth/auth_notifier.dart';
import '../products/products_notifier.dart';
import 'product_data_state.dart';

final productDataNotifierProvider = NotifierProvider<ProductDataNotifier, ProductDataState>(
  ProductDataNotifier.new,
);

class ProductDataNotifier extends Notifier<ProductDataState> {
  @override
  ProductDataState build() {
    return const ProductDataState();
  }

  String _requireUserId() {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated) return authState.user!.id;
    throw 'Unauthenticated!';
  }

  Future<void> exportProducts() async {
    if (state.isBusy) return;

    state = state.copyWith(isBusy: true, error: null);

    try {
      final userId = _requireUserId();
      final productRepository = ref.read(productRepositoryProvider);

      final res = await GetUserProductsUsecase(productRepository).call(
        BaseParams(param: userId, limit: 100000),
      );

      if (!res.isSuccess) {
        state = state.copyWith(isBusy: false, error: 'load_failed');
        return;
      }

      final products = res.data ?? [];
      final payload = products.map((e) => ProductModel.fromEntity(e).toJson()).toList();
      final jsonString = jsonEncode(payload);

      final now = DateTime.now();
      final fileName =
          'products_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';

      final path = await FilePicker.platform.saveFile(
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: utf8.encode(jsonString),
      );

      if (path == null) {
        state = state.copyWith(isBusy: false);
        return;
      }

      state = state.copyWith(
        isBusy: false,
        exportedCount: products.length,
        exportedProducts: products,
        exportedFileName: fileName,
        exportedAt: now,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> importProducts() async {
    if (state.isBusy) return;

    state = state.copyWith(isBusy: true, error: null);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        state = state.copyWith(isBusy: false, error: 'no_file');
        return;
      }

      final bytes = result.files.single.bytes;
      if (bytes == null) {
        state = state.copyWith(isBusy: false, error: 'invalid_file');
        return;
      }

      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! List) {
        state = state.copyWith(isBusy: false, error: 'invalid_file');
        return;
      }

      final userId = _requireUserId();
      final productRepository = ref.read(productRepositoryProvider);

      var imported = 0;
      final importedNames = <String>[];
      var parsed = 0;
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;

        parsed++;

        final model = ProductModel.fromJson(item);
        model.createdById = userId;

        final res = await CreateProductUsecase(productRepository).call(model.toEntity());
        if (res.isSuccess) {
          imported++;
          importedNames.add(model.name);
        }
      }

      final pickedName = result.files.single.name;

      state = state.copyWith(
        isBusy: false,
        importedCount: imported,
        importedNames: importedNames,
        importedFileName: pickedName,
        importedAt: DateTime.now(),
        skippedCount: parsed - imported,
      );

      if (imported > 0) {
        final productsNotifier = ref.read(productsNotifierProvider.notifier);
        productsNotifier.resetProducts();
        await productsNotifier.getAllProducts();

        final berandaNotifier = ref.read(berandaProductsNotifierProvider.notifier);
        berandaNotifier.resetProducts();
        await berandaNotifier.getAllProducts();
      }
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  void clearResult() {
    state = const ProductDataState();
  }
}
