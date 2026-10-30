import 'qris_crc16.dart';
import 'qris_tlv.dart';

/// Normalisasi QRIS agar bisa dipakai sebagai basis konversi.
///
/// QRIS yang diunggah merchant kadang sudah dalam bentuk dinamis (tag 01 = 12)
/// atau masih membawa nominal/biaya dari transaksi sebelumnya. Fungsi ini
/// membuang tag nominal (54), biaya (55/56/57), dan CRC lama, mengubah tag 01
/// menjadi statis (`11`), lalu menghitung ulang CRC.
class QrisNormalizeException implements Exception {
  final String message;

  const QrisNormalizeException(this.message);

  @override
  String toString() => message;
}

const Set<String> _dynamicOnlyTags = {'54', '55', '56', '57', '63'};
const String _crcPlaceholder = '6304';

/// Kembalikan QRIS statis hasil normalisasi.
///
/// [qris] harus berupa payload TLV QRIS (boleh statis maupun dinamis).
/// Melempar [QrisNormalizeException] bila struktur tidak bisa dibaca.
String toStaticQris(String qris) {
  final normalized = qris.trim();
  if (normalized.isEmpty) {
    throw const QrisNormalizeException('QRIS kosong');
  }

  final List<QrisTlv> elements;
  try {
    elements = parseTlv(normalized);
  } on QrisParseException catch (e) {
    throw QrisNormalizeException(e.message);
  }

  if (elements.isEmpty) {
    throw const QrisNormalizeException('Struktur TLV QRIS tidak valid');
  }

  final result = <QrisTlv>[];
  var hasPointOfInitiation = false;

  for (final element in elements) {
    if (_dynamicOnlyTags.contains(element.tag)) continue;

    if (element.tag == '01') {
      result.add(const QrisTlv(tag: '01', value: '11'));
      hasPointOfInitiation = true;
      continue;
    }

    result.add(element);
  }

  if (!hasPointOfInitiation) {
    final payloadFormatIndex = result.indexWhere((e) => e.tag == '00');
    result.insert(
      payloadFormatIndex < 0 ? 0 : payloadFormatIndex + 1,
      const QrisTlv(tag: '01', value: '11'),
    );
  }

  final withoutCrc = buildTlv(result);
  final crcInput = '$withoutCrc$_crcPlaceholder';
  return '$crcInput${calculateCrc16(crcInput)}';
}

/// True bila QRIS membawa penanda dinamis (tag 01 = 12 atau ada tag 54).
bool isDynamicQris(String qris) {
  try {
    final elements = parseTlv(qris.trim());
    final pointOfInitiation = elements.where((e) => e.tag == '01').firstOrNull;
    final hasAmount = elements.any((e) => e.tag == '54');
    return pointOfInitiation?.value == '12' || hasAmount;
  } catch (_) {
    return false;
  }
}
