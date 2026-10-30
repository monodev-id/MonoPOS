import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// Decoder QRIS murni Dart (port ZXing) yang dipakai sebagai fallback ketika
/// decoder native (MLKit) gagal membaca gambar.
///
/// Semua proses berjalan offline di perangkat. Gambar tidak dikirim ke server.
class QrisDartDecodeResult {
  final String? payload;
  final List<String> attempts;
  final int? width;
  final int? height;

  const QrisDartDecodeResult({
    this.payload,
    this.attempts = const [],
    this.width,
    this.height,
  });

  bool get isSuccess => payload != null;
}

const int _maxDecodeDimension = 2048;
const int _minDecodeDimension = 320;

/// Coba baca QR dari [path] dengan beberapa variasi preprocessing.
///
/// Variasi dibuat bertahap supaya gambar buram, gelap, miring, atau hasil
/// screenshot (termasuk yang ter-invert) tetap punya peluang terbaca.
QrisDartDecodeResult decodeQrisWithDart(String path) {
  final attempts = <String>[];

  final file = File(path);
  if (!file.existsSync()) {
    return const QrisDartDecodeResult(attempts: ['file tidak ditemukan']);
  }

  final bytes = file.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return const QrisDartDecodeResult(
      attempts: ['format gambar tidak dikenali'],
    );
  }

  final base = _resizeForDecode(decoded);
  final width = base.width;
  final height = base.height;

  for (final variant in _variants(base)) {
    try {
      final payload = _decodeImage(variant.image);
      attempts.add(
        '${variant.label}: ${payload == null ? 'tidak terbaca' : 'OK'}',
      );
      if (payload != null && payload.trim().isNotEmpty) {
        return QrisDartDecodeResult(
          payload: payload.trim(),
          attempts: attempts,
          width: width,
          height: height,
        );
      }
    } catch (e) {
      attempts.add('${variant.label}: error ${e.runtimeType}');
    }
  }

  return QrisDartDecodeResult(attempts: attempts, width: width, height: height);
}

String? _decodeImage(img.Image image) {
  final pixels = image
      .convert(numChannels: 4)
      .getBytes(order: img.ChannelOrder.abgr)
      .buffer
      .asInt32List();

  final source = RGBLuminanceSource(image.width, image.height, pixels);
  final bitmap = BinaryBitmap(HybridBinarizer(source));
  final hints = DecodeHints()..put(DecodeHintType.tryHarder);

  try {
    return QRCodeReader().decode(bitmap, hints: hints).text;
  } on ReaderException {
    return null;
  }
}

img.Image _resizeForDecode(img.Image source) {
  var image = img.bakeOrientation(source);
  final longestSide = image.width > image.height ? image.width : image.height;

  if (longestSide > _maxDecodeDimension) {
    final scale = _maxDecodeDimension / longestSide;
    image = img.copyResize(
      image,
      width: (image.width * scale).round().clamp(1, _maxDecodeDimension),
      height: (image.height * scale).round().clamp(1, _maxDecodeDimension),
      interpolation: img.Interpolation.average,
    );
  } else if (longestSide < _minDecodeDimension) {
    final scale = _minDecodeDimension / longestSide;
    image = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }

  return image;
}

class _Variant {
  final String label;
  final img.Image image;

  const _Variant(this.label, this.image);
}

List<_Variant> _variants(img.Image base) {
  final grayscale = img.grayscale(base);
  final enhanced = img.adjustColor(
    img.Image.from(base),
    contrast: 1.45,
    brightness: 1.05,
  );

  return [
    _Variant('asli ${base.width}x${base.height}', base),
    _Variant('kontras', img.grayscale(enhanced)),
    _Variant('abu-abu', grayscale),
    _Variant('invert', img.invert(img.Image.from(base))),
    _Variant('rotasi 90', img.copyRotate(base, angle: 90)),
    _Variant('rotasi 270', img.copyRotate(base, angle: 270)),
    _Variant('rotasi 180', img.copyRotate(base, angle: 180)),
  ];
}
