import 'package:equatable/equatable.dart';

import 'product_unit_entity.dart';

class OrderedProductEntity extends Equatable {
  final int? id;
  final int? transactionId;
  final int productId;
  final double quantity;
  final int stock;
  final String name;
  final String imageUrl;
  final int price;
  final String priceType;
  final String unit;
  final int conversionValue;
  final bool isTieredPrice;

  /// Snapshot satuan produk saat item masuk keranjang.
  ///
  /// Dipakai oleh dropdown satuan di keranjang agar tidak bergantung pada
  /// cache daftar produk yang sifatnya paginasi. Tidak diserialisasi ke
  /// database/Supabase karena hanya dibutuhkan selama transaksi berjalan.
  final List<ProductUnitEntity> units;

  final String? createdAt;
  final String? updatedAt;

  const OrderedProductEntity({
    this.id,
    this.transactionId,
    required this.productId,
    required this.quantity,
    required this.stock,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.priceType = 'retail',
    this.unit = 'pcs',
    this.conversionValue = 1,
    this.isTieredPrice = false,
    this.units = const [],
    this.createdAt,
    this.updatedAt,
  });

  OrderedProductEntity copyWith({
    int? id,
    int? transactionId,
    int? productId,
    double? quantity,
    int? stock,
    String? name,
    String? imageUrl,
    int? price,
    String? priceType,
    String? unit,
    int? conversionValue,
    bool? isTieredPrice,
    List<ProductUnitEntity>? units,
    String? createdAt,
    String? updatedAt,
  }) {
    return OrderedProductEntity(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      stock: stock ?? this.stock,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      unit: unit ?? this.unit,
      conversionValue: conversionValue ?? this.conversionValue,
      isTieredPrice: isTieredPrice ?? this.isTieredPrice,
      units: units ?? this.units,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    transactionId,
    productId,
    quantity,
    stock,
    name,
    imageUrl,
    price,
    priceType,
    unit,
    conversionValue,
    isTieredPrice,
    units,
    createdAt,
    updatedAt,
  ];
}
