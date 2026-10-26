import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/common/result.dart';
import '../../../domain/entities/ordered_product_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../auth/auth_notifier.dart';
import 'direct_qris_state.dart';
import 'payment_notifier.dart';

final directQrisNotifierProvider = NotifierProvider.autoDispose<DirectQrisNotifier, DirectQrisState>(
  DirectQrisNotifier.new,
);

class DirectQrisNotifier extends AutoDisposeNotifier<DirectQrisState> {
  @override
  DirectQrisState build() {
    final service = ref.read(klikQrisPaymentServiceProvider);

    return DirectQrisState(
      isConfigured: service.isConfigured,
      isSandbox: service.isSandbox,
    );
  }

  void refreshConfig() {
    final service = ref.read(klikQrisPaymentServiceProvider);
    state = state.copyWith(
      isConfigured: service.isConfigured,
      isSandbox: service.isSandbox,
    );
  }

  void onChangedAmount(int value) {
    state = state.copyWith(amount: value);
  }

  void onChangedDescription(String value) {
    state = state.copyWith(description: value);
  }

  void onChangedCustomerName(String value) {
    state = state.copyWith(customerName: value);
  }

  Future<Result<int>> createDirectQris() async {
    if (!state.isConfigured) {
      return Result.failure(
        error: 'KlikQRIS belum dikonfigurasi. Atur API Key dan ID Merchant terlebih dahulu.',
      );
    }

    if (state.amount <= 0) {
      return Result.failure(error: 'Nominal pembayaran tidak valid.');
    }

    final authState = ref.read(authNotifierProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      return Result.failure(error: 'Unauthenticated!');
    }

    try {
      final user = authState.user!;
      final amount = state.amount;
      final description = state.description.trim();
      final customerName = state.customerName.trim();

      final transaction = TransactionEntity(
        id: DateTime.now().millisecondsSinceEpoch,
        paymentMethod: 'qris',
        paymentType: 'qris',
        customerName: customerName.isEmpty ? null : customerName,
        description: description.isEmpty ? null : description,
        orderedProducts: [
          OrderedProductEntity(
            productId: 0,
            quantity: 1,
            stock: 0,
            name: 'Transaksi Direct',
            imageUrl: '',
            price: amount,
            priceType: 'retail',
          ),
        ],
        createdById: user.id,
        createdBy: user,
        receivedAmount: amount,
        returnAmount: 0,
        totalOrderedProduct: 1,
        totalAmount: amount,
        paymentStatus: 'pending',
      );

      return ref
          .read(klikQrisPaymentNotifierProvider.notifier)
          .startKlikQrisPayment(
            transaction: transaction,
            totalAmount: amount,
            description: description.isEmpty ? null : description,
            isDirect: true,
          );
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
