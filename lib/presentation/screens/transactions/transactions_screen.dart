import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/transactions/transactions_notifier.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_loading_more_indicator.dart';
import '../../widgets/app_progress_indicator.dart';
import '../../widgets/app_text_field.dart';
import 'components/transaction_card.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final scrollController = ScrollController();
  final searchFieldController = TextEditingController();

  @override
  void initState() {
    scrollController.addListener(scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsNotifierProvider.notifier).getAllTransactions();
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

  void scrollListener() async {
    final transactionsState = ref.read(transactionsNotifierProvider);

    // Automatically load more data on end of scroll position
    if (scrollController.offset == scrollController.position.maxScrollExtent) {
      await ref
          .read(transactionsNotifierProvider.notifier)
          .getAllTransactions(
            offset: transactionsState.allTransactions?.length,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionsNotifierProvider.select((s) => s.allTransactions));
    final isLoadingMore = ref.watch(transactionsNotifierProvider.select((s) => s.isLoadingMore));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.transactions),
        elevation: 0,
        shadowColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.directQris_title,
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: () => context.push('/payment/direct'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsNotifierProvider.notifier).getAllTransactions(),
        displacement: 60,
        child: Scrollbar(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
              child: CustomScrollView(
                controller: scrollController,
                // Disable scroll when data is null or empty
                physics: (allTransactions?.isEmpty ?? true)
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
                    builder: (context, constraint) {
                      if (allTransactions == null) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          fillOverscroll: true,
                          child: AppProgressIndicator(),
                        );
                      }

                      if (allTransactions.isEmpty) {
                        return SliverFillRemaining(
                          hasScrollBody: false,
                          fillOverscroll: true,
                          child: AppEmptyState(
                            subtitle: AppLocalizations.of(context)!.transaction_noTransaction,
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(AppSizes.padding, 2, AppSizes.padding, AppSizes.padding),
                        sliver: SliverList.builder(
                          itemCount: allTransactions.length,
                          itemBuilder: (context, i) {
                            return TransactionCard(transaction: allTransactions[i]);
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
        ),
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
      hintText: AppLocalizations.of(context)!.transaction_searchHint,
      type: AppTextFieldType.search,
      textInputAction: TextInputAction.search,
      onEditingComplete: () {
        FocusScope.of(context).unfocus();
        ref.read(transactionsNotifierProvider.notifier).resetTransactions();
        ref.read(transactionsNotifierProvider.notifier).getAllTransactions(contains: controller.text);
      },
      onTapClearButton: () {
        ref.read(transactionsNotifierProvider.notifier).getAllTransactions(contains: controller.text);
      },
    );
  }
}
