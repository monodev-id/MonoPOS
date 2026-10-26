import 'package:equatable/equatable.dart';

class PurchaseItemEntity extends Equatable {
  final int? id;
  final int? purchaseId;
  final int productId;
  final String productName;
  final String unitName;
  final int conversionValue;
  final double quantity;
  final int unitPrice;
  final int totalPrice;
  final int baseUnitPrice;
  final String? createdAt;

  /// Data hasil join dengan tabel Purchase (tidak disimpan di PurchaseItem).
  final String? supplierId;
  final String? supplierName;
  final String? purchaseDate;

  const PurchaseItemEntity({
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

  PurchaseItemEntity copyWith({
    int? id,
    int? purchaseId,
    int? productId,
    String? productName,
    String? unitName,
    int? conversionValue,
    double? quantity,
    int? unitPrice,
    int? totalPrice,
    int? baseUnitPrice,
    String? createdAt,
    String? supplierId,
    String? supplierName,
    String? purchaseDate,
  }) {
    return PurchaseItemEntity(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitName: unitName ?? this.unitName,
      conversionValue: conversionValue ?? this.conversionValue,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      baseUnitPrice: baseUnitPrice ?? this.baseUnitPrice,
      createdAt: createdAt ?? this.createdAt,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }

  @override
  List<Object?> get props => [
    id,
    purchaseId,
    productId,
    productName,
    unitName,
    conversionValue,
    quantity,
    unitPrice,
    totalPrice,
    baseUnitPrice,
    createdAt,
    supplierId,
    supplierName,
    purchaseDate,
  ];
}
