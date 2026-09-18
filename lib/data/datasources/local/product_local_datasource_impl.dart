import 'package:sqflite/sqflite.dart';

import '../../../core/common/result.dart';
import '../../../core/services/database/database_config.dart';
import '../../../core/services/database/database_service.dart';
import '../../models/product_model.dart';
import '../../models/product_tier_model.dart';
import '../../models/product_unit_model.dart';
import '../interfaces/product_datasource.dart';

class ProductLocalDatasourceImpl extends ProductDatasource {
  final DatabaseService _databaseService;

  ProductLocalDatasourceImpl(this._databaseService);

  @override
  Future<Result<int>> createProduct(ProductModel product) async {
    try {
      await _databaseService.database.transaction((trx) async {
        await trx.insert(
          DatabaseConfig.productTableName,
          product.toJson()..remove('units'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (product.units.isNotEmpty) {
          for (var unit in product.units) {
            unit.productId = product.id;
            await trx.insert(
              DatabaseConfig.productUnitTableName,
              unit.toJson(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });

      return Result.success(data: product.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateProduct(ProductModel product) async {
    try {
      await _databaseService.database.transaction((trx) async {
        await trx.update(
          DatabaseConfig.productTableName,
          product.toJson()..remove('units'),
          where: 'id = ?',
          whereArgs: [product.id],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Delete old units and re-insert
        await trx.delete(
          DatabaseConfig.productUnitTableName,
          where: 'productId = ?',
          whereArgs: [product.id],
        );

        for (var unit in product.units) {
          unit.productId = product.id;
          await trx.insert(
            DatabaseConfig.productUnitTableName,
            unit.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProduct(int id) async {
    try {
      await _databaseService.database.transaction((trx) async {
        await trx.delete(
          DatabaseConfig.productUnitTableName,
          where: 'productId = ?',
          whereArgs: [id],
        );

        await trx.delete(
          DatabaseConfig.productTableName,
          where: 'id = ?',
          whereArgs: [id],
        );
      });

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<ProductModel> _loadProductWithUnits(Map<String, dynamic> productJson) async {
    var product = ProductModel.fromJson(productJson);

    var unitRows = await _databaseService.database.query(
      DatabaseConfig.productUnitTableName,
      where: 'productId = ?',
      whereArgs: [product.id],
    );

    product.units = unitRows.map((e) => ProductUnitModel.fromJson(e)).toList();

    return product;
  }

  @override
  Future<Result<ProductModel?>> getProduct(int id) async {
    try {
      var res = await _databaseService.database.query(
        DatabaseConfig.productTableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (res.isEmpty) return Result.success(data: null);

      var product = await _loadProductWithUnits(res.first);

      return Result.success(data: product);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductModel>>> getAllUserProducts(String userId) async {
    try {
      var res = await _databaseService.database.query(
        DatabaseConfig.productTableName,
      );

      var products = <ProductModel>[];
      for (var row in res) {
        products.add(await _loadProductWithUnits(row));
      }

      return Result.success(data: products);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductModel>>> getUserProducts(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    try {
      final keyword = contains?.trim() ?? '';
      var res = await _databaseService.database.query(
        DatabaseConfig.productTableName,
        where: '(name LIKE ? OR barcode LIKE ?)',
        whereArgs: ['%$keyword%', '%$keyword%'],
        orderBy: '$orderBy $sortBy',
        limit: limit,
        offset: offset,
      );

      var products = <ProductModel>[];
      for (var row in res) {
        products.add(await _loadProductWithUnits(row));
      }

      return Result.success(data: products);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductModel?>> getProductByBarcode(String barcode) async {
    try {
      final normalized = barcode.trim();
      if (normalized.isEmpty) return Result.success(data: null);

      var res = await _databaseService.database.query(
        DatabaseConfig.productTableName,
        where: 'TRIM(barcode) = ?',
        whereArgs: [normalized],
      );

      if (res.isEmpty) return Result.success(data: null);

      var product = await _loadProductWithUnits(res.first);

      return Result.success(data: product);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductModel?>> getProductByName(String name) async {
    try {
      var res = await _databaseService.database.query(
        DatabaseConfig.productTableName,
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );

      if (res.isEmpty) return Result.success(data: null);

      var product = await _loadProductWithUnits(res.first);

      return Result.success(data: product);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> saveProductUnits(int productId, List<ProductUnitModel> units) async {
    try {
      await _databaseService.database.transaction((trx) async {
        await trx.delete(
          DatabaseConfig.productUnitTableName,
          where: 'productId = ?',
          whereArgs: [productId],
        );

        for (var unit in units) {
          unit.productId = productId;
          await trx.insert(
            DatabaseConfig.productUnitTableName,
            unit.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductUnitModel>>> getProductUnits(int productId) async {
    try {
      var res = await _databaseService.database.query(
        DatabaseConfig.productUnitTableName,
        where: 'productId = ?',
        whereArgs: [productId],
      );

      return Result.success(
        data: res.map((e) => ProductUnitModel.fromJson(e)).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProductUnits(int productId) async {
    try {
      await _databaseService.database.delete(
        DatabaseConfig.productUnitTableName,
        where: 'productId = ?',
        whereArgs: [productId],
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductTierModel>>> getProductTiers(int productUnitId) async {
    try {
      var res = await _databaseService.database.query(
        DatabaseConfig.productTieredPriceTableName,
        where: 'productUnitId = ?',
        whereArgs: [productUnitId],
        orderBy: 'minQty ASC',
      );

      return Result.success(
        data: res.map((e) => ProductTierModel.fromJson(e)).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> saveProductTiers(int productUnitId, List<ProductTierModel> tiers) async {
    try {
      await _databaseService.database.transaction((trx) async {
        await trx.delete(
          DatabaseConfig.productTieredPriceTableName,
          where: 'productUnitId = ?',
          whereArgs: [productUnitId],
        );

        for (var tier in tiers) {
          tier.productUnitId = productUnitId;
          await trx.insert(
            DatabaseConfig.productTieredPriceTableName,
            tier.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProductTiers(int productUnitId) async {
    try {
      await _databaseService.database.delete(
        DatabaseConfig.productTieredPriceTableName,
        where: 'productUnitId = ?',
        whereArgs: [productUnitId],
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductModel>>> getLowStockProducts(String userId, int threshold) async {
    try {
      var res = await _databaseService.database.query(
        DatabaseConfig.productTableName,
        where: 'stock > 0 AND stock <= ?',
        whereArgs: [threshold],
        orderBy: 'stock ASC',
      );

      var products = <ProductModel>[];
      for (var row in res) {
        products.add(await _loadProductWithUnits(row));
      }

      return Result.success(data: products);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
