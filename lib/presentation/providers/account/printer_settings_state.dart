import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

const _sentinel = Object();

class PrinterSettingsState {
  final bool isScanning;
  final String? connectingDeviceId;
  final bool isDisconnecting;
  final List<PrinterDevice> printers;
  final PaperSize paperSize;
  final Set<PrinterConnectionType> selectedTypes;
  final bool isConnected;
  final String? connectedDeviceId;
  final String? connectedPrinterName;

  const PrinterSettingsState({
    this.isScanning = false,
    this.connectingDeviceId,
    this.isDisconnecting = false,
    this.printers = const [],
    required this.paperSize,
    required this.selectedTypes,
    this.isConnected = false,
    this.connectedDeviceId,
    this.connectedPrinterName,
  });

  PrinterSettingsState copyWith({
    bool? isScanning,
    Object? connectingDeviceId = _sentinel,
    bool? isDisconnecting,
    List<PrinterDevice>? printers,
    PaperSize? paperSize,
    Set<PrinterConnectionType>? selectedTypes,
    bool? isConnected,
    Object? connectedDeviceId = _sentinel,
    Object? connectedPrinterName = _sentinel,
  }) {
    return PrinterSettingsState(
      isScanning: isScanning ?? this.isScanning,
      connectingDeviceId: identical(connectingDeviceId, _sentinel)
          ? this.connectingDeviceId
          : connectingDeviceId as String?,
      isDisconnecting: isDisconnecting ?? this.isDisconnecting,
      printers: printers ?? this.printers,
      paperSize: paperSize ?? this.paperSize,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      isConnected: isConnected ?? this.isConnected,
      connectedDeviceId: identical(connectedDeviceId, _sentinel)
          ? this.connectedDeviceId
          : connectedDeviceId as String?,
      connectedPrinterName: identical(connectedPrinterName, _sentinel)
          ? this.connectedPrinterName
          : connectedPrinterName as String?,
    );
  }
}
