import 'package:equatable/equatable.dart';

import '../../../domain/entities/product_entity.dart';

class ProductDataState extends Equatable {
  final bool isBusy;
  final int? exportedCount;
  final int? importedCount;
  final String? error;
  final List<ProductEntity> exportedProducts;
  final String? exportedFileName;
  final DateTime? exportedAt;
  final List<String> importedNames;
  final String? importedFileName;
  final DateTime? importedAt;
  final int? skippedCount;

  const ProductDataState({
    this.isBusy = false,
    this.exportedCount,
    this.importedCount,
    this.error,
    this.exportedProducts = const [],
    this.exportedFileName,
    this.exportedAt,
    this.importedNames = const [],
    this.importedFileName,
    this.importedAt,
    this.skippedCount,
  });

  ProductDataState copyWith({
    bool? isBusy,
    int? exportedCount,
    int? importedCount,
    String? error,
    List<ProductEntity>? exportedProducts,
    String? exportedFileName,
    DateTime? exportedAt,
    List<String>? importedNames,
    String? importedFileName,
    DateTime? importedAt,
    int? skippedCount,
  }) {
    return ProductDataState(
      isBusy: isBusy ?? this.isBusy,
      exportedCount: exportedCount ?? this.exportedCount,
      importedCount: importedCount ?? this.importedCount,
      error: error ?? this.error,
      exportedProducts: exportedProducts ?? this.exportedProducts,
      exportedFileName: exportedFileName ?? this.exportedFileName,
      exportedAt: exportedAt ?? this.exportedAt,
      importedNames: importedNames ?? this.importedNames,
      importedFileName: importedFileName ?? this.importedFileName,
      importedAt: importedAt ?? this.importedAt,
      skippedCount: skippedCount ?? this.skippedCount,
    );
  }

  @override
  List<Object?> get props => [
    isBusy,
    exportedCount,
    importedCount,
    error,
    exportedProducts,
    exportedFileName,
    exportedAt,
    importedNames,
    importedFileName,
    importedAt,
    skippedCount,
  ];
}
