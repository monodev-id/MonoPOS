import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../domain/entities/daily_revenue_entity.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/revenue/revenue_notifier.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import 'components/revenue_card.dart';
import 'components/revenue_summary_card.dart';

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(revenueNotifierProvider.notifier).loadRevenue();
    });
  }

  @override
  Widget build(BuildContext context) {
    var revenues = ref.watch(revenueNotifierProvider.select((s) => s.revenues));
    var isLoading = ref.watch(
      revenueNotifierProvider.select((s) => s.isLoading),
    );
    var periodDays = ref.watch(
      revenueNotifierProvider.select((s) => s.periodDays),
    );
    var l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.revenue_title),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(revenueNotifierProvider.notifier).loadRevenue(),
        displacement: 60,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.contentMaxWidth,
            ),
            child: CustomScrollView(
              physics: (revenues?.isEmpty ?? true)
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.padding,
                    AppSizes.padding,
                    AppSizes.padding,
                    AppSizes.padding,
                  ),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraint) {
                      if (isLoading && revenues == null) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          fillOverscroll: true,
                          child: AppProgressIndicator(),
                        );
                      }

                      if (revenues == null || revenues.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          fillOverscroll: true,
                          child: AppEmptyState(
                            subtitle: l10n.revenue_noData,
                          ),
                        );
                      }

                      var summary = DailyRevenueEntity.combine(revenues);

                      return SliverList.builder(
                        itemCount: revenues.length + 1,
                        itemBuilder: (context, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSizes.padding,
                              ),
                              child: RevenueSummaryCard(
                                revenue: summary,
                                periodLabel: l10n.revenue_periodLastDays(
                                  periodDays,
                                ),
                              ),
                            );
                          }

                          return RevenueCard(revenue: revenues[i - 1]);
                        },
                      );
                    },
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
