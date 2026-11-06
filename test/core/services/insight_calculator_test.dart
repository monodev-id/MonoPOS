import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/core/services/insight/insight_calculator.dart';
import 'package:mono_pos/domain/entities/ai_insight_entity.dart';
import 'package:mono_pos/domain/entities/ordered_product_entity.dart';
import 'package:mono_pos/domain/entities/product_entity.dart';
import 'package:mono_pos/domain/entities/transaction_entity.dart';

TransactionEntity _tx({
  required int id,
  required DateTime date,
  required int total,
  String method = 'cash',
  List<OrderedProductEntity> items = const [],
}) {
  var iso = date.toIso8601String();
  return TransactionEntity(
    id: id,
    paymentMethod: method,
    createdById: 'u1',
    orderedProducts: items,
    receivedAmount: total,
    returnAmount: 0,
    totalAmount: total,
    totalOrderedProduct: items.length,
    createdAt: iso,
    paymentStatus: 'paid',
  );
}

OrderedProductEntity _item({
  required int productId,
  required String name,
  required double qty,
  required int price,
  String priceType = 'retail',
}) {
  return OrderedProductEntity(
    productId: productId,
    quantity: qty,
    stock: 100,
    name: name,
    imageUrl: '',
    price: price,
    priceType: priceType,
  );
}

ProductEntity _product({required int id, required String name, required int stock, int cost = 0, int price = 10000}) {
  return ProductEntity(
    id: id,
    createdById: 'u1',
    name: name,
    imageUrl: '',
    stock: stock,
    price: price,
    costPrice: cost,
  );
}

void main() {
  test('returns lowData insight when not enough transactions', () {
    var now = DateTime(2026, 10, 15);
    var report = InsightCalculator.calculate(
      transactions: [
        _tx(
          id: 1,
          date: DateTime(2026, 10, 14),
          total: 20000,
          items: [_item(productId: 1, name: 'A', qty: 2, price: 10000)],
        ),
      ],
      products: [_product(id: 1, name: 'A', stock: 10)],
      now: now,
    );

    expect(report.insights.length, 1);
    expect(report.insights.first.type, AiInsightType.lowData);
  });

  test('detects best seller, restock critical, and trend', () {
    var now = DateTime(2026, 10, 15);
    var transactions = <TransactionEntity>[];

    for (var i = 0; i < 10; i++) {
      transactions.add(
        _tx(
          id: i,
          date: DateTime(2026, 10, 15).subtract(Duration(days: i % 5)),
          total: 50000,
          items: [_item(productId: 1, name: 'Indomie', qty: 5, price: 10000)],
        ),
      );
    }

    var report = InsightCalculator.calculate(
      transactions: transactions,
      products: [_product(id: 1, name: 'Indomie', stock: 2, cost: 8000)],
      now: now,
    );

    expect(report.summary.transactionCount, 10);
    expect(report.insights.any((e) => e.type == AiInsightType.bestSeller), isTrue);
    expect(report.insights.any((e) => e.type == AiInsightType.restock), isTrue);
    expect(report.insights.any((e) => e.type == AiInsightType.trend), isTrue);
  });

  test('detects dead stock for products with stock but no recent sales', () {
    var now = DateTime(2026, 10, 15);
    var transactions = <TransactionEntity>[];

    for (var i = 0; i < 6; i++) {
      transactions.add(
        _tx(
          id: i,
          date: DateTime(2026, 10, 14),
          total: 10000,
          items: [_item(productId: 1, name: 'Laku', qty: 1, price: 10000)],
        ),
      );
    }

    var report = InsightCalculator.calculate(
      transactions: transactions,
      products: [
        _product(id: 1, name: 'Laku', stock: 20),
        _product(id: 2, name: 'Mati', stock: 50),
      ],
      now: now,
      periodDays: 30,
    );

    expect(report.insights.any((e) => e.type == AiInsightType.deadStock && e.productId == 2), isTrue);
  });
}
