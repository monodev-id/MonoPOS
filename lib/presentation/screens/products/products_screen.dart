import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mono_pos/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/auth/auth_notifier.dart';
import '../../providers/products/products_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading_more_indicator.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_text_field.dart';
import 'components/products_card.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final scrollController = ScrollController();
  final searchFieldController = TextEditingController();

  @override
  void initState() {
    scrollController.addListener(scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productsNotifierProvider.notifier).getAllProducts();
    });
    super.initState();
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    searchFieldController.dispose();
    super.dispose();
  }

  void scrollListener() {
    if (!scrollController.hasClients) return;

    final productsState = ref.read(productsNotifierProvider);

    if (productsState.isLoadingMore || !productsState.hasMore) return;

    final position = scrollController.position;

    // Automatically load more data on end of scroll position
    if (position.pixels >= position.maxScrollExtent - 50) {
      ref.read(productsNotifierProvider.notifier).getAllProducts(offset: productsState.allProducts?.length);
    }
  }

  void maybeLoadMore() {
    if (!mounted || !scrollController.hasClients) return;

    final productsState = ref.read(productsNotifierProvider);

    if (productsState.isLoadingMore || !productsState.hasMore) return;
    if (productsState.allProducts == null) return;

    if (scrollController.position.maxScrollExtent <= 0) {
      ref.read(productsNotifierProvider.notifier).getAllProducts(offset: productsState.allProducts?.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => maybeLoadMore());

    final allProducts = ref.watch(productsNotifierProvider.select((s) => s.allProducts));
    final isLoadingMore = ref.watch(productsNotifierProvider.select((s) => s.isLoadingMore));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.products),
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: const [_AddButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productsNotifierProvider.notifier).getAllProducts(),
        displacement: 60,
        child: Scrollbar(
          child: CustomScrollView(
            controller: scrollController,
            // Disable scroll when data is null or empty
            physics: (allProducts?.isEmpty ?? true)
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                collapsedHeight: 70,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                  child: _SearchField(controller: searchFieldController),
                ),
              ),
              SliverLayoutBuilder(
                builder: (context, _) {
                  if (allProducts == null) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: AppProgressIndicator(),
                    );
                  }

                  if (allProducts.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      fillOverscroll: true,
                      child: AppEmptyState(
                        subtitle: AppLocalizations.of(context)!.product_noProducts,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSizes.padding, 2, AppSizes.padding, AppSizes.padding),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 1 / 1.5,
                        crossAxisSpacing: AppSizes.padding / 2,
                        mainAxisSpacing: AppSizes.padding / 2,
                      ),
                      itemCount: allProducts.length,
                      itemBuilder: (context, i) {
                        return _ProductCard(product: allProducts[i]);
                      },
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: AppLoadingMoreIndicator(isLoading: isLoadingMore),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends ConsumerWidget {
  const _AddButton();

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
              Icons.add,
              size: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSizes.padding / 4),
            Text(
              AppLocalizations.of(context)!.product_addButton,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        onTap: () => context.go('/products/product-create'),
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppTextField(
      controller: controller,
      hintText: AppLocalizations.of(context)!.product_searchHint,
      type: AppTextFieldType.search,
      textInputAction: TextInputAction.search,
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
        ref.read(productsNotifierProvider.notifier).resetProducts();
        ref.read(productsNotifierProvider.notifier).getAllProducts(contains: controller.text);
      },
      onTapClearButton: () {
        ref.read(productsNotifierProvider.notifier).getAllProducts(contains: controller.text);
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductEntity product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return ProductsCard(
      product: product,
      onTap: () => context.go('/products/product-detail/${product.id}'),
    );
  }
}
