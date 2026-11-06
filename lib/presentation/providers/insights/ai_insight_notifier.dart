import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../domain/usecases/insight_usecases.dart';
import '../auth/auth_notifier.dart';
import 'ai_insight_state.dart';

final aiInsightNotifierProvider = NotifierProvider<AiInsightNotifier, AiInsightState>(
  AiInsightNotifier.new,
);

class AiInsightNotifier extends Notifier<AiInsightState> {
  @override
  AiInsightState build() => const AiInsightState();

  Future<void> loadInsights({int days = 30}) async {
    state = state.copyWith(isLoading: true, periodDays: days);

    var authState = ref.read(authNotifierProvider);
    var userId = authState.user?.id ?? '';
    var isAdmin = authState.user?.role?.value == 'admin';

    if (userId.isEmpty) {
      state = state.copyWith(isLoading: false, insights: [], periodDays: days);
      return;
    }

    var res =
        await GetAiInsightsUsecase(
          ref.read(transactionRepositoryProvider),
          ref.read(productRepositoryProvider),
        ).call(
          GetAiInsightsParams(
            userId: userId,
            periodDays: days,
            showAllUsers: isAdmin,
          ),
        );

    if (res.isSuccess && res.data != null) {
      state = state.copyWith(
        isLoading: false,
        summary: res.data!.summary,
        insights: res.data!.insights,
        periodDays: days,
      );
    } else {
      state = state.copyWith(isLoading: false, insights: [], periodDays: days);
    }
  }
}
