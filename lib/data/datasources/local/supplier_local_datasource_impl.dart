import 'package:sqflite/sqflite.dart';

import '../../../core/common/result.dart';
import '../../../core/services/database/database_config.dart';
import '../../../core/services/database/database_service.dart';
import '../../models/supplier_model.dart';
import '../interfaces/supplier_datasource.dart';

class SupplierLocalDatasourceImpl extends SupplierDatasource {
  final DatabaseService _databaseService;

  SupplierLocalDatasourceImpl(this._databaseService);

  @override
  Future<Result<SupplierModel?>> getSupplier(String id) async {
    try {
      final res = await _databaseService.database.query(
        DatabaseConfig.supplierTableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (res.isEmpty) return Result.success(data: null);

      return Result.success(data: SupplierModel.fromJson(res.first));
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<SupplierModel?>> getSupplierByName(String name) async {
    try {
      final normalized = name.trim();
      if (normalized.isEmpty) return Result.success(data: null);

      final res = await _databaseService.database.query(
        DatabaseConfig.supplierTableName,
        where: 'name = ? COLLATE NOCASE',
        whereArgs: [normalized],
        limit: 1,
      );

      if (res.isEmpty) return Result.success(data: null);

      return Result.success(data: SupplierModel.fromJson(res.first));
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<String>> createSupplier(SupplierModel supplier) async {
    try {
      await _databaseService.database.insert(
        DatabaseConfig.supplierTableName,
        supplier.toJson(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return Result.success(data: supplier.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateSupplier(SupplierModel supplier) async {
    try {
      await _databaseService.database.update(
        DatabaseConfig.supplierTableName,
        supplier.toJson(),
        where: 'id = ?',
        whereArgs: [supplier.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteSupplier(String id) async {
    try {
      final used = await _databaseService.database.query(
        DatabaseConfig.purchaseTableName,
        columns: ['id'],
        where: 'supplierId = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (used.isNotEmpty) {
        return Result.failure(
          error: 'Supplier masih dipakai pada nota pembelian. Hapus nota terkait terlebih dahulu.',
        );
      }

      await _databaseService.database.delete(
        DatabaseConfig.supplierTableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<SupplierModel>>> getAllSuppliers() async {
    try {
      final res = await _databaseService.database.query(
        DatabaseConfig.supplierTableName,
        orderBy: 'name COLLATE NOCASE ASC',
      );

      return Result.success(data: res.map((e) => SupplierModel.fromJson(e)).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<SupplierModel>>> searchSuppliers(String query) async {
    try {
      final keyword = query.trim();
      final res = await _databaseService.database.query(
        DatabaseConfig.supplierTableName,
        where: 'name LIKE ? OR phone LIKE ? OR address LIKE ?',
        whereArgs: ['%$keyword%', '%$keyword%', '%$keyword%'],
        orderBy: 'name COLLATE NOCASE ASC',
      );

      return Result.success(data: res.map((e) => SupplierModel.fromJson(e)).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
