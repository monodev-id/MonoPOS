import 'package:equatable/equatable.dart';

import '../../../domain/entities/product_entity.dart';

enum BarcodeLabelFilter { all, withBarcode, withoutBarcode }

class ProductBarcodeLabelState extends Equatable {
  final bool isLoading;
  final bool isGenerating;
  final bool isSaving;
  final bool isPrinting;
  final String query;
  final BarcodeLabelFilter filter;
  final List<ProductEntity> products;
  final Map<int, String> generated;
  final Map<int, int> copies;
  final Set<int> selected;
  final String? error;
  final int? savedCount;
  final List<String> skippedNoBarcode;
  final String? newName;
  final int? newPrice;
  final int? newWholesalePrice;
  final int? newStock;
  final String? newUnit;
  final String? newDescription;
  final String? newCode;
  final int? newProductId;

  const ProductBarcodeLabelState({
    this.isLoading = false,
    this.isGenerating = false,
    this.isSaving = false,
    this.isPrinting = false,
    this.query = '',
    this.filter = BarcodeLabelFilter.withoutBarcode,
    this.products = const [],
    this.generated = const {},
    this.copies = const {},
    this.selected = const {},
    this.error,
    this.savedCount,
    this.skippedNoBarcode = const [],
    this.newName,
    this.newPrice,
    this.newWholesalePrice,
    this.newStock,
    this.newUnit,
    this.newDescription,
    this.newCode,
    this.newProductId,
  });

  bool get isBusy => isLoading || isGenerating || isSaving || isPrinting;

  String barcodeFor(ProductEntity product) {
    if (product.barcode != null && product.barcode!.trim().isNotEmpty) {
      return product.barcode!.trim();
    }

    return generated[product.id] ?? '';
  }

  ProductBarcodeLabelState copyWith({
    bool? isLoading,
    bool? isGenerating,
    bool? isSaving,
    bool? isPrinting,
    String? query,
    BarcodeLabelFilter? filter,
    List<ProductEntity>? products,
    Map<int, String>? generated,
    Map<int, int>? copies,
    Set<int>? selected,
    String? error,
    int? savedCount,
    List<String>? skippedNoBarcode,
    String? newName,
    int? newPrice,
    int? newWholesalePrice,
    int? newStock,
    String? newUnit,
    String? newDescription,
    String? newCode,
    int? newProductId,
    bool clearNewCode = false,
    bool clearNewProductId = false,
    bool clearNewFields = false,
  }) {
    if (clearNewFields) {
      return ProductBarcodeLabelState(
        isLoading: isLoading ?? this.isLoading,
        isGenerating: isGenerating ?? this.isGenerating,
        isSaving: isSaving ?? this.isSaving,
        isPrinting: isPrinting ?? this.isPrinting,
        query: query ?? this.query,
        filter: filter ?? this.filter,
        products: products ?? this.products,
        generated: generated ?? this.generated,
        copies: copies ?? this.copies,
        selected: selected ?? this.selected,
        savedCount: savedCount,
      );
    }

    return ProductBarcodeLabelState(
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      isSaving: isSaving ?? this.isSaving,
      isPrinting: isPrinting ?? this.isPrinting,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      products: products ?? this.products,
      generated: generated ?? this.generated,
      copies: copies ?? this.copies,
      selected: selected ?? this.selected,
      error: error,
      savedCount: savedCount,
      skippedNoBarcode: skippedNoBarcode ?? this.skippedNoBarcode,
      newName: newName ?? this.newName,
      newPrice: newPrice ?? this.newPrice,
      newWholesalePrice: newWholesalePrice ?? this.newWholesalePrice,
      newStock: newStock ?? this.newStock,
      newUnit: newUnit ?? this.newUnit,
      newDescription: newDescription ?? this.newDescription,
      newCode: clearNewCode ? null : (newCode ?? this.newCode),
      newProductId: clearNewProductId ? null : (newProductId ?? this.newProductId),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isGenerating,
    isSaving,
    isPrinting,
    query,
    filter,
    products,
    generated,
    copies,
    selected,
    error,
    savedCount,
    skippedNoBarcode,
    newName,
    newPrice,
    newWholesalePrice,
    newStock,
    newUnit,
    newDescription,
    newCode,
    newProductId,
  ];
}
