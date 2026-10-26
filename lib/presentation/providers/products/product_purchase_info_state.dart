import '../../../domain/entities/purchase_item_entity.dart';

class ProductPurchaseInfoState {
  final int costPrice;
  final PurchaseItemEntity? lastPurchase;
  final List<PurchaseItemEntity> supplierPrices;
  final List<PurchaseItemEntity> history;
  final bool isLoading;

  const ProductPurchaseInfoState({
    this.costPrice = 0,
    this.lastPurchase,
    this.supplierPrices = const [],
    this.history = const [],
    this.isLoading = true,
  });

  bool get hasData => lastPurchase != null || history.isNotEmpty;

  ProductPurchaseInfoState copyWith({
    int? costPrice,
    PurchaseItemEntity? lastPurchase,
    List<PurchaseItemEntity>? supplierPrices,
    List<PurchaseItemEntity>? history,
    bool? isLoading,
  }) {
    return ProductPurchaseInfoState(
      costPrice: costPrice ?? this.costPrice,
      lastPurchase: lastPurchase ?? this.lastPurchase,
      supplierPrices: supplierPrices ?? this.supplierPrices,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
