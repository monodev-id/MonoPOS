import '../../../domain/entities/daily_revenue_entity.dart';

class RevenueState {
  final bool isLoading;
  final List<DailyRevenueEntity>? revenues;
  final int periodDays;

  const RevenueState({
    this.isLoading = false,
    this.revenues,
    this.periodDays = 7,
  });

  RevenueState copyWith({
    bool? isLoading,
    List<DailyRevenueEntity>? revenues,
    int? periodDays,
  }) {
    return RevenueState(
      isLoading: isLoading ?? this.isLoading,
      revenues: revenues ?? this.revenues,
      periodDays: periodDays ?? this.periodDays,
    );
  }
}
