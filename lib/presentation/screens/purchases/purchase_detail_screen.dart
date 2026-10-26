import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/date_time_formatter.dart';
import '../../providers/purchases/purchase_detail_notifier.dart';
import '../../providers/purchases/purchase_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';

class PurchaseDetailScreen extends ConsumerStatefulWidget {
  final int id;

  const PurchaseDetailScreen({super.key, required this.id});

  @override
  ConsumerState<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends ConsumerState<PurchaseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseDetailNotifierProvider.notifier).getPurchaseDetail(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseDetailNotifierProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pembelian'),
        titleSpacing: 0,
        actions: [
          if (state.purchase != null)
            IconButton(
              tooltip: 'Hapus',
              onPressed: () => _confirmDelete(state.purchase!.supplierName),
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading
          ? const AppProgressIndicator()
          : state.purchase == null
          ? const AppEmptyState(title: 'Pembelian tidak ditemukan')
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
                child: ListView(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  children: [
                    Container(
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
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: scheme.primaryContainer,
                                child: Icon(Icons.storefront_outlined, size: 22, color: scheme.primary),
                              ),
                              const SizedBox(width: AppSizes.padding),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.purchase!.supplierName,
                                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      DateTimeFormatter.detailed(state.purchase!.purchaseDate),
                                      style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.padding),
                          _InfoRow(label: 'Jumlah barang', value: '${state.purchase!.totalItems} item'),
                          _InfoRow(
                            label: 'Tambah stok',
                            value: state.purchase!.addStock ? 'Ya' : 'Tidak',
                          ),
                          if ((state.purchase!.note ?? '').isNotEmpty)
                            _InfoRow(label: 'Catatan', value: state.purchase!.note!),
                          const Divider(height: AppSizes.padding * 2),
                          Row(
                            children: [
                              Text(
                                'Total Pembelian',
                                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                CurrencyFormatter.withoutSymbol(state.purchase!.totalAmount, decimalDigits: 0),
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.padding),
                    Text(
                      'Barang',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSizes.padding / 2),
                    ...state.purchase!.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: AppSizes.padding / 2),
                        padding: const EdgeInsets.all(AppSizes.padding),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(AppSizes.radius),
                          border: Border.all(color: scheme.surfaceContainer),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${item.quantity} ${item.unitName} × '
                                    '${CurrencyFormatter.withoutSymbol(item.unitPrice, decimalDigits: 0)}',
                                    style: textTheme.labelSmall?.copyWith(color: scheme.outline),
                                  ),
                                  if (item.conversionValue > 1)
                                    Text(
                                      'HPP ${CurrencyFormatter.withoutSymbol(item.baseUnitPrice, decimalDigits: 0)} / satuan dasar',
                                      style: textTheme.labelSmall?.copyWith(
                                        fontSize: 9,
                                        color: scheme.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.withoutSymbol(item.totalPrice, decimalDigits: 0),
                              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.padding),
                    AppButton(
                      text: 'Catat Pembelian Lagi',
                      buttonColor: scheme.surfaceContainer,
                      onTap: () => context.pushReplacement('/account/purchases/create'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _confirmDelete(String supplierName) {
    AppDialog.show(
      title: 'Hapus Pembelian',
      text:
          'Yakin ingin menghapus pembelian dari $supplierName? '
          'Stok dan HPP produk akan disesuaikan kembali.',
      rightButtonText: 'Hapus',
      leftButtonText: 'Batal',
      rightButtonColor: Theme.of(context).colorScheme.error,
      onTapRightButton: (ctx) async {
        ctx.pop();
        final res = await ref.read(purchaseDetailNotifierProvider.notifier).deletePurchase(widget.id);
        if (!mounted) return;

        if (res.isSuccess) {
          ref.read(purchaseNotifierProvider.notifier).getPurchases();
          context.pop();
          AppSnackBar.show('Pembelian dihapus');
        } else {
          AppDialog.showError(error: res.error?.toString());
        }
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
