import '../../../core/common/result.dart';
import '../../models/purchase_item_model.dart';
import '../../models/purchase_model.dart';

abstract class PurchaseDatasource {
  Future<Result<int>> createPurchase(PurchaseModel purchase);

  Future<Result<void>> deletePurchase(int id);

  Future<Result<PurchaseModel?>> getPurchase(int id);

  Future<Result<List<PurchaseItemModel>>> getPurchaseItems(int purchaseId);

  Future<Result<List<PurchaseModel>>> getPurchases({
    String? query,
    String? supplierId,
    String? month,
    int limit = 50,
    int? offset,
  });

  Future<Result<PurchaseItemModel?>> getLatestPurchaseItem(int productId, {String? supplierId});

  Future<Result<List<PurchaseItemModel>>> getLatestPurchaseItemsBySupplier(int productId);

  Future<Result<List<PurchaseItemModel>>> getProductPurchaseHistory(int productId, {int limit = 10});

  Future<Result<int>> countPurchasesBySupplier(String supplierId);
}
