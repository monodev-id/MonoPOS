import 'package:flutter_test/flutter_test.dart';

import 'package:mono_pos/core/services/payment/dana_notification_parser.dart';

void main() {
  group('parseDanaNotification', () {
    test('mendeteksi pembayaran masuk DANA Bisnis', () {
      final result = parseDanaNotification(
        title: 'Pembayaran Masuk',
        body: 'Rp1.426 diterima DANA Bisnis.',
        packageName: 'id.dana',
      );

      expect(result.isIncomingPayment, isTrue);
      expect(result.amount, 1426);
    });

    test('mendeteksi nominal ribuan dengan titik', () {
      final result = parseDanaNotification(
        title: 'Pembayaran Masuk',
        body: 'Rp25.042 diterima DANA Bisnis.',
      );

      expect(result.amount, 25042);
    });

    test('menerima notifikasi DANA Kasir tanpa kata bisnis', () {
      final result = parseDanaNotification(
        title: 'Pembayaran diterima',
        body: 'Rp30.000 masuk',
        packageName: 'id.dana.kasir',
      );

      expect(result.isIncomingPayment, isTrue);
      expect(result.amount, 30000);
    });

    test('menolak transfer pribadi tanpa konteks bisnis', () {
      final result = parseDanaNotification(
        title: 'DANA',
        body: 'Kamu berhasil menerima Rp25.042 dari JOHN DOE',
        packageName: 'id.dana',
      );

      expect(result.isIncomingPayment, isFalse);
    });

    test('menolak transaksi keluar', () {
      final result = parseDanaNotification(
        title: 'Pembayaran berhasil',
        body: 'Rp50.000 dibayar ke TOKO MAJU',
      );

      expect(result.isIncomingPayment, isFalse);
    });

    test('menolak notifikasi saldo', () {
      final result = parseDanaNotification(
        title: 'Info Saldo',
        body: 'Saldo DANA kamu Rp100.000',
      );

      expect(result.isIncomingPayment, isFalse);
    });

    test('menolak teks tanpa nominal', () {
      final result = parseDanaNotification(
        title: 'Pembayaran masuk',
        body: 'Segera cek aplikasi DANA Bisnis',
      );

      expect(result.isIncomingPayment, isFalse);
    });
  });

  group('parseAmount', () {
    test('titik sebagai pemisah ribuan', () {
      expect(parseAmount('1.426'), 1426);
      expect(parseAmount('25.042'), 25042);
      expect(parseAmount('1.234.567'), 1234567);
    });

    test('koma desimal diabaikan', () {
      expect(parseAmount('25.000,00'), 25000);
      expect(parseAmount('1.426,50'), 1426);
    });

    test('angka polos', () {
      expect(parseAmount('15007'), 15007);
    });

    test('nilai tidak valid', () {
      expect(parseAmount(''), isNull);
      expect(parseAmount('abc'), isNull);
    });
  });
}
