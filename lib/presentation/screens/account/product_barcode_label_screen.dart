import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/barcode_generator.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/account/product_barcode_label_notifier.dart';
import '../../providers/account/product_barcode_label_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_success_overlay.dart';
import '../../widgets/app_text_field.dart';

class ProductBarcodeLabelScreen extends ConsumerStatefulWidget {
  const ProductBarcodeLabelScreen({super.key});

  @override
  ConsumerState<ProductBarcodeLabelScreen> createState() => _ProductBarcodeLabelScreenState();
}

class _ProductBarcodeLabelScreenState extends ConsumerState<ProductBarcodeLabelScreen> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productBarcodeLabelNotifierProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(productBarcodeLabelNotifierProvider.select((s) => s.isLoading));
    final products = ref.watch(productBarcodeLabelNotifierProvider.select((s) => s.products));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings_printBarcodeLabels),
        titleSpacing: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: RefreshIndicator(
            onRefresh: () => ref.read(productBarcodeLabelNotifierProvider.notifier).loadProducts(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _NewProductCard(),
                  const SizedBox(height: AppSizes.padding * 1.5),
                  Text(
                    l10n.product_labelExistingTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: searchController,
                    hintText: l10n.product_labelSearchHint,
                    type: AppTextFieldType.search,
                    textInputAction: TextInputAction.search,
                    onEditingComplete: () {
                      FocusScope.of(context).unfocus();
                      final notifier = ref.read(productBarcodeLabelNotifierProvider.notifier);
                      notifier.setQuery(searchController.text);
                      notifier.applySearch();
                    },
                    onTapClearButton: () {
                      final notifier = ref.read(productBarcodeLabelNotifierProvider.notifier);
                      notifier.setQuery(searchController.text);
                      notifier.applySearch();
                    },
                  ),
                  const _FilterRow(),
                  const _SelectionRow(),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const AppProgressIndicator()
                  else if (products.isEmpty)
                    AppEmptyState(subtitle: l10n.product_noProducts)
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _ProductRow(product: products[i]),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String number;
  final String title;

  const _StepHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _BarcodeNumber extends StatelessWidget {
  final String code;

  const _BarcodeNumber({required this.code});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    );

    final groups = BarcodeGenerator.displayGroups(code);
    final children = <Widget>[];

    for (var g = 0; g < groups.length; g++) {
      if (g > 0) children.add(const SizedBox(width: 12));

      for (var i = 0; i < groups[g].length; i++) {
        children.add(Text(groups[g][i], style: style));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: children,
    );
  }
}

class _NewProductCard extends ConsumerStatefulWidget {
  const _NewProductCard();

  @override
  ConsumerState<_NewProductCard> createState() => _NewProductCardState();
}

class _NewProductCardState extends ConsumerState<_NewProductCard> {
  final nameController = TextEditingController();
  final barcodeController = TextEditingController();
  int copies = 1;

  @override
  void dispose() {
    nameController.dispose();
    barcodeController.dispose();
    super.dispose();
  }

  String _errorMessage(String code) {
    final l10n = AppLocalizations.of(context)!;

    return switch (code) {
      'new_form_incomplete' => l10n.product_labelNewForm,
      'new_code_invalid' => l10n.product_labelInvalidCode,
      'duplicate_name' => l10n.product_labelDuplicateName,
      'duplicate_barcode' => l10n.product_labelDuplicateBarcode,
      _ => code,
    };
  }

  Future<void> _onGenerate() async {
    await ref.read(productBarcodeLabelNotifierProvider.notifier).generateNewCode();

    if (!mounted) return;

    final code = ref.read(productBarcodeLabelNotifierProvider).newCode;

    if (code != null && barcodeController.text != code) {
      barcodeController.text = code;
    }

    final error = ref.read(productBarcodeLabelNotifierProvider).error;

    if (error != null) AppSnackBar.showError(_errorMessage(error));
  }

  Future<void> _onSave() async {
    final ok = await ref.read(productBarcodeLabelNotifierProvider.notifier).saveNewProduct();

    if (!mounted) return;

    if (!ok) {
      final error = ref.read(productBarcodeLabelNotifierProvider).error;
      if (error != null) AppSnackBar.showError(_errorMessage(error));
      return;
    }

    AppSuccessOverlay.show(AppLocalizations.of(context)!.product_labelSavedOne);
  }

  Future<void> _onPrint() async {
    final printerService = ref.read(printerServiceProvider);

    if (!printerService.isConnected || printerService.selectedPrinter == null) {
      if (!mounted) return;

      AppDialog.show(
        title: AppLocalizations.of(context)!.product_labelPrintLabel,
        text: AppLocalizations.of(context)!.product_labelNeedPrinter,
        leftButtonText: AppLocalizations.of(context)!.home_cancel,
        rightButtonText: AppLocalizations.of(context)!.product_labelGoPrinter,
        onTapRightButton: (ctx) {
          ctx.pop();
          context.go('/account/printer-settings');
        },
      );
      return;
    }

    final ok = await ref.read(productBarcodeLabelNotifierProvider.notifier).printNewProduct(copies: copies);

    if (!mounted) return;

    if (!ok) {
      final error = ref.read(productBarcodeLabelNotifierProvider).error;
      if (error != null) AppSnackBar.showError(_errorMessage(error));
      return;
    }

    AppSuccessOverlay.show(AppLocalizations.of(context)!.product_labelPrinted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(productBarcodeLabelNotifierProvider.notifier);
    final isBusy = ref.watch(productBarcodeLabelNotifierProvider.select((s) => s.isBusy));
    final newCode = ref.watch(productBarcodeLabelNotifierProvider.select((s) => s.newCode));

    if (newCode != null && barcodeController.text != newCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (barcodeController.text != newCode) barcodeController.text = newCode;
      });
    }

    final codeValid = newCode != null && BarcodeGenerator.isValidEan13(newCode);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeader(number: '1', title: l10n.product_labelNewProduct),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(
              controller: nameController,
              labelText: l10n.product_nameLabel,
              hintText: l10n.product_nameHint,
              textInputAction: TextInputAction.next,
              onChanged: notifier.setNewName,
            ),
            const SizedBox(height: AppSizes.padding / 2),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: barcodeController,
                    labelText: l10n.product_barcodeLabel,
                    hintText: l10n.product_barcodeHint,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: notifier.setNewCode,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppSizes.radius),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSizes.radius),
                      onTap: isBusy ? null : _onGenerate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Opacity(
                          opacity: isBusy ? 0.5 : 1,
                          child: Row(
                            children: [
                              Icon(Icons.autorenew_rounded, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(l10n.product_labelGenerate),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.padding),
            _StepHeader(number: '2', title: l10n.product_labelPreview),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.padding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radius),
                border: Border.all(color: Theme.of(context).colorScheme.surfaceContainer),
              ),
              child: codeValid
                  ? Column(
                      children: [
                        ValueListenableBuilder(
                          valueListenable: nameController,
                          builder: (context, value, _) {
                            final name = value.text.trim();

                            if (name.isEmpty) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                        bw.BarcodeWidget(
                          data: newCode,
                          barcode: bw.Barcode.ean13(),
                          width: double.infinity,
                          height: 110,
                          drawText: false,
                        ),
                        const SizedBox(height: 12),
                        _BarcodeNumber(code: newCode),
                      ],
                    )
                  : Text(
                      l10n.product_labelTapGenerate,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                    ),
            ),
            const SizedBox(height: AppSizes.padding / 2),
            Row(
              children: [
                Text(l10n.product_labelCopies, style: Theme.of(context).textTheme.labelSmall),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: copies > 1 ? () => setState(() => copies--) : null,
                ),
                Text('$copies', style: Theme.of(context).textTheme.bodyMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: copies < 99 ? () => setState(() => copies++) : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: l10n.product_labelSaveProduct,
                    enabled: !isBusy,
                    onTap: _onSave,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: l10n.product_labelPrintLabel,
                    buttonColor: Theme.of(context).colorScheme.tertiary,
                    enabled: !isBusy,
                    onTap: _onPrint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(productBarcodeLabelNotifierProvider.select((s) => s.filter));

    Widget chip(BarcodeLabelFilter value, String label) {
      final active = filter == value;

      return ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => ref.read(productBarcodeLabelNotifierProvider.notifier).setFilter(value),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding / 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(BarcodeLabelFilter.withoutBarcode, l10n.product_labelFilterWithout),
            const SizedBox(width: 8),
            chip(BarcodeLabelFilter.withBarcode, l10n.product_labelFilterWith),
            const SizedBox(width: 8),
            chip(BarcodeLabelFilter.all, l10n.product_labelFilterAll),
          ],
        ),
      ),
    );
  }
}

