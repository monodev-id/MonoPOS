import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/account/product_data_notifier.dart';
import '../../providers/account/product_data_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_success_overlay.dart';

class ProductDataScreen extends ConsumerWidget {
  const ProductDataScreen({super.key});

  Future<void> _onExport(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(productDataNotifierProvider.notifier);

    await notifier.exportProducts();
    final state = ref.read(productDataNotifierProvider);

    if (!context.mounted) return;

    if (state.exportedCount != null) {
      AppSuccessOverlay.show(l10n.dataProduct_exportSuccess(state.exportedCount!));
    } else if (state.error != null) {
      AppSnackBar.showError(l10n.dataProduct_exportFailed);
    }
  }

  Future<void> _onImport(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await AppDialog.show(
      title: l10n.dataProduct_importTitle,
      text: l10n.dataProduct_importConfirm,
      leftButtonText: l10n.dataProduct_cancel,
      rightButtonText: l10n.dataProduct_confirm,
      onTapLeftButton: (ctx) => ctx.pop(false),
      onTapRightButton: (ctx) => ctx.pop(true),
    );

    if (confirmed != true) return;

    final notifier = ref.read(productDataNotifierProvider.notifier);
    await notifier.importProducts();
    final state = ref.read(productDataNotifierProvider);

    if (!context.mounted) return;

    if (state.importedCount != null) {
      AppSuccessOverlay.show(l10n.dataProduct_importSuccess(state.importedCount!));
    } else if (state.error == 'no_file') {
      AppSnackBar.showError(l10n.dataProduct_noFile);
    } else if (state.error == 'invalid_file') {
      AppSnackBar.showError(l10n.dataProduct_invalidFile);
    } else if (state.error != null) {
      AppSnackBar.showError(l10n.dataProduct_importFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(productDataNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dataProduct_title),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PageHeader(state: state),
                const SizedBox(height: AppSizes.padding),
                if (state.error != null) ...[
                  _ErrorBanner(state: state),
                  const SizedBox(height: AppSizes.padding),
                ],
                _ExportCard(
                  state: state,
                  onExport: () => _onExport(context, ref),
                ),
                const SizedBox(height: AppSizes.padding),
                _ImportCard(
                  state: state,
                  onImport: () => _onImport(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _t(BuildContext context, String id, String en) {
  return Localizations.localeOf(context).languageCode == 'id' ? id : en;
}

String _formatDateTime(BuildContext context, DateTime? date) {
  if (date == null) return '';

  final locale = Localizations.localeOf(context).toLanguageTag();

  try {
    return DateFormat('d MMM y • HH.mm', locale).format(date);
  } catch (_) {
    return DateFormat('d MMM y • HH.mm').format(date);
  }
}

class _PageHeader extends StatelessWidget {
  final ProductDataState state;

  const _PageHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = (state.exportedCount ?? 0) + (state.importedCount ?? 0);

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radius + 8),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.inventory_2_outlined, color: scheme.onPrimary, size: 28),
          ),
          const SizedBox(width: AppSizes.padding / 2 + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(context, 'Cadangkan & pulihkan katalog', 'Back up & restore catalog'),
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.02 * 18),
                ),
                const SizedBox(height: 4),
                Text(
                  _t(
                    context,
                    'File JSON berisi seluruh data produk di bawah. Hasil export & import dirinci per produk.',
                    'JSON file with all product data below. Export & import results list each product.',
                  ),
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
                ),
              ],
            ),
          ),
          if (total > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(100)),
              child: Text(
                '$total',
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final ProductDataState state;

  const _ErrorBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final notifier = ProviderScope.containerOf(context).read(productDataNotifierProvider.notifier);

    final message = switch (state.error) {
      'no_file' => l10n.dataProduct_noFile,
      'invalid_file' => l10n.dataProduct_invalidFile,
      'load_failed' => l10n.dataProduct_exportFailed,
      _ => state.error ?? l10n.dataProduct_importFailed,
    };

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding / 2 + 4),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSizes.radius + 4),
        border: Border.all(color: scheme.error.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: notifier.clearResult,
            icon: Icon(Icons.close_rounded, size: 18, color: scheme.error),
          ),
        ],
      ),
    );
  }
}

const _exportedFields = [
  'nama',
  'harga',
  'grosir',
  'stok',
  'terjual',
  'satuan',
  'barcode',
  'deskripsi',
  'varian',
];

class _ExportCard extends StatelessWidget {
  final ProductDataState state;
  final VoidCallback onExport;

