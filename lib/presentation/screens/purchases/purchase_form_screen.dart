import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/date_time_formatter.dart';
import '../../providers/purchases/purchase_form_notifier.dart';
import '../../providers/purchases/purchase_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_drop_down.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_success_overlay.dart';
import '../../widgets/app_text_field.dart';
import 'components/product_picker_sheet.dart';
import 'components/purchase_item_editor.dart';

class PurchaseFormScreen extends ConsumerStatefulWidget {
  final int? initialProductId;

  const PurchaseFormScreen({super.key, this.initialProductId});

  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(purchaseFormNotifierProvider.notifier)
          .initPurchaseForm(
            initialProductId: widget.initialProductId,
          );
      if (!mounted) return;
      final state = ref.read(purchaseFormNotifierProvider);
      noteController.text = state.note;
    });
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final state = ref.read(purchaseFormNotifierProvider);
    final current = DateTime.tryParse(state.purchaseDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    ref.read(purchaseFormNotifierProvider.notifier).onChangedDate(picked);
  }

  Future<void> _addProduct() async {
    final product = await showPurchaseProductPicker(context);
    if (product == null) return;
    await ref.read(purchaseFormNotifierProvider.notifier).addProduct(product);
  }

  Future<void> _save() async {
    final notifier = ref.read(purchaseFormNotifierProvider.notifier);
    final res = await AppDialog.showProgress(notifier.createPurchase);

    if (!mounted) return;

    if (res.isSuccess) {
      ref.read(purchaseNotifierProvider.notifier).getPurchases();
      context.pushReplacement('/account/purchases/detail/${res.data}');
      AppSuccessOverlay.show('Pembelian disimpan');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  void _addSupplierDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final notifier = ref.read(purchaseFormNotifierProvider.notifier);

    AppDialog.show(
      title: 'Supplier Baru',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: nameController,
            labelText: 'Nama Supplier / Grosir',
            hintText: 'contoh: Sumber Rejeki',
          ),
          const SizedBox(height: AppSizes.padding),
          AppTextField(
            controller: phoneController,
            labelText: 'No. Telepon (opsional)',
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      leftButtonText: 'Batal',
      rightButtonText: 'Simpan',
      onTapLeftButton: (ctx) => ctx.pop(),
      onTapRightButton: (ctx) async {
        if (nameController.text.trim().isEmpty) {
          AppSnackBar.showError('Nama supplier wajib diisi');
          return;
        }

        final res = await notifier.createSupplierQuick(nameController.text, phoneController.text);
        if (!ctx.mounted) return;

        if (res.isFailure) {
          AppDialog.showError(error: res.error?.toString());
          return;
        }

        final createdId = res.data!.id;
        final supplier = ref.read(purchaseFormNotifierProvider).suppliers.where((s) => s.id == createdId).firstOrNull;

        ctx.pop();
        if (supplier != null) {
          await notifier.onChangedSupplier(supplier);
        }
        nameController.dispose();
        phoneController.dispose();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseFormNotifierProvider);
    final notifier = ref.read(purchaseFormNotifierProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Pembelian'),
        titleSpacing: 0,
      ),
      body: !state.isLoaded
          ? const AppProgressIndicator()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: AppDropDown<String>(
                              selectedValue: state.supplier?.id,
                              labelText: 'Supplier / Grosir',
                              hintText: 'Pilih supplier...',
                              dropdownItems: state.suppliers
                                  .map(
                                    (supplier) => DropdownMenuItem<String>(
                                      value: supplier.id,
                                      child: Text(supplier.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (id) {
                                final supplier = state.suppliers.where((s) => s.id == id).firstOrNull;
                                notifier.onChangedSupplier(supplier);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: AppButton(
                              text: '+ Baru',
                              height: 44,
                              fontSize: 10,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              borderRadius: BorderRadius.circular(AppSizes.radius),
                              buttonColor: AppColors.orange,
                              textColor: AppColors.white,
                              onTap: _addSupplierDialog,
                            ),
                          ),
                        ],
                      ),
                      if (state.supplier != null && (state.supplier!.phone ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          state.supplier!.phone!,
                          style: textTheme.labelSmall?.copyWith(color: scheme.outline),
                        ),
                      ],
                      const SizedBox(height: AppSizes.padding),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(AppSizes.radius),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(AppSizes.radius),
                            border: Border.all(color: scheme.primaryContainer, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tanggal Beli',
                                      style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateTimeFormatter.normal(state.purchaseDate),
                                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.calendar_month_outlined, size: 20, color: scheme.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.padding),
                      Material(
                        color: scheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radius),
                          side: BorderSide(color: scheme.surfaceContainer),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SwitchListTile.adaptive(
                          value: state.addStock,
                          onChanged: notifier.onChangedAddStock,
                          title: Text(
                            'Tambah stok otomatis',
                            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Stok produk bertambah sesuai qty pembelian',
                            style: textTheme.labelSmall?.copyWith(color: scheme.outline),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                      const SizedBox(height: AppSizes.padding),
                      AppTextField(
                        controller: noteController,
                        labelText: 'Catatan (opsional)',
                        hintText: 'contoh: nota nomor 123',
                        maxLines: 2,
                        onChanged: notifier.onChangedNote,
                      ),
                      const SizedBox(height: AppSizes.padding * 1.5),
                      Row(
                        children: [
                          Text(
                            'Barang Dibeli',
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          AppButton(
                            text: '+ Tambah Barang',
                            height: 30,
                            fontSize: 11,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            borderRadius: BorderRadius.circular(4),
                            onTap: _addProduct,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.padding),
                      if (state.items.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSizes.padding),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(AppSizes.radius),
                            border: Border.all(color: scheme.surfaceContainer),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.shopping_basket_outlined, size: 32, color: scheme.outline),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada barang. Tekan Tambah Barang.',
                                style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                              ),
                            ],
                          ),
                        )
                      else
                        ...state.items.map((item) => PurchaseItemEditor(key: ObjectKey(item), item: item)),
                      const SizedBox(height: AppSizes.padding),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.padding),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(AppSizes.radius),
                          border: Border.all(color: scheme.surfaceContainer),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('Jumlah barang', style: textTheme.bodySmall),
                                const Spacer(),
                                Text('${state.totalItems} item', style: textTheme.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Total Pembelian',
                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Text(
                                  CurrencyFormatter.withoutSymbol(state.totalAmount, decimalDigits: 0),
                                  style: textTheme.titleMedium?.copyWith(
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
                      AppButton(
                        text: 'Simpan Pembelian',
                        enabled:
                            state.supplier != null &&
                            state.items.isNotEmpty &&
                            !state.isSaving &&
                            state.items.every((item) => item.quantity > 0 && item.unitPrice > 0),
                        onTap: _save,
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
