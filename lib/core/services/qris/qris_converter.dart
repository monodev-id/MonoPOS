import 'qris_crc16.dart';
import 'qris_tlv.dart';

/// Konversi QRIS statis → dinamis dengan menyisipkan nominal.
///
/// Port Dart dari `BITS-QRIS-Converter` (MIT License).
class QrisConvertException implements Exception {
  final String message;

  const QrisConvertException(this.message);

  @override
  String toString() => message;
}

const String _crcPlaceholder = '6304';
const int _maxQrisAmount = 999999999999999; // 15 digit

const Set<String> _managedTags = {'54', '55', '56', '57', '63'};

/// Ubah QRIS statis menjadi QRIS dinamis bernominal [amount].
///
/// Tag 54 (nominal) disisipkan sebelum tag 58, tag 01 diubah menjadi `12`,
/// lalu CRC dihitung ulang.
String convertQris(String qris, {required int amount}) {
  if (qris.trim().isEmpty) {
    throw const QrisConvertException('QRIS tidak boleh kosong');
  }

  if (amount <= 0) {
    throw QrisConvertException('Nominal harus lebih dari 0 (diterima: $amount)');
  }

  if (amount > _maxQrisAmount) {
    throw const QrisConvertException('Nominal melebihi batas maksimum QRIS');
  }

  final normalized = qris.trim();
  final elements = parseTlv(normalized);

  if (elements.isEmpty) {
    throw const QrisConvertException('Struktur TLV QRIS tidak valid');
  }

  final result = <QrisTlv>[];
  var amountInserted = false;

  for (final element in elements) {
    if (_managedTags.contains(element.tag)) continue;

    if (element.tag == '01') {
      result.add(const QrisTlv(tag: '01', value: '12'));
      continue;
    }

    if (element.tag == '58' && !amountInserted) {
      result.add(QrisTlv(tag: '54', value: amount.toString()));
      amountInserted = true;
    }

    result.add(element);
  }

  if (!amountInserted) {
    result.add(QrisTlv(tag: '54', value: amount.toString()));
  }

  final withoutCrc = buildTlv(result);
  final crcInput = '$withoutCrc$_crcPlaceholder';
  final crc = calculateCrc16(crcInput);

  return '$crcInput$crc';
}
