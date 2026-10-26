import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/purchase_item_entity.dart';
import '../../../domain/entities/supplier_entity.dart';

class PurchaseDraftItem {
  final ProductEntity product;
  String unitName;
  int conversionValue;
  double quantity;
  int unitPrice;
  PurchaseItemEntity? lastFromSupplier;
  PurchaseItemEntity? lastFromAnySupplier;
  List<PurchaseItemEntity> supplierPrices;

  PurchaseDraftItem({
    required this.product,
    required this.unitName,
    required this.conversionValue,
    this.quantity = 1,
    this.unitPrice = 0,
    this.lastFromSupplier,
    this.lastFromAnySupplier,
    this.supplierPrices = const [],
  });

  int get totalPrice => (quantity * unitPrice).round();

  int get baseUnitPrice => conversionValue > 0 ? (unitPrice / conversionValue).round() : unitPrice;

  PurchaseItemEntity? get priceHint => lastFromSupplier ?? lastFromAnySupplier;

  PurchaseDraftItem copyWith({
    String? unitName,
    int? conversionValue,
    double? quantity,
    int? unitPrice,
    PurchaseItemEntity? lastFromSupplier,
    PurchaseItemEntity? lastFromAnySupplier,
    List<PurchaseItemEntity>? supplierPrices,
  }) {
    return PurchaseDraftItem(
      product: product,
      unitName: unitName ?? this.unitName,
      conversionValue: conversionValue ?? this.conversionValue,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lastFromSupplier: lastFromSupplier ?? this.lastFromSupplier,
      lastFromAnySupplier: lastFromAnySupplier ?? this.lastFromAnySupplier,
      supplierPrices: supplierPrices ?? this.supplierPrices,
    );
  }
}

class PurchaseFormState {
  final bool isLoaded;
  final bool isSaving;
  final SupplierEntity? supplier;
  final String purchaseDate;
  final String note;
  final bool addStock;
  final List<PurchaseDraftItem> items;
  final List<SupplierEntity> suppliers;

  const PurchaseFormState({
    this.isLoaded = false,
    this.isSaving = false,
    this.supplier,
    this.purchaseDate = '',
    this.note = '',
    this.addStock = true,
    this.items = const [],
    this.suppliers = const [],
  });

  int get totalAmount => items.fold(0, (total, item) => total + item.totalPrice);

  int get totalItems => items.length;

  PurchaseFormState copyWith({
    bool? isLoaded,
    bool? isSaving,
    SupplierEntity? supplier,
    String? purchaseDate,
    String? note,
    bool? addStock,
    List<PurchaseDraftItem>? items,
    List<SupplierEntity>? suppliers,
  }) {
    return PurchaseFormState(
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      supplier: supplier ?? this.supplier,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      note: note ?? this.note,
      addStock: addStock ?? this.addStock,
      items: items ?? this.items,
      suppliers: suppliers ?? this.suppliers,
    );
  }
}
