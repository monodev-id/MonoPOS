import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mono_pos/generated/app_localizations.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/constants/constants.dart';
import '../../../core/extensions/string_casing_extension.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/console_logger.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/date_time_formatter.dart';
import '../../../domain/entities/ordered_product_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/transactions/transaction_detail_notifier.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_success_overlay.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final int id;

  const TransactionDetailScreen({super.key, required this.id});

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  late final Future<TransactionEntity?> _detailFuture;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = ref.read(transactionDetailNotifierProvider.notifier).getTransactionDetail(widget.id);
  }

  Future<void> _reprint(BuildContext context) async {
    if (_isPrinting) {
      cl('[Reprint] tap ignored: already printing');
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final transaction = ref.read(transactionDetailNotifierProvider);
    cl('[Reprint] tap: transaction=${transaction == null ? 'NULL' : 'id=${transaction.id}'}');

    if (transaction == null) {
      AppSnackBar.showError(l10n.transaction_notFound);
      return;
    }

    final printerService = ref.read(printerServiceProvider);
    cl(
      '[Reprint] printer: selected=${printerService.selectedPrinter?.name ?? 'NULL'} '
      'isConnected=${printerService.isConnected} state=${printerService.connectionState}',
    );

    if (!printerService.isConnected || printerService.selectedPrinter == null) {
      AppDialog.show(
        title: l10n.transaction_reprint,
        text: l10n.product_labelNeedPrinter,
        leftButtonText: l10n.home_cancel,
        rightButtonText: l10n.product_labelGoPrinter,
        onTapRightButton: (ctx) {
          ctx.pop();
          context.go('/account/printer-settings');
        },
      );
      return;
    }

    setState(() => _isPrinting = true);

    try {
      final result = await AppDialog.showProgress(() => printerService.printTransaction(transaction));

      if (!mounted) return;

      cl('[Reprint] print result: isFailure=${result.isFailure} error=${result.error}');

      if (result.isFailure) {
        AppSnackBar.showError(result.error.toString());
      } else {
        AppSuccessOverlay.show(l10n.transaction_printed);
      }
    } catch (e) {
      ce('[Reprint] print exception: $e');
      AppSnackBar.showError(e.toString());
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = ref.watch(transactionDetailNotifierProvider);
    final canPrint = !_isPrinting && transaction != null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          IconButton(
            icon: _isPrinting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
            tooltip: AppLocalizations.of(context)!.transaction_reprint,
            onPressed: canPrint ? () => _reprint(context) : null,
          ),
        ],
      ),
      body: FutureBuilder<TransactionEntity?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppProgressIndicator();
          }

          if (snapshot.hasError) {
            throw snapshot.error.toString();
          }

          if (snapshot.data == null) {
            return AppEmptyState(title: AppLocalizations.of(context)!.transaction_notFound);
          }

          final transaction = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
                child: Column(
                  children: [
                    const _StatusSection(),
                    const SizedBox(height: AppSizes.padding * 2),
                    const _StoreInfoSection(),
                    const SizedBox(height: AppSizes.padding),
                    _TransactionDetail(transaction: transaction),
                    const SizedBox(height: AppSizes.padding),
                    _PaymentDetail(transaction: transaction),
                    const SizedBox(height: AppSizes.padding),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: AppColors.green,
          size: 60,
        ),
        const SizedBox(height: AppSizes.padding / 2),
        Text(
          AppLocalizations.of(context)!.transaction_created,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StoreInfoSection extends ConsumerWidget {
  const _StoreInfoSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.read(sharedPreferencesProvider);
    final storeName = prefs.getString(Constants.storeNameKey) ?? '';
    final storeAddress = prefs.getString(Constants.storeAddressKey) ?? '';
    final receiptFooter = prefs.getString(Constants.receiptFooterKey) ?? '';

    if (storeName.isEmpty && storeAddress.isEmpty && receiptFooter.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        children: [
          if (storeName.isNotEmpty)
            Text(
              storeName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          if (storeAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                storeAddress,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (receiptFooter.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.padding),
              child: Text(
                receiptFooter,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionDetail extends StatelessWidget {
  final TransactionEntity transaction;

  const _TransactionDetail({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.transaction_id,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${transaction.id ?? '-'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.transaction_paymentMethod,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                transaction.paymentMethod.toTitleCase(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.transaction_createdBy,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                transaction.createdBy?.name ?? '-',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.transaction_createdAt,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                DateTimeFormatter.normalWithClock(transaction.createdAt ?? ''),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.transaction_customerName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                transaction.customerName ?? '-',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.transaction_description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                transaction.description ?? '-',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  final TransactionEntity transaction;

  const _PaymentDetail({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.transaction_orderedProducts,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${transaction.orderedProducts?.length ?? '0'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: AppSizes.padding * 2),
          ...List.generate(transaction.orderedProducts?.length ?? 0, (i) {
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : AppSizes.padding / 2),
              child: _ProductItem(order: transaction.orderedProducts![i]),
            );
          }),
          const Divider(height: AppSizes.padding * 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.transaction_total,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyFormatter.withoutSymbol(transaction.totalAmount, decimalDigits: 0),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.transaction_paymentReceived,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                CurrencyFormatter.withoutSymbol(transaction.receivedAmount, decimalDigits: 0),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.transaction_change,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                CurrencyFormatter.withoutSymbol(transaction.receivedAmount - transaction.totalAmount, decimalDigits: 0),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductItem extends StatelessWidget {
  final OrderedProductEntity order;

  const _ProductItem({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: order.priceType == 'grosir'
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                order.priceType == 'grosir'
                    ? AppLocalizations.of(context)!.home_grosir
                    : AppLocalizations.of(context)!.home_retail,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.padding / 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${CurrencyFormatter.withoutSymbol(order.price, decimalDigits: 0)} x ${order.quantity == order.quantity.roundToDouble() ? order.quantity.toInt().toString() : order.quantity.toStringAsFixed(1)} ${order.unit}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              CurrencyFormatter.withoutSymbol((order.price) * order.quantity, decimalDigits: 0),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
