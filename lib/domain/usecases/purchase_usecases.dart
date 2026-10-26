import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../entities/purchase_entity.dart';
import '../entities/purchase_item_entity.dart';
import '../repositories/purchase_repository.dart';

class CreatePurchaseUsecase extends Usecase<Result, PurchaseEntity> {
  CreatePurchaseUsecase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<int>> call(PurchaseEntity params) async => _repository.createPurchase(params);
}

class DeletePurchaseUsecase extends Usecase<Result, int> {
  DeletePurchaseUsecase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<void>> call(int params) async => _repository.deletePurchase(params);
}

class GetPurchaseUsecase extends Usecase<Result, int> {
  GetPurchaseUsecase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<PurchaseEntity?>> call(int params) async => _repository.getPurchase(params);
}

class GetPurchaseItemsUsecase extends Usecase<Result, int> {
  GetPurchaseItemsUsecase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<List<PurchaseItemEntity>>> call(int params) async => _repository.getPurchaseItems(params);
}

class GetPurchasesUsecase
    extends Usecase<Result, ({String? query, String? supplierId, String? month, int limit, int? offset})> {
  GetPurchasesUsecase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<List<PurchaseEntity>>> call(
    ({String? query, String? supplierId, String? month, int limit, int? offset}) params,
  ) async => _repository.getPurchases(
    query: params.query,
    supplierId: params.supplierId,
    month: params.month,
    limit: params.limit,
    offset: params.offset,
  );
}

class GetLatestPurchaseItemUsecase extends Usecase<Result, ({int productId, String? supplierId})> {
  GetLatestPurchaseItemUsecase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<PurchaseItemEntity?>> call(({int productId, String? supplierId}) params) async =>
      _repository.getLatestPurchaseItem(params.productId, supplierId: params.supplierId);
}

class GetLatestPurchaseItemsBySupplierUsecase extends Usecase<Result, int> {
  GetLatestPurchaseItemsBySupplierUsecase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<List<PurchaseItemEntity>>> call(int params) async =>
      _repository.getLatestPurchaseItemsBySupplier(params);
}

class GetProductPurchaseHistoryUsecase extends Usecase<Result, ({int productId, int limit})> {
  GetProductPurchaseHistoryUsecase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<List<PurchaseItemEntity>>> call(({int productId, int limit}) params) async =>
      _repository.getProductPurchaseHistory(params.productId, limit: params.limit);
}

class CountPurchasesBySupplierUsecase extends Usecase<Result, String> {
  CountPurchasesBySupplierUsecase(this._repository);

  final PurchaseRepository _repository;

  @override
  Future<Result<int>> call(String params) async => _repository.countPurchasesBySupplier(params);
}
