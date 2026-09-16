import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unified_esc_pos_printer/unified_esc_pos_printer.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/account/printer_settings_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_drop_down.dart';
import '../../widgets/app_icon_button.dart';
import '../../widgets/app_snack_bar.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(printerSettingsNotifierProvider.notifier).getAndSelectPrinter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.printer_title),
        titleSpacing: 0,
      ),
      body: const _PrinterSettingsBody(),
    );
  }
}

class _PrinterSettingsBody extends StatelessWidget {
  const _PrinterSettingsBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SettingsRow(),
          SizedBox(height: AppSizes.padding * 1.5),
          _ConnectionStatusBanner(),
          SizedBox(height: AppSizes.padding * 1.5),
          _DevicesHeader(),
          SizedBox(height: AppSizes.padding),
          _PrinterList(),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _ConnectionTypeDropDown()),
        SizedBox(width: AppSizes.padding),
        Expanded(child: _PaperSizeSelector()),
      ],
    );
  }
}

class _PaperSizeSelector extends ConsumerWidget {
  const _PaperSizeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperSize = ref.watch(printerSettingsNotifierProvider.select((p) => p.paperSize));
    final isScanning = ref.watch(printerSettingsNotifierProvider.select((p) => p.isScanning));
    final isConnecting = ref.watch(printerSettingsNotifierProvider.select((s) => s.connectingDeviceId != null));
    final isDisconnecting = ref.watch(printerSettingsNotifierProvider.select((p) => p.isDisconnecting));

    final isBusy = isScanning || isConnecting || isDisconnecting;

    return AppDropDown<PaperSize>(
      labelText: AppLocalizations.of(context)!.printer_paperSize,
      selectedValue: paperSize,
      enabled: !isBusy,
      dropdownItems: PaperSize.values.map((size) {
        return DropdownMenuItem<PaperSize>(
          value: size,
          child: Text(_label(size)),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        ref.read(printerSettingsNotifierProvider.notifier).setPaperSize(value);
      },
    );
  }

  String _label(PaperSize size) {
    return switch (size) {
      PaperSize.mm58 => '58mm',
      PaperSize.mm72 => '72mm',
      PaperSize.mm80 => '80mm',
    };
  }
}

class _ConnectionTypeDropDown extends ConsumerWidget {
  const _ConnectionTypeDropDown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTypes = ref.watch(printerSettingsNotifierProvider.select((p) => p.selectedTypes));
    final isScanning = ref.watch(printerSettingsNotifierProvider.select((p) => p.isScanning));
    final isConnecting = ref.watch(printerSettingsNotifierProvider.select((s) => s.connectingDeviceId != null));
    final isDisconnecting = ref.watch(printerSettingsNotifierProvider.select((p) => p.isDisconnecting));

    final isBusy = isScanning || isConnecting || isDisconnecting;

    return AppDropDown<PrinterConnectionType>.multi(
      labelText: AppLocalizations.of(context)!.printer_connectionTypes,
      hintText: AppLocalizations.of(context)!.printer_selectConnection,
      enabled: !isBusy,
      selectedValues: selectedTypes,
      dropdownItems: PrinterConnectionType.values.map((type) {
        return DropdownMenuItem<PrinterConnectionType>(
          value: type,
          child: Row(
            children: [
              Icon(_icon(type), size: 18),
              const SizedBox(width: 8),
              Text(_label(context, type)),
            ],
          ),
        );
      }).toList(),
      selectedValuesTextBuilder: (selected) => _selectedLabel(context, selected),
      onChanged: (type) {
        if (type == null) return;
        ref.read(printerSettingsNotifierProvider.notifier).toggleConnectionType(type);
      },
    );
  }

  String _label(context, PrinterConnectionType type) {
    final l10n = AppLocalizations.of(context)!;
    return switch (type) {
      PrinterConnectionType.usb => l10n.printer_usb,
      PrinterConnectionType.bluetooth => l10n.printer_bluetooth,
      PrinterConnectionType.ble => l10n.printer_ble,
      PrinterConnectionType.network => l10n.printer_network,
    };
  }

