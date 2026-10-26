import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/utilities/date_time_formatter.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../generated/app_localizations.dart';

class RevenueTransactionTile extends StatelessWidget {
  final TransactionEntity transaction;

  const RevenueTransactionTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var l10n = AppLocalizations.of(context)!;
    var method = transaction.paymentMethod.toLowerCase();

    var label = l10n.revenue_other;
    var color = theme.colorScheme.secondary;
    var icon = Icons.account_balance_outlined;

    if (method == 'qris') {
      label = l10n.revenue_qris;
      color = theme.colorScheme.tertiary;
      icon = Icons.qr_code_2;
    } else if (method == 'cash') {
      label = l10n.revenue_cash;
      color = theme.colorScheme.primary;
      icon = Icons.payments_outlined;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.padding / 2),
      child: Material(
        child: InkWell(
          onTap: () {
            context.push('/transactions/transaction-detail/${transaction.id}');
          },
          borderRadius: BorderRadius.circular(AppSizes.radius),
          child: Ink(
            padding: const EdgeInsets.all(AppSizes.padding / 1.5),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.radius),
              border: Border.all(
                width: 0.5,
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateTimeFormatter.onlyClockWithDivider(
                              transaction.createdAt ?? '',
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.revenue_products(transaction.totalOrderedProduct),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.padding / 2),
                Text(
                  CurrencyFormatter.withoutSymbol(
                    transaction.totalAmount,
                    decimalDigits: 0,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
