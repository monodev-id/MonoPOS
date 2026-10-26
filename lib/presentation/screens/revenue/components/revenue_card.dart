import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../domain/entities/daily_revenue_entity.dart';
import '../../../../generated/app_localizations.dart';
import 'revenue_payment_stat.dart';

class RevenueCard extends StatelessWidget {
  final DailyRevenueEntity revenue;

  const RevenueCard({super.key, required this.revenue});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var l10n = AppLocalizations.of(context)!;
    var locale = Localizations.localeOf(context);
    var parsedDate = DateTime.tryParse(revenue.date);
    var formattedDate = parsedDate != null
        ? DateFormat(
            'EEEE, d MMMM y',
            locale.toLanguageTag(),
          ).format(parsedDate)
        : revenue.date;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.padding),
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.surfaceContainer),
        ),
        child: InkWell(
          onTap: () {
            context.push('/account/revenue/day/${revenue.date}');
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
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
                const SizedBox(height: AppSizes.padding / 1.5),
                Divider(
                  height: 1,
                  color: theme.colorScheme.surfaceContainer,
                ),
                const SizedBox(height: AppSizes.padding / 1.5),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
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
        ),
      ),
    );
  }
}
