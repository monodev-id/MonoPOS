import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/core/services/database/database_config.dart';
import 'package:mono_pos/core/services/database/database_service.dart';
import 'package:mono_pos/data/datasources/local/supplier_local_datasource_impl.dart';
import 'package:mono_pos/data/models/supplier_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService appDatabase;
  late SupplierLocalDatasourceImpl datasource;
  late Database testDatabase;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    testDatabase = await openDatabase(inMemoryDatabasePath, version: 1);

    appDatabase = DatabaseService.instance;
    await appDatabase.initTestDatabase(testDatabase: testDatabase);

    datasource = SupplierLocalDatasourceImpl(appDatabase);
  });

  tearDownAll(() async {
    await testDatabase.close();
  });

  setUp(() async {
    await testDatabase.delete(DatabaseConfig.purchaseItemTableName);
    await testDatabase.delete(DatabaseConfig.purchaseTableName);
    await testDatabase.delete(DatabaseConfig.supplierTableName);
  });

  SupplierModel createSampleSupplier({String id = 'supplier-1', String name = 'Sumber Rejeki'}) {
    return SupplierModel(
      id: id,
      name: name,
      phone: '08123456789',
      address: 'Jl. Merdeka No. 1',
      note: 'langganan mingguan',
    );
  }

  group('SupplierLocalDatasourceImpl', () {
    test('createSupplier stores supplier and getSupplier returns it', () async {
      final supplier = createSampleSupplier();

      final created = await datasource.createSupplier(supplier);
      expect(created.isSuccess, isTrue);
      expect(created.data, supplier.id);

      final result = await datasource.getSupplier(supplier.id);
      expect(result.isSuccess, isTrue);
      expect(result.data?.name, supplier.name);
      expect(result.data?.phone, supplier.phone);
    });

    test('createSupplier rejects duplicate name regardless of case', () async {
      await datasource.createSupplier(createSampleSupplier(id: 'a', name: 'Toko Maju'));

      final duplicate = await datasource.createSupplier(
        createSampleSupplier(id: 'b', name: 'toko maju'),
      );

      expect(duplicate.isFailure, isTrue);
    });

    test('getSupplierByName is case-insensitive', () async {
      await datasource.createSupplier(createSampleSupplier(id: 'a', name: 'Toko Maju'));

      final result = await datasource.getSupplierByName('TOKO MAJU');

      expect(result.isSuccess, isTrue);
      expect(result.data?.id, 'a');
    });

    test('updateSupplier changes stored fields', () async {
      final supplier = createSampleSupplier();
      await datasource.createSupplier(supplier);

      supplier
        ..name = 'Sumber Rejeki Baru'
        ..phone = '0899999999';
      final updated = await datasource.updateSupplier(supplier);

      expect(updated.isSuccess, isTrue);

      final result = await datasource.getSupplier(supplier.id);
      expect(result.data?.name, 'Sumber Rejeki Baru');
      expect(result.data?.phone, '0899999999');
    });

    test('searchSuppliers matches name, phone, or address', () async {
      await datasource.createSupplier(createSampleSupplier(id: 'a', name: 'Toko Maju'));
      await datasource.createSupplier(
        SupplierModel(id: 'b', name: 'Toko Jaya', phone: '081200001111', address: 'Bandung'),
      );

      final byName = await datasource.searchSuppliers('maju');
      expect(byName.data?.map((e) => e.id), ['a']);

      final byPhone = await datasource.searchSuppliers('081200001111');
      expect(byPhone.data?.map((e) => e.id), ['b']);

      final byAddress = await datasource.searchSuppliers('bandung');
      expect(byAddress.data?.map((e) => e.id), ['b']);
    });

    test('getAllSuppliers returns alphabetically ordered suppliers', () async {
      await datasource.createSupplier(createSampleSupplier(id: 'b', name: 'Toko Jaya'));
      await datasource.createSupplier(createSampleSupplier(id: 'a', name: 'Andalan Grosir'));

      final result = await datasource.getAllSuppliers();

      expect(result.data?.map((e) => e.name), ['Andalan Grosir', 'Toko Jaya']);
    });

    test('deleteSupplier is blocked while purchase notes reference it', () async {
      final supplier = createSampleSupplier();
      await datasource.createSupplier(supplier);

      await testDatabase.insert(DatabaseConfig.purchaseTableName, {
        'id': 1,
        'supplierId': supplier.id,
        'supplierName': supplier.name,
        'purchaseDate': '2026-01-01',
        'totalAmount': 0,
        'totalItems': 0,
        'addStock': 1,
      });

      final blocked = await datasource.deleteSupplier(supplier.id);
      expect(blocked.isFailure, isTrue);
      expect(blocked.error.toString(), contains('nota pembelian'));

      await testDatabase.delete(DatabaseConfig.purchaseTableName);

      final deleted = await datasource.deleteSupplier(supplier.id);
      expect(deleted.isSuccess, isTrue);

      final result = await datasource.getSupplier(supplier.id);
      expect(result.data, isNull);
    });
  });
}
