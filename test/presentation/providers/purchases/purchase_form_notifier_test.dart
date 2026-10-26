import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/app/di/app_providers.dart';
import 'package:mono_pos/core/common/result.dart';
import 'package:mono_pos/domain/entities/product_entity.dart';
import 'package:mono_pos/domain/repositories/product_repository.dart';
import 'package:mono_pos/presentation/providers/purchases/purchase_form_notifier.dart';

class _FakeProductRepository implements ProductRepository {
  String? receivedUserId;

  @override
  Future<Result<List<ProductEntity>>> getUserProducts(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    receivedUserId = userId;
    return Result.success(data: const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('searchProducts passes a non-null user id to the product repository', () async {
    final repository = _FakeProductRepository();
    final container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(purchaseFormNotifierProvider, (_, _) {});

    final notifier = container.read(purchaseFormNotifierProvider.notifier);
    final products = await notifier.searchProducts('indomie');

    expect(repository.receivedUserId, isNotNull);
    expect(products, isEmpty);
  });
}
