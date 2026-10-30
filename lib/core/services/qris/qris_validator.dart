import 'qris_crc16.dart';
import 'qris_tlv.dart';

/// Hasil validasi QRIS.
class QrisValidationResult {
  final bool isValid;
  final List<String> errors;

  const QrisValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  String get message => errors.join('; ');
}

const String qrisPayloadPrefix = '000201';
const int _minQrisLength = 20;

const Map<String, String> _requiredTags = {
  '00': 'Payload Format Indicator',
  '01': 'Point of Initiation Method',
  '52': 'Merchant Category Code',
  '53': 'Transaction Currency',
  '58': 'Country Code',
  '59': 'Merchant Name',
  '60': 'Merchant City',
  '63': 'CRC',
};

/// Validasi struktur QRIS: prefix, panjang, CRC, tag wajib, merchant info.
///
/// [requireStatic] dipakai saat menyimpan QRIS merchant, karena QRIS dinamis
/// (tag 01 = 12) tidak boleh dipakai sebagai basis konversi.
QrisValidationResult validateQris(String qris, {bool requireStatic = false}) {
  final errors = <String>[];

  if (qris.trim().isEmpty) {
    return const QrisValidationResult(isValid: false, errors: ['QRIS kosong']);
  }

  final normalized = qris.trim();

  if (!normalized.startsWith(qrisPayloadPrefix)) {
    errors.add('QRIS harus diawali "$qrisPayloadPrefix"');
  }

  if (normalized.length < _minQrisLength) {
    errors.add('Panjang QRIS tidak valid');
    return QrisValidationResult(isValid: false, errors: errors);
  }

  final dataWithoutCrc = normalized.substring(0, normalized.length - 4);
  final declaredCrc = normalized.substring(normalized.length - 4).toUpperCase();
  final calculatedCrc = calculateCrc16(dataWithoutCrc);

  if (declaredCrc != calculatedCrc) {
    errors.add('CRC tidak cocok (ditemukan $declaredCrc, seharusnya $calculatedCrc)');
  }

  List<QrisTlv> elements;
  try {
    elements = parseTlv(normalized);
  } on QrisParseException catch (e) {
    errors.add('QRIS tidak dapat dibaca: ${e.message}');
    return QrisValidationResult(isValid: false, errors: errors);
  }

  if (elements.isEmpty) {
    errors.add('Tidak ada data TLV pada QRIS');
    return QrisValidationResult(isValid: false, errors: errors);
  }

  final presentTags = elements.map((e) => e.tag).toSet();
  for (final entry in _requiredTags.entries) {
    if (!presentTags.contains(entry.key)) {
      errors.add('Tag ${entry.key} (${entry.value}) tidak ditemukan');
    }
  }

  final pointOfInitiation = elements.where((e) => e.tag == '01').firstOrNull;
  if (pointOfInitiation != null && pointOfInitiation.value != '11' && pointOfInitiation.value != '12') {
    errors.add('Point of Initiation tidak valid: "${pointOfInitiation.value}"');
  }

  if (requireStatic && pointOfInitiation?.value == '12') {
    errors.add('QRIS ini sudah dinamis (bernominal). Gunakan QRIS statis dari DANA Bisnis');
  }

  final hasMerchantInfo = elements.any((e) {
    final tagNumber = int.tryParse(e.tag);
    return tagNumber != null && tagNumber >= 26 && tagNumber <= 51;
  });

  if (!hasMerchantInfo) {
    errors.add('Merchant Account Information (tag 26-51) tidak ditemukan');
  }

  return QrisValidationResult(isValid: errors.isEmpty, errors: errors);
}

bool isValidQris(String qris, {bool requireStatic = false}) => validateQris(qris, requireStatic: requireStatic).isValid;
