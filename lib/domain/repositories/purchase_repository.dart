import '../../core/common/result.dart';
import '../entities/purchase_entity.dart';
import '../entities/purchase_item_entity.dart';

abstract class PurchaseRepository {
  Future<Result<int>> createPurchase(PurchaseEntity purchase);

  Future<Result<void>> deletePurchase(int id);

  Future<Result<PurchaseEntity?>> getPurchase(int id);

  Future<Result<List<PurchaseItemEntity>>> getPurchaseItems(int purchaseId);

  Future<Result<List<PurchaseEntity>>> getPurchases({
    String? query,
    String? supplierId,
    String? month,
    int limit = 50,
    int? offset,
  });

  Future<Result<PurchaseItemEntity?>> getLatestPurchaseItem(int productId, {String? supplierId});

  Future<Result<List<PurchaseItemEntity>>> getLatestPurchaseItemsBySupplier(int productId);

  Future<Result<List<PurchaseItemEntity>>> getProductPurchaseHistory(int productId, {int limit = 10});

  Future<Result<int>> countPurchasesBySupplier(String supplierId);
}
