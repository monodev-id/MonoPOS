import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/domain/entities/daily_revenue_entity.dart';
import 'package:mono_pos/domain/entities/ordered_product_entity.dart';
import 'package:mono_pos/domain/entities/transaction_entity.dart';

void main() {
  group('DailyRevenueEntity.fromTransactions', () {
    test('splits cash, qris, and other payment methods', () {
      var transactions = [
        _transaction(paymentMethod: 'cash', totalAmount: 50000, quantity: 2),
        _transaction(paymentMethod: 'Cash', totalAmount: 25000),
        _transaction(paymentMethod: 'qris', totalAmount: 75000, quantity: 3),
        _transaction(paymentMethod: 'bank', totalAmount: 10000),
      ];

      var result = DailyRevenueEntity.fromTransactions(
        '2026-10-26',
        transactions,
      );

      expect(result.date, '2026-10-26');
      expect(result.totalAmount, 160000);
      expect(result.transactionCount, 4);
      expect(result.totalProducts, 7);
      expect(result.cashAmount, 75000);
      expect(result.cashTransactionCount, 2);
      expect(result.qrisAmount, 75000);
      expect(result.qrisTransactionCount, 1);
      expect(result.otherAmount, 10000);
      expect(result.otherTransactionCount, 1);
    });

    test('returns zero values for an empty list', () {
      var result = DailyRevenueEntity.fromTransactions('2026-10-26', []);

      expect(result.totalAmount, 0);
      expect(result.transactionCount, 0);
      expect(result.totalProducts, 0);
      expect(result.cashAmount, 0);
      expect(result.qrisAmount, 0);
      expect(result.otherAmount, 0);
    });

    test('ignores missing ordered products', () {
      var transaction = TransactionEntity(
        paymentMethod: 'cash',
        createdById: 'user-1',
        receivedAmount: 20000,
        returnAmount: 0,
        totalAmount: 20000,
        totalOrderedProduct: 1,
      );

      var result = DailyRevenueEntity.fromTransactions(
        '2026-10-26',
        [transaction],
      );

      expect(result.totalAmount, 20000);
      expect(result.totalProducts, 0);
    });
  });

  group('DailyRevenueEntity.combine', () {
    test('sums daily summaries for the report period', () {
      var first = DailyRevenueEntity.fromTransactions('2026-10-25', [
        _transaction(paymentMethod: 'cash', totalAmount: 30000, quantity: 2),
      ]);
      var second = DailyRevenueEntity.fromTransactions('2026-10-26', [
        _transaction(paymentMethod: 'qris', totalAmount: 45000, quantity: 3),
      ]);

      var result = DailyRevenueEntity.combine([first, second]);

      expect(result.totalAmount, 75000);
      expect(result.transactionCount, 2);
      expect(result.totalProducts, 5);
      expect(result.cashAmount, 30000);
      expect(result.cashTransactionCount, 1);
      expect(result.qrisAmount, 45000);
      expect(result.qrisTransactionCount, 1);
    });
  });
}

TransactionEntity _transaction({
  required String paymentMethod,
  required int totalAmount,
  int quantity = 1,
}) {
  return TransactionEntity(
    id: 1,
    paymentMethod: paymentMethod,
    createdById: 'user-1',
    receivedAmount: totalAmount,
    returnAmount: 0,
    totalAmount: totalAmount,
    totalOrderedProduct: 1,
    orderedProducts: [
      OrderedProductEntity(
        productId: 1,
        quantity: quantity.toDouble(),
        stock: 10,
        name: 'Product',
        imageUrl: '',
        price: totalAmount,
      ),
    ],
  );
}
