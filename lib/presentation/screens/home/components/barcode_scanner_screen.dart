import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../domain/usecases/product_usecases.dart';
import '../../../widgets/app_snack_bar.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

const _linearFormats = {
  BarcodeFormat.ean13,
  BarcodeFormat.ean8,
  BarcodeFormat.upcA,
  BarcodeFormat.upcE,
  BarcodeFormat.itf,
};

final _digitsOnly = RegExp(r'^[0-9]+$');

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: _linearFormats.toList(),
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final detected = capture.barcodes.firstOrNull;
    final rawBarcode = detected?.rawValue;
    if (rawBarcode == null || rawBarcode.trim().isEmpty) return;
    final barcode = rawBarcode.trim();

    if (!_linearFormats.contains(detected?.format) || !_digitsOnly.hasMatch(barcode)) {
      AppSnackBar.showError('Hanya kode batang angka');
      return;
    }

    _isProcessing = true;

    final repo = ref.read(productRepositoryProvider);
    final result = await GetProductByBarcodeUsecase(repo).call(barcode);

    if (!mounted) return;

    if (result.isFailure) {
      _isProcessing = false;
      AppSnackBar.showError(result.error?.toString() ?? 'Gagal mencari produk');
    } else if (result.data == null) {
      _isProcessing = false;
      AppSnackBar.showError('Produk dengan barcode "$barcode" tidak ditemukan');
    } else {
      Navigator.pop(context, barcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 32,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  'Arahkan kamera ke barcode produk',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
