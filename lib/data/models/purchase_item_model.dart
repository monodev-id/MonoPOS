import '../../domain/entities/purchase_item_entity.dart';

class PurchaseItemModel {
  int? id;
  int? purchaseId;
  int productId;
  String productName;
  String unitName;
  int conversionValue;
  double quantity;
  int unitPrice;
  int totalPrice;
  int baseUnitPrice;
  String? createdAt;

  /// Hasil join dengan Purchase, tidak ikut disimpan ke tabel PurchaseItem.
  String? supplierId;
  String? supplierName;
  String? purchaseDate;

  PurchaseItemModel({
    this.id,
    this.purchaseId,
    required this.productId,
    required this.productName,
    required this.unitName,
    this.conversionValue = 1,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    required this.baseUnitPrice,
    this.createdAt,
    this.supplierId,
    this.supplierName,
    this.purchaseDate,
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      id: json['id'] as int?,
      purchaseId: json['purchaseId'] as int?,
      productId: json['productId'] as int? ?? 0,
      productName: json['productName'] ?? '',
      unitName: json['unitName'] ?? 'pcs',
      conversionValue: json['conversionValue'] ?? 1,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unitPrice: json['unitPrice'] ?? 0,
      totalPrice: json['totalPrice'] ?? 0,
      baseUnitPrice: json['baseUnitPrice'] ?? 0,
      createdAt: json['createdAt'],
      supplierId: json['supplierId'],
      supplierName: json['supplierName'],
      purchaseDate: json['purchaseDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchaseId': purchaseId,
      'productId': productId,
      'productName': productName,
      'unitName': unitName,
      'conversionValue': conversionValue,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'baseUnitPrice': baseUnitPrice,
      'createdAt': createdAt,
    };
  }

  factory PurchaseItemModel.fromEntity(PurchaseItemEntity entity) {
    return PurchaseItemModel(
      id: entity.id,
      purchaseId: entity.purchaseId,
      productId: entity.productId,
      productName: entity.productName,
      unitName: entity.unitName,
      conversionValue: entity.conversionValue,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      totalPrice: entity.totalPrice,
      baseUnitPrice: entity.baseUnitPrice,
      createdAt: entity.createdAt ?? DateTime.now().toIso8601String(),
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      purchaseDate: entity.purchaseDate,
    );
  }

  PurchaseItemEntity toEntity() {
    return PurchaseItemEntity(
      id: id,
      purchaseId: purchaseId,
      productId: productId,
      productName: productName,
      unitName: unitName,
      conversionValue: conversionValue,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      baseUnitPrice: baseUnitPrice,
      createdAt: createdAt,
      supplierId: supplierId,
      supplierName: supplierName,
      purchaseDate: purchaseDate,
    );
  }
}
