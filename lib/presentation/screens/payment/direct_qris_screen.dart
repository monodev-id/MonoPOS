import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/auth/auth_notifier.dart';
import '../../providers/payment/direct_qris_notifier.dart';
import '../../providers/payment/direct_qris_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_text_field.dart';

class DirectQrisScreen extends ConsumerStatefulWidget {
  const DirectQrisScreen({super.key});

  @override
  ConsumerState<DirectQrisScreen> createState() => _DirectQrisScreenState();
}

class _DirectQrisScreenState extends ConsumerState<DirectQrisScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  void _setAmount(int amount) {
    _amountController.text = CurrencyFormatter.withoutSymbol(amount, decimalDigits: 0);
    ref.read(directQrisNotifierProvider.notifier).onChangedAmount(amount);
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();

    final notifier = ref.read(directQrisNotifierProvider.notifier);
    final result = await AppDialog.showProgress(() => notifier.createDirectQris());

    if (!mounted) return;

    if (result.isSuccess) {
      await context.push('/payment/qris');
      if (!mounted) return;
      ref.read(directQrisNotifierProvider.notifier).refreshConfig();
      return;
    }

    await AppDialog.showError(error: result.error?.toString());
  }

  Future<void> _openPaymentSettings() async {
    await context.push('/account/payment-settings');
    if (!mounted) return;
    ref.read(directQrisNotifierProvider.notifier).refreshConfig();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(directQrisNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.directQris_title),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(state: state),
                const SizedBox(height: AppSizes.padding),
                if (!state.isConfigured) ...[
                  _NotConfiguredBanner(
                    isAdmin: isAdmin,
                    onOpenSettings: _openPaymentSettings,
                  ),
                  const SizedBox(height: AppSizes.padding),
                ],
                AppTextField(
                  autofocus: true,
                  controller: _amountController,
                  labelText: l10n.directQris_amountLabel,
                  hintText: l10n.directQris_amountHint,
                  type: AppTextFieldType.currency,
                  fontSize: 20,
                  onChanged: (value) {
                    final clean = value.replaceAll('.', '');
                    ref.read(directQrisNotifierProvider.notifier).onChangedAmount(int.tryParse(clean) ?? 0);
                  },
                ),
                const SizedBox(height: AppSizes.padding / 2),
                Wrap(
                  spacing: AppSizes.padding / 2,
                  runSpacing: AppSizes.padding / 2,
                  children: [
                    for (final amount in const [10000, 25000, 50000, 100000])
                      _QuickAmountButton(
                        amount: amount,
                        selected: state.amount == amount,
                        onTap: () => _setAmount(amount),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.padding),
                AppTextField(
                  controller: _descriptionController,
                  labelText: l10n.directQris_descriptionLabel,
                  hintText: l10n.directQris_descriptionHint,
                  maxLength: 100,
                  onChanged: (value) {
                    ref.read(directQrisNotifierProvider.notifier).onChangedDescription(value);
                  },
                ),
                const SizedBox(height: AppSizes.padding),
                AppTextField(
                  controller: _customerController,
                  labelText: l10n.directQris_customerLabel,
                  hintText: l10n.directQris_customerHint,
                  maxLength: 100,
                  onChanged: (value) {
                    ref.read(directQrisNotifierProvider.notifier).onChangedCustomerName(value);
                  },
                ),
                const SizedBox(height: AppSizes.padding / 2),
                _UniqueCodeNote(text: l10n.directQris_uniqueCodeNote),
                const SizedBox(height: AppSizes.padding * 1.5),
                AppButton(
                  text: l10n.directQris_createButton,
                  enabled: state.canSubmit,
                  onTap: _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DirectQrisState state;

  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.directQris_subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.padding / 2),
            _ModeBadge(isSandbox: state.isSandbox),
          ],
        ),
      ],
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final bool isSandbox;

  const _ModeBadge({required this.isSandbox});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final color = isSandbox ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSandbox ? Icons.science_outlined : Icons.verified_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            isSandbox ? l10n.directQris_sandbox : l10n.directQris_production,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotConfiguredBanner extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onOpenSettings;

  const _NotConfiguredBanner({required this.isAdmin, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: scheme.error),
              const SizedBox(width: AppSizes.padding / 2),
              Expanded(
                child: Text(
                  l10n.directQris_notConfiguredTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding / 2),
          Text(
            isAdmin ? l10n.directQris_notConfiguredMessage : l10n.directQris_contactAdmin,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onErrorContainer,
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: AppSizes.padding),
            AppButton(
              text: l10n.directQris_openSettings,
              fontSize: 12,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              onTap: onOpenSettings,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  final int amount;
  final bool selected;
  final VoidCallback onTap;

  const _QuickAmountButton({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppButton(
      text: CurrencyFormatter.withoutSymbol(amount, decimalDigits: 0),
      height: 36,
      fontSize: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      buttonColor: selected ? scheme.primary : scheme.surface,
      borderColor: selected ? scheme.primary : scheme.outlineVariant,
      textColor: selected ? scheme.onPrimary : scheme.onSurface,
      onTap: onTap,
    );
  }
}

class _UniqueCodeNote extends StatelessWidget {
  final String text;

  const _UniqueCodeNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding / 1.5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: scheme.outline),
          const SizedBox(width: AppSizes.padding / 2),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