class _SelectionRow extends ConsumerWidget {
  const _SelectionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(productBarcodeLabelNotifierProvider.notifier);
    final isBusy = ref.watch(productBarcodeLabelNotifierProvider.select((s) => s.isBusy));

    String errorMessage(String code) {
      return switch (code) {
        'empty_selection' => l10n.product_labelEmptySelection,
        'empty_generated' => l10n.product_labelEmptyGenerated,
        'empty_printable' => l10n.product_labelEmptyPrintable,
        _ => code,
      };
    }

    Future<void> onGenerate() async {
      await notifier.generateForSelected();
      final error = ref.read(productBarcodeLabelNotifierProvider).error;
      if (error != null) AppSnackBar.showError(errorMessage(error));
    }

    Future<void> onSave() async {
      final ok = await notifier.saveGenerated();

      if (!ok) {
        final error = ref.read(productBarcodeLabelNotifierProvider).error;
        if (error != null) AppSnackBar.showError(errorMessage(error));
        return;
      }

      final saved = ref.read(productBarcodeLabelNotifierProvider).savedCount ?? 0;
      AppSuccessOverlay.show(l10n.product_labelSaved(saved));
    }

    Future<void> onPrint() async {
      final printerService = ref.read(printerServiceProvider);

      if (!printerService.isConnected || printerService.selectedPrinter == null) {
        AppDialog.show(
          title: l10n.product_labelPrint,
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

      final ok = await notifier.printSelected();

      if (!ok) {
        final error = ref.read(productBarcodeLabelNotifierProvider).error;
        if (error != null) AppSnackBar.showError(errorMessage(error));
        return;
      }

      AppSuccessOverlay.show(l10n.product_labelPrinted);

      final skipped = ref.read(productBarcodeLabelNotifierProvider).skippedNoBarcode;

      if (skipped.isNotEmpty) {
        AppSnackBar.showError(l10n.product_labelSkipped(skipped.length));
      }
    }

    final selectedCount = ref.watch(productBarcodeLabelNotifierProvider.select((s) => s.selected.length));

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding / 2),
      child: Column(
        children: [
          Row(
            children: [
              TextButton(
                onPressed: isBusy ? null : notifier.selectAllVisible,
                child: Text(l10n.product_labelSelectAll),
              ),
              TextButton(
                onPressed: isBusy ? null : notifier.clearSelection,
                child: Text(l10n.product_labelClear),
              ),
              const Spacer(),
              if (selectedCount > 0) ...[
                Icon(Icons.check_circle, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  '$selectedCount',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: l10n.product_labelGenerate,
                  enabled: !isBusy,
                  onTap: onGenerate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  text: l10n.product_labelSave,
                  buttonColor: Theme.of(context).colorScheme.secondary,
                  enabled: !isBusy,
                  onTap: onSave,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  text: l10n.product_labelPrint,
                  buttonColor: Theme.of(context).colorScheme.tertiary,
                  enabled: !isBusy,
                  onTap: onPrint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  final ProductEntity product;

  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(productBarcodeLabelNotifierProvider.notifier);
    final isSelected = ref.watch(productBarcodeLabelNotifierProvider.select((s) => s.selected.contains(product.id)));
    final copies = ref.watch(productBarcodeLabelNotifierProvider.select((s) => s.copies[product.id] ?? 1));
    final generated = ref.watch(productBarcodeLabelNotifierProvider.select((s) => s.generated[product.id]));
    final hasBarcode = product.barcode != null && product.barcode!.trim().isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => notifier.toggleSelected(product.id!),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding / 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => notifier.toggleSelected(product.id!),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatter.withoutSymbol(product.price, decimalDigits: 0),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    if (hasBarcode)
                      Text(
                        '${product.barcode} · ${l10n.product_labelHasBarcode}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    else if (generated != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.product_labelNewCode(generated),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            tooltip: l10n.product_labelRegenerate,
                            onPressed: () => notifier.regenerateSingle(product),
                          ),
                        ],
                      )
                    else
                      Text(
                        l10n.product_labelNoBarcode,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(l10n.product_labelCopies, style: Theme.of(context).textTheme.labelSmall),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () => notifier.setCopies(product.id!, copies - 1),
                        ),
                        Text('$copies', style: Theme.of(context).textTheme.bodyMedium),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () => notifier.setCopies(product.id!, copies + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
