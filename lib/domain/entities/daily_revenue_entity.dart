import 'package:equatable/equatable.dart';

import 'transaction_entity.dart';

class DailyRevenueEntity extends Equatable {
  final String date;
  final int totalAmount;
  final int transactionCount;
  final int totalProducts;
  final int cashAmount;
  final int cashTransactionCount;
  final int qrisAmount;
  final int qrisTransactionCount;
  final int otherAmount;
  final int otherTransactionCount;

  const DailyRevenueEntity({
    required this.date,
    required this.totalAmount,
    required this.transactionCount,
    required this.totalProducts,
    this.cashAmount = 0,
    this.cashTransactionCount = 0,
    this.qrisAmount = 0,
    this.qrisTransactionCount = 0,
    this.otherAmount = 0,
    this.otherTransactionCount = 0,
  });

  /// Aggregates a list of paid transactions into a daily revenue summary.
  ///
  /// Payment methods are matched case-insensitively because transactions may
  /// come from the remote API with values such as `Cash` or `QRIS`.
  factory DailyRevenueEntity.fromTransactions(
    String date,
    List<TransactionEntity> transactions,
  ) {
    var totalAmount = 0;
    var totalProducts = 0;
    var cashAmount = 0;
    var cashTransactionCount = 0;
    var qrisAmount = 0;
    var qrisTransactionCount = 0;
    var otherAmount = 0;
    var otherTransactionCount = 0;

    for (var transaction in transactions) {
      totalAmount += transaction.totalAmount;

      var orderedProducts = transaction.orderedProducts;
      if (orderedProducts != null) {
        for (var orderedProduct in orderedProducts) {
          totalProducts += orderedProduct.quantity.round();
        }
      }

      switch (transaction.paymentMethod.toLowerCase()) {
        case 'qris':
          qrisAmount += transaction.totalAmount;
          qrisTransactionCount += 1;
          break;
        case 'cash':
          cashAmount += transaction.totalAmount;
          cashTransactionCount += 1;
          break;
        default:
          otherAmount += transaction.totalAmount;
          otherTransactionCount += 1;
      }
    }

    return DailyRevenueEntity(
      date: date,
      totalAmount: totalAmount,
      transactionCount: transactions.length,
      totalProducts: totalProducts,
      cashAmount: cashAmount,
      cashTransactionCount: cashTransactionCount,
      qrisAmount: qrisAmount,
      qrisTransactionCount: qrisTransactionCount,
      otherAmount: otherAmount,
      otherTransactionCount: otherTransactionCount,
    );
  }

  /// Combines multiple daily summaries (for example the whole report period).
  factory DailyRevenueEntity.combine(
    Iterable<DailyRevenueEntity> revenues, {
    String date = '',
  }) {
    var totalAmount = 0;
    var transactionCount = 0;
    var totalProducts = 0;
    var cashAmount = 0;
    var cashTransactionCount = 0;
    var qrisAmount = 0;
    var qrisTransactionCount = 0;
    var otherAmount = 0;
    var otherTransactionCount = 0;

    for (var revenue in revenues) {
      totalAmount += revenue.totalAmount;
      transactionCount += revenue.transactionCount;
      totalProducts += revenue.totalProducts;
      cashAmount += revenue.cashAmount;
      cashTransactionCount += revenue.cashTransactionCount;
      qrisAmount += revenue.qrisAmount;
      qrisTransactionCount += revenue.qrisTransactionCount;
      otherAmount += revenue.otherAmount;
      otherTransactionCount += revenue.otherTransactionCount;
    }

    return DailyRevenueEntity(
      date: date,
      totalAmount: totalAmount,
      transactionCount: transactionCount,
      totalProducts: totalProducts,
      cashAmount: cashAmount,
      cashTransactionCount: cashTransactionCount,
      qrisAmount: qrisAmount,
      qrisTransactionCount: qrisTransactionCount,
      otherAmount: otherAmount,
      otherTransactionCount: otherTransactionCount,
    );
  }

  @override
  List<Object> get props => [
    date,
    totalAmount,
    transactionCount,
    totalProducts,
    cashAmount,
    cashTransactionCount,
    qrisAmount,
    qrisTransactionCount,
    otherAmount,
    otherTransactionCount,
  ];
}
