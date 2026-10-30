import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/payment/dana_listener_notifier.dart';
import '../../providers/payment/payment_notifier.dart';
import '../../providers/payment/payment_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';

class QrisPaymentScreen extends ConsumerStatefulWidget {
  const QrisPaymentScreen({super.key});

  @override
  ConsumerState<QrisPaymentScreen> createState() => _QrisPaymentScreenState();
}

class _QrisPaymentScreenState extends ConsumerState<QrisPaymentScreen> {
  bool _navigated = false;
  bool _expiredDialogShown = false;

  @override
  void initState() {
    super.initState();

    // Pastikan listener aktif saat layar pembayaran dibuka (mis. setelah app
    // di-resume), tanpa memblokir render QR.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(danaListenerProvider.notifier).ensureStarted();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrisPaymentNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final listener = ref.watch(danaListenerProvider);

    ref.listen(qrisPaymentNotifierProvider.select((s) => s.paymentStatus), (previous, next) {
      if (next == 'paid' && !_navigated) {
        _navigated = true;
        final id = ref.read(qrisPaymentNotifierProvider).transaction?.id;
        if (id != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/transactions/transaction-detail/$id');
          });
        }
      }

      if (next == 'expired' && !_expiredDialogShown) {
        _expiredDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showExpiredDialog();
        });
      }
    });

    final listenerActive = listener.isPermissionGranted && listener.isServiceConnected;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showCancelDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.isDirect ? l10n.qris_directTitle : l10n.qris_title),
          titleSpacing: 0,
        ),
        body: state.transaction == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.padding * 2),
                  child: Text(
                    l10n.qris_genericError,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: Column(
                  children: [
                    _AmountHeader(state: state),
                    const SizedBox(height: AppSizes.padding * 1.5),
                    Container(
                      width: 280,
                      height: 280,
                      padding: const EdgeInsets.all(AppSizes.padding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.radius),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Center(
                        child: state.hasQr
                            ? bw.BarcodeWidget(
                                barcode: bw.Barcode.qrCode(
                                  errorCorrectLevel: bw.BarcodeQRCorrectionLevel.medium,
                                ),
                                data: state.payload,
                                width: 240,
                                height: 240,
                                color: Colors.black,
                                backgroundColor: Colors.white,
                              )
                            : const CircularProgressIndicator(),
                      ),
                    ),
                    const SizedBox(height: AppSizes.padding),
                    Text(
                      l10n.qris_scanInstruction,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.padding),
                    _CountdownChip(
                      remainingSeconds: state.remainingSeconds,
                      expired: state.isExpired,
                    ),
                    const SizedBox(height: AppSizes.padding),
                    _ListenerChip(active: listenerActive),
                    const SizedBox(height: AppSizes.padding),
                    Text(
                      state.isExpired
                          ? l10n.qris_expiredMessage
                          : state.isManualChecking
                          ? l10n.qris_checking
                          : l10n.qris_waiting,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: state.errorMessage != null ? AppColors.red : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppSizes.padding / 2),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.red,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSizes.padding * 1.5),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: l10n.qris_checkPayment,
                            enabled: !state.isManualChecking && !state.isExpired,
                            onTap: state.isExpired ? null : _onCheckPayment,
                          ),
                        ),
                        const SizedBox(width: AppSizes.padding / 2),
                        Expanded(
                          child: AppButton(
                            text: l10n.qris_printQr,
                            buttonColor: Theme.of(context).colorScheme.surface,
                            borderColor: Theme.of(context).colorScheme.outline,
                            textColor: Theme.of(context).colorScheme.onSurface,
                            enabled: state.hasQr,
                            onTap: _onPrintQr,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.padding / 2),
                    AppButton(
                      text: l10n.qris_markPaid,
                      buttonColor: Colors.green.shade600,
                      enabled: !state.isExpired,
                      onTap: _onMarkPaidManually,
                    ),
                    const SizedBox(height: AppSizes.padding / 2),
                    AppButton(
                      text: l10n.qris_cancelConfirm,
                      buttonColor: Theme.of(context).colorScheme.errorContainer,
                      textColor: Theme.of(context).colorScheme.onErrorContainer,
                      onTap: _showCancelDialog,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _onCheckPayment() async {
    await ref.read(qrisPaymentNotifierProvider.notifier).checkPaymentManually();
    if (!mounted) return;

    final state = ref.read(qrisPaymentNotifierProvider);
    if (state.isPending) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.qris_paymentNotReceived)),
      );
    }
  }

  Future<void> _onPrintQr() async {
    final state = ref.read(qrisPaymentNotifierProvider);
    if (!state.hasQr) return;

    final result = await AppDialog.showProgress(() {
      return ref
          .read(printerServiceProvider)
          .printQrCode(
            qrData: state.payload,
            totalAmount: state.expectedAmount,
            merchantName: ref.read(danaQrisPaymentServiceProvider).merchantInfo?.merchantName,
          );
    });

    if (!mounted) return;
    if (result.isFailure) {
      AppDialog.showError(error: result.error?.toString());
    }
  }

  Future<void> _onMarkPaidManually() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.qris_markPaidConfirmTitle),
        content: Text(l10n.qris_markPaidConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.qris_close),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.qris_markPaid),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(qrisPaymentNotifierProvider.notifier).markPaidManually();
  }

  void _showExpiredDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.qris_expiredTitle),
        content: Text(l10n.qris_expiredMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) context.pop();
            },
            child: Text(l10n.qris_close),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.qris_cancelTitle),
        content: Text(l10n.qris_cancelMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.home_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(qrisPaymentNotifierProvider.notifier).cancelPayment();
              if (mounted) context.pop();
            },
            child: Text(l10n.qris_cancelConfirm),
          ),
        ],
      ),
    );
  }
}

class _AmountHeader extends StatelessWidget {
  final QrisPaymentState state;

  const _AmountHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        children: [
          Text(
            l10n.qris_totalPayment,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(state.expectedAmount, decimalDigits: 0),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (state.uniqueCode > 0) ...[
            const SizedBox(height: 6),
            Text(
              '${CurrencyFormatter.format(state.totalAmount, decimalDigits: 0)} '
              '+ ${l10n.qris_uniqueCode} ${state.uniqueCode}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
          ],
        ],
      ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  final int remainingSeconds;
  final bool expired;

  const _CountdownChip({required this.remainingSeconds, required this.expired});

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding, vertical: AppSizes.padding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 18),
          const SizedBox(width: AppSizes.padding / 2),
          Text(
            expired ? '00:00' : '$minutes:$seconds',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ListenerChip extends StatelessWidget {
  final bool active;

  const _ListenerChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = active ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.notifications_active_outlined : Icons.notifications_off_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            active ? l10n.qris_listenerActive : l10n.qris_listenerInactive,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
