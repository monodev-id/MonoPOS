import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/core/services/payment/qris_dart_decoder.dart';
import 'package:mono_pos/core/services/qris/qris_merchant_info.dart';
import 'package:mono_pos/core/services/qris/qris_normalizer.dart';
import 'package:mono_pos/core/services/qris/qris_validator.dart';

const _expectedPayload =
    '00020101021126570011ID.DANA.WWW011893600915303467789702090346778970303UMI'
    '51440014ID.CO.QRIS.WWW0215ID10265829773140303UMI5204549953033605802ID'
    '5915Kedai Dua Putri6015Kab. Padang Par610525586630445E7';

void main() {
  test('decode QRIS asli Kedai Dua Putri dengan fallback Dart', () {
    var file = File('test/fixtures/qrisduaputri.jpeg');
    if (!file.existsSync()) {
      file = File('assets/images/qrisduaputri.jpeg');
    }
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));

    final result = decodeQrisWithDart(file.path);

    expect(result.isSuccess, isTrue, reason: result.attempts.join(' | '));
    expect(result.payload, _expectedPayload);
    expect(result.width, 1136);
    expect(result.height, 1600);

    // Payload hasil decode harus lolos sanitasi & validasi seperti di aplikasi.
    final sanitized = sanitizeQrisInput(result.payload!);
    expect(sanitized, _expectedPayload);
    expect(sanitizeQrisInput(sanitized), sanitized);
    expect(validateQris(sanitized, requireStatic: true).isValid, isTrue);

    final info = QrisMerchantInfo.tryParse(sanitized);
    expect(info, isNotNull);
    expect(info!.merchantName, 'Kedai Dua Putri');
    expect(info.merchantCity, 'Kab. Padang Par');
    expect(info.nmid, 'ID1026582977314');
    expect(info.acquirer, 'ID.DANA.WWW');
    expect(info.crcValid, isTrue);
  });
}