  const _ExportCard({required this.state, required this.onExport});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasResult = state.exportedCount != null;

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius + 8),
        border: Border.all(color: scheme.surfaceContainerHighest, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.upload_rounded, color: scheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.dataProduct_export, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      _t(context, 'Simpan katalog ke file JSON', 'Save catalog to a JSON file'),
                      style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _t(context, 'Data yang ikut diekspor:', 'Data included in export:'),
            style: textTheme.labelSmall?.copyWith(color: scheme.outline, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final field in _exportedFields) _FieldChip(label: field)],
          ),
          const SizedBox(height: AppSizes.padding / 2 + 2),
          AppButton(
            text: state.isBusy ? l10n.dataProduct_exporting : l10n.dataProduct_export,
            enabled: !state.isBusy,
            onTap: onExport,
            child: state.isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : null,
          ),
          if (hasResult) ...[
            const SizedBox(height: 12),
            _ExportResult(state: state),
          ],
        ],
      ),
    );
  }
}

class _ExportResult extends StatelessWidget {
  final ProductDataState state;

  const _ExportResult({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final notifier = ProviderScope.containerOf(context).read(productDataNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.dataProduct_exportSuccess(state.exportedCount!),
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: notifier.clearResult,
                icon: Icon(Icons.close_rounded, size: 18, color: scheme.outline),
              ),
            ],
          ),
          if (state.exportedFileName != null) ...[
            const SizedBox(height: 4),
            _FileChip(fileName: state.exportedFileName!, timestamp: _formatDateTime(context, state.exportedAt)),
          ],
          const SizedBox(height: 8),
          Text(
            _t(context, 'Produk yang diekspor:', 'Exported products:'),
            style: textTheme.labelSmall?.copyWith(color: scheme.outline, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          if (state.exportedProducts.isEmpty)
            Text(
              _t(context, 'Tidak ada rincian produk.', 'No product details.'),
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            )
          else
            for (final product in state.exportedProducts.take(6)) _ProductRow(product: product),
          if (state.exportedProducts.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${state.exportedProducts.length - 6} ${_t(context, 'produk lainnya', 'more products')}',
                style: textTheme.labelSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImportCard extends StatelessWidget {
  final ProductDataState state;
  final VoidCallback onImport;

  const _ImportCard({required this.state, required this.onImport});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasResult = state.importedCount != null;

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius + 8),
        border: Border.all(color: scheme.surfaceContainerHighest, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.download_rounded, color: scheme.onTertiaryContainer, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.dataProduct_import, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                      _t(context, 'Tambahkan produk dari file backup', 'Add products from a backup file'),
                      style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: scheme.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.dataProduct_importConfirm,
                    style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.padding / 2 + 2),
          AppButton(
            text: state.isBusy ? l10n.dataProduct_importing : l10n.dataProduct_import,
            enabled: !state.isBusy,
            onTap: onImport,
            child: state.isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : null,
          ),
          if (hasResult) ...[
            const SizedBox(height: 12),
            _ImportResult(state: state),
          ],
        ],
      ),
    );
  }
}

class _ImportResult extends StatelessWidget {
  final ProductDataState state;

  const _ImportResult({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final notifier = ProviderScope.containerOf(context).read(productDataNotifierProvider.notifier);
    final skipped = state.skippedCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: scheme.tertiary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.dataProduct_importSuccess(state.importedCount!),
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: notifier.clearResult,
                icon: Icon(Icons.close_rounded, size: 18, color: scheme.outline),
              ),
            ],
          ),
          if (state.importedFileName != null) ...[
            const SizedBox(height: 4),
            _FileChip(fileName: state.importedFileName!, timestamp: _formatDateTime(context, state.importedAt)),
          ],
          if (skipped > 0) ...[
            const SizedBox(height: 4),
            Text(
              _t(context, '$skipped data dilewati (gagal/duplikat)', '$skipped items skipped (failed/duplicate)'),
              style: textTheme.labelSmall?.copyWith(color: scheme.error, fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _t(context, 'Produk yang diimpor:', 'Imported products:'),
            style: textTheme.labelSmall?.copyWith(color: scheme.outline, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          if (state.importedNames.isEmpty)
            Text(
              _t(context, 'Tidak ada rincian produk.', 'No product details.'),
              style: textTheme.bodySmall?.copyWith(color: scheme.outline),
            )
          else
            for (final name in state.importedNames.take(6)) _ImportedNameRow(name: name),
          if (state.importedNames.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${state.importedNames.length - 6} ${_t(context, 'produk lainnya', 'more products')}',
                style: textTheme.labelSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldChip extends StatelessWidget {
  final String label;

  const _FieldChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: scheme.surfaceContainerHighest, width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  final String fileName;
  final String timestamp;

  const _FileChip({required this.fileName, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: scheme.surfaceContainerHighest, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 14, color: scheme.outline),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              timestamp.isEmpty ? fileName : '$fileName • $timestamp',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final ProductEntity product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final initial = product.name.isEmpty ? '?' : product.name[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${CurrencyFormatter.format(product.price, decimalDigits: 0)} • ${_t(context, 'stok', 'stock')} ${product.stock} ${product.unit}',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportedNameRow extends StatelessWidget {
  final String name;

  const _ImportedNameRow({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.tertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: textTheme.labelLarge?.copyWith(color: scheme.tertiary, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Icon(Icons.check_rounded, size: 16, color: scheme.tertiary),
        ],
      ),
    );
  }
}
