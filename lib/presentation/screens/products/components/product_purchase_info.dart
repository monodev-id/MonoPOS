import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/utilities/date_time_formatter.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../providers/auth/auth_notifier.dart';
import '../../../providers/products/product_purchase_info_notifier.dart';
import '../../../widgets/app_button.dart';

class ProductPurchaseInfo extends ConsumerStatefulWidget {
  final ProductEntity product;

  const ProductPurchaseInfo({super.key, required this.product});

  @override
  ConsumerState<ProductPurchaseInfo> createState() => _ProductPurchaseInfoState();
}

class _ProductPurchaseInfoState extends ConsumerState<ProductPurchaseInfo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.product.id != null) {
        ref.read(productPurchaseInfoNotifierProvider.notifier).load(widget.product.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));
    if (!isAdmin) return const SizedBox.shrink();

    final state = ref.watch(productPurchaseInfoNotifierProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final baseUnit = widget.product.units.where((u) => u.isBase).firstOrNull?.unitName ?? widget.product.unit;
    final displayCostPrice = state.isLoading ? widget.product.costPrice : state.costPrice;

    return Container(
      margin: const EdgeInsets.only(top: AppSizes.padding),
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius + 4),
        border: Border.all(color: scheme.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.price_check_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Harga Beli',
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              AppButton(
                text: '+ Catat Pembelian',
                height: 26,
                fontSize: 9,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                borderRadius: BorderRadius.circular(4),
                buttonColor: scheme.surfaceContainer,
                onTap: () async {
                  await context.push('/account/purchases/create?productId=${widget.product.id}');
                  if (!mounted) return;
                  ref.read(productPurchaseInfoNotifierProvider.notifier).load(widget.product.id!);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'HPP / $baseUnit',
                  value: CurrencyFormatter.withoutSymbol(displayCostPrice, decimalDigits: 0),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Estimasi untung',
                  value: CurrencyFormatter.withoutSymbol(
                    widget.product.price - displayCostPrice,
                    decimalDigits: 0,
                  ),
                ),
              ),
            ],
          ),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (!state.hasData)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Belum ada pembelian tercatat untuk produk ini.',
                style: textTheme.labelSmall?.copyWith(color: scheme.outline),
              ),
            )
          else ...[
            if (state.lastPurchase != null) ...[
              const Divider(height: AppSizes.padding * 2),
              Text(
                'Pembelian terakhir',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${CurrencyFormatter.withoutSymbol(state.lastPurchase!.unitPrice, decimalDigits: 0)} / '
                '${state.lastPurchase!.unitName}'
                ' • ${state.lastPurchase!.supplierName ?? '-'}',
                style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                DateTimeFormatter.normal(state.lastPurchase!.purchaseDate ?? ''),
                style: textTheme.labelSmall?.copyWith(color: scheme.outline),
              ),
            ],
            if (state.supplierPrices.length > 1) ...[
              const SizedBox(height: 12),
              Text(
                'Harga terakhir per supplier',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              ...state.supplierPrices.map(
                (price) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          price.supplierName ?? '-',
                          style: textTheme.labelSmall,
                        ),
                      ),
                      Text(
                        '${CurrencyFormatter.withoutSymbol(price.unitPrice, decimalDigits: 0)} / ${price.unitName}',
                        style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (state.history.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Riwayat pembelian',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              ...state.history.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${DateTimeFormatter.slashDate(item.purchaseDate ?? '')} • ${item.supplierName ?? '-'}',
                          style: textTheme.labelSmall,
                        ),
                      ),
                      Text(
                        '${item.quantity} ${item.unitName} × '
                        '${CurrencyFormatter.withoutSymbol(item.unitPrice, decimalDigits: 0)}',
                        style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
