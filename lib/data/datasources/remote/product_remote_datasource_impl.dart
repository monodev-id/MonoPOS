import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/common/result.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../../models/product_model.dart';
import '../../models/product_tier_model.dart';
import '../../models/product_unit_model.dart';
import '../interfaces/product_datasource.dart';

class ProductRemoteDatasourceImpl extends ProductDatasource {
  ProductRemoteDatasourceImpl({SupabaseClient? clientOverride}) : _clientOverride = clientOverride;

  final SupabaseClient? _clientOverride;

  SupabaseClient? get _client => _clientOverride ?? SupabaseService.client;

  @override
  Future<Result<int>> createProduct(ProductModel product) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final json = product.toJson();
      final units = json.remove('units') as List<dynamic>?;

      await client.from(SupabaseConfig.productsTable).upsert(json, onConflict: 'id');

      if (units != null && units.isNotEmpty) {
        final uniqueUnits = _uniqueRowsById(units);
        for (final unit in uniqueUnits) {
          unit['productId'] = product.id;
        }
        await client.from(SupabaseConfig.productUnitsTable).upsert(uniqueUnits, onConflict: 'id');
      }

      return Result.success(data: product.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateProduct(ProductModel product) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final json = product.toJson();
      final units = json.remove('units') as List<dynamic>?;

      await client.from(SupabaseConfig.productsTable).update(json).eq('id', product.id);

      if (units != null) {
        final uniqueUnits = _uniqueRowsById(units);
        await client.from(SupabaseConfig.productUnitsTable).delete().eq('productId', product.id);

        for (final unit in uniqueUnits) {
          unit['productId'] = product.id;
        }
        await client.from(SupabaseConfig.productUnitsTable).upsert(uniqueUnits, onConflict: 'id');
      }

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProduct(int id) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.productUnitsTable).delete().eq('productId', id);

      await client.from(SupabaseConfig.productsTable).delete().eq('id', id);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductModel?>> getProduct(int id) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      final res = await client.from(SupabaseConfig.productsTable).select().eq('id', id).maybeSingle();

      if (res == null) return Result.success(data: null);

      final product = ProductModel.fromJson(Map<String, dynamic>.from(res));
      await _loadUnits(client, product);

      return Result.success(data: product);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductModel>>> getAllUserProducts(String userId) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client.from(SupabaseConfig.productsTable).select();

      final products = <ProductModel>[];
      for (final row in res) {
        final product = ProductModel.fromJson(Map<String, dynamic>.from(row));
        await _loadUnits(client, product);
        products.add(product);
      }

      return Result.success(data: products);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductModel?>> getProductByBarcode(String barcode) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      final normalized = barcode.trim();
      if (normalized.isEmpty) return Result.success(data: null);

      final res = await client.from(SupabaseConfig.productsTable).select().eq('barcode', normalized).maybeSingle();

      if (res == null) return Result.success(data: null);

      final product = ProductModel.fromJson(Map<String, dynamic>.from(res));
      await _loadUnits(client, product);

      return Result.success(data: product);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductModel?>> getProductByName(String name) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      final res = await client.from(SupabaseConfig.productsTable).select().eq('name', name).maybeSingle();

      if (res == null) return Result.success(data: null);

      final product = ProductModel.fromJson(Map<String, dynamic>.from(res));
      await _loadUnits(client, product);

      return Result.success(data: product);
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
      final client = _client;
      if (client == null) return Result.success(data: []);

      dynamic query = client.from(SupabaseConfig.productsTable).select();

      final keyword = contains?.trim() ?? '';
      if (keyword.isNotEmpty) {
        query = query.or('name.ilike.%$keyword%,barcode.ilike.%$keyword%');
      }

      query = query.order(orderBy, ascending: sortBy == 'ASC').limit(limit);

      if (offset != null) {
        query = query.range(offset, offset + limit - 1);
      }

      final res = await query as List<dynamic>;

      final products = <ProductModel>[];
      for (final row in res) {
        final product = ProductModel.fromJson(Map<String, dynamic>.from(row));
        await _loadUnits(client, product);
        products.add(product);
      }

      return Result.success(data: products);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> saveProductUnits(int productId, List<ProductUnitModel> units) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.productUnitsTable).delete().eq('productId', productId);

      final rows = _uniqueRowsById(units.map((e) => e.toJson()).toList());
      for (final unit in rows) {
        unit['productId'] = productId;
      }
      await client.from(SupabaseConfig.productUnitsTable).upsert(rows, onConflict: 'id');

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductUnitModel>>> getProductUnits(int productId) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client.from(SupabaseConfig.productUnitsTable).select().eq('productId', productId);

      return Result.success(
        data: res.map((e) => ProductUnitModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProductUnits(int productId) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.productUnitsTable).delete().eq('productId', productId);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductTierModel>>> getProductTiers(int productUnitId) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client
          .from(SupabaseConfig.productTieredPricesTable)
          .select()
          .eq('productUnitId', productUnitId)
          .order('minQty', ascending: true);

      return Result.success(
        data: res.map((e) => ProductTierModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> saveProductTiers(int productUnitId, List<ProductTierModel> tiers) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.productTieredPricesTable).delete().eq('productUnitId', productUnitId);

      final tierRows = _uniqueRowsById(tiers.map((e) => e.toJson()).toList());
      for (final tier in tierRows) {
        tier['productUnitId'] = productUnitId;
      }
      await client
          .from(SupabaseConfig.productTieredPricesTable)
          .upsert(
            tierRows,
            onConflict: 'id',
          );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProductTiers(int productUnitId) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      await client.from(SupabaseConfig.productTieredPricesTable).delete().eq('productUnitId', productUnitId);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductModel>>> getLowStockProducts(String userId, int threshold) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client
          .from(SupabaseConfig.productsTable)
          .select()
          .gt('stock', 0)
          .lte('stock', threshold)
          .order('stock', ascending: true);

      final products = <ProductModel>[];
      for (final row in res) {
        final product = ProductModel.fromJson(Map<String, dynamic>.from(row));
        await _loadUnits(client, product);
        products.add(product);
      }

      return Result.success(data: products);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<void> _loadUnits(SupabaseClient client, ProductModel product) async {
    final unitRes = await client.from(SupabaseConfig.productUnitsTable).select().eq('productId', product.id);

    product.units = unitRes.map((e) => ProductUnitModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  List<Map<String, dynamic>> _uniqueRowsById(List<dynamic> rows) {
    final seen = <int>{};
    var counter = 0;
    final out = <Map<String, dynamic>>[];

    for (final raw in rows) {
      final m = Map<String, dynamic>.from(raw as Map);
      var id = m['id'];

      if (id is! int) {
        id = DateTime.now().millisecondsSinceEpoch + (counter++);
      } else {
        while (seen.contains(id)) {
          id = DateTime.now().millisecondsSinceEpoch + (counter++);
        }
      }

      seen.add(id);
      m['id'] = id;
      out.add(m);
    }

    return out;
  }
}
