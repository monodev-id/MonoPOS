import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../domain/entities/daily_revenue_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/usecases/revenue_usecases.dart';
import '../auth/auth_notifier.dart';
import 'revenue_day_state.dart';

final revenueDayNotifierProvider = NotifierProvider.autoDispose<RevenueDayNotifier, RevenueDayState>(
  RevenueDayNotifier.new,
);

class RevenueDayNotifier extends AutoDisposeNotifier<RevenueDayState> {
  @override
  RevenueDayState build() => const RevenueDayState();

  Future<void> loadDay(String date) async {
    state = RevenueDayState(
      isLoading: true,
      summary: state.summary,
      transactions: state.transactions,
    );

    var authState = ref.read(authNotifierProvider);
    var userId = authState.user?.id ?? '';
    var isAdmin = authState.user?.role?.value == 'admin';
    if (userId.isEmpty) {
      state = const RevenueDayState(transactions: []);
      return;
    }

    var repo = ref.read(transactionRepositoryProvider);
    var res = await GetDailyRevenueUsecase(repo).call(
      GetDailyRevenueParams(
        userId: userId,
        startDate: '${date}T00:00:00',
        endDate: '${date}T23:59:59',
        paymentStatus: 'paid',
        showAllUsers: isAdmin,
      ),
    );

    if (res.isSuccess) {
      var transactions = [...(res.data ?? <TransactionEntity>[])];
      transactions.sort(
        (a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''),
      );

      state = RevenueDayState(
        summary: DailyRevenueEntity.fromTransactions(date, transactions),
        transactions: transactions,
      );
    } else {
      state = RevenueDayState(
        transactions: const [],
        errorMessage: res.error?.toString(),
      );
    }
  }
}
