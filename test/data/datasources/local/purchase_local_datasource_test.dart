import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/core/services/database/database_config.dart';
import 'package:mono_pos/core/services/database/database_service.dart';
import 'package:mono_pos/data/datasources/local/purchase_local_datasource_impl.dart';
import 'package:mono_pos/data/models/purchase_item_model.dart';
import 'package:mono_pos/data/models/purchase_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService appDatabase;
  late PurchaseLocalDatasourceImpl datasource;
  late Database testDatabase;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    testDatabase = await openDatabase(inMemoryDatabasePath, version: 1);

    appDatabase = DatabaseService.instance;
    await appDatabase.initTestDatabase(testDatabase: testDatabase);

    datasource = PurchaseLocalDatasourceImpl(appDatabase);
  });

  tearDownAll(() async {
    await testDatabase.close();
  });

  setUp(() async {
    await testDatabase.delete(DatabaseConfig.purchaseItemTableName);
    await testDatabase.delete(DatabaseConfig.purchaseTableName);
    await testDatabase.delete(DatabaseConfig.productTableName);
  });

  Future<void> createProduct({int id = 1, int stock = 0, int costPrice = 0}) async {
    await testDatabase.insert(DatabaseConfig.productTableName, {
      'id': id,
      'createdById': 'admin',
      'name': 'Product $id',
      'imageUrl': '',
      'stock': stock,
      'sold': 0,
      'price': 50000,
      'costPrice': costPrice,
      'unit': 'pcs',
    });
  }

  Future<int?> stockOf(int productId) async {
    final rows = await testDatabase.query(
      DatabaseConfig.productTableName,
      columns: ['stock'],
      where: 'id = ?',
      whereArgs: [productId],
    );
    return rows.first['stock'] as int?;
  }

  Future<int?> costPriceOf(int productId) async {
    final rows = await testDatabase.query(
      DatabaseConfig.productTableName,
      columns: ['costPrice'],
      where: 'id = ?',
      whereArgs: [productId],
    );
    return rows.first['costPrice'] as int?;
  }

  PurchaseItemModel buildItem({
    int productId = 1,
    String unitName = 'pcs',
    int conversionValue = 1,
    double quantity = 1,
    int unitPrice = 10000,
  }) {
    return PurchaseItemModel(
      productId: productId,
      productName: 'Product $productId',
      unitName: unitName,
      conversionValue: conversionValue,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: (quantity * unitPrice).round(),
      baseUnitPrice: (unitPrice / conversionValue).round(),
    );
  }

  PurchaseModel buildPurchase({
    required int id,
    String supplierId = 'supplier-1',
    String supplierName = 'Sumber Rejeki',
    required String purchaseDate,
    required List<PurchaseItemModel> items,
    bool addStock = true,
  }) {
    return PurchaseModel(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName,
      purchaseDate: purchaseDate,
      totalAmount: items.fold(0, (total, item) => total + item.totalPrice),
      totalItems: items.length,
      addStock: addStock,
      items: items,
    );
  }

  group('PurchaseLocalDatasourceImpl', () {
    group('createPurchase', () {
      test('adds stock using quantity / conversionValue rounding convention', () async {
        await createProduct(id: 1, stock: 10);

        final res = await datasource.createPurchase(
          buildPurchase(
            id: 1,
            purchaseDate: '2026-01-10',
            items: [
              buildItem(productId: 1, unitName: 'dus', conversionValue: 12, quantity: 24, unitPrice: 120000),
            ],
          ),
        );

        expect(res.isSuccess, isTrue);
        expect(await stockOf(1), 12);
        expect(await costPriceOf(1), 10000);
      });

      test('can skip stock increase while still updating cost price', () async {
        await createProduct(id: 1, stock: 7);

        final res = await datasource.createPurchase(
          buildPurchase(
            id: 1,
            purchaseDate: '2026-01-10',
            addStock: false,
            items: [buildItem(productId: 1, quantity: 5, unitPrice: 8000)],
          ),
        );

        expect(res.isSuccess, isTrue);
        expect(await stockOf(1), 7);
        expect(await costPriceOf(1), 8000);
      });

      test('stores purchase items and header totals', () async {
        await createProduct(id: 1);

        final res = await datasource.createPurchase(
          buildPurchase(
            id: 10,
            purchaseDate: '2026-01-10',
            items: [buildItem(productId: 1, quantity: 2, unitPrice: 15000)],
          ),
        );

        expect(res.isSuccess, isTrue);

        final purchase = await datasource.getPurchase(10);
        expect(purchase.data?.supplierName, 'Sumber Rejeki');
        expect(purchase.data?.totalAmount, 30000);
        expect(purchase.data?.totalItems, 1);
        expect(purchase.data?.items?.first.baseUnitPrice, 15000);
      });

      test('latest purchase date wins for product cost price', () async {
        await createProduct(id: 1);

        await datasource.createPurchase(
          buildPurchase(
            id: 1,
            purchaseDate: '2026-01-10',
            items: [buildItem(productId: 1, quantity: 1, unitPrice: 9000)],
          ),
        );
        await datasource.createPurchase(
          buildPurchase(
            id: 2,
            purchaseDate: '2026-02-10',
            items: [buildItem(productId: 1, quantity: 1, unitPrice: 11000)],
          ),
        );
        // Older date entered last must not override the newest purchase date.
        await datasource.createPurchase(
          buildPurchase(
            id: 3,
            purchaseDate: '2025-12-10',
            items: [buildItem(productId: 1, quantity: 1, unitPrice: 5000)],
          ),
        );

        expect(await costPriceOf(1), 11000);
      });
    });

    group('latest price queries', () {
      test('getLatestPurchaseItem returns latest price for a specific supplier', () async {
        await createProduct(id: 1);

        await datasource.createPurchase(
          buildPurchase(
            id: 1,
            supplierId: 's1',
            supplierName: 'Supplier A',
            purchaseDate: '2026-01-01',
            items: [buildItem(productId: 1, quantity: 1, unitPrice: 7000)],
          ),
        );
        await datasource.createPurchase(
          buildPurchase(
            id: 2,
            supplierId: 's2',
            supplierName: 'Supplier B',
            purchaseDate: '2026-02-01',
            items: [buildItem(productId: 1, quantity: 1, unitPrice: 8000)],
          ),
        );
        await datasource.createPurchase(
          buildPurchase(
            id: 3,
            supplierId: 's1',
            supplierName: 'Supplier A',
            purchaseDate: '2026-03-01',
            items: [buildItem(productId: 1, quantity: 1, unitPrice: 6000)],
          ),
        );

        final fromS1 = await datasource.getLatestPurchaseItem(1, supplierId: 's1');
        expect(fromS1.data?.unitPrice, 6000);
        expect(fromS1.data?.supplierName, 'Supplier A');

        final any = await datasource.getLatestPurchaseItem(1);
        expect(any.data?.unitPrice, 6000);
      });

      test('getLatestPurchaseItemsBySupplier returns one latest item per supplier', () async {
        await createProduct(id: 1);

        await datasource.createPurchase(
          buildPurchase(
            id: 1,
            supplierId: 's1',
            supplierName: 'Supplier A',
            purchaseDate: '2026-01-01',
            items: [buildItem(productId: 1, quantity: 1, unitPrice: 7000)],
          ),
        );
        await datasource.createPurchase(
          buildPurchase(
            id: 2,
            supplierId: 's2',
            supplierName: 'Supplier B',
            purchaseDate: '2026-02-01',
            items: [buildItem(productId: 1, quantity: 1, unitPrice: 8000)],
          ),
        );
        await datasource.createPurchase(
          buildPurchase(
            id: 3,
            supplierId: 's1',
            supplierName: 'Supplier A',
            purchaseDate: '2026-03-01',
            items: [buildItem(productId: 1, quantity: 1, unitPrice: 6500)],
          ),
        );

        final result = await datasource.getLatestPurchaseItemsBySupplier(1);

        expect(result.data?.length, 2);
        expect(
          result.data?.map((e) => '${e.supplierId}:${e.unitPrice}').toSet(),
          {'s1:6500', 's2:8000'},
        );
      });

      test('getProductPurchaseHistory returns newest purchases first', () async {
        await createProduct(id: 1);

        await datasource.createPurchase(
          buildPurchase(
            id: 1,
            purchaseDate: '2026-01-01',
            items: [buildItem(productId: 1, quantity: 1, unitPrice: 7000)],
          ),
        );
        await datasource.createPurchase(
          buildPurchase(
            id: 2,
            purchaseDate: '2026-02-01',
            items: [buildItem(productId: 1, quantity: 1, unitPrice: 8000)],
          ),
        );

        final result = await datasource.getProductPurchaseHistory(1);

        expect(result.data?.map((e) => e.unitPrice), [8000, 7000]);
      });
    });

    group('deletePurchase', () {
      test('rolls back stock and recalculates cost price', () async {
        await createProduct(id: 1, stock: 0);

        await datasource.createPurchase(
          buildPurchase(
            id: 1,
            purchaseDate: '2026-01-01',
            items: [buildItem(productId: 1, quantity: 5, unitPrice: 10000)],
          ),
        );
        await datasource.createPurchase(
          buildPurchase(
            id: 2,
            purchaseDate: '2026-02-01',
            items: [buildItem(productId: 1, quantity: 3, unitPrice: 12000)],
          ),
        );

        expect(await stockOf(1), 8);
        expect(await costPriceOf(1), 12000);

        await datasource.deletePurchase(2);

        expect(await stockOf(1), 5);
        expect(await costPriceOf(1), 10000);

        await datasource.deletePurchase(1);

        expect(await stockOf(1), 0);
        expect(await costPriceOf(1), 0);
      });

      test('does not change stock when purchase was saved without stock increase', () async {
        await createProduct(id: 1, stock: 4);

        await datasource.createPurchase(
          buildPurchase(
            id: 1,
            purchaseDate: '2026-01-01',
            addStock: false,
            items: [buildItem(productId: 1, quantity: 2, unitPrice: 10000)],
          ),
        );

        await datasource.deletePurchase(1);

        expect(await stockOf(1), 4);
        expect(await costPriceOf(1), 0);
      });

      test('never lowers stock below zero', () async {
        await createProduct(id: 1, stock: 1);

        await datasource.createPurchase(
          buildPurchase(
            id: 1,
            purchaseDate: '2026-01-01',
            items: [buildItem(productId: 1, quantity: 5, unitPrice: 10000)],
          ),
        );
        expect(await stockOf(1), 6);

        // Simulate stock being sold before the purchase is deleted.
        await testDatabase.update(
          DatabaseConfig.productTableName,
          {'stock': 0},
          where: 'id = ?',
          whereArgs: [1],
        );

        await datasource.deletePurchase(1);

        expect(await stockOf(1), 0);
      });
    });

    group('getPurchases', () {
      test('filters by supplier and search keyword', () async {
        await createProduct(id: 1);

        await datasource.createPurchase(
          buildPurchase(
            id: 1,
            supplierId: 's1',
            supplierName: 'Supplier A',
            purchaseDate: '2026-01-01',
            items: [buildItem(productId: 1)],
          ),
        );
        await datasource.createPurchase(
          buildPurchase(
            id: 2,
            supplierId: 's2',
            supplierName: 'Supplier B',
            purchaseDate: '2026-02-01',
            items: [buildItem(productId: 1)],
          ),
        );

        final bySupplier = await datasource.getPurchases(supplierId: 's2');
        expect(bySupplier.data?.map((e) => e.id), [2]);

        final byKeyword = await datasource.getPurchases(query: 'Supplier A');
        expect(byKeyword.data?.map((e) => e.id), [1]);
      });

      test('countPurchasesBySupplier counts matching notes', () async {
        await createProduct(id: 1);

        await datasource.createPurchase(
          buildPurchase(
            id: 1,
            supplierId: 's1',
            purchaseDate: '2026-01-01',
            items: [buildItem(productId: 1)],
          ),
        );
        await datasource.createPurchase(
          buildPurchase(
            id: 2,
            supplierId: 's2',
            purchaseDate: '2026-02-01',
            items: [buildItem(productId: 1)],
          ),
        );

        final result = await datasource.countPurchasesBySupplier('s1');
        expect(result.data, 1);
      });
    });
  });
}
