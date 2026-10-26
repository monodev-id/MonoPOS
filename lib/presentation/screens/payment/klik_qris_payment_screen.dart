import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/console_logger.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/external_launcher.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/payment/payment_notifier.dart';
import '../../providers/payment/payment_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_progress_indicator.dart';

class KlikQrisPaymentScreen extends ConsumerStatefulWidget {
  const KlikQrisPaymentScreen({super.key});

  @override
  ConsumerState<KlikQrisPaymentScreen> createState() => _KlikQrisPaymentScreenState();
}

class _KlikQrisPaymentScreenState extends ConsumerState<KlikQrisPaymentScreen> {
  late final KlikQrisPaymentNotifier _notifier;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(klikQrisPaymentNotifierProvider.notifier);
  }

  @override
  void dispose() {
    super.dispose();
    Future(() => _notifier.reset());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(klikQrisPaymentNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    if (state.isPaid && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/transactions/transaction-detail/${state.transaction?.id}');
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBackPressed(state);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(state.isDirect ? l10n.qris_directTitle : l10n.qris_title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _onBackPressed(state),
          ),
        ),
        body: state.isPolling ? const Center(child: AppProgressIndicator()) : _buildContent(state),
      ),
    );
  }

  void _onBackPressed(KlikQrisPaymentState state) {
    if (state.isExpired) {
      _notifier.reset();
      context.pop();
      return;
    }

    _showCancelDialog();
  }

  Widget _buildContent(KlikQrisPaymentState state) {
    if (state.isExpired) {
      return _StatusView(
        icon: Icons.timer_off_outlined,
        iconColor: AppColors.red,
        title: AppLocalizations.of(context)!.qris_expiredTitle,
        message: AppLocalizations.of(context)!.qris_expiredMessage,
        primaryButtonText: AppLocalizations.of(context)!.qris_createNew,
        onTapPrimary: () {
          _notifier.reset();
          context.pop();
        },
        secondaryButtonText: AppLocalizations.of(context)!.qris_close,
        onTapSecondary: () {
          _notifier.reset();
          context.pop();
        },
      );
    }

    if (state.errorMessage != null && state.qrCode.isEmpty) {
      return _StatusView(
        icon: Icons.error_outline,
        iconColor: AppColors.red,
        title: AppLocalizations.of(context)!.qris_failedTitle,
        message: state.errorMessage!,
        primaryButtonText: AppLocalizations.of(context)!.qris_close,
        onTapPrimary: () {
          _notifier.reset();
          context.pop();
        },
      );
    }

    if (state.paymentStatus == 'failed') {
      return _StatusView(
        icon: Icons.cancel_outlined,
        iconColor: AppColors.red,
        title: AppLocalizations.of(context)!.qris_failedTitle,
        message: state.errorMessage ?? AppLocalizations.of(context)!.qris_genericError,
        primaryButtonText: AppLocalizations.of(context)!.qris_close,
        onTapPrimary: () {
          _notifier.reset();
          context.pop();
        },
      );
    }

    return _buildPaymentContent(state);
  }

  Widget _buildPaymentContent(KlikQrisPaymentState state) {
    final l10n = AppLocalizations.of(context)!;
    final minutes = (state.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (state.elapsedSeconds % 60).toString().padLeft(2, '0');

    final paidAmount = state.totalAmount > 0 ? state.totalAmount : state.transaction?.totalAmount ?? 0;
    final baseAmount = state.transaction?.totalAmount ?? paidAmount;
    final uniqueCode = paidAmount - baseAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Center(
        child: SizedBox(
          width: 420,
          child: Column(
            children: [
              const SizedBox(height: AppSizes.padding),
              Text(
                l10n.qris_totalPayment,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.padding / 2),
              Text(
                CurrencyFormatter.withoutSymbol(paidAmount, decimalDigits: 0),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (uniqueCode > 0) ...[
                const SizedBox(height: AppSizes.padding / 2),
                _AmountBreakdown(
                  baseAmount: baseAmount,
                  uniqueCode: uniqueCode,
                  totalAmount: paidAmount,
                ),
              ],
              const SizedBox(height: AppSizes.padding * 2),
              Container(
                width: 260,
                height: 260,
                padding: const EdgeInsets.all(AppSizes.padding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Center(
                  child: state.qrCode.isNotEmpty ? _buildQrDisplay(state.qrCode) : const AppProgressIndicator(),
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
              const SizedBox(height: AppSizes.padding * 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.padding,
                  vertical: AppSizes.padding / 2,
                ),
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
                      '$minutes:$seconds',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.padding),
              Text(
                state.autoCheckDone ? l10n.qris_checkInstruction : l10n.qris_waiting,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              if (state.autoCheckDone) ...[
                const SizedBox(height: AppSizes.padding * 2),
                AppButton(
                  text: state.isManualChecking ? l10n.qris_checking : l10n.qris_checkPayment,
                  enabled: !state.isManualChecking,
                  onTap: () {
                    _notifier.checkPaymentManually();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrDisplay(String qrData) {
    if (qrData.startsWith('http://') || qrData.startsWith('https://')) {
      cl('[KlikQRIS] QR display: network URL len=${qrData.length}');
      return Image.network(
        qrData,
        width: 220,
        height: 220,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          cl('[KlikQRIS] QR display: network error $error');
          return _FallbackQrDisplay(qrData: qrData);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const AppProgressIndicator();
        },
      );
    }

    if (qrData.startsWith('data:image')) {
      cl('[KlikQRIS] QR display: base64 len=${qrData.length}');
      return _Base64QrDisplay(base64Data: qrData);
    }

    cl('[KlikQRIS] QR display: fallback (prefix="${qrData.length > 12 ? qrData.substring(0, 12) : qrData}")');
    return _FallbackQrDisplay(qrData: qrData);
  }

  void _showCancelDialog() {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
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
            onPressed: () {
              Navigator.of(ctx).pop();
              _notifier.cancelPolling();
              context.pop();
            },
            child: Text(l10n.qris_cancelConfirm),
          ),
        ],
      ),
    );
  }
}

class _AmountBreakdown extends StatelessWidget {
  final int baseAmount;
  final int uniqueCode;
  final int totalAmount;

  const _AmountBreakdown({
    required this.baseAmount,
    required this.uniqueCode,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.padding,
        vertical: AppSizes.padding / 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        children: [
          _row(
            context,
            l10n.qris_nominal,
            CurrencyFormatter.withoutSymbol(baseAmount, decimalDigits: 0),
            textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          _row(
            context,
            l10n.qris_uniqueCode,
            '+ ${CurrencyFormatter.withoutSymbol(uniqueCode, decimalDigits: 0)}',
            textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const Divider(height: 12),
          _row(
            context,
            l10n.qris_totalPayment,
            CurrencyFormatter.withoutSymbol(totalAmount, decimalDigits: 0),
            textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, TextStyle? style) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryButtonText;
  final VoidCallback onTapPrimary;
  final String? secondaryButtonText;
  final VoidCallback? onTapSecondary;

  const _StatusView({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryButtonText,
    required this.onTapPrimary,
    this.secondaryButtonText,
    this.onTapSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: iconColor),
              const SizedBox(height: AppSizes.padding),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.padding / 2),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.padding * 2),
              AppButton(
                text: primaryButtonText,
                onTap: onTapPrimary,
              ),
              if (secondaryButtonText != null) ...[
                const SizedBox(height: AppSizes.padding / 2),
                AppButton(
                  text: secondaryButtonText!,
                  buttonColor: Theme.of(context).colorScheme.surface,
                  borderColor: Theme.of(context).colorScheme.primary,
                  textColor: Theme.of(context).colorScheme.primary,
                  onTap: onTapSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackQrDisplay extends StatelessWidget {
  final String qrData;

  const _FallbackQrDisplay({required this.qrData});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUrl = qrData.startsWith('http://') || qrData.startsWith('https://');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.qr_code_2, size: 80, color: Colors.black54),
        const SizedBox(height: AppSizes.padding / 2),
        Text(
          l10n.qris_codeAvailable,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black54,
          ),
        ),
        if (isUrl) ...[
          const SizedBox(height: AppSizes.padding / 2),
          TextButton(
            onPressed: () => ExternalLauncher.openUrl(qrData),
            child: Text(l10n.qris_openImage),
          ),
        ],
      ],
    );
  }
}

class _Base64QrDisplay extends StatelessWidget {
  final String base64Data;

  const _Base64QrDisplay({required this.base64Data});

  @override
  Widget build(BuildContext context) {
    try {
      final dataUri = Uri.tryParse(base64Data)?.data;
      final bytes = dataUri?.contentAsBytes();

      if (bytes == null || bytes.isEmpty) {
        cl('[KlikQRIS] QR display: base64 decode returned empty');
        return const _FallbackQrDisplay(qrData: '');
      }

      cl('[KlikQRIS] QR display: base64 decoded ${bytes.length} bytes');
      return Image.memory(
        bytes,
        width: 220,
        height: 220,
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return const AppProgressIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          cl('[KlikQRIS] QR display: image decode error $error');
          return const _FallbackQrDisplay(qrData: '');
        },
      );
    } catch (e) {
      cl('[KlikQRIS] QR display: base64 decode exception $e');
      return const _FallbackQrDisplay(qrData: '');
    }
  }
}
