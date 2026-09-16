import 'dart:io';

import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mono_pos/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/barcode_generator.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/rupiah_input_formatter.dart';
import '../../../domain/entities/product_tier_entity.dart';
import '../../../domain/entities/product_unit_entity.dart';
import '../../providers/products/product_form_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_drop_down.dart';
import '../../widgets/app_icon_button.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_success_overlay.dart';
import '../../widgets/app_text_field.dart';
import '../home/components/barcode_scanner_screen.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final int? id;

  const ProductFormScreen({
    super.key,
    this.id,
  });

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final wholesalePriceController = TextEditingController();
  final stockController = TextEditingController();
  final barcodeController = TextEditingController();
  final descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(productFormNotifierProvider.notifier).initProductForm(widget.id);

      final state = ref.read(productFormNotifierProvider);
      nameController.text = state.name ?? '';
      priceController.text = RupiahInputFormatter()
          .formatEditUpdate(
            const TextEditingValue(text: ''),
            TextEditingValue(text: state.price?.toString() ?? ''),
          )
          .text;
      wholesalePriceController.text = RupiahInputFormatter()
          .formatEditUpdate(
            const TextEditingValue(text: ''),
            TextEditingValue(text: state.wholesalePrice?.toString() ?? ''),
          )
          .text;
      stockController.text = state.stock?.toString() ?? '';
      barcodeController.text = state.barcode ?? '';
      descController.text = state.description ?? '';
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    wholesalePriceController.dispose();
    stockController.dispose();
    barcodeController.dispose();
    descController.dispose();
    super.dispose();
  }

  void onTapImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile == null) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'Crop Photo'),
        IOSUiSettings(title: 'Crop Photo'),
      ],
    );

    if (croppedFile != null) {
      var file = File(croppedFile.path);
      ref.read(productFormNotifierProvider.notifier).onChangedImage(file);
    }
  }

  void createProduct() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(productFormNotifierProvider.notifier).createProduct();
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.go('/products');
      AppSnackBar.show(AppLocalizations.of(context)!.product_created);
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  void updatedProduct() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(productFormNotifierProvider.notifier).updatedProduct(widget.id!);
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.pop();
      AppSnackBar.show(AppLocalizations.of(context)!.product_updated);
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  void deleteProduct() async {
    var res = await AppDialog.showProgress(() {
      return ref.read(productFormNotifierProvider.notifier).deleteProduct(widget.id!);
    });

    if (res.isSuccess) {
      if (!mounted) return;
      context.go('/products');
      AppSuccessOverlay.show(AppLocalizations.of(context)!.product_deleted);
    } else {
      AppDialog.showError(error: res.error?.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(productFormNotifierProvider.notifier);

    final isLoaded = ref.watch(productFormNotifierProvider.select((s) => s.isLoaded));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.id == null
              ? AppLocalizations.of(context)!.product_createTitle
              : AppLocalizations.of(context)!.product_editTitle,
        ),
        titleSpacing: 0,
      ),
      body: !isLoaded
          ? const AppProgressIndicator()
          : Center(
              child: Container(
                constraints: AppSizes.isTablet(context) || AppSizes.isDesktop(context)
                    ? const BoxConstraints(maxWidth: 600)
                    : null,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ImageSection(onTapImage: onTapImage),
                      _NameField(
                        controller: nameController,
                        onChanged: notifier.onChangedName,
                      ),
                      _RetailPriceField(
                        controller: priceController,
                        onChanged: notifier.onChangedPrice,
                      ),
                      _WholesalePriceField(
                        controller: wholesalePriceController,
                        onChanged: notifier.onChangedWholesalePrice,
                      ),
                      _StockField(
                        controller: stockController,
                        onChanged: notifier.onChangedStock,
                      ),
                      _BarcodeField(
                        controller: barcodeController,
                        onChanged: notifier.onChangedBarcode,
                      ),
                      _UnitField(
                        onChanged: notifier.onChangedUnit,
                      ),
                      _UnitManagementSection(),
                      _DescriptionField(
                        controller: descController,
                        onChanged: notifier.onChangedDesc,
                      ),
                      _CreateOrUpdateButton(
                        id: widget.id,
                        onCreateProduct: createProduct,
                        onUpdatedProduct: updatedProduct,
                      ),
                      _DeleteButton(
                        id: widget.id,
                        onDeleteProduct: deleteProduct,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ImageSection extends ConsumerWidget {
  final VoidCallback onTapImage;

  const _ImageSection({required this.onTapImage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageFile = ref.watch(productFormNotifierProvider.select((p) => p.imageFile));
    final imageUrl = ref.watch(productFormNotifierProvider.select((p) => p.imageUrl));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.product_image,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.padding / 2),
        Stack(
          children: [
            GestureDetector(
              onTap: onTapImage,
              child: AppImage(
                image: imageFile?.path ?? imageUrl ?? '',
                imgProvider: imageFile != null ? ImgProvider.fileImage : ImgProvider.networkImage,
                width: 100,
                height: 100,
                borderRadius: BorderRadius.circular(AppSizes.radius),
                backgroundColor: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  width: 1,
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                errorWidget: Icon(
                  Icons.image,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  size: 32,
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: AppIconButton(
                icon: Icons.camera_alt_rounded,
                iconSize: 14,
                borderRadius: 8,
                padding: const EdgeInsets.all(6),
                onTap: onTapImage,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NameField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.product_nameLabel,
        hintText: AppLocalizations.of(context)!.product_nameHint,
        onChanged: onChanged,
      ),
    );
  }
}

class _BarcodeField extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _BarcodeField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: controller,
              labelText: AppLocalizations.of(context)!.product_barcodeLabel,
              hintText: AppLocalizations.of(context)!.product_barcodeHint,
              onChanged: onChanged,
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
                onTap: () async {
                  final productRepository = ref.read(productRepositoryProvider);

                  final code = await BarcodeGenerator.generateUniqueEan13(
                    exists: (c) async {
                      final res = await productRepository.getProductByBarcode(c);
                      return res.isSuccess && res.data != null;
                    },
                  );

                  controller.text = code;
                  onChanged(code);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.autorenew_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
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
                onTap: () async {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BarcodeScannerScreen(),
                    ),
                  );
                  if (result != null) {
                    controller.text = result;
                    onChanged(result);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetailPriceField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _RetailPriceField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.product_retailPriceLabel,
        hintText: AppLocalizations.of(context)!.product_retailPriceHint,
        type: AppTextFieldType.currency,
        onChanged: onChanged,
      ),
    );
  }
}

class _WholesalePriceField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _WholesalePriceField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.product_wholesalePriceLabel,
        hintText: AppLocalizations.of(context)!.product_wholesalePriceHint,
        type: AppTextFieldType.currency,
        onChanged: onChanged,
      ),
    );
  }
}

class _StockField extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _StockField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.product_stockLabel,
        hintText: AppLocalizations.of(context)!.product_stockHint,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
      ),
    );
  }
}

