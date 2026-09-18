import 'dart:io';

import '../../../domain/entities/product_tier_entity.dart';
import '../../../domain/entities/product_unit_entity.dart';

class ProductFormState {
  final File? imageFile;
  final String? imageUrl;
  final String? name;
  final int? price;
  final int? wholesalePrice;
  final int? stock;
  final String? unit;
  final String? barcode;
  final String? description;
  final List<ProductUnitEntity> units;
  final Map<int, List<ProductTierEntity>> tieredPrices;
  final List<String> customUnitNames;
  final bool isLoaded;
  final bool isSaving;

  const ProductFormState({
    this.imageFile,
    this.imageUrl,
    this.name,
    this.price,
    this.wholesalePrice,
    this.stock,
    this.unit,
    this.barcode,
    this.description,
    this.units = const [],
    this.tieredPrices = const {},
    this.customUnitNames = const [],
    this.isLoaded = false,
    this.isSaving = false,
  });

  static const _sentinel = Object();

  ProductFormState copyWith({
    Object? imageFile = _sentinel,
    Object? imageUrl = _sentinel,
    Object? name = _sentinel,
    Object? price = _sentinel,
    Object? wholesalePrice = _sentinel,
    Object? stock = _sentinel,
    Object? unit = _sentinel,
    Object? barcode = _sentinel,
    Object? description = _sentinel,
    List<ProductUnitEntity>? units,
    Map<int, List<ProductTierEntity>>? tieredPrices,
    List<String>? customUnitNames,
    bool? isLoaded,
    bool? isSaving,
  }) {
    return ProductFormState(
      imageFile: imageFile == _sentinel ? this.imageFile : imageFile as File?,
      imageUrl: imageUrl == _sentinel ? this.imageUrl : imageUrl as String?,
      name: name == _sentinel ? this.name : name as String?,
      price: price == _sentinel ? this.price : price as int?,
      wholesalePrice: wholesalePrice == _sentinel ? this.wholesalePrice : wholesalePrice as int?,
      stock: stock == _sentinel ? this.stock : stock as int?,
      unit: unit == _sentinel ? this.unit : unit as String?,
      barcode: barcode == _sentinel ? this.barcode : barcode as String?,
      description: description == _sentinel ? this.description : description as String?,
      units: units ?? this.units,
      tieredPrices: tieredPrices ?? this.tieredPrices,
      customUnitNames: customUnitNames ?? this.customUnitNames,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
