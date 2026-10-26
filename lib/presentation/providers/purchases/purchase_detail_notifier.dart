import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/usecases/purchase_usecases.dart';
import 'purchase_detail_state.dart';

final purchaseDetailNotifierProvider = NotifierProvider.autoDispose<PurchaseDetailNotifier, PurchaseDetailState>(
  PurchaseDetailNotifier.new,
);

class PurchaseDetailNotifier extends AutoDisposeNotifier<PurchaseDetailState> {
  @override
  PurchaseDetailState build() {
    return const PurchaseDetailState();
  }

  Future<void> getPurchaseDetail(int id) async {
    state = state.copyWith(isLoading: true);

    final res = await GetPurchaseUsecase(ref.read(purchaseRepositoryProvider)).call(id);
    if (res.isSuccess) {
      state = PurchaseDetailState(purchase: res.data, isLoading: false);
    } else {
      state = const PurchaseDetailState(isLoading: false);
    }
  }

  Future<Result<void>> deletePurchase(int id) async {
    return DeletePurchaseUsecase(ref.read(purchaseRepositoryProvider)).call(id);
  }
}
