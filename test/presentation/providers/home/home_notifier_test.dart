import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/app/di/app_providers.dart';
import 'package:mono_pos/domain/entities/product_entity.dart';
import 'package:mono_pos/domain/entities/product_unit_entity.dart';
import 'package:mono_pos/domain/repositories/product_repository.dart';
import 'package:mono_pos/presentation/providers/home/home_notifier.dart';

class _FakeProductRepository implements ProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProductEntity _product({
  required String unit,
  List<ProductUnitEntity> units = const [],
}) {
  return ProductEntity(
    id: 1,
    createdById: 'user-1',
    name: 'Indomie',
    imageUrl: '',
    stock: 100,
    price: 3500,
    unit: unit,
    barcode: '8998866200017',
    units: units,
  );
}

void main() {
  test('scan adds the base unit and increments quantity on repeated scans', () async {
    final container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(_FakeProductRepository())],
    );
    addTearDown(container.dispose);
    container.listen(homeNotifierProvider, (_, _) {});

    final notifier = container.read(homeNotifierProvider.notifier);
    final product = _product(
      unit: 'pcs',
      units: const [
        ProductUnitEntity(productId: 1, unitName: 'pcs', conversionValue: 1, price: 3500, isBase: true),
        ProductUnitEntity(productId: 1, unitName: 'dus', conversionValue: 12, price: 40000),
      ],
    );

    final first = await notifier.addScannedProduct(product);
    final second = await notifier.addScannedProduct(product);

    expect(first.unit, 'pcs');
    expect(second.quantity, 2);

    final ordered = container.read(homeNotifierProvider).orderedProducts;
    expect(ordered, hasLength(1));
    expect(ordered.single.unit, 'pcs');
    expect(ordered.single.quantity, 2);
  });

  test('scan keeps lines in different units separate', () async {
    final container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(_FakeProductRepository())],
    );
    addTearDown(container.dispose);
    container.listen(homeNotifierProvider, (_, _) {});

    final notifier = container.read(homeNotifierProvider.notifier);
    final product = _product(
      unit: 'pcs',
      units: const [
        ProductUnitEntity(productId: 1, unitName: 'pcs', conversionValue: 1, price: 3500, isBase: true),
        ProductUnitEntity(productId: 1, unitName: 'dus', conversionValue: 12, price: 40000),
      ],
    );

    await notifier.onAddOrderedProduct(product, 1, unitName: 'dus', conversionValue: 12);
    await notifier.addScannedProduct(product);

    final ordered = container.read(homeNotifierProvider).orderedProducts;

    expect(ordered, hasLength(2));
    expect(ordered.where((e) => e.unit == 'dus').single.quantity, 1);
    expect(ordered.where((e) => e.unit == 'pcs').single.quantity, 1);
  });
}
