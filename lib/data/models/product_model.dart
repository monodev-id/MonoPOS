import '../../domain/entities/product_entity.dart';
import 'product_unit_model.dart';

class ProductModel {
  int id;
  String createdById;
  String name;
  String imageUrl;
  int stock;
  int sold;
  int price;
  int? wholesalePrice;
  String unit;
  String? barcode;
  String? description;
  List<ProductUnitModel> units;
  String? createdAt;
  String? updatedAt;
  bool isCustomPrice;

  ProductModel({
    required this.id,
    required this.createdById,
    required this.name,
    required this.imageUrl,
    required this.stock,
    required this.sold,
    required this.price,
    this.wholesalePrice,
    this.unit = 'pcs',
    this.barcode,
    this.description,
    this.units = const [],
    this.createdAt,
    this.updatedAt,
    this.isCustomPrice = false,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      createdById: json['createdById'],
      name: json['name'],
      imageUrl: json['imageUrl'] ?? '',
      stock: json['stock'],
      sold: json['sold'],
      price: json['price'],
      wholesalePrice: json['wholesalePrice'],
      unit: json['unit'] ?? 'pcs',
      barcode: json['barcode'],
      description: json['description'],
      units: json['units'] != null ? (json['units'] as List).map((e) => ProductUnitModel.fromJson(e)).toList() : [],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      isCustomPrice: json['isCustomPrice'] == 1 || json['isCustomPrice'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdById': createdById,
      'name': name,
      'imageUrl': imageUrl,
      'stock': stock,
      'sold': sold,
      'price': price,
      'wholesalePrice': wholesalePrice,
      'unit': unit,
      'barcode': barcode,
      'description': description,
      'units': units.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isCustomPrice': isCustomPrice ? 1 : 0,
    };
  }

  factory ProductModel.fromEntity(ProductEntity entity) {
    final normalizedBarcode = entity.barcode?.trim();
    return ProductModel(
      id: entity.id ?? DateTime.now().millisecondsSinceEpoch,
      createdById: entity.createdById,
      name: entity.name,
      imageUrl: entity.imageUrl,
      stock: entity.stock,
      sold: entity.sold ?? 0,
      price: entity.price,
      wholesalePrice: entity.wholesalePrice,
      unit: entity.unit,
      barcode: normalizedBarcode == null || normalizedBarcode.isEmpty ? null : normalizedBarcode,
      description: entity.description,
      units: entity.units.map((e) => ProductUnitModel.fromEntity(e)).toList(),
      createdAt: entity.createdAt ?? DateTime.now().toIso8601String(),
      updatedAt: entity.updatedAt ?? DateTime.now().toIso8601String(),
      isCustomPrice: entity.isCustomPrice,
    );
  }

  ProductEntity toEntity() {
    return ProductEntity(
      id: id,
      createdById: createdById,
      name: name,
      imageUrl: imageUrl,
      stock: stock,
      sold: sold,
      price: price,
      wholesalePrice: wholesalePrice,
      unit: unit,
      barcode: barcode,
      description: description,
      units: units.map((e) => e.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isCustomPrice: isCustomPrice,
    );
  }
}
