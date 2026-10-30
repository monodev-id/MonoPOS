import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/common/result.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../../models/ordered_product_model.dart';
import '../../models/transaction_model.dart';
import '../interfaces/transaction_datasource.dart';

class TransactionRemoteDatasourceImpl extends TransactionDatasource {
  TransactionRemoteDatasourceImpl();

  SupabaseClient? get _client => SupabaseService.client;

  @override
  Future<Result<int>> createTransaction(TransactionModel transaction) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final json = transaction.toJson();
      json.remove('orderedProducts');
      json.remove('createdBy');
      _removeLocalOnlyFields(json);

      await client.from(SupabaseConfig.transactionsTable).upsert(json, onConflict: 'id');

      if (transaction.orderedProducts?.isNotEmpty ?? false) {
        final rows = _uniqueRowsById(transaction.orderedProducts!.map((e) => e.toJson()).toList());
        for (final op in rows) {
          op['transactionId'] = transaction.id;
        }
        await client
            .from(SupabaseConfig.orderedProductsTable)
            .upsert(
              rows,
              onConflict: 'id',
            );
      }

      return Result.success(data: transaction.id);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> updateTransaction(TransactionModel transaction) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final json = transaction.toJson();
      json.remove('orderedProducts');
      json.remove('createdBy');
      _removeLocalOnlyFields(json);

      await client.from(SupabaseConfig.transactionsTable).update(json).eq('id', transaction.id);

      if (transaction.orderedProducts?.isNotEmpty ?? false) {
        final rows = _uniqueRowsById(transaction.orderedProducts!.map((e) => e.toJson()).toList());
        await client.from(SupabaseConfig.orderedProductsTable).delete().eq('transactionId', transaction.id);

        for (final op in rows) {
          op['transactionId'] = transaction.id;
        }
        await client
            .from(SupabaseConfig.orderedProductsTable)
            .upsert(
              rows,
              onConflict: 'id',
            );
      }

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
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final values = <String, dynamic>{'paymentStatus': status};
      if (paymentQR != null) values['paymentQR'] = paymentQR;
      if (paymentExternalId != null) values['paymentExternalId'] = paymentExternalId;

      await client.from(SupabaseConfig.transactionsTable).update(values).eq('id', id);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<void>> deleteTransaction(int id) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      await client.from(SupabaseConfig.orderedProductsTable).delete().eq('transactionId', id);

      await client.from(SupabaseConfig.transactionsTable).delete().eq('id', id);

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<TransactionModel?>> getTransaction(int id) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: null);

      final res = await client.from(SupabaseConfig.transactionsTable).select().eq('id', id).maybeSingle();

      if (res == null) return Result.success(data: null);

      final transaction = TransactionModel.fromJson(Map<String, dynamic>.from(res));
      await _loadRelations(client, transaction);

      return Result.success(data: transaction);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<List<TransactionModel>>> getAllUserTransactions(String userId) async {
    try {
      final client = _client;
      if (client == null) return Result.success(data: []);

      final res = await client
          .from(SupabaseConfig.transactionsTable)
          .select()
          .eq('createdById', userId)
          .order('createdAt', ascending: false);

      final transactions = <TransactionModel>[];
      for (final row in res) {
        final transaction = TransactionModel.fromJson(Map<String, dynamic>.from(row));
        await _loadRelations(client, transaction);
        transactions.add(transaction);
      }

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
      final client = _client;
      if (client == null) return Result.success(data: []);

      var query = client
          .from(SupabaseConfig.transactionsTable)
          .select()
          .gte('createdAt', startDate)
          .lte('createdAt', endDate);

      if (!showAllUsers) {
        query = query.eq('createdById', userId);
      }
      if (paymentStatus != null) {
        query = query.eq('paymentStatus', paymentStatus);
      }

      final res = await query.order('createdAt', ascending: false);

      final transactions = <TransactionModel>[];
      for (final row in res) {
        final transaction = TransactionModel.fromJson(Map<String, dynamic>.from(row));
        await _loadRelations(client, transaction);
        transactions.add(transaction);
      }

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
      final client = _client;
      if (client == null) return Result.success(data: []);

      dynamic query = client.from(SupabaseConfig.transactionsTable).select().eq('createdById', userId);

      query = query.order(orderBy, ascending: sortBy == 'ASC').limit(limit);

      if (offset != null) {
        query = query.range(offset, offset + limit - 1);
      }

      final res = await query as List<dynamic>;

      final transactions = <TransactionModel>[];
      for (final row in res) {
        final transaction = TransactionModel.fromJson(Map<String, dynamic>.from(row));
        await _loadRelations(client, transaction);
        transactions.add(transaction);
      }

      return Result.success(data: transactions);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  Future<void> _loadRelations(SupabaseClient client, TransactionModel transaction) async {
    final opRes = await client.from(SupabaseConfig.orderedProductsTable).select().eq('transactionId', transaction.id);

    transaction.orderedProducts = opRes.map((e) => OrderedProductModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Kolom pembayaran DANA hanya berlaku lokal (belum ada di tabel Supabase).
  void _removeLocalOnlyFields(Map<String, dynamic> json) {
    json.remove('paymentProvider');
    json.remove('paymentExpectedAmount');
    json.remove('paymentUniqueCode');
    json.remove('paymentExpiresAt');
    json.remove('paymentPaidAt');
  }

  List<Map<String, dynamic>> _uniqueRowsById(List<dynamic> rows) {    final seen = <int>{};
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
