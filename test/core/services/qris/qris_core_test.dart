import 'package:flutter_test/flutter_test.dart';

import 'package:mono_pos/core/services/qris/qris_converter.dart';
import 'package:mono_pos/core/services/qris/qris_crc16.dart';
import 'package:mono_pos/core/services/qris/qris_merchant_info.dart';
import 'package:mono_pos/core/services/qris/qris_tlv.dart';
import 'package:mono_pos/core/services/qris/qris_validator.dart';

const _samplePayload =
    '00020101021126560014ID.CO.QRIS.WWW0115ID10231625260990215ID10231625260995204581253033605802ID5914TOKO BITS JAYA6007JAKARTA6105123456304';

String get _validQris => '$_samplePayload${calculateCrc16(_samplePayload)}';

void main() {
  group('CRC16', () {
    test('menghitung CRC untuk payload QRIS', () {
      final crc = calculateCrc16(_samplePayload);
      expect(crc.length, 4);
      expect(RegExp(r'^[0-9A-F]{4}$').hasMatch(crc), isTrue);
    });

    test('string kosong menghasilkan FFFF', () {
      expect(calculateCrc16(''), 'FFFF');
    });

    test('deterministik', () {
      expect(calculateCrc16(_samplePayload), calculateCrc16(_samplePayload));
    });

    test('isCrcValid mengenali CRC valid dan rusak', () {
      expect(isCrcValid(_validQris), isTrue);
      expect(isCrcValid('${_samplePayload}0000'), isFalse);
    });
  });

  group('parseTlv', () {
    test('parse elemen dasar', () {
      final elements = parseTlv(_validQris);
      expect(elements.length, greaterThan(0));
      expect(elements.first.tag, '00');
      expect(elements.first.value, '01');
    });

    test('string kosong menghasilkan list kosong', () {
      expect(parseTlv(''), isEmpty);
    });

    test('tag merchant info punya children', () {
      final tag26 = parseTlv(_validQris).firstWhere((e) => e.tag == '26');
      expect(tag26.children, isNotNull);
      expect(tag26.children!.isNotEmpty, isTrue);
      expect(tag26.child('00')?.value, 'ID.CO.QRIS.WWW');
    });

    test('menolak tag tidak valid', () {
      expect(() => parseTlv('AB0201'), throwsA(isA<QrisParseException>()));
    });

    test('menolak non-ASCII', () {
      expect(() => parseTlv('00020101é'), throwsA(isA<QrisParseException>()));
    });
  });

  group('validateQris', () {
    test('QRIS valid', () {
      expect(validateQris(_validQris).isValid, isTrue);
    });

    test('CRC salah ditolak', () {
      final result = validateQris('${_samplePayload}0000');
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('CRC')), isTrue);
    });

    test('QRIS dinamis ditolak saat requireStatic', () {
      final dynamicQris = convertQris(_validQris, amount: 50000);
      expect(validateQris(dynamicQris).isValid, isTrue);

      final result = validateQris(dynamicQris, requireStatic: true);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('dinamis')), isTrue);
    });

    test('string kosong ditolak', () {
      expect(validateQris('').isValid, isFalse);
    });
  });

  group('convertQris', () {
    test('menyisipkan nominal 50000', () {
      final dynamic = convertQris(_validQris, amount: 50000);
      expect(dynamic.contains('540550000'), isTrue);
      expect(validateQris(dynamic).isValid, isTrue);
    });

    test('mengubah tag 01 menjadi dinamis', () {
      final dynamic = convertQris(_validQris, amount: 15007);
      final method = parseTlv(dynamic).firstWhere((e) => e.tag == '01');
      expect(method.value, '12');
      expect(dynamic.contains('540515007'), isTrue);
    });

    test('membedakan nominal dengan kode unik', () {
      final a = convertQris(_validQris, amount: 15000);
      final b = convertQris(_validQris, amount: 15007);
      expect(a, isNot(b));
      expect(b.contains('540515007'), isTrue);
    });

    test('QRIS dinamis yang dikonversi ulang tetap valid', () {
      final dynamic = convertQris(_validQris, amount: 20000);
      final reconverted = convertQris(dynamic, amount: 20001);
      expect(validateQris(reconverted).isValid, isTrue);
      expect(reconverted.contains('540520001'), isTrue);
    });

    test('menolak nominal tidak valid', () {
      expect(() => convertQris(_validQris, amount: 0), throwsA(isA<QrisConvertException>()));
      expect(() => convertQris(_validQris, amount: -1), throwsA(isA<QrisConvertException>()));
    });

    test('menolak QRIS kosong', () {
      expect(() => convertQris('', amount: 1000), throwsA(isA<QrisConvertException>()));
    });
  });

  group('QrisMerchantInfo', () {
    test('membaca nama merchant, kota, dan NMID', () {
      final info = QrisMerchantInfo.tryParse(_validQris);
      expect(info, isNotNull);
      expect(info!.merchantName, 'TOKO BITS JAYA');
      expect(info.merchantCity, 'JAKARTA');
      expect(info.nmid, 'ID1023162526099');
      expect(info.acquirer, 'ID.CO.QRIS.WWW');
      expect(info.crcValid, isTrue);
    });
  });
}
