import 'dart:convert';

import '../../../core/common/result.dart';
import '../../../core/services/sync/sync_service.dart';
import '../../../core/utilities/console_logger.dart';
import '../../../domain/entities/queued_action_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/product_tier_entity.dart';
import '../../../domain/entities/product_unit_entity.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/repositories/queued_action_repository.dart';
import '../datasources/interfaces/product_datasource.dart';
import '../datasources/local/product_local_datasource_impl.dart';
import '../models/product_model.dart';
import '../models/product_tier_model.dart';
import '../models/product_unit_model.dart';

class ProductRepositoryImpl extends ProductRepository {
  final ProductLocalDatasourceImpl productLocalDatasource;
  final ProductDatasource? productRemoteDatasource;
  final SyncService syncService;
  final QueuedActionRepository queuedActionRepository;

  ProductRepositoryImpl({
    required this.productLocalDatasource,
    this.productRemoteDatasource,
    required this.syncService,
    required this.queuedActionRepository,
  });

  @override
  Future<Result<List<ProductEntity>>> getUserProducts(
    String userId, {
    String orderBy = 'createdAt',
    String sortBy = 'DESC',
    int limit = 10,
    int? offset,
    String? contains,
  }) async {
    try {
      final local = await productLocalDatasource.getUserProducts(
        userId,
        orderBy: orderBy,
        sortBy: sortBy,
        limit: limit,
        offset: offset,
        contains: contains,
      );

      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductEntity?>> getProduct(int productId) async {
    try {
      final local = await productLocalDatasource.getProduct(productId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductEntity?>> getProductByBarcode(String barcode) async {
    try {
      final normalized = barcode.trim();
      if (normalized.isEmpty) return Result.success(data: null);

      final local = await productLocalDatasource.getProductByBarcode(normalized);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<ProductEntity?>> getProductByName(String name) async {
    try {
      final local = await productLocalDatasource.getProductByName(name);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data?.toEntity());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<int>> createProduct(ProductEntity product) async {
    try {
      final data = ProductModel.fromEntity(product);

      final local = await productLocalDatasource.createProduct(data);
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => productRemoteDatasource?.createProduct(data),
        method: 'createProduct',
        param: data.toJson(),
      );

      return Result.success(data: local.data!);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteProduct(int productId) async {
    try {
      final local = await productLocalDatasource.deleteProduct(productId);
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => productRemoteDatasource?.deleteProduct(productId),
        method: 'deleteProduct',
        param: {'id': productId},
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateProduct(ProductEntity product) async {
    try {
      final local = await productLocalDatasource.updateProduct(ProductModel.fromEntity(product));
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => productRemoteDatasource?.updateProduct(ProductModel.fromEntity(product)),
        method: 'updateProduct',
        param: ProductModel.fromEntity(product).toJson(),
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductUnitEntity>>> getProductUnits(int productId) async {
    try {
      final local = await productLocalDatasource.getProductUnits(productId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> saveProductUnits(int productId, List<ProductUnitEntity> units) async {
    try {
      final models = units.map((e) => ProductUnitModel.fromEntity(e)).toList();
      final local = await productLocalDatasource.saveProductUnits(productId, models);
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => productRemoteDatasource?.saveProductUnits(productId, models),
        method: 'saveProductUnits',
        param: {'productId': productId, 'units': models.map((e) => e.toJson()).toList()},
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductEntity>>> getLowStockProducts(String userId, int threshold) async {
    try {
      final local = await productLocalDatasource.getLowStockProducts(userId, threshold);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<ProductTierEntity>>> getProductTiers(int productUnitId) async {
    try {
      final local = await productLocalDatasource.getProductTiers(productUnitId);
      if (local.isFailure) return Result.failure(error: local.error!);

      return Result.success(data: local.data!.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> saveProductTiers(int productUnitId, List<ProductTierEntity> tiers) async {
    try {
      final models = tiers.map((e) => ProductTierModel.fromEntity(e)).toList();
      final local = await productLocalDatasource.saveProductTiers(productUnitId, models);
      if (local.isFailure) return Result.failure(error: local.error!);

      await _syncRemote(
        remoteCall: () => productRemoteDatasource?.saveProductTiers(productUnitId, models),
        method: 'saveProductTiers',
        param: {'productUnitId': productUnitId, 'tiers': models.map((e) => e.toJson()).toList()},
      );

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<void> _syncRemote({
    required Future<Result<dynamic>>? Function() remoteCall,
    required String method,
    required Map<String, dynamic> param,
  }) async {
    if (productRemoteDatasource == null) {
      cw('Sync produk nonaktif — Supabase tidak dikonfigurasi ($method)');
      return;
    }

    if (syncService.isOnline) {
      try {
        final result = await remoteCall();
        if (result?.isSuccess == true) return;

        ce(
          result?.error ?? 'Sync gagal',
          title: 'Sync produk gagal — $method',
          message: 'Ditambahkan ke antrian sync',
        );
      } catch (e) {
        ce(e, title: 'Sync produk error — $method');
      }
    }

    await queuedActionRepository.createQueuedAction(
      QueuedActionEntity(
        repository: 'product',
        method: method,
        param: jsonEncode(param),
        isCritical: false,
      ),
    );
  }
}
