import 'package:equatable/equatable.dart';

import 'purchase_item_entity.dart';

class PurchaseEntity extends Equatable {
  final int? id;
  final String? supplierId;
  final String supplierName;
  final String purchaseDate;
  final String? note;
  final int totalAmount;
  final int totalItems;
  final bool addStock;
  final String? createdById;
  final List<PurchaseItemEntity> items;
  final String? createdAt;
  final String? updatedAt;

  const PurchaseEntity({
    this.id,
    this.supplierId,
    required this.supplierName,
    required this.purchaseDate,
    this.note,
    this.totalAmount = 0,
    this.totalItems = 0,
    this.addStock = true,
    this.createdById,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  PurchaseEntity copyWith({
    int? id,
    String? supplierId,
    String? supplierName,
    String? purchaseDate,
    String? note,
    int? totalAmount,
    int? totalItems,
    bool? addStock,
    String? createdById,
    List<PurchaseItemEntity>? items,
    String? createdAt,
    String? updatedAt,
  }) {
    return PurchaseEntity(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      note: note ?? this.note,
      totalAmount: totalAmount ?? this.totalAmount,
      totalItems: totalItems ?? this.totalItems,
      addStock: addStock ?? this.addStock,
      createdById: createdById ?? this.createdById,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    supplierId,
    supplierName,
    purchaseDate,
    note,
    totalAmount,
    totalItems,
    addStock,
    createdById,
    items,
    createdAt,
    updatedAt,
  ];
}
