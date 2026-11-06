import '../../core/services/insight/insight_calculator.dart';
import '../../core/common/result.dart';
import '../../core/usecase/usecase.dart';
import '../entities/ai_insight_entity.dart';
import '../repositories/product_repository.dart';
import '../repositories/transaction_repository.dart';

class GetAiInsightsUsecase extends Usecase<Result<AiInsightReport>, GetAiInsightsParams> {
  GetAiInsightsUsecase(this._transactionRepository, this._productRepository);

  final TransactionRepository _transactionRepository;
  final ProductRepository _productRepository;

  @override
  Future<Result<AiInsightReport>> call(GetAiInsightsParams params) async {
    var now = DateTime.now();
    var endDate = _formatEnd(now);
    var startDate = _formatStart(now.subtract(Duration(days: params.periodDays * 2 - 1)));

    var txRes = await _transactionRepository.getTransactionsByDateRange(
      params.userId,
      startDate: startDate,
      endDate: endDate,
      paymentStatus: 'paid',
      showAllUsers: params.showAllUsers,
    );

    if (txRes.isFailure) {
      return Result.failure(error: txRes.error ?? 'Failed to load transactions');
    }

    var productRes = await _productRepository.getUserProducts(
      params.userId,
      limit: 2000,
    );

    if (productRes.isFailure) {
      return Result.failure(error: productRes.error ?? 'Failed to load products');
    }

    var transactions = txRes.data ?? const [];
    var products = productRes.data ?? const [];

    var report = InsightCalculator.calculate(
      transactions: transactions,
      products: products,
      now: now,
      periodDays: params.periodDays,
    );

    return Result.success(data: report);
  }

  String _formatStart(DateTime date) {
    return '${_date(date)}T00:00:00';
  }

  String _formatEnd(DateTime date) {
    return '${_date(date)}T23:59:59';
  }

  String _date(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class GetAiInsightsParams {
  final String userId;
  final int periodDays;
  final bool showAllUsers;

  const GetAiInsightsParams({
    required this.userId,
    this.periodDays = 30,
    this.showAllUsers = false,
  });
}
