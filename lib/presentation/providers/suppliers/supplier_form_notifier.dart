import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/entities/supplier_entity.dart';
import '../../../domain/usecases/supplier_usecases.dart';
import 'supplier_form_state.dart';

final supplierFormNotifierProvider = NotifierProvider.autoDispose<SupplierFormNotifier, SupplierFormState>(
  SupplierFormNotifier.new,
);

class SupplierFormNotifier extends AutoDisposeNotifier<SupplierFormState> {
  @override
  SupplierFormState build() {
    return const SupplierFormState();
  }

  bool _isSaving = false;

  Future<void> initSupplierForm(String? id) async {
    if (id == null) {
      state = state.copyWith(isLoaded: true);
      return;
    }

    final repository = ref.read(supplierRepositoryProvider);
    final res = await GetSupplierUsecase(repository).call(id);

    if (res.isSuccess && res.data != null) {
      final supplier = res.data!;
      state = state.copyWith(
        id: supplier.id,
        name: supplier.name,
        phone: supplier.phone,
        address: supplier.address,
        note: supplier.note,
        isLoaded: true,
      );
      return;
    }

    throw res.error ?? 'Supplier tidak ditemukan';
  }

  void onChangedName(String value) => state = state.copyWith(name: value);
  void onChangedPhone(String value) => state = state.copyWith(phone: value);
  void onChangedAddress(String value) => state = state.copyWith(address: value);
  void onChangedNote(String value) => state = state.copyWith(note: value);

  Future<Result<String>> createSupplier() async {
    if (_isSaving) return Result.failure(error: 'Sedang menyimpan');
    _isSaving = true;
    state = state.copyWith(isSaving: true);

    try {
      final name = state.name.trim();
      if (name.isEmpty) return Result.failure(error: 'Nama supplier wajib diisi');

      final repository = ref.read(supplierRepositoryProvider);
      final duplicate = await GetSupplierByNameUsecase(repository).call(name);
      if (duplicate.isSuccess && duplicate.data != null) {
        return Result.failure(error: 'Supplier "$name" sudah ada');
      }

      final res = await CreateSupplierUsecase(repository).call(
        SupplierEntity(
          name: name,
          phone: state.phone?.trim(),
          address: state.address?.trim(),
          note: state.note?.trim(),
        ),
      );

      return res;
    } finally {
      _isSaving = false;
      state = state.copyWith(isSaving: false);
    }
  }

  Future<Result<void>> updateSupplier() async {
    if (_isSaving) return Result.failure(error: 'Sedang menyimpan');
    if (state.id == null) return Result.failure(error: 'Supplier tidak ditemukan');
    _isSaving = true;
    state = state.copyWith(isSaving: true);

    try {
      final name = state.name.trim();
      if (name.isEmpty) return Result.failure(error: 'Nama supplier wajib diisi');

      final repository = ref.read(supplierRepositoryProvider);
      final duplicate = await GetSupplierByNameUsecase(repository).call(name);
      if (duplicate.isSuccess && duplicate.data != null && duplicate.data!.id != state.id) {
        return Result.failure(error: 'Supplier "$name" sudah ada');
      }

      final res = await UpdateSupplierUsecase(repository).call(
        SupplierEntity(
          id: state.id,
          name: name,
          phone: state.phone?.trim(),
          address: state.address?.trim(),
          note: state.note?.trim(),
        ),
      );

      return res;
    } finally {
      _isSaving = false;
      state = state.copyWith(isSaving: false);
    }
  }
}
