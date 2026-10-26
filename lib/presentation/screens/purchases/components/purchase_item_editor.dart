import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../core/utilities/date_time_formatter.dart';
import '../../../../core/utilities/rupiah_input_formatter.dart';
import '../../../providers/purchases/purchase_form_notifier.dart';
import '../../../providers/purchases/purchase_form_state.dart';
import '../../../widgets/app_drop_down.dart';
import '../../../widgets/app_text_field.dart';

class PurchaseItemEditor extends ConsumerStatefulWidget {
  final PurchaseDraftItem item;

  const PurchaseItemEditor({super.key, required this.item});

  @override
  ConsumerState<PurchaseItemEditor> createState() => _PurchaseItemEditorState();
}

class _PurchaseItemEditorState extends ConsumerState<PurchaseItemEditor> {
  late final TextEditingController quantityController;
  late final TextEditingController priceController;
  late int _lastKnownPrice;

  PurchaseDraftItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController(text: _formatQty(item.quantity));
    priceController = TextEditingController(
      text: _formatCurrency(item.unitPrice),
    );
    _lastKnownPrice = item.unitPrice;
  }

  @override
  void didUpdateWidget(covariant PurchaseItemEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (item.unitPrice != _lastKnownPrice) {
      _lastKnownPrice = item.unitPrice;
      final text = _formatCurrency(item.unitPrice);
      if (priceController.text != text) {
        priceController.text = text;
      }
    }
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  String _formatQty(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  String _formatCurrency(int value) {
    if (value <= 0) return '';
    return RupiahInputFormatter()
        .formatEditUpdate(
          const TextEditingValue(text: ''),
          TextEditingValue(text: value.toString()),
        )
        .text;
  }

  List<String> _unitNames() {
    final names = <String>[];
    for (final unit in item.product.units) {
      if (unit.unitName.isEmpty) continue;
      if (!names.contains(unit.unitName)) names.add(unit.unitName);
    }

    if (item.unitName.isNotEmpty && !names.contains(item.unitName)) {
      names.add(item.unitName);
    }

    if (names.isEmpty) names.add(item.unitName);
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(purchaseFormNotifierProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hint = item.priceHint;
    final unitNames = _unitNames();
    final selectedUnit = unitNames.contains(item.unitName)
        ? item.unitName
        : unitNames.first;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.padding),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.product.barcode != null &&
                        item.product.barcode!.isNotEmpty)
                      Text(
                        item.product.barcode!,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: scheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => notifier.removeItem(item),
                icon: Icon(Icons.close_rounded, size: 18, color: scheme.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppDropDown<String>(
            selectedValue: selectedUnit,
            labelText: 'Satuan',
            fontSize: 12,
            dropdownItems: unitNames
                .map(
                  (unitName) => DropdownMenuItem<String>(
                    value: unitName,
                    child: Text(unitName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              notifier.onChangedUnit(item, value);
              final text = _formatCurrency(item.unitPrice);
              priceController.text = text;
              _lastKnownPrice = item.unitPrice;
            },
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  controller: quantityController,
                  labelText: 'Qty',
                  hintText: '0',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) => notifier.onChangedQuantity(item, value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: priceController,
                  labelText: 'Harga Beli / ${item.unitName}',
                  hintText: '0',
                  type: AppTextFieldType.currency,
                  onChanged: (value) =>
                      notifier.onChangedUnitPrice(item, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Subtotal',
                style: textTheme.labelSmall?.copyWith(color: scheme.outline),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.withoutSymbol(
                  item.totalPrice,
                  decimalDigits: 0,
                ),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.lastFromSupplier != null
                        ? 'Harga terakhir di ${hint.supplierName ?? 'supplier ini'}: '
                              '${CurrencyFormatter.withoutSymbol(hint.unitPrice, decimalDigits: 0)} / ${hint.unitName}'
                        : 'Harga terakhir (${hint.supplierName ?? 'supplier lain'}): '
                              '${CurrencyFormatter.withoutSymbol(hint.unitPrice, decimalDigits: 0)} / ${hint.unitName}',
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
                  if ((hint.purchaseDate ?? '').isNotEmpty)
                    Text(
                      'Tanggal beli: ${DateTimeFormatter.normal(hint.purchaseDate!)}',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: scheme.outline,
                      ),
                    ),
                  if (item.supplierPrices.length > 1) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: item.supplierPrices
                          .map(
                            (price) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: scheme.surfaceContainerHighest,
                                ),
                              ),
                              child: Text(
                                '${price.supplierName ?? '-'}: '
                                '${CurrencyFormatter.withoutSymbol(price.unitPrice, decimalDigits: 0)}/${price.unitName}',
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
