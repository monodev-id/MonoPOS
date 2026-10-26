import 'package:sqflite/sqflite.dart';

import '../../../core/common/result.dart';
import '../../../core/services/database/database_config.dart';
import '../../../core/services/database/database_service.dart';
import '../../models/purchase_item_model.dart';
import '../../models/purchase_model.dart';
import '../interfaces/purchase_datasource.dart';

class PurchaseLocalDatasourceImpl extends PurchaseDatasource {
  final DatabaseService _databaseService;

  PurchaseLocalDatasourceImpl(this._databaseService);

  /// Mengikuti aturan konversi stok yang sudah dipakai fitur penjualan:
  /// quantity / conversionValue, dibulatkan.
  int _stockDeltaOf(PurchaseItemModel item) {
    final conversion = item.conversionValue;
    final quantity = item.quantity;

    if (conversion <= 0 || !quantity.isFinite) return 0;

    return (quantity / conversion).round();
  }

  int _baseUnitPriceOf(PurchaseItemModel item) {
    if (item.conversionValue <= 0) return item.unitPrice;
    return (item.unitPrice / item.conversionValue).round();
  }

  Future<void> _refreshProductCostPrice(DatabaseExecutor trx, int productId) async {
    final latest = await trx.rawQuery(
      '''
SELECT pi.baseUnitPrice
FROM '${DatabaseConfig.purchaseItemTableName}' pi
INNER JOIN '${DatabaseConfig.purchaseTableName}' p ON p.id = pi.purchaseId
WHERE pi.productId = ?
ORDER BY p.purchaseDate DESC, p.id DESC, pi.id DESC
LIMIT 1
''',
      [productId],
    );

    final costPrice = latest.isEmpty ? 0 : (latest.first['baseUnitPrice'] as num?)?.toInt() ?? 0;

    await trx.update(
      DatabaseConfig.productTableName,
      {
        'costPrice': costPrice,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  @override
  Future<Result<int>> createPurchase(PurchaseModel purchase) async {
    try {
      await _databaseService.database.transaction((trx) async {
        final header = purchase.toJson()..remove('items');

        await trx.insert(
          DatabaseConfig.purchaseTableName,
          header,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        final affectedProducts = <int>{};
        for (final item in purchase.items ?? <PurchaseItemModel>[]) {
          item.purchaseId = purchase.id;
          item.baseUnitPrice = _baseUnitPriceOf(item);

          final itemJson = item.toJson();
          if (itemJson['id'] == null) itemJson.remove('id');

          await trx.insert(
            DatabaseConfig.purchaseItemTableName,
            itemJson,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );

          affectedProducts.add(item.productId);

          if (purchase.addStock) {
            final delta = _stockDeltaOf(item);
            if (delta != 0) {
              await trx.rawUpdate(
                "UPDATE '${DatabaseConfig.productTableName}' "
                'SET stock = COALESCE(stock, 0) + ?, updatedAt = ? WHERE id = ?',
                [delta, DateTime.now().toIso8601String(), item.productId],
              );
            }
          }
        }

        for (final productId in affectedProducts) {
          await _refreshProductCostPrice(trx, productId);
        }
      });

      return Result.success(data: purchase.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deletePurchase(int id) async {
    try {
      await _databaseService.database.transaction((trx) async {
        final purchaseRows = await trx.query(
          DatabaseConfig.purchaseTableName,
          where: 'id = ?',
          whereArgs: [id],
        );

        if (purchaseRows.isEmpty) return;

        final purchase = PurchaseModel.fromJson(purchaseRows.first);
        final items = await _getItemsWith(trx, id);
        final affectedProducts = <int>{};

        for (final item in items) {
          affectedProducts.add(item.productId);

          if (purchase.addStock) {
            final delta = _stockDeltaOf(item);
            if (delta != 0) {
              await trx.rawUpdate(
                "UPDATE '${DatabaseConfig.productTableName}' "
                'SET stock = MAX(COALESCE(stock, 0) - ?, 0), updatedAt = ? WHERE id = ?',
                [delta, DateTime.now().toIso8601String(), item.productId],
              );
            }
          }
        }

        await trx.delete(
          DatabaseConfig.purchaseItemTableName,
          where: 'purchaseId = ?',
          whereArgs: [id],
        );
        await trx.delete(
          DatabaseConfig.purchaseTableName,
          where: 'id = ?',
          whereArgs: [id],
        );

        for (final productId in affectedProducts) {
          await _refreshProductCostPrice(trx, productId);
        }
      });

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<List<PurchaseItemModel>> _getItemsWith(DatabaseExecutor executor, int purchaseId) async {
    final rows = await executor.query(
      DatabaseConfig.purchaseItemTableName,
      where: 'purchaseId = ?',
      whereArgs: [purchaseId],
      orderBy: 'id ASC',
    );

    return rows.map((e) => PurchaseItemModel.fromJson(e)).toList();
  }

  @override
  Future<Result<PurchaseModel?>> getPurchase(int id) async {
    try {
      final rows = await _databaseService.database.query(
        DatabaseConfig.purchaseTableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rows.isEmpty) return Result.success(data: null);

      final purchase = PurchaseModel.fromJson(rows.first);
      purchase.items = await _getItemsWith(_databaseService.database, id);

      return Result.success(data: purchase);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<PurchaseItemModel>>> getPurchaseItems(int purchaseId) async {
    try {
      return Result.success(data: await _getItemsWith(_databaseService.database, purchaseId));
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<PurchaseModel>>> getPurchases({
    String? query,
    String? supplierId,
    String? month,
    int limit = 50,
    int? offset,
  }) async {
    try {
      final where = <String>[];
      final args = <Object?>[];

      final keyword = query?.trim() ?? '';
      if (keyword.isNotEmpty) {
        where.add('(supplierName LIKE ? OR note LIKE ? OR purchaseDate LIKE ?)');
        args.addAll(['%$keyword%', '%$keyword%', '%$keyword%']);
      }

      if (supplierId != null && supplierId.isNotEmpty) {
        where.add('supplierId = ?');
        args.add(supplierId);
      }

      if (month != null && month.isNotEmpty) {
        where.add('purchaseDate LIKE ?');
        args.add('$month%');
      }

      final rows = await _databaseService.database.query(
        DatabaseConfig.purchaseTableName,
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'purchaseDate DESC, id DESC',
        limit: limit,
        offset: offset,
      );

      return Result.success(data: rows.map((e) => PurchaseModel.fromJson(e)).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  String _latestItemQuery({required bool withSupplierFilter, String? orderLimit}) {
    final supplierFilter = withSupplierFilter ? 'AND p.supplierId = ?' : '';
    return '''
SELECT pi.*, p.supplierId AS supplierId, p.supplierName AS supplierName, p.purchaseDate AS purchaseDate
FROM '${DatabaseConfig.purchaseItemTableName}' pi
INNER JOIN '${DatabaseConfig.purchaseTableName}' p ON p.id = pi.purchaseId
WHERE pi.productId = ? $supplierFilter
ORDER BY p.purchaseDate DESC, p.id DESC, pi.id DESC
${orderLimit ?? ''}
''';
  }

  @override
  Future<Result<PurchaseItemModel?>> getLatestPurchaseItem(int productId, {String? supplierId}) async {
    try {
      final withSupplier = supplierId != null && supplierId.isNotEmpty;
      final rows = await _databaseService.database.rawQuery(
        _latestItemQuery(withSupplierFilter: withSupplier, orderLimit: 'LIMIT 1'),
        withSupplier ? [productId, supplierId] : [productId],
      );

      if (rows.isEmpty) return Result.success(data: null);

      return Result.success(data: PurchaseItemModel.fromJson(rows.first));
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<PurchaseItemModel>>> getLatestPurchaseItemsBySupplier(int productId) async {
    try {
      final rows = await _databaseService.database.rawQuery(
        _latestItemQuery(withSupplierFilter: false),
        [productId],
      );

      final seen = <String>{};
      final latest = <PurchaseItemModel>[];

      for (final row in rows) {
        final item = PurchaseItemModel.fromJson(row);
        final key = item.supplierId ?? item.supplierName ?? '';
        if (seen.add(key)) latest.add(item);
      }

      return Result.success(data: latest);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<PurchaseItemModel>>> getProductPurchaseHistory(int productId, {int limit = 10}) async {
    try {
      final rows = await _databaseService.database.rawQuery(
        _latestItemQuery(withSupplierFilter: false, orderLimit: 'LIMIT $limit'),
        [productId],
      );

      return Result.success(data: rows.map((e) => PurchaseItemModel.fromJson(e)).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<int>> countPurchasesBySupplier(String supplierId) async {
    try {
      final rows = await _databaseService.database.rawQuery(
        "SELECT COUNT(*) AS total FROM '${DatabaseConfig.purchaseTableName}' WHERE supplierId = ?",
        [supplierId],
      );

      final total = (rows.first['total'] as num?)?.toInt() ?? 0;
      return Result.success(data: total);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
