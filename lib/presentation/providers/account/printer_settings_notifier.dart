import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/constants/constants.dart';
import '../../widgets/app_snack_bar.dart';
import 'printer_settings_state.dart';

final printerSettingsNotifierProvider = NotifierProvider.autoDispose<PrinterSettingsNotifier, PrinterSettingsState>(
  PrinterSettingsNotifier.new,
);

class PrinterSettingsNotifier extends AutoDisposeNotifier<PrinterSettingsState> {
  StreamSubscription<PrinterConnectionState>? _stateSubscription;

  @override
  PrinterSettingsState build() {
    final printerService = ref.watch(printerServiceProvider);

    final selected = printerService.selectedPrinter;

    final initialState = PrinterSettingsState(
      paperSize: printerService.paperSize,
      selectedTypes: {
        PrinterConnectionType.usb,
        PrinterConnectionType.bluetooth,
        PrinterConnectionType.ble,
        PrinterConnectionType.network,
      },
      isConnected: printerService.isConnected,
      connectedDeviceId: selected == null ? null : printerService.getDeviceId(selected),
      connectedPrinterName: selected?.name,
    );

    _stateSubscription?.cancel();
    _stateSubscription = printerService.stateStream.listen(_onManagerStateChanged);

    ref.onDispose(() {
      _stateSubscription?.cancel();
      _stateSubscription = null;
    });

    return initialState;
  }

  void _onManagerStateChanged(PrinterConnectionState managerState) {
    final printerService = ref.read(printerServiceProvider);

    if (managerState == PrinterConnectionState.connected) {
      final selected = printerService.selectedPrinter;

      state = state.copyWith(
        isConnected: true,
        connectedDeviceId: selected == null ? null : printerService.getDeviceId(selected),
        connectedPrinterName: selected?.name,
      );
      return;
    }

    if (managerState == PrinterConnectionState.disconnected || managerState == PrinterConnectionState.error) {
      if (state.isConnected || state.connectedDeviceId != null) {
        state = state.copyWith(
          isConnected: false,
          connectedDeviceId: null,
          connectedPrinterName: null,
        );
      }
      return;
    }

    if (managerState == PrinterConnectionState.connecting) {
      if (state.isConnected) {
        state = state.copyWith(isConnected: false);
      }
    }
  }

  void setPaperSize(PaperSize size) {
    if (state.paperSize == size) return;

    ref.read(printerServiceProvider).setPaperSize(size);
    state = state.copyWith(paperSize: size);
  }

  int get selectedPrinterIndex {
    final printerService = ref.read(printerServiceProvider);
    if (printerService.selectedPrinter == null) return -1;
    final selectedId = printerService.getDeviceId(printerService.selectedPrinter!);
    return state.printers.indexWhere(
      (p) => printerService.getDeviceId(p) == selectedId,
    );
  }

  int get connectedPrinterIndex {
    if (!state.isConnected || state.connectedDeviceId == null) return -1;
    final printerService = ref.read(printerServiceProvider);
    return state.printers.indexWhere(
      (p) => printerService.getDeviceId(p) == state.connectedDeviceId,
    );
  }

  bool get isConnecting => state.connectingDeviceId != null;

  String? get connectingPrinterName {
    final connectingId = state.connectingDeviceId;
    if (connectingId == null) return null;

    final printerService = ref.read(printerServiceProvider);
    final match = state.printers.where((p) => printerService.getDeviceId(p) == connectingId).firstOrNull;

    return match?.name ?? state.connectedPrinterName;
  }

  void toggleConnectionType(PrinterConnectionType type) {
    final types = Set<PrinterConnectionType>.from(state.selectedTypes);
    if (types.contains(type)) {
      if (types.length > 1) types.remove(type);
    } else {
      types.add(type);
    }
    state = state.copyWith(selectedTypes: types);
  }