  IconData _icon(PrinterConnectionType type) {
    return switch (type) {
      PrinterConnectionType.usb => Icons.usb,
      PrinterConnectionType.bluetooth => Icons.bluetooth,
      PrinterConnectionType.ble => Icons.bluetooth_searching,
      PrinterConnectionType.network => Icons.wifi,
    };
  }

  String _selectedLabel(context, Set<PrinterConnectionType> selectedTypes) {
    final l10n = AppLocalizations.of(context)!;
    if (selectedTypes.length == PrinterConnectionType.values.length) {
      return l10n.printer_allConnections;
    }

    return selectedTypes.map((t) => _label(context, t)).join(', ');
  }
}

class _ConnectionStatusBanner extends ConsumerWidget {
  const _ConnectionStatusBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final isScanning = ref.watch(printerSettingsNotifierProvider.select((s) => s.isScanning));
    final connectingDeviceId = ref.watch(printerSettingsNotifierProvider.select((s) => s.connectingDeviceId));
    final isDisconnecting = ref.watch(printerSettingsNotifierProvider.select((s) => s.isDisconnecting));
    final isConnected = ref.watch(printerSettingsNotifierProvider.select((s) => s.isConnected));
    final connectedPrinterName = ref.watch(printerSettingsNotifierProvider.select((s) => s.connectedPrinterName));

    final Color backgroundColor;
    final Color foregroundColor;
    final IconData icon;
    final String text;
    final bool showSpinner;

