import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../constants/constants.dart';
import '../../utilities/console_logger.dart';
import '../database/database_config.dart';
import '../database/database_service.dart';

/// Satu baris transaksi QRIS DANA yang masih menunggu pembayaran.
class DanaPendingTransaction {
  final int id;
  final int expectedAmount;
  final int baseAmount;
  final String? expiresAt;

  const DanaPendingTransaction({
    required this.id,
    required this.expectedAmount,
    required this.baseAmount,
    this.expiresAt,
  });
}

/// Notifikasi DANA yang sudah tersimpan di perangkat.
class DanaNotificationRecord {
  final String notifKey;
  final String packageName;
  final String title;
  final String body;
  final int? amount;
  final String? postedAt;
  final String status;
  final int? matchedTransactionId;

  const DanaNotificationRecord({
    required this.notifKey,
    required this.packageName,
    required this.title,
    required this.body,
    this.amount,
    this.postedAt,
    this.status = 'unmatched',
    this.matchedTransactionId,
  });

  factory DanaNotificationRecord.fromMap(Map<String, dynamic> map) {
    return DanaNotificationRecord(
      notifKey: (map['notifKey'] as String?) ?? '',
      packageName: (map['packageName'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      amount: map['amount'] as int?,
      postedAt: map['postedAt'] as String?,
      status: (map['status'] as String?) ?? 'unmatched',
      matchedTransactionId: map['matchedTransactionId'] as int?,
    );
  }
}

/// Akses lokal untuk metadata pembayaran DANA dan queue notifikasi.
///
/// Semua data di sini lokal saja (tidak disinkronkan ke Supabase).
class DanaPaymentStore {
  final DatabaseService _databaseService;

  DanaPaymentStore(this._databaseService);

  Database get _db => _databaseService.database;

  /// Alokasikan kode unik 1..99 (fallback 100..999) yang belum dipakai
  /// transaksi pending dengan nominal dasar yang sama.
  Future<int> allocateUniqueCode({required int baseAmount}) async {
    final rows = await _db.query(
      DatabaseConfig.transactionTableName,
      columns: ['paymentUniqueCode'],
      where: 'paymentStatus = ? AND paymentProvider = ? AND totalAmount = ?',
      whereArgs: ['pending', Constants.danaProviderStatic, baseAmount],
    );

    final used = <int>{};
    for (final row in rows) {
      final code = row['paymentUniqueCode'] as int?;
      if (code != null) used.add(code);
    }

    final primary = _pickFreeCode(used, 1, 99);
    if (primary != null) return primary;

    final fallback = _pickFreeCode(used, 100, 999);
    if (fallback != null) return fallback;

    throw StateError('Kode unik pembayaran habis. Selesaikan transaksi pending terlebih dahulu.');
  }

  int? _pickFreeCode(Set<int> used, int min, int max) {
    final free = <int>[];
    for (var code = min; code <= max; code++) {
      if (!used.contains(code)) free.add(code);
    }
    if (free.isEmpty) return null;

    // Mulai dari posisi acak supaya nominal tidak mudah ditebak berurutan.
    final start = Random().nextInt(free.length);
    return free[start];
  }

  Future<List<DanaPendingTransaction>> getPendingTransactions() async {
    final rows = await _db.query(
      DatabaseConfig.transactionTableName,
      columns: ['id', 'paymentExpectedAmount', 'totalAmount', 'paymentExpiresAt'],
      where: 'paymentStatus = ? AND paymentProvider = ?',
      whereArgs: ['pending', Constants.danaProviderStatic],
    );

    return rows
        .map(
          (row) => DanaPendingTransaction(
            id: row['id'] as int,
            expectedAmount: (row['paymentExpectedAmount'] as int?) ?? 0,
            baseAmount: (row['totalAmount'] as int?) ?? 0,
            expiresAt: row['paymentExpiresAt'] as String?,
          ),
        )
        .where((row) => row.expectedAmount > 0)
        .toList();
  }

  /// Cari transaksi pending dengan nominal persis sama dan belum kedaluwarsa.
  Future<List<DanaPendingTransaction>> findPendingByAmount(int amount) async {
    final now = DateTime.now().toIso8601String();
    final rows = await _db.query(
      DatabaseConfig.transactionTableName,
      columns: ['id', 'paymentExpectedAmount', 'totalAmount', 'paymentExpiresAt'],
      where:
          'paymentStatus = ? AND paymentProvider = ? AND paymentExpectedAmount = ? '
          'AND (paymentExpiresAt IS NULL OR paymentExpiresAt >= ?)',
      whereArgs: ['pending', Constants.danaProviderStatic, amount, now],
    );

    return rows
        .map(
          (row) => DanaPendingTransaction(
            id: row['id'] as int,
            expectedAmount: (row['paymentExpectedAmount'] as int?) ?? 0,
            baseAmount: (row['totalAmount'] as int?) ?? 0,
            expiresAt: row['paymentExpiresAt'] as String?,
          ),
        )
        .toList();
  }

  /// Transaksi kedaluwarsa yang masih mungkin dibayar terlambat (grace period).
  Future<List<DanaPendingTransaction>> findExpiredByAmount(
    int amount, {
    Duration grace = const Duration(minutes: 60),
  }) async {
    final since = DateTime.now().subtract(grace).toIso8601String();
    final rows = await _db.query(
      DatabaseConfig.transactionTableName,
      columns: ['id', 'paymentExpectedAmount', 'totalAmount', 'paymentExpiresAt'],
      where:
          'paymentStatus = ? AND paymentProvider = ? AND paymentExpectedAmount = ? '
          'AND paymentExpiresAt >= ?',
      whereArgs: ['expired', Constants.danaProviderStatic, amount, since],
    );

    return rows
        .map(
          (row) => DanaPendingTransaction(
            id: row['id'] as int,
            expectedAmount: (row['paymentExpectedAmount'] as int?) ?? 0,
            baseAmount: (row['totalAmount'] as int?) ?? 0,
            expiresAt: row['paymentExpiresAt'] as String?,
          ),
        )
        .toList();
  }

  /// Tandai transaksi pending yang lewat waktu sebagai expired.
  Future<int> sweepExpired() async {
    final now = DateTime.now().toIso8601String();
    return _db.update(
      DatabaseConfig.transactionTableName,
      {'paymentStatus': 'expired', 'updatedAt': now},
      where:
          'paymentStatus = ? AND paymentProvider = ? '
          'AND paymentExpiresAt IS NOT NULL AND paymentExpiresAt < ?',
      whereArgs: ['pending', Constants.danaProviderStatic, now],
    );
  }

  /// Simpan notifikasi DANA. Mengembalikan `false` jika sudah pernah disimpan.
  Future<bool> saveNotification({
    required String notifKey,
    required String packageName,
    required String title,
    required String body,
    int? amount,
    String? postedAt,
    String status = 'unmatched',
    String? rawJson,
  }) async {
    try {
      final id = await _db.insert(
        DatabaseConfig.paymentNotificationTableName,
        {
          'notifKey': notifKey,
          'packageName': packageName,
          'title': title,
          'body': body,
          'amount': amount,
          'postedAt': postedAt,
          'capturedAt': DateTime.now().toIso8601String(),
          'status': status,
          'rawJson': rawJson,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      return id != 0;
    } catch (e) {
      cw('Gagal menyimpan notifikasi DANA: $e');
      return false;
    }
  }

  Future<void> updateNotificationStatus(
    String notifKey, {
    required String status,
    int? matchedTransactionId,
  }) async {
    await _db.update(
      DatabaseConfig.paymentNotificationTableName,
      {
        'status': status,
        'matchedTransactionId': matchedTransactionId,
      },
      where: 'notifKey = ?',
      whereArgs: [notifKey],
    );
  }

  Future<List<DanaNotificationRecord>> getRecentNotifications({int limit = 20}) async {
    final rows = await _db.query(
      DatabaseConfig.paymentNotificationTableName,
      orderBy: 'id DESC',
      limit: limit,
    );

    return rows.map(DanaNotificationRecord.fromMap).toList();
  }

  Future<void> clearNotifications() async {
    await _db.delete(DatabaseConfig.paymentNotificationTableName);
  }
}
