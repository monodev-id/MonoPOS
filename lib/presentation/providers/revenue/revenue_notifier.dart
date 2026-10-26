import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../domain/entities/daily_revenue_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/revenue_usecases.dart';
import '../auth/auth_notifier.dart';
import 'revenue_state.dart';

final revenueNotifierProvider = NotifierProvider<RevenueNotifier, RevenueState>(
  RevenueNotifier.new,
);

class RevenueNotifier extends Notifier<RevenueState> {
  @override
  RevenueState build() => const RevenueState();

  Future<void> loadRevenue({int days = 7}) async {
    state = state.copyWith(isLoading: true, periodDays: days);

    var now = DateTime.now();
    var endDate = _formatDate(now);
    var startDate = _formatDate(now.subtract(Duration(days: days - 1)));

    var authState = ref.read(authNotifierProvider);
    var userId = authState.user?.id ?? '';
    var isAdmin = authState.user?.role?.value == 'admin';
    if (userId.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        revenues: [],
        periodDays: days,
      );
      return;
    }

    var repo = ref.read(transactionRepositoryProvider);
    var res = await GetDailyRevenueUsecase(repo).call(
      GetDailyRevenueParams(
        userId: userId,
        startDate: '${startDate}T00:00:00',
        endDate: '${endDate}T23:59:59',
        paymentStatus: 'paid',
        showAllUsers: isAdmin,
      ),
    );

    if (res.isSuccess) {
      var transactions = res.data;
      if (transactions == null) {
        state = state.copyWith(
          isLoading: false,
          revenues: [],
          periodDays: days,
        );
        return;
      }

      var transactionsByDate = <String, List<TransactionEntity>>{};
      for (var transaction in transactions) {
        var date = _extractDate(transaction.createdAt ?? '');
        if (date.isEmpty) continue;

        transactionsByDate.putIfAbsent(date, () => []).add(transaction);
      }

      var dailyRevenues = <DailyRevenueEntity>[];
      for (var i = 0; i < days; i++) {
        var date = _formatDate(now.subtract(Duration(days: i)));
        dailyRevenues.add(
          DailyRevenueEntity.fromTransactions(
            date,
            transactionsByDate[date] ?? const [],
          ),
        );
      }

      dailyRevenues.sort((a, b) => b.date.compareTo(a.date));

      state = state.copyWith(
        isLoading: false,
        revenues: dailyRevenues,
        periodDays: days,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        revenues: [],
        periodDays: days,
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _extractDate(String isoDate) {
    if (isoDate.length >= 10) return isoDate.substring(0, 10);
    return '';
  }
}
