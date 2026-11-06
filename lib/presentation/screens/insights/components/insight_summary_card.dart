import 'package:flutter/material.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../domain/entities/ai_insight_entity.dart';
import '../../../../generated/app_localizations.dart';

class InsightSummaryCard extends StatelessWidget {
  final AiInsightSummary summary;
  final String? periodLabel;

  const InsightSummaryCard({
    super.key,
    required this.summary,
    this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var l10n = AppLocalizations.of(context)!;
    var trend = summary.trendPercent;
    var trendUp = trend >= 0;
    var trendColor = trendUp ? Colors.green : theme.colorScheme.error;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.surfaceContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.insight_summary,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (periodLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      periodLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.padding / 2),
            Text(
              CurrencyFormatter.withoutSymbol(
                summary.totalAmount,
                decimalDigits: 0,
              ),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  trendUp ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: trendColor,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.insight_trendValue(
                    '${trendUp ? '+' : ''}${trend.toStringAsFixed(1)}%',
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.insight_avgTicket(
                      CurrencyFormatter.withoutSymbol(
                        summary.avgTicket.round(),
                        decimalDigits: 0,
                      ),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.padding / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.insight_transactionsCount(summary.transactionCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  l10n.insight_productsCount(summary.totalProducts),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
