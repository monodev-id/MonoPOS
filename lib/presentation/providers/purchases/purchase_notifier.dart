import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/usecases/purchase_usecases.dart';
import 'purchase_state.dart';

final purchaseNotifierProvider = NotifierProvider<PurchaseNotifier, PurchaseState>(
  PurchaseNotifier.new,
);

class PurchaseNotifier extends Notifier<PurchaseState> {
  @override
  PurchaseState build() {
    return const PurchaseState(isLoading: true);
  }

  Future<void> getPurchases({String? query, String? month, bool resetMonth = false}) async {
    state = state.copyWith(
      isLoading: true,
      query: query ?? state.query,
      month: resetMonth ? month : (month ?? state.month),
    );

    final repository = ref.read(purchaseRepositoryProvider);
    final res = await GetPurchasesUsecase(repository).call((
      query: state.query,
      month: state.month,
      supplierId: null,
      limit: 100,
      offset: null,
    ));

    if (res.isSuccess) {
      state = state.copyWith(purchases: res.data!, isLoading: false, isLoaded: true);
    } else {
      state = state.copyWith(isLoading: false, isLoaded: true);
    }
  }

  Future<Result<void>> deletePurchase(int id) async {
    final repository = ref.read(purchaseRepositoryProvider);
    final res = await DeletePurchaseUsecase(repository).call(id);

    if (res.isSuccess) {
      await getPurchases();
    }

    return res;
  }
}
