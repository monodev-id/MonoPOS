import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/revenue/revenue_day_notifier.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import 'components/revenue_summary_card.dart';
import 'components/revenue_transaction_tile.dart';

class RevenueDayScreen extends ConsumerStatefulWidget {
  final String date;

  const RevenueDayScreen({
    super.key,
    required this.date,
  });

  @override
  ConsumerState<RevenueDayScreen> createState() => _RevenueDayScreenState();
}

class _RevenueDayScreenState extends ConsumerState<RevenueDayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(revenueDayNotifierProvider.notifier).loadDay(widget.date);
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var l10n = AppLocalizations.of(context)!;
    var summary = ref.watch(
      revenueDayNotifierProvider.select((s) => s.summary),
    );
    var transactions = ref.watch(
      revenueDayNotifierProvider.select((s) => s.transactions),
    );
    var isLoading = ref.watch(
      revenueDayNotifierProvider.select((s) => s.isLoading),
    );

    var locale = Localizations.localeOf(context);
    var parsedDate = DateTime.tryParse(widget.date);
    var formattedDate = parsedDate != null
        ? DateFormat(
            'EEEE, d MMMM y',
            locale.toLanguageTag(),
          ).format(parsedDate)
        : widget.date;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.revenue_dayDetailTitle),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(revenueDayNotifierProvider.notifier).loadDay(widget.date),
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
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (summary != null) ...[
                          const SizedBox(height: AppSizes.padding),
                          RevenueSummaryCard(revenue: summary),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isLoading && transactions == null)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: true,
                    child: AppProgressIndicator(),
                  )
                else if (transactions == null || transactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: true,
                    child: AppEmptyState(
                      subtitle: l10n.revenue_dayNoTransactions,
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.padding,
                      AppSizes.padding,
                      AppSizes.padding,
                      AppSizes.padding / 2,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        l10n.revenue_transactionsTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.padding,
                      0,
                      AppSizes.padding,
                      AppSizes.padding,
                    ),
                    sliver: SliverList.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, i) {
                        return RevenueTransactionTile(
                          transaction: transactions[i],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
