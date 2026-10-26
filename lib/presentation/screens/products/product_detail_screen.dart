import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mono_pos/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/currency_formatter.dart';
import '../../../core/utilities/date_time_formatter.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/auth/auth_notifier.dart';
import '../../providers/products/product_detail_notifier.dart';
import '../../providers/products/products_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_success_overlay.dart';
import 'components/product_purchase_info.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int id;

  const ProductDetailScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.product_detailTitle),
        titleSpacing: 0,
        actions: [
          _EditButton(id: id),
          _DeleteButton(id: id),
        ],
      ),
      body: FutureBuilder(
        future: ref.read(productDetailNotifierProvider.notifier).getProductDetail(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppProgressIndicator();
          }

          if (snapshot.hasError) {
            throw snapshot.error.toString();
          }

          if (snapshot.data == null) {
            return AppEmptyState(title: AppLocalizations.of(context)!.product_notFound);
          }

          final product = snapshot.data!;

          return Center(
            child: Container(
              constraints: AppSizes.isTablet(context) || AppSizes.isDesktop(context)
                  ? const BoxConstraints(maxWidth: 600)
                  : null,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductImage(imageUrl: product.imageUrl),
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ProductName(
                            productName: product.name,
                            createdAt: product.createdAt,
                            updatedAt: product.updatedAt,
                          ),
                          _ProductPrice(price: product.price),
                          _ProductBarcode(barcode: product.barcode),
                          _ProductStock(
                            stock: product.stock,
                            unit: product.units.where((u) => u.isBase).firstOrNull?.unitName ?? product.unit,
                          ),
                          _ProductSold(sold: product.sold),
                          if (product.units.length > 1) _ProductUnits(product: product),
                          _ProductDescription(description: product.description),
                          ProductPurchaseInfo(product: product),
                        ],
                      ),
                    ),
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

class _EditButton extends ConsumerWidget {
  final int id;

  const _EditButton({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));

    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.padding),
      child: AppButton(
        height: 26,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
        buttonColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSizes.padding / 4),
            Text(
              AppLocalizations.of(context)!.product_editProduct,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        onTap: () {
          context.push('/products/product-edit/$id');
        },
      ),
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  final int id;

  const _DeleteButton({required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));

    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.padding),
      child: AppButton(
        height: 26,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
        buttonColor: Theme.of(context).colorScheme.errorContainer,
        child: Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 12,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: AppSizes.padding / 4),
            Text(
              l10n.product_deleteButton,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        onTap: () => _confirmDelete(context, ref, l10n),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    AppDialog.show(
      title: l10n.product_deleteButton,
      text: l10n.product_deleteConfirm,
      leftButtonText: l10n.home_cancel,
      rightButtonText: l10n.product_deleteButton,
      rightButtonColor: Theme.of(context).colorScheme.errorContainer,
      rightButtonTextColor: Theme.of(context).colorScheme.error,
      onTapRightButton: (ctx) async {
        ctx.pop();
        final res = await AppDialog.showProgress(
          () => ref.read(productDetailNotifierProvider.notifier).deleteProduct(id),
        );

        if (!context.mounted) return;

        if (res.isSuccess) {
          AppSuccessOverlay.show(l10n.product_deleted);
          ref.read(productsNotifierProvider.notifier).resetProducts();
          ref.read(productsNotifierProvider.notifier).getAllProducts();
          context.go('/products');
        } else {
          AppDialog.showError(error: res.error?.toString());
        }
      },
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: AppSizes.screenWidth(context),
        minHeight: AppSizes.screenHeight(context) / 3,
        maxHeight: AppSizes.screenHeight(context) / 3,
      ),
      child: AppImage(
        image: imageUrl ?? '',
        backgroundColor: Theme.of(context).colorScheme.surface,
        border: Border.all(
          width: 0.5,
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        enableFullScreenView: true,
        errorWidget: Icon(
          Icons.image,
          color: Theme.of(context).colorScheme.surfaceDim,
          size: 32,
        ),
      ),
    );
  }
}

class _ProductName extends StatelessWidget {
  final String? productName;
  final String? createdAt;
  final String? updatedAt;

  const _ProductName({
    required this.productName,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          productName ?? AppLocalizations.of(context)!.product_noName,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.padding / 2),
        Text(
          AppLocalizations.of(context)!.product_addedAt(DateTimeFormatter.stripDateWithClock(createdAt ?? '')),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Text(
          AppLocalizations.of(context)!.product_lastUpdated(DateTimeFormatter.stripDateWithClock(updatedAt ?? '')),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _ProductPrice extends StatelessWidget {
  final int? price;

  const _ProductPrice({required this.price});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.product_price,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            CurrencyFormatter.withoutSymbol(price ?? 0, decimalDigits: 0),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductBarcode extends StatelessWidget {
  final String? barcode;

  const _ProductBarcode({this.barcode});

  @override
  Widget build(BuildContext context) {
    if (barcode == null || barcode!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.product_barcode,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            barcode!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductStock extends StatelessWidget {
  final int? stock;
  final String unit;

  const _ProductStock({required this.stock, this.unit = 'pcs'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.product_stock,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '$stock $unit',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSold extends StatelessWidget {
  final int? sold;

  const _ProductSold({required this.sold});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.product_sold,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            "$sold",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductUnits extends StatelessWidget {
  final ProductEntity product;

  const _ProductUnits({required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Satuan',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          ...product.units.map((unit) {
            final base = product.units.firstWhere((u) => u.isBase, orElse: () => product.units.first);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: unit.isBase
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      unit.unitName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '1 ${base.unitName} = ${unit.conversionValue} ${unit.unitName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    CurrencyFormatter.withoutSymbol(unit.price, decimalDigits: 0),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (unit.wholesalePrice != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Grosir: ${CurrencyFormatter.withoutSymbol(unit.wholesalePrice!, decimalDigits: 0)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ProductDescription extends StatelessWidget {
  final String? description;

  const _ProductDescription({required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.product_description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            description ?? AppLocalizations.of(context)!.product_noDescription,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
