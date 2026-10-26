import '../../../core/common/result.dart';
import '../../models/supplier_model.dart';

abstract class SupplierDatasource {
  Future<Result<SupplierModel?>> getSupplier(String id);

  Future<Result<SupplierModel?>> getSupplierByName(String name);

  Future<Result<String>> createSupplier(SupplierModel supplier);

  Future<Result<void>> updateSupplier(SupplierModel supplier);

  Future<Result<void>> deleteSupplier(String id);

  Future<Result<List<SupplierModel>>> getAllSuppliers();

  Future<Result<List<SupplierModel>>> searchSuppliers(String query);
}
