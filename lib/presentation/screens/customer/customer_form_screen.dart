import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';

import '../../providers/customer/customer_form_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_success_overlay.dart';
import '../../widgets/app_text_field.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const CustomerFormScreen({super.key, this.id});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(customerFormNotifierProvider.notifier).initCustomerForm(widget.id);

      final state = ref.read(customerFormNotifierProvider);
      nameController.text = state.name ?? '';
      phoneController.text = state.phone ?? '';
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void createCustomer() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(customerFormNotifierProvider.notifier).createCustomer();
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.pop();
      AppSuccessOverlay.show('Pelanggan berhasil ditambahkan');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  void updateCustomer() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(customerFormNotifierProvider.notifier).updateCustomer(widget.id!);
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.pop();
      AppSuccessOverlay.show('Pelanggan berhasil diupdate');
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(customerFormNotifierProvider.notifier);
    final isLoaded = ref.watch(customerFormNotifierProvider.select((s) => s.isLoaded));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
        titleSpacing: 0,
      ),
      body: !isLoaded
          ? const AppProgressIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                children: [
                  AppTextField(
                    controller: nameController,
                    labelText: 'Nama Pelanggan',
                    hintText: 'Masukkan nama pelanggan',
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
                  const SizedBox(height: AppSizes.padding * 2),
                  AppButton(
                    text: widget.id == null ? 'Simpan Pelanggan' : 'Update Pelanggan',
                    enabled: ref.watch(
                      customerFormNotifierProvider.select(
                        (s) => (s.name?.isNotEmpty ?? false),
                      ),
                    ),
                    onTap: () {
                      if (widget.id != null) {
                        updateCustomer();
                      } else {
                        createCustomer();
                      }
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
