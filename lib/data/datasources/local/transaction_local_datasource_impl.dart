import 'package:sqflite/sqflite.dart';

import '../../../core/common/result.dart';
import '../../../core/services/database/database_config.dart';
import '../../../core/services/database/database_service.dart';
import '../../../core/utilities/console_logger.dart';
import '../../models/ordered_product_model.dart';
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../interfaces/transaction_datasource.dart';

class TransactionLocalDatasourceImpl extends TransactionDatasource {
  final DatabaseService _databaseService;

  TransactionLocalDatasourceImpl(this._databaseService);

  int _deductionOf(OrderedProductModel orderedProduct) {
    final conversion = orderedProduct.conversionValue;
    final quantity = orderedProduct.quantity;

    if (conversion <= 0 || !quantity.isFinite) {
      cw(
        'Konversi atau qty tidak valid, potongan stok dilewati',
        title: 'Data produk rusak',
        message:
            'productId=${orderedProduct.productId} name="${orderedProduct.name}" '
            'unit=${orderedProduct.unit} qty=$quantity conversion=$conversion',
      );

      return 0;
    }

    return (quantity / conversion).round();
  }

  @override
  Future<Result<int>> createTransaction(TransactionModel transaction) async {
    try {
      final transactionId = await _databaseService.database.transaction((trx) async {
        // Create transaction
        await trx.insert(
          DatabaseConfig.transactionTableName,
          transaction.toJson()
            ..remove('orderedProducts')
            ..remove('createdBy'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (transaction.orderedProducts?.isNotEmpty ?? false) {
          // Use batch for better performance
          var batch = trx.batch();

          for (var orderedProduct in transaction.orderedProducts!) {
            // Create ordered product
            orderedProduct.transactionId = transaction.id;

            batch.insert(
              DatabaseConfig.orderedProductTableName,
              orderedProduct.toJson(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );

            // Get product
            var rawProduct = await trx.query(
              DatabaseConfig.productTableName,
              where: 'id = ?',
              whereArgs: [orderedProduct.productId],
            );

            if (rawProduct.isEmpty) continue;

            var product = ProductModel.fromJson(rawProduct.first);

            // Update product stock and sold
            int deduction = _deductionOf(orderedProduct);
            int stock = product.stock - deduction;
            int sold = product.sold + deduction;

            batch.update(
              DatabaseConfig.productTableName,
              {'stock': stock, 'sold': sold},
              where: 'id = ?',
              whereArgs: [product.id],
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          // Commit batch operations
          await batch.commit(noResult: true);
        }

        // The id has been generated in models
        return transaction.id;
      });

      return Result.success(data: transactionId);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateTransaction(TransactionModel transaction) async {
    try {
      await _databaseService.database.transaction((trx) async {
        // Update transaction
        await trx.update(
          DatabaseConfig.transactionTableName,
          transaction.toJson()
            ..remove('orderedProducts')
            ..remove('createdBy'),
          where: 'id = ?',
          whereArgs: [transaction.id],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (transaction.orderedProducts?.isNotEmpty ?? false) {
          // Use batch for better performance
          var batch = trx.batch();

          for (var orderedProduct in transaction.orderedProducts!) {
            // Update ordered product - Added proper where clause
            batch.update(
              DatabaseConfig.orderedProductTableName,
              orderedProduct.toJson(),
              where: 'id = ?',
              whereArgs: [orderedProduct.id],
            );

            // Get product
            var rawProduct = await trx.query(
              DatabaseConfig.productTableName,
              where: 'id = ?',
              whereArgs: [orderedProduct.productId],
            );

            if (rawProduct.isEmpty) continue;

            var product = ProductModel.fromJson(rawProduct.first);

            // Update product stock and sold
            int deduction = _deductionOf(orderedProduct);
            int stock = product.stock - deduction;
            int sold = product.sold + deduction;

            batch.update(
              DatabaseConfig.productTableName,
              {'stock': stock, 'sold': sold},
              where: 'id = ?',
              whereArgs: [product.id],
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          // Commit batch operations
          await batch.commit(noResult: true);
        }
      });

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updatePaymentStatus(
    int id,
    String status, {
    String? paymentQR,
    String? paymentExternalId,
  }) async {
    try {
      var values = <String, dynamic>{'paymentStatus': status};
      if (paymentQR != null) values['paymentQR'] = paymentQR;
      if (paymentExternalId != null) values['paymentExternalId'] = paymentExternalId;

      await _databaseService.database.update(
        DatabaseConfig.transactionTableName,
        values,
        where: 'id = ?',
        whereArgs: [id],
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteTransaction(int id) async {
    try {
      await _databaseService.database.transaction((trx) async {
        // Get ordered products to revert stock
        var orderedProducts = await trx.query(
          DatabaseConfig.orderedProductTableName,
          where: 'transactionId = ?',
          whereArgs: [id],
        );

        // Revert stock for each ordered product
        for (var orderedProductMap in orderedProducts) {
          var orderedProduct = OrderedProductModel.fromJson(orderedProductMap);

          // Get current product data
          var productResults = await trx.query(
            DatabaseConfig.productTableName,
            where: 'id = ?',
            whereArgs: [orderedProduct.productId],
          );

          if (productResults.isNotEmpty) {
            var product = ProductModel.fromJson(productResults.first);

            int revertDeduction = _deductionOf(orderedProduct);
            int revertedStock = product.stock + revertDeduction;
            int revertedSold = product.sold - revertDeduction;

            // Update product stock and sold count
            await trx.update(
              DatabaseConfig.productTableName,
              {'stock': revertedStock, 'sold': revertedSold},
              where: 'id = ?',
              whereArgs: [orderedProduct.productId],
            );
          }
        }

        // Delete related ordered products
        await trx.delete(
          DatabaseConfig.orderedProductTableName,
          where: 'transactionId = ?',
          whereArgs: [id],
        );

        // Then delete the transaction
        await trx.delete(
          DatabaseConfig.transactionTableName,
          where: 'id = ?',
          whereArgs: [id],
        );
      });

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<TransactionModel?>> getTransaction(int id) async {
    try {
      final transaction = await _databaseService.database.transaction((trx) async {
        // Get transaction
        var rawTransactions = await trx.query(
          DatabaseConfig.transactionTableName,
          where: 'id = ?',
          whereArgs: [id],
        );

        if (rawTransactions.isEmpty) {
          return null;
        }

        var transaction = TransactionModel.fromJson(rawTransactions.first);

        // Get transaction ordered products
        var rawOrderedProducts = await trx.query(
          DatabaseConfig.orderedProductTableName,
          where: 'transactionId = ?',
          whereArgs: [id],
        );

        var orderedProducts = rawOrderedProducts.map((e) => OrderedProductModel.fromJson(e)).toList();

        // Set ordered products to transaction
        transaction.orderedProducts = orderedProducts;

        // Get created by
        var rawCreatedBy = await trx.query(
          DatabaseConfig.userTableName,
          where: 'id = ?',
          whereArgs: [transaction.createdById],
        );

        // Set created by to transaction
        if (rawCreatedBy.isNotEmpty) {
          transaction.createdBy = UserModel.fromJson(rawCreatedBy.first);
        }

        return transaction;
      });

      return Result.success(data: transaction);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<TransactionModel>>> getAllUserTransactions(String userId) async {
    try {
      final transactions = await _databaseService.database.transaction((trx) async {
        var rawTransactions = await trx.query(
          DatabaseConfig.transactionTableName,
          where: 'createdById = ?',
          whereArgs: [userId],
          orderBy: 'createdAt DESC',
        );

        var transactions = rawTransactions.map((e) => TransactionModel.fromJson(e)).toList();

        // Use batch processing for better performance
        for (var transaction in transactions) {
          // Get transaction ordered products
          var rawOrderedProducts = await trx.query(
            DatabaseConfig.orderedProductTableName,
            where: 'transactionId = ?',
            whereArgs: [transaction.id],
          );

          var orderedProducts = rawOrderedProducts.map((e) => OrderedProductModel.fromJson(e)).toList();

          // Set ordered products to transaction
          transaction.orderedProducts = orderedProducts;

          // Get created by
          var rawCreatedBy = await trx.query(
            DatabaseConfig.userTableName,
            where: 'id = ?',
            whereArgs: [transaction.createdById],
          );

          // Set created by to transaction
          if (rawCreatedBy.isNotEmpty) {
            transaction.createdBy = UserModel.fromJson(rawCreatedBy.first);
          }
        }

        return transactions;
      });

      return Result.success(data: transactions);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<TransactionModel>>> getTransactionsByDateRange(
    String userId, {
    required String startDate,
    required String endDate,
    String? paymentStatus,
    bool showAllUsers = false,
  }) async {
    try {
      final transactions = await _databaseService.database.transaction((trx) async {
        var conditions = <String>['createdAt >= ?', 'createdAt <= ?'];
        var args = <dynamic>[startDate, endDate];

        if (!showAllUsers) {
          conditions.insert(0, 'createdById = ?');
          args.insert(0, userId);
        }
        if (paymentStatus != null) {
          conditions.add('paymentStatus = ?');
          args.add(paymentStatus);
        }

        var rawTransactions = await trx.query(
          DatabaseConfig.transactionTableName,
          where: conditions.join(' AND '),
          whereArgs: args,
          orderBy: 'createdAt DESC',
        );

        var transactions = rawTransactions.map((e) => TransactionModel.fromJson(e)).toList();

        for (var transaction in transactions) {
          var rawOrderedProducts = await trx.query(
            DatabaseConfig.orderedProductTableName,
            where: 'transactionId = ?',
            whereArgs: [transaction.id],
          );

          var orderedProducts = rawOrderedProducts.map((e) => OrderedProductModel.fromJson(e)).toList();
          transaction.orderedProducts = orderedProducts;

          var rawCreatedBy = await trx.query(
            DatabaseConfig.userTableName,
            where: 'id = ?',
            whereArgs: [transaction.createdById],
          );

          if (rawCreatedBy.isNotEmpty) {
            transaction.createdBy = UserModel.fromJson(rawCreatedBy.first);
          }
        }

        return transactions;
      });

      return Result.success(data: transactions);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<TransactionModel>>> getUserTransactions(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    try {
      final transactions = await _databaseService.database.transaction((trx) async {
        var rawTransactions = await trx.query(
          DatabaseConfig.transactionTableName,
          where: 'createdById = ? AND id LIKE ?',
          whereArgs: [userId, "%${contains ?? ''}%"],
          orderBy: '$orderBy $sortBy',
          limit: limit,
          offset: offset,
        );

        var transactions = rawTransactions.map((e) => TransactionModel.fromJson(e)).toList();

        for (var transaction in transactions) {
          // Get transaction ordered products
          var rawOrderedProducts = await trx.query(
            DatabaseConfig.orderedProductTableName,
            where: 'transactionId = ?',
            whereArgs: [transaction.id],
          );

          var orderedProducts = rawOrderedProducts.map((e) => OrderedProductModel.fromJson(e)).toList();

          // Set ordered products to transaction
          transaction.orderedProducts = orderedProducts;

          // Get created by
          var rawCreatedBy = await trx.query(
            DatabaseConfig.userTableName,
            where: 'id = ?',
            whereArgs: [transaction.createdById],
          );

          // Set created by to transaction
          if (rawCreatedBy.isNotEmpty) {
            transaction.createdBy = UserModel.fromJson(rawCreatedBy.first);
          }
        }

        return transactions;
      });

      return Result.success(data: transactions);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
