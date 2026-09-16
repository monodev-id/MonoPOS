import '../../../domain/entities/product_entity.dart';

class ProductsState {
  final List<ProductEntity>? allProducts;
  final bool isLoadingMore;
  final bool hasMore;
  final String? contains;

  const ProductsState({this.allProducts, this.isLoadingMore = false, this.hasMore = true, this.contains});

  ProductsState copyWith({
    List<ProductEntity>? allProducts,
    bool? isLoadingMore,
    bool? hasMore,
    String? contains,
  }) {
    return ProductsState(
      allProducts: allProducts ?? this.allProducts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      contains: contains ?? this.contains,
    );
  }
}
