import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../domain/usecases/product_usecases.dart';
import '../../../domain/usecases/purchase_usecases.dart';
import 'product_purchase_info_state.dart';

final productPurchaseInfoNotifierProvider =
    NotifierProvider.autoDispose<ProductPurchaseInfoNotifier, ProductPurchaseInfoState>(
      ProductPurchaseInfoNotifier.new,
    );

class ProductPurchaseInfoNotifier extends AutoDisposeNotifier<ProductPurchaseInfoState> {
  @override
  ProductPurchaseInfoState build() {
    return const ProductPurchaseInfoState();
  }

  Future<void> load(int productId) async {
    state = const ProductPurchaseInfoState(isLoading: true);

    final repository = ref.read(purchaseRepositoryProvider);

    final product = await GetProductUsecase(ref.read(productRepositoryProvider)).call(productId);
    final latest = await GetLatestPurchaseItemUsecase(repository).call((
      productId: productId,
      supplierId: null,
    ));
    final prices = await GetLatestPurchaseItemsBySupplierUsecase(repository).call(productId);
    final history = await GetProductPurchaseHistoryUsecase(repository).call((
      productId: productId,
      limit: 5,
    ));

    state = ProductPurchaseInfoState(
      costPrice: product.data?.costPrice ?? 0,
      lastPurchase: latest.data,
      supplierPrices: prices.data ?? const [],
      history: history.data ?? const [],
      isLoading: false,
    );
  }
}
