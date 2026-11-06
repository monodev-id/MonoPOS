import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/insights/ai_insight_notifier.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import 'components/insight_card.dart';
import 'components/insight_summary_card.dart';

class AiInsightScreen extends ConsumerStatefulWidget {
  const AiInsightScreen({super.key});

  @override
  ConsumerState<AiInsightScreen> createState() => _AiInsightScreenState();
}

class _AiInsightScreenState extends ConsumerState<AiInsightScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiInsightNotifierProvider.notifier).loadInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    var state = ref.watch(aiInsightNotifierProvider);
    var l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.insight_title),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(aiInsightNotifierProvider.notifier).loadInsights(days: state.periodDays),
        displacement: 60,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.padding,
                    AppSizes.padding,
                    AppSizes.padding,
                    AppSizes.padding,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _PeriodFilter(
                        selected: state.periodDays,
                        onSelected: (days) => ref.read(aiInsightNotifierProvider.notifier).loadInsights(days: days),
                      ),
                      const SizedBox(height: AppSizes.padding),
                      if (state.isLoading && state.insights == null)
                        const AppProgressIndicator()
                      else if (state.summary == null || state.insights == null || state.insights!.isEmpty)
                        AppEmptyState(subtitle: l10n.insight_noData)
                      else ...[
                        InsightSummaryCard(
                          summary: state.summary!,
                          periodLabel: l10n.revenue_periodLastDays(
                            state.periodDays,
                          ),
                        ),
                        const SizedBox(height: AppSizes.padding),
                        for (var insight in state.insights!)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizes.padding / 1.5,
                            ),
                            child: InsightCard(insight: insight),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _PeriodFilter({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var options = const [7, 14, 30];

    return Row(
      children: [
        for (var days in options) ...[
          ChoiceChip(
            label: Text('$days h'),
            selected: selected == days,
            onSelected: (_) => onSelected(days),
            selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}
