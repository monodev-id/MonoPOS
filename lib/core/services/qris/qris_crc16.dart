/// CRC16-CCITT untuk QRIS/EMVCo (poly 0x1021, init 0xFFFF).
///
/// Port Dart dari `BITS-QRIS-Converter` (MIT License).
library;

const int _crcPolynomial = 0x1021;
const int _crcInit = 0xFFFF;

/// Hitung CRC16 dan kembalikan 4 karakter hex uppercase.
String calculateCrc16(String data) {
  var crc = _crcInit;

  for (final codeUnit in data.codeUnits) {
    crc ^= codeUnit << 8;

    for (var i = 0; i < 8; i++) {
      if (crc & 0x8000 != 0) {
        crc = ((crc << 1) ^ _crcPolynomial) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
  }

  return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
}

/// Bandingkan CRC di 4 karakter terakhir dengan hasil hitung ulang.
bool isCrcValid(String qris) {
  if (qris.length < 4) return false;

  final withoutCrc = qris.substring(0, qris.length - 4);
  final declared = qris.substring(qris.length - 4).toUpperCase();
  return calculateCrc16(withoutCrc) == declared;
}
