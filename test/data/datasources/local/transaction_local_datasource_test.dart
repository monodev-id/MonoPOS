import 'package:mono_pos/core/services/database/database_config.dart';
import 'package:mono_pos/core/services/database/database_service.dart';
import 'package:mono_pos/data/datasources/local/transaction_local_datasource_impl.dart';
import 'package:mono_pos/data/models/ordered_product_model.dart';
import 'package:mono_pos/data/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService appDatabase;
  late TransactionLocalDatasourceImpl datasource;
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

    datasource = TransactionLocalDatasourceImpl(appDatabase);
  });

  const userId = "user123";
  const seedProductId = 99;

  Future<void> seedProduct() async {
    await testDatabase.insert(
      DatabaseConfig.productTableName,
      {
        'id': seedProductId,
        'name': 'Seed Product',
        'createdById': userId,
        'imageUrl': '',
        'stock': 10,
        'sold': 0,
        'price': 1000,
        'unit': 'pcs',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<(int stock, int sold)> seedProductStock() async {
    final rows = await testDatabase.query(
      DatabaseConfig.productTableName,
      where: 'id = ?',
      whereArgs: [seedProductId],
    );

    return ((rows.first['stock'] as num).toInt(), (rows.first['sold'] as num).toInt());
  }

  TransactionModel createSampleTransaction({
    int id = 1,
    String createdById = userId,
    int totalAmount = 1,
    int productId = 1,
    double quantity = 1,
    int conversionValue = 1,
  }) {
    return TransactionModel(
      id: id,
      createdById: createdById,
      paymentMethod: 'Cash',
      receivedAmount: totalAmount,
      returnAmount: 0,
      totalAmount: totalAmount,
      totalOrderedProduct: 1,
      orderedProducts: [
        OrderedProductModel(
          id: 1,
          transactionId: id,
          productId: productId,
          quantity: quantity,
          stock: 1,
          name: 'Sample Product',
          imageUrl: '',
          price: totalAmount,
          conversionValue: conversionValue,
        ),
      ],
    );
  }

  group('TransactionLocalDatasourceImpl', () {
    // Test: createTransaction inserts the transaction into the database
    group('createTransaction', () {
      test('should insert transaction into the database and return transaction id', () async {
        final transaction = createSampleTransaction();

        final result = await datasource.createTransaction(transaction);

        expect(result.data, equals(transaction.id));
      });

      test('should create multiple transactions successfully', () async {
        final transaction1 = createSampleTransaction(id: 1);
        final transaction2 = createSampleTransaction(id: 2);

        final result1 = await datasource.createTransaction(transaction1);
        final result2 = await datasource.createTransaction(transaction2);

        expect(result1.data, equals(1));
        expect(result2.data, equals(2));
      });

      test('should store ordered products with the transaction', () async {
        final transaction = createSampleTransaction();

        await datasource.createTransaction(transaction);
        final retrieved = await datasource.getTransaction(transaction.id);

        expect(retrieved.data?.orderedProducts, isNotEmpty);
        expect(retrieved.data?.orderedProducts?.length, equals(1));
        expect(retrieved.data?.orderedProducts?.first.productId, equals(1));
      });
    });

    group('updateTransaction', () {
      test('should update existing transaction in the database', () async {
        final transaction = createSampleTransaction();
        await datasource.createTransaction(transaction);

        final updatedTransaction = createSampleTransaction(
          id: transaction.id,
          totalAmount: 100,
        );

        await expectLater(
          datasource.updateTransaction(updatedTransaction),
          completes,
        );

        final retrieved = await datasource.getTransaction(transaction.id);
        expect(retrieved.data?.totalAmount, equals(100));
      });

      test('should complete even if transaction does not exist', () async {
        final transaction = createSampleTransaction();
        await datasource.createTransaction(transaction);

        final updatedTransaction = createSampleTransaction(
          id: transaction.id,
          totalAmount: 100,
        );

        await expectLater(
          datasource.updateTransaction(updatedTransaction),
          completes,
        );
      });
    });

    group('getTransaction', () {
      test('should retrieve existing transaction from the database', () async {
        final transaction = createSampleTransaction();
        await datasource.createTransaction(transaction);

        final result = await datasource.getTransaction(transaction.id);

        expect(result.data, isNotNull);
        expect(result.data?.id, equals(transaction.id));
        expect(result.data?.createdById, equals(userId));
        expect(result.data?.paymentMethod, equals('Cash'));
        expect(result.data?.totalAmount, equals(transaction.totalAmount));
      });

      test('should return null when transaction does not exist', () async {
        final result = await datasource.getTransaction(999);

        expect(result.data, isNull);
      });

      test('should retrieve transaction with all ordered products', () async {
        final transaction = createSampleTransaction();
        await datasource.createTransaction(transaction);

        final result = await datasource.getTransaction(transaction.id);

        expect(result.data?.orderedProducts, isNotEmpty);
        expect(result.data?.totalOrderedProduct, equals(1));
      });
    });

    group('getAllUserTransactions', () {
      test('should retrieve all transactions for a given user', () async {
        final transaction1 = createSampleTransaction(id: 1);
        final transaction2 = createSampleTransaction(id: 2);

        await datasource.createTransaction(transaction1);
        await datasource.createTransaction(transaction2);

        final result = await datasource.getAllUserTransactions(userId);

        expect(result.data, isNotEmpty);
        expect(result.data?.length, equals(2));
        expect(result.data?.any((t) => t.id == 1), isTrue);
        expect(result.data?.any((t) => t.id == 2), isTrue);
      });

      test('should return empty list when user has no transactions', () async {
        final result = await datasource.getAllUserTransactions('nonexistent_user');

        expect(result.data, isEmpty);
      });

      test('should not return transactions from other users', () async {
        final transaction = createSampleTransaction();
        await datasource.createTransaction(transaction);

        final result = await datasource.getAllUserTransactions('different_user');

        expect(result.data, isEmpty);
      });

      test('should retrieve transactions with ordered products', () async {
        final transaction = createSampleTransaction();
        await datasource.createTransaction(transaction);

        final result = await datasource.getAllUserTransactions(userId);

        expect(result.data?.first.orderedProducts, isNotEmpty);
        expect(result.data?.first.orderedProducts?.length, equals(1));
      });
    });

    group('deleteTransaction', () {
      test('should delete existing transaction from the database', () async {
        final transaction = createSampleTransaction();
        await datasource.createTransaction(transaction);

        await expectLater(
          datasource.deleteTransaction(transaction.id),
          completes,
        );

        final retrieved = await datasource.getTransaction(transaction.id);
        expect(retrieved.data, isNull);
      });

      test('should complete even if transaction does not exist', () async {
        await expectLater(
          datasource.deleteTransaction(999),
          completes,
        );
      });

      test('should delete transaction and its ordered products', () async {
        final transaction = createSampleTransaction();
        await datasource.createTransaction(transaction);

        await datasource.deleteTransaction(transaction.id);

        final retrieved = await datasource.getTransaction(transaction.id);
        expect(retrieved.data, isNull);
      });
    });

    group('stock deduction', () {
      setUp(() async {
        await seedProduct();
      });

      test('should deduct stock by quantity divided by conversionValue', () async {
        final transaction = createSampleTransaction(
          id: 500,
          productId: seedProductId,
          quantity: 4,
          conversionValue: 2,
        );

        final result = await datasource.createTransaction(transaction);

        expect(result.isFailure, isFalse, reason: '${result.error}');

        final (stock, sold) = await seedProductStock();
        expect(stock, equals(8));
        expect(sold, equals(2));
      });

      test('should not fail when conversionValue is 0', () async {
        final transaction = createSampleTransaction(
          id: 501,
          productId: seedProductId,
          quantity: 3,
          conversionValue: 0,
        );

        final result = await datasource.createTransaction(transaction);

        expect(result.isFailure, isFalse, reason: '${result.error}');
        expect(result.data, equals(501));

        final (stock, sold) = await seedProductStock();
        expect(stock, equals(10));
        expect(sold, equals(0));
      });

      test('should not fail when quantity is not finite', () async {
        final transaction = createSampleTransaction(
          id: 502,
          productId: seedProductId,
          quantity: double.infinity,
        );

        final result = await datasource.createTransaction(transaction);

        expect(result.isFailure, isFalse, reason: '${result.error}');

        final (stock, sold) = await seedProductStock();
        expect(stock, equals(10));
        expect(sold, equals(0));
      });

      test('should not fail on updateTransaction when conversionValue is 0', () async {
        final transaction = createSampleTransaction(
          id: 503,
          productId: seedProductId,
          quantity: 3,
          conversionValue: 0,
        );
        await datasource.createTransaction(transaction);

        final updated = createSampleTransaction(
          id: 503,
          totalAmount: 100,
          productId: seedProductId,
          quantity: 3,
          conversionValue: 0,
        );

        final result = await datasource.updateTransaction(updated);

        expect(result.isSuccess, isTrue, reason: '${result.error}');
      });

      test('should not fail on deleteTransaction when conversionValue is 0', () async {
        final transaction = createSampleTransaction(
          id: 504,
          productId: seedProductId,
          quantity: 3,
          conversionValue: 0,
        );
        await datasource.createTransaction(transaction);

        final result = await datasource.deleteTransaction(transaction.id);

        expect(result.isSuccess, isTrue, reason: '${result.error}');

        final (stock, sold) = await seedProductStock();
        expect(stock, equals(10));
        expect(sold, equals(0));
      });
    });
  });
}
