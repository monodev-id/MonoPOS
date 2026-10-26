import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/utilities/date_time_formatter.dart';
import '../../../../domain/entities/purchase_entity.dart';

class PurchaseCard extends StatelessWidget {
  final PurchaseEntity purchase;
  final VoidCallback? onDelete;

  const PurchaseCard({super.key, required this.purchase, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => context.push('/account/purchases/detail/${purchase.id}'),
      onLongPress: onDelete,
      borderRadius: BorderRadius.circular(AppSizes.radius),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius),
          border: Border.all(color: scheme.surfaceContainer),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.receipt_long_outlined, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase.supplierName,
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateTimeFormatter.detailed(purchase.purchaseDate),
                        style: textTheme.labelSmall?.copyWith(color: scheme.outline),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.withoutSymbol(purchase.totalAmount, decimalDigits: 0),
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: scheme.primary),
                    ),
                    Text(
                      '${purchase.totalItems} item',
                      style: textTheme.labelSmall?.copyWith(color: scheme.outline),
                    ),
                  ],
                ),
              ],
            ),
            if (purchase.addStock || (purchase.note ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (purchase.addStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Stok bertambah',
                        style: textTheme.labelSmall?.copyWith(fontSize: 9, color: scheme.primary),
                      ),
                    ),
                  if ((purchase.note ?? '').isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        purchase.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(fontSize: 9, color: scheme.outline),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
