import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../providers/suppliers/supplier_form_notifier.dart';
import '../../providers/suppliers/supplier_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';

class SupplierFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const SupplierFormScreen({super.key, this.id});

  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(supplierFormNotifierProvider.notifier).initSupplierForm(widget.id);
      if (!mounted) return;

      final state = ref.read(supplierFormNotifierProvider);
      nameController.text = state.name;
      phoneController.text = state.phone ?? '';
      addressController.text = state.address ?? '';
      noteController.text = state.note ?? '';
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(supplierFormNotifierProvider.notifier);
    final res = await AppDialog.showProgress(() {
      return widget.id == null ? notifier.createSupplier() : notifier.updateSupplier();
    });

    if (!mounted) return;

    if (res.isSuccess) {
      ref.read(supplierNotifierProvider.notifier).getAllSuppliers();
      context.pop();
      AppSnackBar.show(widget.id == null ? 'Supplier ditambahkan' : 'Supplier diperbarui');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(supplierFormNotifierProvider.notifier);
    final isLoaded = ref.watch(supplierFormNotifierProvider.select((s) => s.isLoaded));
    final canSave = ref.watch(supplierFormNotifierProvider.select((s) => s.name.trim().isNotEmpty && !s.isSaving));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Tambah Supplier' : 'Edit Supplier'),
        titleSpacing: 0,
      ),
      body: !isLoaded
          ? const AppProgressIndicator()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: nameController,
                        labelText: 'Nama Supplier / Grosir',
                        hintText: 'contoh: Sumber Rejeki',
                        onChanged: notifier.onChangedName,
                      ),
                      const SizedBox(height: AppSizes.padding),
                      AppTextField(
                        controller: phoneController,
                        labelText: 'No. Telepon (opsional)',
                        hintText: 'contoh: 0812xxxxxx',
                        keyboardType: TextInputType.phone,
                        onChanged: notifier.onChangedPhone,
                      ),
                      const SizedBox(height: AppSizes.padding),
                      AppTextField(
                        controller: addressController,
                        labelText: 'Alamat (opsional)',
                        hintText: 'Alamat supplier...',
                        maxLines: 2,
                        onChanged: notifier.onChangedAddress,
                      ),
                      const SizedBox(height: AppSizes.padding),
                      AppTextField(
                        controller: noteController,
                        labelText: 'Catatan (opsional)',
                        hintText: 'contoh: langganan mingguan',
                        maxLines: 2,
                        onChanged: notifier.onChangedNote,
                      ),
                      const SizedBox(height: AppSizes.padding * 2),
                      AppButton(
                        text: widget.id == null ? 'Simpan Supplier' : 'Update Supplier',
                        enabled: canSave,
                        onTap: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
