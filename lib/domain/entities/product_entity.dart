import 'package:equatable/equatable.dart';

import 'product_unit_entity.dart';

class ProductEntity extends Equatable {
  final int? id;
  final String createdById;
  final String name;
  final String imageUrl;
  final int stock;
  final int? sold;
  final int price;
  final int? wholesalePrice;
  final int costPrice;
  final String unit;
  final String? barcode;
  final String? description;
  final String? createdAt;
  final String? updatedAt;
  final List<ProductUnitEntity> units;
  final bool isCustomPrice;

  const ProductEntity({
    this.id,
    required this.createdById,
    required this.name,
    required this.imageUrl,
    required this.stock,
    this.sold,
    required this.price,
    this.wholesalePrice,
    this.costPrice = 0,
    this.unit = 'pcs',
    this.barcode,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.units = const [],
    this.isCustomPrice = false,
  });

  ProductEntity copyWith({
    int? id,
    String? createdById,
    String? name,
    String? imageUrl,
    int? stock,
    int? sold,
    int? price,
    int? wholesalePrice,
    int? costPrice,
    String? unit,
    String? barcode,
    String? description,
    String? createdAt,
    String? updatedAt,
    List<ProductUnitEntity>? units,
    bool? isCustomPrice,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      createdById: createdById ?? this.createdById,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      sold: sold ?? this.sold,
      price: price ?? this.price,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      costPrice: costPrice ?? this.costPrice,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      units: units ?? this.units,
      isCustomPrice: isCustomPrice ?? this.isCustomPrice,
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdById,
    name,
    imageUrl,
    stock,
    sold,
    price,
    wholesalePrice,
    costPrice,
    unit,
    barcode,
    description,
    createdAt,
    updatedAt,
    units,
    isCustomPrice,
  ];
}
