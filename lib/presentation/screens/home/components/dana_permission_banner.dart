import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../providers/payment/dana_listener_notifier.dart';

/// Pengingat persisten di Home saat akses notifikasi DANA belum aktif atau
/// service listener belum tersambung.
class DanaPermissionBanner extends ConsumerStatefulWidget {
  const DanaPermissionBanner({super.key});

  @override
  ConsumerState<DanaPermissionBanner> createState() =>
      _DanaPermissionBannerState();
}

class _DanaPermissionBannerState extends ConsumerState<DanaPermissionBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    final listener = ref.watch(danaListenerProvider);

    if (!listener.isEnabled || !listener.isStarted) {
      return const SizedBox.shrink();
    }

    if (listener.isPermissionGranted && listener.isServiceConnected) {
      return const SizedBox.shrink();
    }

    final needsPermission = !listener.isPermissionGranted;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.padding,
        8,
        AppSizes.padding,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.padding / 1.5),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppSizes.radius + 8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    needsPermission
                        ? Icons.notifications_off_rounded
                        : Icons.sync_problem_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        needsPermission
                            ? 'Akses notifikasi DANA belum aktif'
                            : 'Listener DANA belum terhubung',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        needsPermission
                            ? 'Pembayaran tidak terdeteksi otomatis. Aktifkan agar transaksi QRIS jadi lunas sendiri.'
                            : 'Izin sudah diberikan tetapi service belum tersambung. Coba muat ulang.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onPressed: () => setState(() => _dismissed = true),
                  icon: Icon(Icons.close_rounded, color: scheme.outline),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.padding / 2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: needsPermission ? _openSettings : _rebind,
                icon: Icon(
                  needsPermission
                      ? Icons.settings_rounded
                      : Icons.refresh_rounded,
                  size: 18,
                ),
                label: Text(needsPermission ? 'Aktifkan' : 'Muat ulang'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettings() =>
      ref.read(danaListenerProvider.notifier).openPermissionSettings();

  Future<void> _rebind() async {
    final notifier = ref.read(danaListenerProvider.notifier);
    await notifier.rebindService();

    if (!mounted) return;

    final connected = ref.read(danaListenerProvider).isServiceConnected;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          connected
              ? 'Listener DANA tersambung kembali.'
              : 'Listener belum tersambung. Coba tutup dan buka ulang aplikasi.',
        ),
      ),
    );
  }
}
