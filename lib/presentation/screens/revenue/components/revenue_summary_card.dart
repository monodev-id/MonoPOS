import 'package:flutter/material.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../domain/entities/daily_revenue_entity.dart';
import '../../../../generated/app_localizations.dart';
import 'revenue_payment_stat.dart';

class RevenueSummaryCard extends StatelessWidget {
  final DailyRevenueEntity revenue;
  final String? periodLabel;

  const RevenueSummaryCard({
    super.key,
    required this.revenue,
    this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var l10n = AppLocalizations.of(context)!;

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
                    l10n.revenue_summary,
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
              l10n.revenue_totalRevenue,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.withoutSymbol(
                revenue.totalAmount,
                decimalDigits: 0,
              ),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSizes.padding / 1.5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RevenuePaymentStat(
                    icon: Icons.payments_outlined,
                    label: l10n.revenue_cash,
                    amount: revenue.cashAmount,
                    transactionCount: revenue.cashTransactionCount,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSizes.padding / 2),
                Expanded(
                  child: RevenuePaymentStat(
                    icon: Icons.qr_code_2,
                    label: l10n.revenue_qris,
                    amount: revenue.qrisAmount,
                    transactionCount: revenue.qrisTransactionCount,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            if (revenue.otherAmount > 0) ...[
              const SizedBox(height: AppSizes.padding / 2),
              RevenuePaymentStat(
                icon: Icons.account_balance_outlined,
                label: l10n.revenue_other,
                amount: revenue.otherAmount,
                transactionCount: revenue.otherTransactionCount,
                color: theme.colorScheme.secondary,
              ),
            ],
            const SizedBox(height: AppSizes.padding / 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.revenue_transactions(revenue.transactionCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  l10n.revenue_products(revenue.totalProducts),
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
