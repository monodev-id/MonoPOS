import 'package:mono_pos/core/services/database/database_service.dart';
import 'package:mono_pos/data/datasources/local/product_local_datasource_impl.dart';
import 'package:mono_pos/data/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService appDatabase;
  late ProductLocalDatasourceImpl datasource;
  late Database testDatabase;

  setUpAll(() async {
    // Initialize FFI (Foreign Function Interface) for SQFlite
    sqfliteFfiInit();
    // Change the default factory for unit testing calls to use FFI
    databaseFactory = databaseFactoryFfi;

    // Open an in-memory database for testing
    testDatabase = await openDatabase(inMemoryDatabasePath, version: 1);

    appDatabase = DatabaseService.instance;
    await appDatabase.initTestDatabase(testDatabase: testDatabase);

    datasource = ProductLocalDatasourceImpl(appDatabase);
  });

  const userId = "user123";

  ProductModel createSampleProduct({int id = 1, String? barcode}) {
    return ProductModel(
      id: id,
      name: 'Sample Product',
      createdById: userId,
      imageUrl: '',
      price: 42,
      sold: 10,
      stock: 50,
      barcode: barcode,
    );
  }

  group('ProductLocalDatasourceImpl', () {
    group('createProduct', () {
      test('should insert product into the database and return product id', () async {
        final product = createSampleProduct();
        final result = await datasource.createProduct(product);

        expect(result.data, equals(product.id));
      });

      test('should create multiple products successfully', () async {
        final product1 = createSampleProduct(id: 1);
        final product2 = createSampleProduct(id: 2);

        final result1 = await datasource.createProduct(product1);
        final result2 = await datasource.createProduct(product2);

        expect(result1.data, equals(1));
        expect(result2.data, equals(2));
      });
    });

    group('updateProduct', () {
      test('should update existing product in the database', () async {
        final product = createSampleProduct();
        await datasource.createProduct(product);

        final updatedProduct = product
          ..name = 'Updated Product'
          ..price = 100;

        await expectLater(
          datasource.updateProduct(updatedProduct),
          completes,
        );

        final retrieved = await datasource.getProduct(product.id);
        expect(retrieved.data?.name, equals('Updated Product'));
        expect(retrieved.data?.price, equals(100));
      });

      test('should complete even if product does not exist', () async {
        final product = createSampleProduct();

        await expectLater(
          datasource.updateProduct(product),
          completes,
        );
      });
    });

    group('getProduct', () {
      test('should retrieve existing product from the database', () async {
        final product = createSampleProduct();
        await datasource.createProduct(product);

        final result = await datasource.getProduct(product.id);

        expect(result, isNotNull);
        expect(result.data?.id, equals(product.id));
        expect(result.data?.name, equals(product.name));
        expect(result.data?.price, equals(product.price));
      });

      test('should return null when product does not exist', () async {
        final result = await datasource.getProduct(999);

        expect(result.data, isNull);
      });
    });

    group('getAllUserProducts', () {
      test('should retrieve all products for a given user', () async {
        final product1 = createSampleProduct(id: 1);
        final product2 = createSampleProduct(id: 2);

        await datasource.createProduct(product1);
        await datasource.createProduct(product2);

        final result = await datasource.getAllUserProducts(userId);

        expect(result.data, isNotEmpty);
        expect(result.data?.length, equals(2));
        expect(result.data?.any((p) => p.id == 1), isTrue);
        expect(result.data?.any((p) => p.id == 2), isTrue);
      });

      test('should return all products even when user has no products of their own', () async {
        final result = await datasource.getAllUserProducts('nonexistent_user');

        expect(result.data, isNotEmpty);
      });

      test('should return products from other users (shared catalog)', () async {
        final product = createSampleProduct();
        await datasource.createProduct(product);

        final result = await datasource.getAllUserProducts('different_user');

        expect(result.data, isNotEmpty);
      });
    });

    group('getProductByBarcode', () {
      test('should find product by barcode', () async {
        const barcode = '8991234567890';
        final product = createSampleProduct(id: 10, barcode: barcode);
        await datasource.createProduct(product);

        final result = await datasource.getProductByBarcode(barcode);

        expect(result.data, isNotNull);
        expect(result.data?.id, equals(10));
        expect(result.data?.barcode, equals(barcode));
      });

      test('should return null when barcode does not match any product', () async {
        final result = await datasource.getProductByBarcode('nonexistent-barcode');

        expect(result.data, isNull);
      });

      test('should find correct product among multiple products', () async {
        await datasource.createProduct(createSampleProduct(id: 1, barcode: 'barcode-1'));
        await datasource.createProduct(createSampleProduct(id: 2, barcode: 'barcode-2'));
        await datasource.createProduct(createSampleProduct(id: 3, barcode: 'barcode-3'));

        final result = await datasource.getProductByBarcode('barcode-2');

        expect(result.data, isNotNull);
        expect(result.data?.id, equals(2));
        expect(result.data?.barcode, equals('barcode-2'));
      });
    });

    group('deleteProduct', () {
      test('should delete existing product from the database', () async {
        final product = createSampleProduct();
        await datasource.createProduct(product);

        await expectLater(
          datasource.deleteProduct(product.id),
          completes,
        );

        final retrieved = await datasource.getProduct(product.id);
        expect(retrieved.data, isNull);
      });

      test('should complete even if product does not exist', () async {
        await expectLater(
          datasource.deleteProduct(999),
          completes,
        );
      });
    });

    group('getLowStockProducts', () {
      setUpAll(() async {
        await testDatabase.delete('Product');

        await datasource.createProduct(
          ProductModel(
            id: 100,
            name: 'No Stock',
            createdById: userId,
            imageUrl: '',
            price: 1000,
            sold: 0,
            stock: 0,
          ),
        );
        await datasource.createProduct(
          ProductModel(
            id: 101,
            name: 'Low Stock 1',
            createdById: userId,
            imageUrl: '',
            price: 2000,
            sold: 0,
            stock: 2,
          ),
        );
        await datasource.createProduct(
          ProductModel(
            id: 102,
            name: 'Low Stock 5',
            createdById: userId,
            imageUrl: '',
            price: 3000,
            sold: 0,
            stock: 5,
          ),
        );
        await datasource.createProduct(
          ProductModel(
            id: 103,
            name: 'Normal Stock',
            createdById: userId,
            imageUrl: '',
            price: 4000,
            sold: 0,
            stock: 20,
          ),
        );
        await datasource.createProduct(
          ProductModel(
            id: 104,
            name: 'Low Stock 3',
            createdById: 'other_user',
            imageUrl: '',
            price: 5000,
            sold: 0,
            stock: 3,
          ),
        );
      });

      test('should return products with stock > 0 and stock <= threshold', () async {
        final result = await datasource.getLowStockProducts(userId, 5);

        expect(result.isSuccess, true);
        expect(result.data!.length, equals(3));
        expect(result.data!.any((p) => p.name == 'Low Stock 1'), isTrue);
        expect(result.data!.any((p) => p.name == 'Low Stock 5'), isTrue);
      });

      test('should not include out-of-stock products (stock = 0)', () async {
        final result = await datasource.getLowStockProducts(userId, 5);

        expect(result.data!.any((p) => p.name == 'No Stock'), isFalse);
      });

      test('should not include products above threshold', () async {
        final result = await datasource.getLowStockProducts(userId, 5);

        expect(result.data!.any((p) => p.name == 'Normal Stock'), isFalse);
      });

      test('should include products from other users (shared catalog)', () async {
        final result = await datasource.getLowStockProducts(userId, 5);

        expect(result.data!.any((p) => p.name == 'Low Stock 3'), isTrue);
      });

      test('should return results sorted by stock ascending', () async {
        final result = await datasource.getLowStockProducts(userId, 5);

        expect(result.data!.first.stock, lessThanOrEqualTo(result.data!.last.stock));
      });

      test('should return empty list when no low stock products exist', () async {
        final result = await datasource.getLowStockProducts(userId, 0);

        expect(result.isSuccess, true);
        expect(result.data, isEmpty);
      });

      test('should respect different threshold values', () async {
        final result = await datasource.getLowStockProducts(userId, 2);

        expect(result.data!.length, equals(1));
        expect(result.data!.first.name, equals('Low Stock 1'));
      });
    });
  });
}
