import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../qris/qris_merchant_info.dart';
import '../qris/qris_normalizer.dart';
import '../qris/qris_validator.dart';
import 'qris_dart_decoder.dart';

class QrisImageDecodeResult {
  final String? payload;
  final String? error;
  final int qrFoundCount;
  final bool wasDynamic;
  final List<String> diagnostics;

  const QrisImageDecodeResult({
    this.payload,
    this.error,
    this.qrFoundCount = 0,
    this.wasDynamic = false,
    this.diagnostics = const [],
  });

  bool get isSuccess => payload != null;
}

/// Decode QRIS dari file gambar (galeri/kamera).
///
/// Strategi berlapis:
/// 1. Decoder native (MLKit lewat `mobile_scanner`) — cepat untuk gambar jelas.
/// 2. Fallback decoder Dart murni (port ZXing) dengan resize, kontras, invert,
///    dan rotasi — menutup kasus MLKit gagal pada gambar kurang sempurna.
///
/// QRIS dinamis yang diunggah otomatis dinormalisasi menjadi statis.
class QrisImageDecoder {
  Future<QrisImageDecodeResult> decodeFile(String path) async {
    final diagnostics = <String>[];
    var qrFoundCount = 0;

    try {
      final nativeValues = await _decodeNative(path, diagnostics);
      qrFoundCount = nativeValues.length;

      final nativeMatch = _firstValidCandidate(nativeValues);
      if (nativeMatch != null) {
        _log('native: ${nativeMatch.payload.substring(0, 20)}...');
        return QrisImageDecodeResult(
          payload: nativeMatch.payload,
          qrFoundCount: qrFoundCount,
          wasDynamic: nativeMatch.wasDynamic,
          diagnostics: diagnostics,
        );
      }

      final dartResult = await _decodeWithDart(path);
      diagnostics.addAll(dartResult.attempts);
      if (dartResult.isSuccess) {
        final match = _firstValidCandidate([dartResult.payload!]);
        if (match != null) {
          _log('dart fallback: ${match.payload.substring(0, 20)}...');
          return QrisImageDecodeResult(
            payload: match.payload,
            qrFoundCount: qrFoundCount > 0 ? qrFoundCount : 1,
            wasDynamic: match.wasDynamic,
            diagnostics: diagnostics,
          );
        }
      }

      _log('decode gagal: $diagnostics');

      if (qrFoundCount > 0) {
        return QrisImageDecodeResult(
          error:
              'QR terbaca, tetapi bukan QRIS yang valid. '
              'Pastikan menggunakan QRIS dari DANA Bisnis, bukan kode lain.',
          qrFoundCount: qrFoundCount,
          diagnostics: diagnostics,
        );
      }

      return QrisImageDecodeResult(
        error:
            'QR tidak terdeteksi. Coba foto lebih dekat dengan cahaya cukup, '
            'atau tempel kode QRIS secara manual.',
        diagnostics: diagnostics,
      );
    } catch (e) {
      _log('decode error: $e');
      return QrisImageDecodeResult(
        error: 'Gagal membaca gambar: $e',
        diagnostics: diagnostics,
      );
    } finally {
      // File hasil pick hanya dipakai untuk decode, jangan menumpuk di cache.
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Abaikan kegagalan hapus file sementara.
      }
    }
  }

  Future<List<String>> _decodeNative(
    String path,
    List<String> diagnostics,
  ) async {
    MobileScannerController? controller;
    try {
      controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        autoStart: false,
      );
      final capture = await controller.analyzeImage(path);
      final values = (capture?.barcodes ?? const <Barcode>[])
          .map((barcode) => barcode.rawValue)
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      diagnostics.add(
        'mlkit: ${values.isEmpty ? 'tidak ada QR' : '${values.length} QR'}',
      );
      return values;
    } catch (e) {
      // mobile_scanner menelan sebagian error native; catat untuk diagnosa.
      diagnostics.add('mlkit: error ${e.runtimeType}');
      return const [];
    } finally {
      await controller?.dispose();
    }
  }

  Future<QrisDartDecodeResult> _decodeWithDart(String path) async {
    try {
      return await Isolate.run(() => decodeQrisWithDart(path));
    } catch (_) {
      return decodeQrisWithDart(path);
    }
  }

  _QrisCandidate? _firstValidCandidate(List<String> rawValues) {
    for (final raw in rawValues) {
      final candidate = _interpret(raw);
      if (candidate != null) return candidate;
    }
    return null;
  }

  /// Ubah payload mentah hasil scan menjadi QRIS statis yang siap disimpan.
  _QrisCandidate? _interpret(String raw) {
    // Jangan hapus spasi: spasi adalah bagian sah dari nilai tag 59/60.
    final normalized = sanitizeQrisInput(raw);
    if (normalized.isEmpty || !normalized.startsWith(qrisPayloadPrefix)) {
      return null;
    }

    final validation = validateQris(normalized);
    if (!validation.isValid) {
      _log('kandidat tidak valid: ${validation.message}');
      return null;
    }

    final wasDynamic = isDynamicQris(normalized);
    final staticPayload = wasDynamic ? toStaticQris(normalized) : normalized;
    final staticValidation = validateQris(staticPayload, requireStatic: true);
    if (!staticValidation.isValid) {
      _log('normalisasi gagal: ${staticValidation.message}');
      return null;
    }

    // Pastikan data merchant tetap terbaca setelah normalisasi.
    final info = QrisMerchantInfo.tryParse(staticPayload);
    if (info == null || (info.merchantName.isEmpty && info.nmid.isEmpty)) {
      return null;
    }

    return _QrisCandidate(payload: staticPayload, wasDynamic: wasDynamic);
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[QRIS decode] $message');
  }
}

class _QrisCandidate {
  final String payload;
  final bool wasDynamic;

  const _QrisCandidate({required this.payload, required this.wasDynamic});
}