class _UnitField extends ConsumerWidget {
  final ValueChanged<String> onChanged;

  const _UnitField({
    required this.onChanged,
  });

  static const _presetUnits = [
    'pcs',
    'dus',
    'kg',
    'pack',
    'box',
    'sachet',
    'botol',
    'lusin',
    'kodi',
    'rim',
    'bungkus',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUnit = ref.watch(productFormNotifierProvider.select((s) => s.unit));
    final customUnits = ref.watch(productFormNotifierProvider.select((s) => s.customUnitNames));
    final notifier = ref.read(productFormNotifierProvider.notifier);

    final allUnits = [
      ..._presetUnits,
      ...customUnits.where((u) => !_presetUnits.contains(u)),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Row(
        children: [
          Expanded(
            child: AppDropDown(
              labelText: '${AppLocalizations.of(context)!.product_unitLabel} (default)',
              hintText: 'Pilih satuan default',
              selectedValue: selectedUnit,
              dropdownItems: allUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: SizedBox(
              height: 48,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSizes.radius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  onTap: () => _showAddUnitDialog(context, ref, notifier),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUnitDialog(BuildContext context, WidgetRef ref, ProductFormNotifier notifier) {
    final controller = TextEditingController();

    AppDialog.show(
      title: 'Tambah Nama Satuan',
      child: AppTextField(
        controller: controller,
        labelText: 'Nama Satuan',
        hintText: 'contoh: karton, lembar',
      ),
      rightButtonText: 'Simpan',
      leftButtonText: 'Batal',
      onTapLeftButton: (ctx) => ctx.pop(),
      onTapRightButton: (ctx) {
        final name = controller.text.trim();
        if (name.isNotEmpty) {
          notifier.addCustomUnitName(name);
        }
        ctx.pop();
      },
    );
  }
}

class _UnitManagementSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(productFormNotifierProvider.select((s) => s.units));
    final notifier = ref.read(productFormNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Satuan & Harga',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppButton(
                text: '+ Tambah Satuan',
                height: 30,
                fontSize: 11,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                borderRadius: BorderRadius.circular(4),
                onTap: () => _showUnitDialog(context, ref, null, -1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (units.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSizes.radius),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              child: Text(
                'Belum ada satuan. Tambah minimal 1 satuan.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ...List.generate(units.length, (i) {
            final unit = units[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  border: Border.all(
                    color: unit.isBase
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    unit.unitName,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (unit.isBase) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        'base',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '1 ${_findBaseUnitName(units)} = ${unit.conversionValue} ${unit.unitName}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              Text(
                                'Retail: ${unit.price} ${unit.wholesalePrice != null ? "| Grosir: ${unit.wholesalePrice}" : ""}',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppIconButton(
                          icon: Icons.edit,
                          iconSize: 14,
                          onTap: () => _showUnitDialog(context, ref, unit, i),
                        ),
                        const SizedBox(width: 4),
                        AppIconButton(
                          icon: Icons.delete_outline,
                          iconSize: 14,
                          onTap: () => notifier.removeUnit(i),
                        ),
                      ],
                    ),
                    _TieredPriceSection(unitIndex: i),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _findBaseUnitName(List<ProductUnitEntity> units) {
    final base = units.where((u) => u.isBase).firstOrNull;
    return base?.unitName ?? 'unit';
  }

  String _findBaseUnitNameOrNull(List<ProductUnitEntity> units) {
    final base = units.where((u) => u.isBase).firstOrNull;
    return base?.unitName ?? '';
  }

  void _showUnitDialog(BuildContext context, WidgetRef ref, ProductUnitEntity? existing, int index) {
    final nameController = TextEditingController(text: existing?.unitName ?? '');
    final conversionController = TextEditingController(text: existing?.conversionValue.toString() ?? '1');
    final priceController = TextEditingController(
      text: RupiahInputFormatter()
          .formatEditUpdate(
            const TextEditingValue(text: ''),
            TextEditingValue(text: existing?.price.toString() ?? ''),
          )
          .text,
    );
    final wholesalePriceController = TextEditingController(
      text: RupiahInputFormatter()
          .formatEditUpdate(
            const TextEditingValue(text: ''),
            TextEditingValue(text: existing?.wholesalePrice?.toString() ?? ''),
          )
          .text,
    );
    bool isBase = existing?.isBase ?? false;

    final units = ref.read(productFormNotifierProvider).units;
    final hasBase = units.any((u) => u.isBase);

    AppDialog.show(
      title: existing == null ? 'Tambah Satuan' : 'Edit Satuan',
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: nameController,
                labelText: 'Nama Satuan',
                hintText: 'contoh: pcs, dus, kg',
              ),
              const SizedBox(height: AppSizes.padding),
              AppTextField(
                controller: conversionController,
                labelText: 'Nilai Konversi',
                hintText: '1 ${_findBaseUnitNameOrNull(units)} = ? ${nameController.text}',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: AppSizes.padding),
              AppTextField(
                controller: priceController,
                labelText: 'Harga Retail',
                type: AppTextFieldType.currency,
              ),
              const SizedBox(height: AppSizes.padding),
              AppTextField(
                controller: wholesalePriceController,
                labelText: 'Harga Grosir (opsional)',
                type: AppTextFieldType.currency,
              ),
              if (!hasBase || isBase) ...[
                const SizedBox(height: AppSizes.padding),
                CheckboxListTile(
                  title: const Text('Satuan dasar (base)'),
                  subtitle: Text(
                    'Stok dihitung dalam satuan ini',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                  ),
                  value: isBase,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) {
                    setDialogState(() => isBase = v ?? false);
                  },
                ),
              ],
            ],
          );
        },
      ),
      rightButtonText: 'Simpan',
      leftButtonText: 'Batal',
      onTapLeftButton: (ctx) => ctx.pop(),
      onTapRightButton: (ctx) {
        final notifier = ref.read(productFormNotifierProvider.notifier);
        final unit = ProductUnitEntity(
          unitName: nameController.text,
          conversionValue: int.tryParse(conversionController.text) ?? 1,
          price: int.tryParse(priceController.text.replaceAll('.', '')) ?? 0,
          wholesalePrice: int.tryParse(wholesalePriceController.text.replaceAll('.', '')),
          isBase: isBase,
          productId: 0,
        );

        if (existing != null) {
          notifier.updateUnit(index, unit);
        } else {
          notifier.addUnit(unit);
        }

        ctx.pop();
      },
    );
  }
}

class _TieredPriceSection extends ConsumerWidget {
  final int unitIndex;

  const _TieredPriceSection({required this.unitIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(
      productFormNotifierProvider.select(
        (s) => s.tieredPrices[unitIndex] ?? <ProductTierEntity>[],
      ),
    );
    final notifier = ref.read(productFormNotifierProvider.notifier);

    if (tiers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Text(
              'Harga bertingkat: belum ada',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 22,
              child: AppButton(
                text: '+ Tambah',
                height: 22,
                fontSize: 9,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                borderRadius: BorderRadius.circular(3),
                onTap: () => _showTierDialog(context, ref, unitIndex, null, -1),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Harga Bertingkat:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 22,
                child: AppButton(
                  text: '+ Tambah',
                  height: 22,
                  fontSize: 9,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  borderRadius: BorderRadius.circular(3),
                  onTap: () => _showTierDialog(context, ref, unitIndex, null, -1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...List.generate(tiers.length, (ti) {
            final tier = tiers[ti];
            final rangeText = tier.maxQty != null ? '${tier.minQty} - ${tier.maxQty}' : '>= ${tier.minQty}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$rangeText: ${CurrencyFormatter.withoutSymbol(tier.price, decimalDigits: 0)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showTierDialog(context, ref, unitIndex, tier, ti),
                      child: Icon(Icons.edit, size: 12, color: Theme.of(context).colorScheme.outline),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => notifier.removeTier(unitIndex, ti),
                      child: Icon(Icons.delete_outline, size: 12, color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showTierDialog(
    BuildContext context,
    WidgetRef ref,
    int unitIndex,
    ProductTierEntity? existing,
    int tierIndex,
  ) {
    final minQtyController = TextEditingController(text: existing?.minQty.toString() ?? '');
    final maxQtyController = TextEditingController(text: existing?.maxQty?.toString() ?? '');
    final priceController = TextEditingController(
      text: RupiahInputFormatter()
          .formatEditUpdate(
            const TextEditingValue(text: ''),
            TextEditingValue(text: existing?.price.toString() ?? ''),
          )
          .text,
    );

    AppDialog.show(
      title: existing == null ? 'Tambah Harga Bertingkat' : 'Edit Harga Bertingkat',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: minQtyController,
            labelText: 'Min. Qty',
            hintText: 'contoh: 5',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppSizes.padding),
          AppTextField(
            controller: maxQtyController,
            labelText: 'Max. Qty (biarkan kosong jika tak terbatas)',
            hintText: 'contoh: 10',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: AppSizes.padding),
          AppTextField(
            controller: priceController,
            labelText: 'Harga',
            type: AppTextFieldType.currency,
          ),
        ],
      ),
      rightButtonText: 'Simpan',
      leftButtonText: 'Batal',
      onTapLeftButton: (ctx) => ctx.pop(),
      onTapRightButton: (ctx) {
        final notifier = ref.read(productFormNotifierProvider.notifier);
        final tier = ProductTierEntity(
          productUnitId: 0,
          minQty: int.tryParse(minQtyController.text) ?? 1,
          maxQty: int.tryParse(maxQtyController.text),
          price: int.tryParse(priceController.text.replaceAll('.', '')) ?? 0,
        );

        if (existing != null) {
          notifier.updateTier(unitIndex, tierIndex, tier);
        } else {
          notifier.addTier(unitIndex, tier);
        }

        ctx.pop();
      },
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _DescriptionField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppTextField(
        controller: controller,
        labelText: AppLocalizations.of(context)!.product_descriptionLabel,
        hintText: AppLocalizations.of(context)!.product_descriptionHint,
        maxLines: 4,
        onChanged: onChanged,
      ),
    );
  }
}

class _CreateOrUpdateButton extends ConsumerWidget {
  final int? id;
  final VoidCallback onCreateProduct;
  final VoidCallback onUpdatedProduct;

  const _CreateOrUpdateButton({
    required this.id,
    required this.onCreateProduct,
    required this.onUpdatedProduct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFormValid = ref.watch(
      productFormNotifierProvider.select((s) {
        return (s.name?.isNotEmpty ?? false) &&
            (s.price ?? 0) > 0 &&
            (s.stock ?? 0) > 0 &&
            s.unit != null &&
            s.unit!.isNotEmpty &&
            s.units.isNotEmpty;
      }),
    );

    final isSaving = ref.watch(
      productFormNotifierProvider.select((s) => s.isSaving),
    );

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding * 1.5),
      child: AppButton(
        text: id == null
            ? AppLocalizations.of(context)!.product_addButton
            : AppLocalizations.of(context)!.product_updateButton,
        enabled: isFormValid && !isSaving,
        onTap: () {
          if (id != null) {
            onUpdatedProduct();
          } else {
            onCreateProduct();
          }
        },
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final int? id;
  final VoidCallback onDeleteProduct;

  const _DeleteButton({
    required this.id,
    required this.onDeleteProduct,
  });

  @override
  Widget build(BuildContext context) {
    if (id == null) return const SizedBox(height: AppSizes.padding * 2);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSizes.padding,
        bottom: AppSizes.padding * 2,
      ),
      child: AppButton(
        text: AppLocalizations.of(context)!.product_deleteButton,
        textColor: Theme.of(context).colorScheme.error,
        buttonColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        onTap: () {
          AppDialog.show(
            title: AppLocalizations.of(context)!.cart_confirm,
            text: AppLocalizations.of(context)!.product_deleteConfirm,
            leftButtonText: AppLocalizations.of(context)!.home_cancel,
            rightButtonText: AppLocalizations.of(context)!.cart_remove,
            rightButtonColor: Theme.of(context).colorScheme.errorContainer,
            rightButtonTextColor: Theme.of(context).colorScheme.error,
            onTapRightButton: (context) async {
              context.pop();
              onDeleteProduct();
            },
          );
        },
      ),
    );
  }
}
