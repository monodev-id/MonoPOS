import '../../../core/common/result.dart';
import '../../../domain/entities/supplier_entity.dart';
import '../../../domain/repositories/supplier_repository.dart';
import '../datasources/local/supplier_local_datasource_impl.dart';
import '../models/supplier_model.dart';

class SupplierRepositoryImpl extends SupplierRepository {
  final SupplierLocalDatasourceImpl supplierLocalDatasource;

  SupplierRepositoryImpl({required this.supplierLocalDatasource});

  @override
  Future<Result<SupplierEntity?>> getSupplier(String id) async {
    try {
      final local = await supplierLocalDatasource.getSupplier(id);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<SupplierEntity?>> getSupplierByName(String name) async {
    try {
      final local = await supplierLocalDatasource.getSupplierByName(name);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<String>> createSupplier(SupplierEntity supplier) async {
    try {
      final local = await supplierLocalDatasource.createSupplier(SupplierModel.fromEntity(supplier));
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateSupplier(SupplierEntity supplier) async {
    try {
      final local = await supplierLocalDatasource.updateSupplier(SupplierModel.fromEntity(supplier));
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteSupplier(String id) async {
    try {
      final local = await supplierLocalDatasource.deleteSupplier(id);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<SupplierEntity>>> getAllSuppliers() async {
    try {
      final local = await supplierLocalDatasource.getAllSuppliers();
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<SupplierEntity>>> searchSuppliers(String query) async {
    try {
      final local = await supplierLocalDatasource.searchSuppliers(query);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
