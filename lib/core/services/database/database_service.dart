import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../utilities/console_logger.dart';
import 'database_config.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService _instance = DatabaseService._internal();

  static DatabaseService get instance => _instance;

  late Database database;

  Future<void> init() async {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), DatabaseConfig.dbPath);

    database = await openDatabase(
      path,
      version: DatabaseConfig.version,
      onCreate: (db, version) async {
        await Future.wait([
          db.execute(DatabaseConfig.createUserTable),
          db.execute(DatabaseConfig.createProductTable),
          db.execute(DatabaseConfig.createProductUnitTable),
          db.execute(DatabaseConfig.createProductTieredPriceTable),
          db.execute(DatabaseConfig.createCustomerTable),
          db.execute(DatabaseConfig.createTransactionTable),
          db.execute(DatabaseConfig.createOrderedProductTable),
          db.execute(DatabaseConfig.createQueuedActionTable),
        ]);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _applyMigrations(db);
        if (oldVersion < 3) await _applyMigrationsV3(db);
      },
    );

    await _applyMigrations(database);
    await _applyMigrationsV3(database);
    await _addProductNameUniqueConstraint(database);
    await _seedUsers(database);
    await _migrateLegacyProductUnits();
    await _seedProducts();
  }

  Future<void> _migrateLegacyProductUnits() async {
    try {
      // Find all products that don't have any units in ProductUnit table
      final legacyProducts = await database.rawQuery('''
        SELECT p.id, p.unit, p.price, p.wholesalePrice 
        FROM Product p 
        WHERE p.id NOT IN (SELECT DISTINCT productId FROM ProductUnit)
      ''');

      if (legacyProducts.isNotEmpty) {
        // Insert a single ProductUnit row for each legacy product
        for (final product in legacyProducts) {
          await database.insert(
            DatabaseConfig.productUnitTableName,
            {
              'productId': product['id'],
              'unitName': product['unit'] ?? 'pcs',
              'conversionValue': 1,
              'price': product['price'] ?? 0,
              'wholesalePrice': product['wholesalePrice'],
              'isBase': 1,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        cw('Migrated ${legacyProducts.length} legacy products to new unit system');
      }
    } catch (e) {
      ce('Migration failed: $e');
    }
  }

  Future<void> _seedUsers(Database db) async {
    // Migrate old 'local-user-id' to 'admin' if it exists
    final oldUser = await db.query(
      DatabaseConfig.userTableName,
      where: 'id = ?',
      whereArgs: ['local-user-id'],
    );
    if (oldUser.isNotEmpty) {
      await db.update(
        DatabaseConfig.userTableName,
        {
          'id': 'admin',
          'name': 'Admin',
          'password': 'admin123',
          'role': 'admin',
          'authProvider': 'local',
        },
        where: 'id = ?',
        whereArgs: ['local-user-id'],
      );
    }

    final seedUsers = [
      {
        'id': 'admin',
        'name': 'Admin',
        'email': 'admin@localhost',
        'authProvider': 'local',
        'password': 'admin123',
        'role': 'admin',
      },
      {
        'id': '7778024b-98a5-4df2-b912-a6e541a2ff1b',
        'name': 'Admin',
        'email': 'admin@monopos.local',
        'authProvider': 'supabase',
        'password': 'admin123',
        'role': 'admin',
      },
      {
        'id': 'kasir1',
        'name': 'Kasir 1',
        'email': 'kasir1@localhost',
        'authProvider': 'local',
        'password': 'kasir123',
        'role': 'kasir',
      },
      {
        'id': 'kasir2',
        'name': 'Kasir 2',
        'email': 'kasir2@localhost',
        'authProvider': 'local',
        'password': 'kasir123',
        'role': 'kasir',
      },
    ];

    for (final user in seedUsers) {
      await db.insert(
        DatabaseConfig.userTableName,
        user,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Fix: ensure existing rows have correct password (handles pre-migration DBs
      // where password column was added via ALTER TABLE and is NULL/empty for existing rows)
      await db.rawUpdate(
        "UPDATE '${DatabaseConfig.userTableName}' SET password = ? WHERE id = ? AND (password IS NULL OR password = '')",
        [user['password'], user['id']],
      );

      // Fix: ensure admin users keep admin role after migration (role column default is 'kasir')
      if (user['role'] == 'admin') {
        await db.rawUpdate(
          "UPDATE '${DatabaseConfig.userTableName}' SET role = 'admin' WHERE id = ? AND (role IS NULL OR role != 'admin')",
          [user['id']],
        );
      }
    }
  }

  Future<void> _applyMigrations(Database db) async {
    // Migration: add wholesalePrice column
    await _addColumnIfNotExists(db, 'Product', 'wholesalePrice', 'INTEGER');

    // Migration: add priceType column
    await _addColumnIfNotExists(db, 'OrderedProduct', 'priceType', "TEXT DEFAULT 'retail'");

    // Migration: add unit column to Product
    await _addColumnIfNotExists(db, 'Product', 'unit', "TEXT DEFAULT 'pcs'");

    // Migration: add barcode column
    await _addColumnIfNotExists(db, 'Product', 'barcode', 'TEXT');

    // Migration: add unit column to OrderedProduct
    await _addColumnIfNotExists(db, 'OrderedProduct', 'unit', "TEXT DEFAULT 'pcs'");

    // Migration: add conversionValue column to OrderedProduct
    await _addColumnIfNotExists(db, 'OrderedProduct', 'conversionValue', 'INTEGER NOT NULL DEFAULT 1');

    // Migration: add password column to User
    await _addColumnIfNotExists(db, 'User', 'password', 'TEXT');

    // Migration: add role column to User
    await _addColumnIfNotExists(db, 'User', 'role', "TEXT DEFAULT 'kasir'");

    // Migration: add columns to Transaction (check existence first)
    await _addColumnIfNotExists(db, 'Transaction', 'paymentStatus', "TEXT DEFAULT 'paid'");
    await _addColumnIfNotExists(db, 'Transaction', 'paymentQR', 'TEXT');
    await _addColumnIfNotExists(db, 'Transaction', 'paymentExternalId', 'TEXT');

    // Migration: create tiered price table
    try {
      await db.execute(DatabaseConfig.createProductTieredPriceTable);
    } catch (_) {}

    // Migration: create customer table
    try {
      await db.execute(DatabaseConfig.createCustomerTable);
    } catch (_) {}

    // Migration: add paymentType column to Transaction
    await _addColumnIfNotExists(db, 'Transaction', 'paymentType', "TEXT DEFAULT 'cash'");

    // Migration: add customerId column to Transaction
    await _addColumnIfNotExists(db, 'Transaction', 'customerId', 'TEXT');

    // Migration: add dueDate column to Transaction
    await _addColumnIfNotExists(db, 'Transaction', 'dueDate', 'TEXT');

    // Migration: add UNIQUE constraint on Product name
    await _addProductNameUniqueConstraint(db);
  }

  Future<void> _applyMigrationsV3(Database db) async {
    // Migration: add isCustomPrice column to Product
    await _addColumnIfNotExists(db, 'Product', 'isCustomPrice', 'INTEGER NOT NULL DEFAULT 0');

    // Migration: add isTieredPrice column to OrderedProduct
    await _addColumnIfNotExists(db, 'OrderedProduct', 'isTieredPrice', 'INTEGER NOT NULL DEFAULT 0');
  }

  static const int seedProductCount = 150;

  Future<void> _seedProducts() async {
    if (!kDebugMode) return;

    const userId = 'admin';
    final existing = await database.query(
      DatabaseConfig.productTableName,
      where: 'createdById = ?',
      whereArgs: [userId],
    );
    if (existing.length >= seedProductCount) return;

    final baseNames = [
      'Teh Botol',
      'Indomie',
      'Coca Cola',
      'Aqua',
      'Minyak Goreng',
      'Beras',
      'Gula',
      'Telur',
      'Susu',
      'Kopi',
      'Sabun',
      'Shampoo',
      'Kecap',
      'Saos',
      'Tepung',
      'Biskuit',
      'Permen',
      'Coklat',
      'Roti',
      'Keju',
    ];

    for (int i = existing.length + 1; i <= seedProductCount; i++) {
      try {
        final name = '${baseNames[i % baseNames.length]} $i';
        final price = 2000 * ((i % 25) + 1);
        final wholesale = (price * 0.9).toInt();
        final stock = 10 + (i * 7) % 90;
        final barcode = 'SEED${1000 + i}';

        final productId = await database.insert(
          DatabaseConfig.productTableName,
          {
            'createdById': userId,
            'name': name,
            'imageUrl': '',
            'stock': stock,
            'sold': i % 5,
            'price': price,
            'wholesalePrice': wholesale,
            'unit': 'pcs',
            'barcode': barcode,
            'description': 'Produk seed ke-$i',
          },
        );

        await database.insert(DatabaseConfig.productUnitTableName, {
          'productId': productId,
          'unitName': 'pcs',
          'conversionValue': 1,
          'price': price,
          'wholesalePrice': wholesale,
          'isBase': 1,
        });

        if (i % 10 == 8) {
          final unitRows = await database.query(
            DatabaseConfig.productUnitTableName,
            where: 'productId = ?',
            whereArgs: [productId],
            limit: 1,
          );
          if (unitRows.isNotEmpty) {
            final unitId = unitRows.first['id'];
            await database.insert(DatabaseConfig.productTieredPriceTableName, {
              'productUnitId': unitId,
              'minQty': 3,
              'maxQty': null,
              'price': 5000,
            });
            cw('Added tiered price for $name: 3pcs = 5000');
          }
        }
      } catch (e) {
        ce('Seed produk ke-$i gagal: $e');
      }
    }

    cw('Seeded products for user: $userId');
  }

  @visibleForTesting
  Future<void> _addColumnIfNotExists(Database db, String table, String column, String type) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info('$table')");
      final exists = result.any((row) => row['name'] == column);
      if (!exists) {
        await db.execute("ALTER TABLE '$table' ADD COLUMN '$column' $type");
        cw('Added column $column to $table');
      }
    } catch (e) {
      ce('Migration add column $column failed: $e');
    }
  }

  Future<void> _addProductNameUniqueConstraint(Database db) async {
    try {
      // Check if unique index already exists
      final indexes = await db.rawQuery("PRAGMA index_list('Product')");
      final hasUniqueIndex = indexes.any((row) => row['unique'] == 1 && row['name'] == 'idx_product_name_unique');

      if (!hasUniqueIndex) {
        // Remove duplicate names before adding constraint (keep the one with the lowest id)
        await db.rawDelete('''
          DELETE FROM Product WHERE rowid NOT IN (
            SELECT MIN(rowid) FROM Product GROUP BY name
          )
        ''');

        await db.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_product_name_unique ON Product(name)',
        );
        cw('Added UNIQUE constraint on Product.name');
      }
    } catch (e) {
      ce('Migration add UNIQUE constraint on Product.name failed: $e');
    }
  }

  Future<void> initTestDatabase({required Database testDatabase}) async {
    database = testDatabase;

    await Future.wait([
      database.execute(DatabaseConfig.createUserTable),
      database.execute(DatabaseConfig.createProductTable),
      database.execute(DatabaseConfig.createProductUnitTable),
      database.execute(DatabaseConfig.createProductTieredPriceTable),
      database.execute(DatabaseConfig.createCustomerTable),
      database.execute(DatabaseConfig.createTransactionTable),
      database.execute(DatabaseConfig.createOrderedProductTable),
      database.execute(DatabaseConfig.createQueuedActionTable),
    ]);

    await _seedUsers(database);
  }

  Future<void> dropDatabase(String path) async {
    File databaseFile = File(path);

    if (await databaseFile.exists()) {
      await databaseFile.delete();
      cw('Database deleted successfully!');
    } else {
      ce('Database does not exist!');
    }
  }
}
