import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../core/utilities/currency_formatter.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../providers/purchases/purchase_form_notifier.dart';
import '../../../widgets/app_text_field.dart';

Future<ProductEntity?> showPurchaseProductPicker(BuildContext context) {
  return showModalBottomSheet<ProductEntity>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return const FractionallySizedBox(
        heightFactor: 0.85,
        child: _ProductPickerSheet(),
      );
    },
  );
}

class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet();

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  final searchController = TextEditingController();
  List<ProductEntity> products = const [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => isLoading = true);
    try {
      final result = await ref
          .read(purchaseFormNotifierProvider.notifier)
          .searchProducts(query);
      if (!mounted) return;
      setState(() {
        products = result;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        products = const [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: searchController,
                    type: AppTextFieldType.search,
                    hintText: 'Cari produk / barcode...',
                    autofocus: true,
                    onChanged: _search,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                ? Center(
                    child: Text(
                      'Produk tidak ditemukan',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.padding,
                    ),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final product = products[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Stok ${product.stock} ${product.unit}'
                          '${product.barcode != null && product.barcode!.isNotEmpty ? ' • ${product.barcode}' : ''}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        trailing: Text(
                          CurrencyFormatter.withoutSymbol(
                            product.price,
                            decimalDigits: 0,
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => Navigator.of(context).pop(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
