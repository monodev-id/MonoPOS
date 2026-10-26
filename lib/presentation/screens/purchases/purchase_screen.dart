import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../providers/purchases/purchase_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_success_overlay.dart';
import '../../widgets/app_text_field.dart';
import 'components/purchase_card.dart';

class PurchaseScreen extends ConsumerStatefulWidget {
  const PurchaseScreen({super.key});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseNotifierProvider.notifier).getPurchases(resetMonth: true);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembelian'),
        titleSpacing: 0,
        actions: [
          IconButton(
            tooltip: 'Supplier',
            onPressed: () => context.push('/account/suppliers'),
            icon: const Icon(Icons.storefront_outlined),
          ),
          AppButton(
            text: '+ Catat',
            height: 30,
            fontSize: 11,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            borderRadius: BorderRadius.circular(4),
            onTap: () => context.push('/account/purchases/create'),
          ),
          const SizedBox(width: AppSizes.padding),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: AppTextField(
                  controller: searchController,
                  type: AppTextFieldType.search,
                  hintText: 'Cari supplier, tanggal, atau catatan...',
                  onChanged: (value) => ref.read(purchaseNotifierProvider.notifier).getPurchases(query: value),
                ),
              ),
              Expanded(
                child: state.isLoading
                    ? const AppProgressIndicator()
                    : state.purchases.isEmpty
                    ? AppEmptyState(
                        title: 'Belum ada pembelian',
                        subtitle: 'Catat pembelian dari grosir atau supplier',
                        buttonText: 'Catat Pembelian',
                        onTapButton: () => context.push('/account/purchases/create'),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(purchaseNotifierProvider.notifier).getPurchases(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.padding,
                            0,
                            AppSizes.padding,
                            AppSizes.padding,
                          ),
                          itemCount: state.purchases.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSizes.padding / 2),
                          itemBuilder: (context, i) {
                            final purchase = state.purchases[i];
                            return PurchaseCard(
                              purchase: purchase,
                              onDelete: () => _confirmDelete(purchase.id!, purchase.supplierName),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int id, String supplierName) {
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
        final res = await ref.read(purchaseNotifierProvider.notifier).deletePurchase(id);
        if (res.isSuccess) {
          AppSuccessOverlay.show('Pembelian dihapus');
        } else {
          AppDialog.showError(error: res.error?.toString());
        }
      },
    );
  }
}
