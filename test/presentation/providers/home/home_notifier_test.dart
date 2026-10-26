import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/app/di/app_providers.dart';
import 'package:mono_pos/domain/entities/product_entity.dart';
import 'package:mono_pos/domain/entities/product_unit_entity.dart';
import 'package:mono_pos/domain/repositories/product_repository.dart';
import 'package:mono_pos/presentation/providers/home/home_notifier.dart';
import 'package:mono_pos/presentation/providers/products/products_notifier.dart';

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

  test('scan stores every product unit on the cart line without relying on list cache', () async {
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
        ProductUnitEntity(productId: 1, unitName: 'pack', conversionValue: 6, price: 20000),
        ProductUnitEntity(productId: 1, unitName: 'dus', conversionValue: 24, price: 75000),
      ],
    );

    await notifier.addScannedProduct(product);

    final ordered = container.read(homeNotifierProvider).orderedProducts.single;

    expect(container.read(berandaProductsNotifierProvider).allProducts, isNull);
    expect(ordered.units.map((e) => e.unitName), ['pcs', 'pack', 'dus']);
  });

  test('changing cart unit uses the stored unit snapshot when product is not cached', () async {
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
        ProductUnitEntity(productId: 1, unitName: 'dus', conversionValue: 24, price: 75000),
      ],
    );

    await notifier.addScannedProduct(product);
    await notifier.onChangedOrderedProductUnit(0, 'dus');

    final ordered = container.read(homeNotifierProvider).orderedProducts.single;

    expect(ordered.unit, 'dus');
    expect(ordered.conversionValue, 24);
    expect(ordered.price, 75000);
    expect(ordered.units.map((e) => e.unitName), ['pcs', 'dus']);
  });

  test('legacy product without unit rows gets a synthetic base unit snapshot', () async {
    final container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(_FakeProductRepository())],
    );
    addTearDown(container.dispose);
    container.listen(homeNotifierProvider, (_, _) {});

    final notifier = container.read(homeNotifierProvider.notifier);
    await notifier.addScannedProduct(_product(unit: 'pcs'));

    final ordered = container.read(homeNotifierProvider).orderedProducts.single;

    expect(ordered.units, hasLength(1));
    expect(ordered.units.single.unitName, 'pcs');
    expect(ordered.units.single.conversionValue, 1);
    expect(ordered.units.single.price, 3500);
    expect(ordered.units.single.isBase, isTrue);
  });
}
