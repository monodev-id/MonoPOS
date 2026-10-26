import '../../core/common/result.dart';
import '../entities/supplier_entity.dart';

abstract class SupplierRepository {
  Future<Result<SupplierEntity?>> getSupplier(String id);

  Future<Result<SupplierEntity?>> getSupplierByName(String name);

  Future<Result<String>> createSupplier(SupplierEntity supplier);

  Future<Result<void>> updateSupplier(SupplierEntity supplier);

  Future<Result<void>> deleteSupplier(String id);

  Future<Result<List<SupplierEntity>>> getAllSuppliers();

  Future<Result<List<SupplierEntity>>> searchSuppliers(String query);
}
