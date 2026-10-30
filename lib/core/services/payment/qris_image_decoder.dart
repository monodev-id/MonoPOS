import 'dart:io';

import 'package:mobile_scanner/mobile_scanner.dart';

import '../qris/qris_validator.dart';

class QrisImageDecodeResult {
  final String? payload;
  final String? error;
  final int qrFoundCount;

  const QrisImageDecodeResult({
    this.payload,
    this.error,
    this.qrFoundCount = 0,
  });

  bool get isSuccess => payload != null;
}

/// Decode QRIS dari file gambar (galeri/kamera) memakai native scanner.
class QrisImageDecoder {
  Future<QrisImageDecodeResult> decodeFile(String path) async {
    MobileScannerController? controller;

    try {
      controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
      final capture = await controller.analyzeImage(path);

      final rawValues = (capture?.barcodes ?? const <Barcode>[])
          .map((barcode) => barcode.rawValue)
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();

      if (rawValues.isEmpty) {
        return const QrisImageDecodeResult(
          error: 'QR tidak terdeteksi. Pastikan gambar tidak blur dan QR terlihat utuh.',
        );
      }

      final qrisCandidates = rawValues.where((value) => value.startsWith(qrisPayloadPrefix)).toList();

      if (qrisCandidates.isEmpty) {
        return QrisImageDecodeResult(
          error: 'Gambar ini bukan QRIS.',
          qrFoundCount: rawValues.length,
        );
      }

      String? dynamicError;
      for (final candidate in qrisCandidates) {
        final validation = validateQris(candidate, requireStatic: true);
        if (validation.isValid) {
          return QrisImageDecodeResult(
            payload: candidate,
            qrFoundCount: qrisCandidates.length,
          );
        }

        if (validation.errors.any((e) => e.contains('sudah dinamis'))) {
          dynamicError = 'Ini QRIS dinamis (sudah ada nominal). Gunakan QRIS statis dari DANA Bisnis.';
        }
      }

      return QrisImageDecodeResult(
        error: dynamicError ?? 'QRIS tidak valid atau rusak. Coba upload ulang atau tempel kode QRIS manual.',
        qrFoundCount: qrisCandidates.length,
      );
    } catch (e) {
      return QrisImageDecodeResult(error: 'Gagal membaca gambar: $e');
    } finally {
      await controller?.dispose();

      // File hasil pick hanya dipakai untuk decode, jangan menumpuk di cache.
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Abaikan kegagalan hapus file sementara.
      }
    }
  }
}
