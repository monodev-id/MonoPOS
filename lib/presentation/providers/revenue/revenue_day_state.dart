import '../../../domain/entities/daily_revenue_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

class RevenueDayState {
  final bool isLoading;
  final DailyRevenueEntity? summary;
  final List<TransactionEntity>? transactions;
  final String? errorMessage;

  const RevenueDayState({
    this.isLoading = false,
    this.summary,
    this.transactions,
    this.errorMessage,
  });
}
