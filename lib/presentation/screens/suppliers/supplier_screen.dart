import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../providers/suppliers/supplier_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_success_overlay.dart';
import '../../widgets/app_text_field.dart';

class SupplierScreen extends ConsumerStatefulWidget {
  const SupplierScreen({super.key});

  @override
  ConsumerState<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends ConsumerState<SupplierScreen> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supplierNotifierProvider.notifier).getAllSuppliers();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supplierNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier / Grosir'),
        titleSpacing: 0,
        actions: [
          AppButton(
            text: '+ Tambah',
            height: 30,
            fontSize: 11,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            borderRadius: BorderRadius.circular(4),
            onTap: () => context.push('/account/suppliers/create'),
          ),
          const SizedBox(width: AppSizes.padding),
        ],
      ),
      body: state.isLoading
          ? const AppProgressIndicator()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.padding,
                        AppSizes.padding,
                        AppSizes.padding,
                        0,
                      ),
                      child: AppTextField(
                        controller: searchController,
                        type: AppTextFieldType.search,
                        hintText: 'Cari nama, telepon, atau alamat...',
                        onChanged: (value) => ref.read(supplierNotifierProvider.notifier).searchSuppliers(value),
                      ),
                    ),
                    Expanded(
                      child: state.suppliers.isEmpty
                          ? AppEmptyState(
                              title: 'Belum ada supplier',
                              subtitle: 'Tambahkan grosir atau supplier langganan Anda',
                              buttonText: 'Tambah Supplier',
                              onTapButton: () => context.push('/account/suppliers/create'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSizes.padding),
                              itemCount: state.suppliers.length,
                              separatorBuilder: (_, _) => const SizedBox(height: AppSizes.padding / 2),
                              itemBuilder: (context, i) {
                                final supplier = state.suppliers[i];
                                return Container(
                                  padding: const EdgeInsets.all(AppSizes.padding),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(AppSizes.radius),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.surfaceContainer,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                        child: Icon(
                                          Icons.storefront_outlined,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(width: AppSizes.padding),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              supplier.name,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if ((supplier.phone ?? '').isNotEmpty)
                                              Text(
                                                supplier.phone!,
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            if ((supplier.address ?? '').isNotEmpty)
                                              Text(
                                                supplier.address!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.outline,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AppButton(
                                        text: 'Edit',
                                        textColor: Theme.of(context).colorScheme.primary,
                                        height: 28,
                                        fontSize: 10,
                                        borderRadius: BorderRadius.circular(4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        buttonColor: Theme.of(context).colorScheme.surfaceContainer,
                                        onTap: () => context.push('/account/suppliers/edit/${supplier.id}'),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                        onPressed: () => _confirmDelete(supplier.id!, supplier.name),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _confirmDelete(String id, String name) {
    AppDialog.show(
      title: 'Hapus Supplier',
      text: 'Yakin ingin menghapus $name?',
      rightButtonText: 'Hapus',
      leftButtonText: 'Batal',
      rightButtonColor: Theme.of(context).colorScheme.error,
      onTapRightButton: (ctx) async {
        ctx.pop();
        final res = await ref.read(supplierNotifierProvider.notifier).deleteSupplier(id);
        if (res.isSuccess) {
          AppSuccessOverlay.show('Supplier dihapus');
        } else {
          AppDialog.showError(error: res.error?.toString());
        }
      },
    );
  }
}
