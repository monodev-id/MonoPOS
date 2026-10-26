import '../../domain/entities/purchase_entity.dart';
import 'purchase_item_model.dart';

class PurchaseModel {
  int id;
  String? supplierId;
  String supplierName;
  String purchaseDate;
  String? note;
  int totalAmount;
  int totalItems;
  bool addStock;
  String? createdById;
  List<PurchaseItemModel>? items;
  String? createdAt;
  String? updatedAt;

  PurchaseModel({
    required this.id,
    this.supplierId,
    required this.supplierName,
    required this.purchaseDate,
    this.note,
    this.totalAmount = 0,
    this.totalItems = 0,
    this.addStock = true,
    this.createdById,
    this.items,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as int? ?? 0,
      supplierId: json['supplierId'],
      supplierName: json['supplierName'] ?? '',
      purchaseDate: json['purchaseDate'] ?? '',
      note: json['note'],
      totalAmount: json['totalAmount'] ?? 0,
      totalItems: json['totalItems'] ?? 0,
      addStock: json['addStock'] == 1 || json['addStock'] == true,
      createdById: json['createdById'],
      items: json['items'] != null
          ? (json['items'] as List).map((e) => PurchaseItemModel.fromJson(Map<String, dynamic>.from(e))).toList()
          : null,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchaseDate': purchaseDate,
      'note': note,
      'totalAmount': totalAmount,
      'totalItems': totalItems,
      'addStock': addStock ? 1 : 0,
      'createdById': createdById,
      'items': items?.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory PurchaseModel.fromEntity(PurchaseEntity entity) {
    return PurchaseModel(
      id: entity.id ?? DateTime.now().millisecondsSinceEpoch,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      purchaseDate: entity.purchaseDate,
      note: entity.note,
      totalAmount: entity.totalAmount,
      totalItems: entity.totalItems,
      addStock: entity.addStock,
      createdById: entity.createdById,
      items: entity.items.map((e) => PurchaseItemModel.fromEntity(e)).toList(),
      createdAt: entity.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: entity.updatedAt ?? DateTime.now().toIso8601String(),
    );
  }

  PurchaseEntity toEntity() {
    return PurchaseEntity(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName,
      purchaseDate: purchaseDate,
      note: note,
      totalAmount: totalAmount,
      totalItems: totalItems,
      addStock: addStock,
      createdById: createdById,
      items: items?.map((e) => e.toEntity()).toList() ?? const [],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
