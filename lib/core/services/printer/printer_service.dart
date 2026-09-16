import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../generated/app_localizations.dart';
import '../../../generated/app_localizations_id.dart';
import '../../../generated/app_localizations_en.dart';
import '../../common/result.dart';
import '../../constants/constants.dart';
import '../../utilities/barcode_generator.dart';
import '../../utilities/console_logger.dart';
import '../../utilities/currency_formatter.dart';
import '../../utilities/date_time_formatter.dart';

class PrinterService {
  final PrinterManager _manager = PrinterManager();
  final SharedPreferences _sharedPreferences;
  String _languageCode = 'id';

  PrinterService(this._sharedPreferences);

  AppLocalizations get _l10n {
    if (_languageCode == 'id') return AppLocalizationsId();
    return AppLocalizationsEn();
  }

  void setLocale(String languageCode) {
    _languageCode = languageCode;
  }

  List<PrinterDevice> printers = [];
  PrinterDevice? selectedPrinter;

  PrinterConnectionState get connectionState => _manager.state;
  Stream<PrinterConnectionState> get stateStream => _manager.stateStream;
  bool get isConnected => _manager.isConnected;

  PaperSize get paperSize {
    final saved = _sharedPreferences.getString(Constants.selectedPaperSizeKey);
    return switch (saved) {
      'mm72' => PaperSize.mm72,
      'mm80' => PaperSize.mm80,
      _ => PaperSize.mm58,
    };
  }

  void setPaperSize(PaperSize size) {
    final key = switch (size) {
      PaperSize.mm58 => 'mm58',
      PaperSize.mm72 => 'mm72',
      PaperSize.mm80 => 'mm80',
    };
    _sharedPreferences.setString(Constants.selectedPaperSizeKey, key);
  }