    if (connectingDeviceId != null) {
      final connectingName = ref.read(printerSettingsNotifierProvider.notifier).connectingPrinterName;

      backgroundColor = theme.colorScheme.secondaryContainer;
      foregroundColor = theme.colorScheme.onSecondaryContainer;
      icon = Icons.bluetooth_searching;
      text = l10n.printer_connectingTo(connectingName ?? connectingDeviceId);
      showSpinner = true;
    } else if (isScanning) {
      backgroundColor = theme.colorScheme.secondaryContainer;
      foregroundColor = theme.colorScheme.onSecondaryContainer;
      icon = Icons.sync;
      text = l10n.printer_scanning;
      showSpinner = true;
    } else if (isDisconnecting) {
      backgroundColor = theme.colorScheme.secondaryContainer;
      foregroundColor = theme.colorScheme.onSecondaryContainer;
      icon = Icons.link_off;
      text = l10n.printer_disconnecting;
      showSpinner = true;
    } else if (isConnected) {
      backgroundColor = theme.colorScheme.tertiaryContainer;
      foregroundColor = theme.colorScheme.onTertiaryContainer;
      icon = Icons.check_circle;
      text = l10n.printer_connected(connectedPrinterName ?? '-');
      showSpinner = false;
    } else {
      backgroundColor = theme.colorScheme.errorContainer;
      foregroundColor = theme.colorScheme.onErrorContainer;
      icon = Icons.link_off;
      text = l10n.printer_notConnected;
      showSpinner = false;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding, vertical: AppSizes.padding / 1.25),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (showSpinner)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: foregroundColor),
            )
          else
            Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(width: AppSizes.padding / 1.5),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: foregroundColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicesHeader extends ConsumerWidget {
  const _DevicesHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isScanning = ref.watch(printerSettingsNotifierProvider.select((p) => p.isScanning));
    final isConnecting = ref.watch(printerSettingsNotifierProvider.select((s) => s.connectingDeviceId != null));
    final isDisconnecting = ref.watch(printerSettingsNotifierProvider.select((p) => p.isDisconnecting));
    final isConnected = ref.watch(printerSettingsNotifierProvider.select((p) => p.isConnected));

    final isBusy = isScanning || isConnecting || isDisconnecting;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.printer_availableDevices,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: AppSizes.padding / 1.5),
            if (isScanning || isConnecting || isDisconnecting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        Row(
          children: [
            AppIconButton(
              icon: Icons.refresh,
              iconSize: 18,
              enabled: !isBusy,
              onTap: () {
                ref.read(printerSettingsNotifierProvider.notifier).getAndSelectPrinter();
              },
            ),
            const SizedBox(width: 4),
            AppIconButton(
              icon: Icons.link_off,
              iconSize: 18,
              enabled: isConnected && !isBusy,
              onTap: () {
                ref.read(printerSettingsNotifierProvider.notifier).disconnectPrinter();
              },
            ),
            const SizedBox(width: 4),
            AppIconButton(
              icon: Icons.print_outlined,
              iconSize: 18,
              enabled: isConnected && !isBusy,
              onTap: () async {
                final result = await ref.read(printerServiceProvider).testPrint();

                if (result.isFailure) {
                  AppSnackBar.showError(result.error.toString());
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _PrinterList extends ConsumerWidget {
  const _PrinterList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(printerSettingsNotifierProvider.notifier);

    final printers = ref.watch(printerSettingsNotifierProvider.select((s) => s.printers));
    final isScanning = ref.watch(printerSettingsNotifierProvider.select((s) => s.isScanning));
    final isConnecting = ref.watch(printerSettingsNotifierProvider.select((s) => s.connectingDeviceId != null));
    final isConnected = ref.watch(printerSettingsNotifierProvider.select((s) => s.isConnected));
    final connectedDeviceId = ref.watch(printerSettingsNotifierProvider.select((s) => s.connectedDeviceId));

    if (printers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.padding * 2),
        child: Center(
          child: Text(
            isScanning
                ? AppLocalizations.of(context)!.printer_scanning
                : AppLocalizations.of(context)!.printer_noDevice,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Column(
      spacing: AppSizes.padding,
      children: List.generate(
        printers.length,
        (i) {
          final printer = printers[i];
          final isLoading = notifier.isConnectingPrinter(printer);
          final isConnectedItem =
              !isLoading && isConnected && connectedDeviceId != null && notifier.isConnectedPrinter(printer);

          return _PrinterButton(
            printer: printer,
            isSelected: isConnectedItem,
            isLoading: isLoading,
            isConnected: isConnectedItem,
            enabled: !isConnecting || isLoading,
            subtitle: notifier.getDeviceSubtitle(printer),
            onTap: () => notifier.onSelectPrinter(printer),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isLoading;
  final bool isConnected;

  const _StatusBadge({required this.isLoading, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.secondary),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.printer_connectingBadge,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      );
    }

    if (isConnected) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: theme.colorScheme.tertiary),
          const SizedBox(width: 6),
          Text(
            l10n.printer_connectedBadge,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _PrinterButton extends StatelessWidget {
  final PrinterDevice printer;
  final bool isSelected;
  final bool isLoading;
  final bool isConnected;
  final bool enabled;
  final String subtitle;
  final VoidCallback onTap;

  const _PrinterButton({
    required this.printer,
    required this.isSelected,
    required this.isLoading,
    required this.isConnected,
    required this.enabled,
    required this.subtitle,
    required this.onTap,
  });

  IconData _connectionIcon(PrinterConnectionType type) {
    return switch (type) {
      PrinterConnectionType.usb => Icons.usb,
      PrinterConnectionType.bluetooth => Icons.bluetooth,
      PrinterConnectionType.ble => Icons.bluetooth_searching,
      PrinterConnectionType.network => Icons.wifi,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      enabled: enabled,
      buttonColor: isSelected
          ? Theme.of(context).colorScheme.surfaceContainer
          : Theme.of(context).colorScheme.surfaceContainerLowest,
      borderColor: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _connectionIcon(printer.connectionType),
                size: 36,
              ),
              const SizedBox(width: AppSizes.padding),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    printer.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  _StatusBadge(isLoading: isLoading, isConnected: isConnected),
                ],
              ),
            ],
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 2.0),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else if (isSelected)
            Icon(
              Icons.check_circle,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}
