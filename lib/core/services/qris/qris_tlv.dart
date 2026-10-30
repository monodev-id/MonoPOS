/// EMVCo TLV (Tag-Length-Value) parser & builder untuk QRIS.
///
/// Port Dart dari `BITS-QRIS-Converter` (MIT License)
/// https://github.com/Banten-IT-Solutions/BITS-QRIS-Converter
library;

/// Tag yang nilainya berupa TLV bersarang.
const Set<String> qrisNestedTags = {
  '26',
  '27',
  '28',
  '29',
  '30',
  '31',
  '32',
  '33',
  '34',
  '35',
  '36',
  '37',
  '38',
  '39',
  '40',
  '41',
  '42',
  '43',
  '44',
  '45',
  '46',
  '47',
  '48',
  '49',
  '50',
  '51',
  '62',
};

class QrisParseException implements Exception {
  final String message;

  const QrisParseException(this.message);

  @override
  String toString() => message;
}

class QrisTlv {
  final String tag;
  final String value;
  final List<QrisTlv>? children;

  const QrisTlv({
    required this.tag,
    required this.value,
    this.children,
  });

  int get length => value.length;

  String encode() {
    final encodedValue = children != null ? buildTlv(children!) : value;
    return '$tag${_padLength(encodedValue.length)}$encodedValue';
  }

  QrisTlv? child(String childTag) {
    final list = children;
    if (list == null) return null;
    for (final child in list) {
      if (child.tag == childTag) return child;
    }
    return null;
  }
}

String _padLength(int length) {
  if (length > 99) {
    throw const QrisParseException('TLV length exceeds max 99');
  }
  return length.toString().padLeft(2, '0');
}

/// Parse raw TLV string menjadi daftar elemen.
List<QrisTlv> parseTlv(String data) {
  if (data.isEmpty) return const [];

  for (final codeUnit in data.codeUnits) {
    if (codeUnit > 0x7F) {
      throw const QrisParseException('Non-ASCII payload not supported');
    }
  }

  final elements = <QrisTlv>[];
  var position = 0;

  while (position < data.length) {
    if (position + 4 > data.length) {
      throw QrisParseException('Invalid TLV: truncated header at position $position');
    }

    final tag = data.substring(position, position + 2);
    final lengthStr = data.substring(position + 2, position + 4);

    if (!_twoDigits.hasMatch(tag)) {
      throw QrisParseException('Invalid TLV: invalid tag "$tag" at position $position');
    }

    if (!_twoDigits.hasMatch(lengthStr)) {
      throw QrisParseException(
        'Invalid TLV: non-numeric length "$lengthStr" at position $position (tag $tag)',
      );
    }

    final length = int.parse(lengthStr);

    if (position + 4 + length > data.length) {
      throw QrisParseException('Invalid TLV: truncated value at position $position (tag $tag)');
    }

    final value = data.substring(position + 4, position + 4 + length);
    final children = qrisNestedTags.contains(tag) ? parseTlv(value) : null;

    elements.add(QrisTlv(tag: tag, value: value, children: children));
    position += 4 + length;
  }

  return elements;
}

/// Susun kembali daftar elemen menjadi string TLV.
String buildTlv(List<QrisTlv> elements) {
  final buffer = StringBuffer();
  for (final element in elements) {
    buffer.write(element.encode());
  }
  return buffer.toString();
}

final RegExp _twoDigits = RegExp(r'^\d{2}$');
