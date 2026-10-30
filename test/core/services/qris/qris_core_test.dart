import 'package:flutter_test/flutter_test.dart';

import 'package:mono_pos/core/services/qris/qris_converter.dart';
import 'package:mono_pos/core/services/qris/qris_crc16.dart';
import 'package:mono_pos/core/services/qris/qris_merchant_info.dart';
import 'package:mono_pos/core/services/qris/qris_normalizer.dart';
import 'package:mono_pos/core/services/qris/qris_tlv.dart';
import 'package:mono_pos/core/services/qris/qris_validator.dart';

const _samplePayload =
    '00020101021126560014ID.CO.QRIS.WWW0115ID10231625260990215ID10231625260995204581253033605802ID5914TOKO BITS JAYA6007JAKARTA6105123456304';

String get _validQris => '$_samplePayload${calculateCrc16(_samplePayload)}';

/// Vektor nyata: QRIS statis DANA Bisnis milik "Kedai Dua Putri".
const _kedaiDuaPutriQris =
    '00020101021126570011ID.DANA.WWW011893600915303467789702090346778970303UMI'
    '51440014ID.CO.QRIS.WWW0215ID10265829773140303UMI5204549953033605802ID'
    '5915Kedai Dua Putri6015Kab. Padang Par610525586630445E7';

/// Vektor dinamis dari dokumentasi BITS (Monoframe Studio, Padang).
const _monoframeDynamicQris =
    '00020101021226610014COM.GO-JEK.WWW01189360091434239717110210G4239717110303UMI'
    '51440014ID.CO.QRIS.WWW0215ID10254202001030303UMI520473335303360540550000'
    '5802ID5925Monoframe Studio, PDNG TR6006PADANG61052513262070703A0163040716';

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
      expect(
        () => convertQris(_validQris, amount: 0),
        throwsA(isA<QrisConvertException>()),
      );
      expect(
        () => convertQris(_validQris, amount: -1),
        throwsA(isA<QrisConvertException>()),
      );
    });

    test('menolak QRIS kosong', () {
      expect(
        () => convertQris('', amount: 1000),
        throwsA(isA<QrisConvertException>()),
      );
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

  group('QRIS Kedai Dua Putri (vektor nyata)', () {
    test('statis dan CRC valid', () {
      final result = validateQris(_kedaiDuaPutriQris, requireStatic: true);
      expect(result.isValid, isTrue, reason: result.message);
      expect(isCrcValid(_kedaiDuaPutriQris), isTrue);
    });

    test('membaca merchant, kota, NMID, dan acquirer DANA', () {
      final info = QrisMerchantInfo.tryParse(_kedaiDuaPutriQris);
      expect(info, isNotNull);
      expect(info!.merchantName, 'Kedai Dua Putri');
      expect(info.merchantCity, 'Kab. Padang Par');
      expect(info.nmid, 'ID1026582977314');
      expect(info.acquirer, 'ID.DANA.WWW');
      expect(info.crcValid, isTrue);
    });

    test('konversi nominal menyisipkan tag 54 dan CRC tetap valid', () {
      final dynamic = convertQris(_kedaiDuaPutriQris, amount: 25007);
      expect(dynamic.contains('540525007'), isTrue);
      expect(validateQris(dynamic).isValid, isTrue);
      expect(
        parseTlv(dynamic).firstWhere((e) => e.tag == '01').value,
        '12',
      );
    });
  });

  group('toStaticQris', () {
    test('QRIS statis tetap sama setelah dinormalisasi', () {
      final normalized = toStaticQris(_kedaiDuaPutriQris);
      expect(normalized, _kedaiDuaPutriQris);
      expect(validateQris(normalized, requireStatic: true).isValid, isTrue);
    });

    test('QRIS dinamis diubah menjadi statis tanpa tag nominal', () {
      expect(isDynamicQris(_monoframeDynamicQris), isTrue);

      final normalized = toStaticQris(_monoframeDynamicQris);
      final tags = parseTlv(normalized).map((e) => e.tag).toSet();

      expect(tags.contains('54'), isFalse);
      expect(
        parseTlv(normalized).firstWhere((e) => e.tag == '01').value,
        '11',
      );
      expect(validateQris(normalized, requireStatic: true).isValid, isTrue);
      expect(isCrcValid(normalized), isTrue);

      final info = QrisMerchantInfo.tryParse(normalized);
      expect(info!.merchantName, 'Monoframe Studio, PDNG TR');
      expect(info.nmid, 'ID1025420200103');
    });

    test('hasil konversi bisa dikembalikan ke statis', () {
      final dynamic = convertQris(_kedaiDuaPutriQris, amount: 15000);
      expect(isDynamicQris(dynamic), isTrue);

      final normalized = toStaticQris(dynamic);
      expect(normalized, _kedaiDuaPutriQris);
    });

    test('menolak string yang bukan TLV', () {
      expect(() => toStaticQris(''), throwsA(isA<QrisNormalizeException>()));
      expect(
        () => toStaticQris('bukan-qris'),
        throwsA(isA<QrisNormalizeException>()),
      );
    });
  });
}