  Future<Result<void>> scanPrinters({
    Set<PrinterConnectionType> types = const {
      PrinterConnectionType.usb,
      PrinterConnectionType.bluetooth,
      PrinterConnectionType.ble,
      PrinterConnectionType.network,
    },
    String? selectedDeviceId,
    Function(List<PrinterDevice>)? onDeviceStream,
  }) async {
    final permissions = await checkPermissions();
    if (permissions.isFailure) return Result.failure(error: permissions.error!);

    try {
      printers = [];
      final stream = _manager.scanAll(
        timeout: const Duration(seconds: 5),
        types: types,
      );

      await for (final devices in stream) {
        for (final device in devices) {
          if (!printers.any((p) => getDeviceId(p) == getDeviceId(device))) {
            printers.add(device);
          }
        }

        onDeviceStream?.call(printers);

        if (selectedDeviceId != null && !(_manager.state == PrinterConnectionState.scanning)) {
          final match = printers.where((d) => getDeviceId(d) == selectedDeviceId).firstOrNull;
          if (match != null && selectedPrinter == null) {
            final result = await selectPrinter(match);
            if (result.isFailure) {
              return Result.failure(error: result.error!);
            }
          } else if (match != null) {
            // Update reference to the new scan instance without reconnecting
            selectedPrinter = match;
          }
        }
      }

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> selectPrinter(PrinterDevice device) async {
    cl('[PrinterService].selectPrinter: ${device.name} (${device.connectionType.name})');

    try {
      final currentSelectedDeviceId = selectedPrinter == null ? null : getDeviceId(selectedPrinter!);
      final nextSelectedDeviceId = getDeviceId(device);

      if (_manager.isConnected && currentSelectedDeviceId == nextSelectedDeviceId) {
        selectedPrinter = device;
        return Result.success(data: null);
      }

      if (_manager.isConnected) {
        await _manager.disconnect();
      }

      await _manager.connect(device, timeout: const Duration(seconds: 10));
      selectedPrinter = device;
      return Result.success(data: null);
    } on PrinterException catch (e) {
      if (!_manager.isConnected) {
        selectedPrinter = null;
      }

      cl('[PrinterService].selectPrinter connection error: ${e.message}');
      return Result.failure(error: e.message);
    } catch (e) {
      if (!_manager.isConnected) {
        selectedPrinter = null;
      }

      cl('[PrinterService].selectPrinter connection error: $e');
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> disconnectPrinter() async {
    try {
      if (_manager.isConnected) {
        await _manager.disconnect();
      }

      selectedPrinter = null;
      return Result.success(data: null);
    } on PrinterException catch (e) {
      cl('[PrinterService].disconnectPrinter error: ${e.message}');
      return Result.failure(error: e.message);
    } catch (e) {
      cl('[PrinterService].disconnectPrinter error: $e');
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> printTicket(Ticket ticket) async {
    if (selectedPrinter == null) {
      return Result.failure(error: 'Printer is not selected yet!');
    }

    try {
      if (!_manager.isConnected) {
        await _manager.connect(selectedPrinter!, timeout: const Duration(seconds: 10));
      }

      await _manager.printTicket(ticket);
      return Result.success(data: null);
    } on PrinterException catch (e) {
      return Result.failure(error: e.message);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> printData(List<int> bytes) async {
    if (selectedPrinter == null) {
      return Result.failure(error: 'Printer is not selected yet!');
    }

    try {
      if (!_manager.isConnected) {
        await _manager.connect(selectedPrinter!, timeout: const Duration(seconds: 10));
      }

      await _manager.printBytes(bytes);
      return Result.success(data: null);
    } on PrinterException catch (e) {
      return Result.failure(error: e.message);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> printTransaction(TransactionEntity transaction) async {
    try {
      final ticket = await Ticket.create(paperSize);

      final storeName = _sharedPreferences.getString(Constants.storeNameKey) ?? _l10n.receipt_storeName;
      final storeAddress = _sharedPreferences.getString(Constants.storeAddressKey) ?? '';
      final receiptFooter = _sharedPreferences.getString(Constants.receiptFooterKey) ?? '';

      ticket.text(
        storeName,
        align: PrintAlign.center,
        style: const PrintTextStyle(
          bold: true,
          height: TextSize.size2,
        ),
      );
      if (storeAddress.isNotEmpty) {
        ticket.text(
          storeAddress,
          align: PrintAlign.center,
          style: PrintTextStyle(
            fontType: FontType.fontB,
          ),
        );
      }

      ticket.emptyLines();

      final date = DateTimeFormatter.slashDateShortedYearWithClock(
        transaction.createdAt ?? DateTime.now().toIso8601String(),
      );

      ticket.text('${_l10n.receipt_date} : $date');
      ticket.text('${_l10n.receipt_trxId} : #${transaction.id}');
      if (transaction.customerName != null && transaction.customerName!.isNotEmpty) {
        ticket.text('${_l10n.receipt_customer} : ${transaction.customerName}');
      }
      ticket.text('${_l10n.receipt_cashier} : ${transaction.createdBy?.name ?? '-'}');

      ticket.separator();

      final grosirItems = transaction.orderedProducts?.where((p) => p.priceType == 'grosir').toList() ?? [];
      final retailItems = transaction.orderedProducts?.where((p) => p.priceType != 'grosir').toList() ?? [];

      if (grosirItems.isNotEmpty) {
        ticket.text(
          _l10n.receipt_grosir,
          align: PrintAlign.center,
          style: const PrintTextStyle(bold: true),
        );
        for (final product in grosirItems) {
          final qtyStr = product.quantity == product.quantity.roundToDouble()
              ? product.quantity.toInt().toString()
              : product.quantity.toStringAsFixed(1);

          final unitPrice = CurrencyFormatter.withoutSymbol(product.price, decimalDigits: 0);
          final subtotal = CurrencyFormatter.withoutSymbol(
            (product.price * product.quantity).round(),
            decimalDigits: 0,
          );

          ticket.text(product.name);
          ticket.row([
            PrintColumn(text: '$unitPrice x $qtyStr ${product.unit}', flex: 3),
            PrintColumn(text: subtotal, flex: 2, align: PrintAlign.right),
          ]);
        }
      }

      if (retailItems.isNotEmpty) {
        if (grosirItems.isNotEmpty) {
          ticket.separator();
          ticket.text(
            _l10n.receipt_retail,
            align: PrintAlign.center,
            style: const PrintTextStyle(bold: true),
          );
        }
        for (final product in retailItems) {
          final qtyStr = product.quantity == product.quantity.roundToDouble()
              ? product.quantity.toInt().toString()
              : product.quantity.toStringAsFixed(1);

          final unitPrice = CurrencyFormatter.withoutSymbol(product.price, decimalDigits: 0);
          final subtotal = CurrencyFormatter.withoutSymbol(
            (product.price * product.quantity).round(),
            decimalDigits: 0,
          );

          ticket.text(product.name);
          ticket.row([
            PrintColumn(text: '$unitPrice x $qtyStr ${product.unit}', flex: 3),
            PrintColumn(text: subtotal, flex: 2, align: PrintAlign.right),
          ]);
        }
      }

      ticket.separator();

      ticket.row([
        PrintColumn(
          text: _l10n.receipt_total,
          flex: 3,
          style: const PrintTextStyle(bold: true),
        ),
        PrintColumn(
          text: CurrencyFormatter.withoutSymbol(transaction.totalAmount, decimalDigits: 0),
          flex: 3,
          align: PrintAlign.right,
          style: const PrintTextStyle(bold: true),
        ),
      ]);

      ticket.emptyLines();

      ticket.row([
        PrintColumn(
          text: '${_l10n.receipt_pay} (${transaction.paymentMethod})',
          flex: 3,
        ),
        PrintColumn(
          text: CurrencyFormatter.withoutSymbol(transaction.receivedAmount, decimalDigits: 0),
          flex: 3,
          align: PrintAlign.right,
        ),
      ]);
      ticket.row([
        PrintColumn(
          text: _l10n.receipt_change,
          flex: 3,
        ),
        PrintColumn(
          text: CurrencyFormatter.withoutSymbol(transaction.returnAmount, decimalDigits: 0),
          flex: 3,
          align: PrintAlign.right,
        ),
      ]);

      ticket.emptyLines();

      if (receiptFooter.isNotEmpty) {
        ticket.text(receiptFooter, align: PrintAlign.center);
        ticket.emptyLines();
      }

      ticket.cut(linesBefore: 2);

      return await printTicket(ticket);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> printQrCode({
    required String qrData,
    required int totalAmount,
    String? storeName,
    String? merchantName,
  }) async {
    try {
      final ticket = await Ticket.create(paperSize);

      final name = storeName ?? _sharedPreferences.getString(Constants.storeNameKey) ?? _l10n.receipt_storeName;
      final merchant = merchantName ?? '';

      ticket.text(
        name,
        align: PrintAlign.center,
        style: const PrintTextStyle(
          bold: true,
          height: TextSize.size2,
        ),
      );

      if (merchant.isNotEmpty) {
        ticket.emptyLines();
        ticket.text('${_l10n.receipt_merchant}: $merchant', align: PrintAlign.center);
      }

      ticket.emptyLines();
      ticket.text(
        _l10n.receipt_qrisTotal,
        align: PrintAlign.center,
        style: const PrintTextStyle(fontType: FontType.fontB),
      );
      ticket.text(
        CurrencyFormatter.withoutSymbol(totalAmount, decimalDigits: 0),
        align: PrintAlign.center,
        style: const PrintTextStyle(
          bold: true,
          height: TextSize.size2,
        ),
      );

      ticket.emptyLines(2);
      ticket.text(_l10n.receipt_qrisScan, align: PrintAlign.center);
      ticket.emptyLines();
      ticket.qrcode(qrData, size: QRSize.size4);
      ticket.emptyLines();
      ticket.text(_l10n.receipt_qrisNote, align: PrintAlign.center);

      ticket.cut(linesBefore: 2);

      return await printTicket(ticket);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> testPrint() async {
    try {
      final ticket = await Ticket.create(paperSize);

      ticket.row([
        PrintColumn(
          text: _l10n.receipt_testTopLeft,
          flex: 1,
        ),
        PrintColumn(
          text: _l10n.receipt_testTopRight,
          flex: 1,
          align: PrintAlign.right,
        ),
      ]);

      ticket.emptyLines(3);

      ticket.text(
        _l10n.receipt_testTitle,
        align: PrintAlign.center,
        style: const PrintTextStyle(
          bold: true,
          height: TextSize.size2,
        ),
      );
      ticket.emptyLines();
      ticket.text(
        _l10n.receipt_testThanks,
        align: PrintAlign.center,
        style: const PrintTextStyle(fontType: FontType.fontB),
      );

      ticket.emptyLines(3);

      ticket.row([
        PrintColumn(
          text: _l10n.receipt_testBottomLeft,
          flex: 1,
        ),
        PrintColumn(
          text: _l10n.receipt_testBottomRight,
          flex: 1,
          align: PrintAlign.right,
        ),
      ]);

      ticket.feed(4);
      ticket.cut();

      return await printTicket(ticket);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> checkPermissions() async {
    final isBluetoothScanGranted = await Permission.bluetoothScan.request();
    if (isBluetoothScanGranted.isDenied) {
      return Result.failure(error: 'Bluetooth scan permission is not granted!');
    }

    final isBluetoothConnectGranted = await Permission.bluetoothConnect.request();
    if (isBluetoothConnectGranted.isDenied) {
      return Result.failure(error: 'Bluetooth connect permission is not granted!');
    }

    return Result.success(data: null);
  }

  String getDeviceId(PrinterDevice device) {
    return switch (device) {
      NetworkPrinterDevice d => '${d.host}:${d.port}',
      BlePrinterDevice d => d.deviceId,
      BluetoothPrinterDevice d => d.address,
      UsbPrinterDevice d => d.identifier,
      _ => device.name,
    };
  }

  Future<Result<void>> printProductLabels(Map<ProductEntity, int> items) async {
    if (items.isEmpty) {
      return Result.failure(error: _l10n.product_labelEmptySelection);
    }

    try {
      final ticket = await Ticket.create(paperSize);

      for (final entry in items.entries) {
        final product = entry.key;
        final copies = entry.value < 1 ? 1 : entry.value;
        final code = product.barcode?.trim() ?? '';

        if (code.isEmpty) {
          return Result.failure(error: _l10n.product_labelMissingBarcode(product.name));
        }

        if (!BarcodeGenerator.isValidEan13(code)) {
          return Result.failure(error: _l10n.product_labelInvalidBarcode(product.name));
        }

        for (var i = 0; i < copies; i++) {
          ticket.text(
            product.name,
            align: PrintAlign.center,
            style: const PrintTextStyle(bold: true),
          );
          if (product.price > 0) {
            ticket.text(
              CurrencyFormatter.withoutSymbol(product.price, decimalDigits: 0),
              align: PrintAlign.center,
            );
          }
          ticket.emptyLines();
          ticket.barcode(
            code,
            type: BarcodeType.ean13,
            align: PrintAlign.center,
            textPosition: BarcodeTextPosition.none,
          );
          ticket.emptyLines();
          ticket.text(
            BarcodeGenerator.formatDisplay(code),
            align: PrintAlign.center,
            style: const PrintTextStyle(bold: true),
          );
          ticket.emptyLines();
          ticket.cut();
        }
      }

      return await printTicket(ticket);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<void> dispose() async {
    await _manager.dispose();
  }
}
