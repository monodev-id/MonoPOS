import '../../../core/common/result.dart';
import '../../../domain/entities/purchase_entity.dart';
import '../../../domain/entities/purchase_item_entity.dart';
import '../../../domain/repositories/purchase_repository.dart';
import '../datasources/local/purchase_local_datasource_impl.dart';
import '../models/purchase_model.dart';

class PurchaseRepositoryImpl extends PurchaseRepository {
  final PurchaseLocalDatasourceImpl purchaseLocalDatasource;

  PurchaseRepositoryImpl({required this.purchaseLocalDatasource});

  @override
  Future<Result<int>> createPurchase(PurchaseEntity purchase) async {
    try {
      final local = await purchaseLocalDatasource.createPurchase(PurchaseModel.fromEntity(purchase));
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deletePurchase(int id) async {
    try {
      final local = await purchaseLocalDatasource.deletePurchase(id);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<PurchaseEntity?>> getPurchase(int id) async {
    try {
      final local = await purchaseLocalDatasource.getPurchase(id);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<PurchaseItemEntity>>> getPurchaseItems(int purchaseId) async {
    try {
      final local = await purchaseLocalDatasource.getPurchaseItems(purchaseId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<PurchaseEntity>>> getPurchases({
    String? query,
    String? supplierId,
    String? month,
    int limit = 50,
    int? offset,
  }) async {
    try {
      final local = await purchaseLocalDatasource.getPurchases(
        query: query,
        supplierId: supplierId,
        month: month,
        limit: limit,
        offset: offset,
      );
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<PurchaseItemEntity?>> getLatestPurchaseItem(int productId, {String? supplierId}) async {
    try {
      final local = await purchaseLocalDatasource.getLatestPurchaseItem(productId, supplierId: supplierId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<PurchaseItemEntity>>> getLatestPurchaseItemsBySupplier(int productId) async {
    try {
      final local = await purchaseLocalDatasource.getLatestPurchaseItemsBySupplier(productId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<PurchaseItemEntity>>> getProductPurchaseHistory(int productId, {int limit = 10}) async {
    try {
      final local = await purchaseLocalDatasource.getProductPurchaseHistory(productId, limit: limit);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<int>> countPurchasesBySupplier(String supplierId) async {
    try {
      final local = await purchaseLocalDatasource.countPurchasesBySupplier(supplierId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
