import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../entities/supplier_entity.dart';
import '../repositories/supplier_repository.dart';

class GetSupplierUsecase extends Usecase<Result, String> {
  GetSupplierUsecase(this._repository);

  final SupplierRepository _repository;

  @override
  Future<Result<SupplierEntity?>> call(String params) async => _repository.getSupplier(params);
}

class GetSupplierByNameUsecase extends Usecase<Result, String> {
  GetSupplierByNameUsecase(this._repository);

  final SupplierRepository _repository;

  @override
  Future<Result<SupplierEntity?>> call(String params) async => _repository.getSupplierByName(params);
}

class CreateSupplierUsecase extends Usecase<Result, SupplierEntity> {
  CreateSupplierUsecase(this._repository);

  final SupplierRepository _repository;

  @override
  Future<Result<String>> call(SupplierEntity params) async => _repository.createSupplier(params);
}

class UpdateSupplierUsecase extends Usecase<Result, SupplierEntity> {
  UpdateSupplierUsecase(this._repository);

  final SupplierRepository _repository;

  @override
  Future<Result<void>> call(SupplierEntity params) async => _repository.updateSupplier(params);
}

class DeleteSupplierUsecase extends Usecase<Result, String> {
  DeleteSupplierUsecase(this._repository);

  final SupplierRepository _repository;

  @override
  Future<Result<void>> call(String params) async => _repository.deleteSupplier(params);
}

class GetAllSuppliersUsecase extends Usecase<Result, void> {
  GetAllSuppliersUsecase(this._repository);

  final SupplierRepository _repository;

  @override
  Future<Result<List<SupplierEntity>>> call(void params) async => _repository.getAllSuppliers();
}

class SearchSuppliersUsecase extends Usecase<Result, String> {
  SearchSuppliersUsecase(this._repository);

  final SupplierRepository _repository;

  @override
  Future<Result<List<SupplierEntity>>> call(String params) async => _repository.searchSuppliers(params);
}
