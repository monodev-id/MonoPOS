import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/usecases/supplier_usecases.dart';
import 'supplier_state.dart';

final supplierNotifierProvider = NotifierProvider<SupplierNotifier, SupplierState>(
  SupplierNotifier.new,
);

class SupplierNotifier extends Notifier<SupplierState> {
  @override
  SupplierState build() {
    return const SupplierState(isLoading: true);
  }

  Future<void> getAllSuppliers() async {
    state = state.copyWith(isLoading: true);

    final repository = ref.read(supplierRepositoryProvider);
    final res = await GetAllSuppliersUsecase(repository).call(null);

    if (res.isSuccess) {
      state = state.copyWith(suppliers: res.data!, isLoading: false, isLoaded: true);
    } else {
      state = state.copyWith(isLoading: false, isLoaded: true);
    }
  }

  Future<void> searchSuppliers(String query) async {
    state = state.copyWith(query: query, isLoading: true);

    final repository = ref.read(supplierRepositoryProvider);
    final resolved = query.trim().isEmpty
        ? await GetAllSuppliersUsecase(repository).call(null)
        : await SearchSuppliersUsecase(repository).call(query.trim());

    state = state.copyWith(
      suppliers: resolved.data ?? const [],
      isLoading: false,
      isLoaded: true,
    );
  }

  Future<Result<void>> deleteSupplier(String id) async {
    final repository = ref.read(supplierRepositoryProvider);
    final res = await DeleteSupplierUsecase(repository).call(id);

    if (res.isSuccess) {
      await getAllSuppliers();
    }

    return res;
  }
}
