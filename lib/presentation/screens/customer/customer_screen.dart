import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../providers/customer/customer_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_success_overlay.dart';

class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key});

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerNotifierProvider.notifier).getAllCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan'),
        titleSpacing: 0,
        actions: [
          AppButton(
            text: '+ Tambah',
            height: 30,
            fontSize: 11,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            borderRadius: BorderRadius.circular(4),
            onTap: () => context.push('/account/customers/customer-create'),
          ),
          const SizedBox(width: AppSizes.padding),
        ],
      ),
      body: state.isLoading
          ? const AppProgressIndicator()
          : state.customers.isEmpty
          ? AppEmptyState(
              title: 'Belum ada pelanggan',
              subtitle: 'Tambahkan pelanggan pertama Anda',
              buttonText: 'Tambah Pelanggan',
              onTapButton: () => context.push('/account/customers/customer-create'),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  itemCount: state.customers.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final customer = state.customers[i];

                    return ListTile(
                      title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        customer.phone ?? '-',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: SizedBox(
                        width: 60,
                        child: AppButton(
                          text: 'Edit',
                          textColor: Theme.of(context).colorScheme.primary,
                          height: 28,
                          fontSize: 10,
                          borderRadius: BorderRadius.circular(4),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          buttonColor: Theme.of(context).colorScheme.surfaceContainer,
                          onTap: () => context.push('/account/customers/customer-edit/${customer.id}'),
                        ),
                      ),
                      onLongPress: () {
                        AppDialog.show(
                          title: 'Hapus Pelanggan',
                          text: 'Yakin ingin menghapus ${customer.name}?',
                          rightButtonText: 'Hapus',
                          leftButtonText: 'Batal',
                          rightButtonColor: Theme.of(context).colorScheme.error,
                          onTapRightButton: (ctx) async {
                            ctx.pop();
                            var res = await ref.read(customerNotifierProvider.notifier).deleteCustomer(customer.id!);

                            if (res.isSuccess) {
                              AppSuccessOverlay.show('Pelanggan dihapus');
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }
}