  Future<void> getAndSelectPrinter() async {
    if (state.isScanning || state.isDisconnecting || state.connectingDeviceId != null) return;

    final printerService = ref.read(printerServiceProvider);
    final sharedPreferences = ref.read(sharedPreferencesProvider);

    state = state.copyWith(isScanning: true);

    final selectedDeviceId = sharedPreferences.getString(Constants.selectedDeviceIdKey);
    final wasConnected = state.isConnected;

    final result = await printerService.scanPrinters(
      types: state.selectedTypes,
      selectedDeviceId: selectedDeviceId,
      onDeviceStream: _onDeviceStream,
    );

    _syncConnectionStatus();
    state = state.copyWith(isScanning: false);

    if (result.isFailure) {
      AppSnackBar.showError(result.error.toString());
      return;
    }

    if (!wasConnected && state.isConnected && state.connectedPrinterName != null) {
      AppSnackBar.show('Terhubung ke ${state.connectedPrinterName}');
    }
  }

  void _onDeviceStream(List<PrinterDevice> printers) {
    if (_hasSamePrinters(printers)) return;

    state = state.copyWith(printers: List.unmodifiable(printers));
  }

  Future<void> onSelectPrinter(PrinterDevice printer) async {
    final printerService = ref.read(printerServiceProvider);
    final sharedPreferences = ref.read(sharedPreferencesProvider);

    final deviceId = printerService.getDeviceId(printer);
    if (state.connectingDeviceId == deviceId || state.isDisconnecting) return;

    state = state.copyWith(connectingDeviceId: deviceId);

    final result = await printerService.selectPrinter(printer);
    _syncConnectionStatus();
    state = state.copyWith(connectingDeviceId: null);

    if (result.isFailure) {
      AppSnackBar.showError(result.error.toString());
      return;
    }

    sharedPreferences.setString(Constants.selectedDeviceIdKey, deviceId);
    sharedPreferences.setString(Constants.selectedConnectionTypeKey, printer.connectionType.name);
    AppSnackBar.show('Terhubung ke ${printer.name}');
  }

  Future<void> disconnectPrinter() async {
    if (state.isDisconnecting || state.connectingDeviceId != null) return;

    final printerService = ref.read(printerServiceProvider);
    final sharedPreferences = ref.read(sharedPreferencesProvider);

    state = state.copyWith(isDisconnecting: true);

    final result = await printerService.disconnectPrinter();
    _syncConnectionStatus();
    state = state.copyWith(isDisconnecting: false);

    if (result.isFailure) {
      AppSnackBar.showError(result.error.toString());
      return;
    }

    await sharedPreferences.remove(Constants.selectedDeviceIdKey);
    await sharedPreferences.remove(Constants.selectedConnectionTypeKey);
    AppSnackBar.show('Printer disconnected');
  }

  void _syncConnectionStatus() {
    final printerService = ref.read(printerServiceProvider);
    final selected = printerService.selectedPrinter;

    if (printerService.isConnected && selected != null) {
      state = state.copyWith(
        isConnected: true,
        connectedDeviceId: printerService.getDeviceId(selected),
        connectedPrinterName: selected.name,
      );
    } else {
      state = state.copyWith(
        isConnected: false,
        connectedDeviceId: null,
        connectedPrinterName: null,
      );
    }
  }

  bool isConnectingPrinter(PrinterDevice device) {
    final printerService = ref.read(printerServiceProvider);
    return state.connectingDeviceId == printerService.getDeviceId(device);
  }

  bool isConnectedPrinter(PrinterDevice device) {
    if (!state.isConnected || state.connectedDeviceId == null) return false;

    final printerService = ref.read(printerServiceProvider);
    return state.connectedDeviceId == printerService.getDeviceId(device);
  }

  String getDeviceSubtitle(PrinterDevice device) {
    return switch (device) {
      NetworkPrinterDevice d => '${d.host}:${d.port}',
      BlePrinterDevice d => d.deviceId,
      BluetoothPrinterDevice d => d.address,
      UsbPrinterDevice d => d.identifier,
      _ => device.connectionType.name,
    };
  }

  bool _hasSamePrinters(List<PrinterDevice> printers) {
    final current = state.printers;
    if (current.length != printers.length) return false;

    final printerService = ref.read(printerServiceProvider);
    for (int i = 0; i < printers.length; i++) {
      if (printerService.getDeviceId(current[i]) != printerService.getDeviceId(printers[i])) {
        return false;
      }
    }

    return true;
  }
}
