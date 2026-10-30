import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/themes/app_sizes.dart';
import '../../../providers/payment/dana_access_prompt_policy.dart';
import '../../../providers/payment/dana_listener_notifier.dart';
import '../../../widgets/app_dialog.dart';

enum _PromptAction { later, settings }

/// Menampilkan dialog izin akses notifikasi DANA setelah pengguna masuk.
///
/// Android tidak punya dialog izin runtime untuk Notification Listener, jadi
/// aplikasi menampilkan penjelasan sendiri lalu membuka halaman Settings yang
/// relevan. Widget ini transparan (hanya mengembalikan [child]) dan memasang
/// dirinya di dalam Navigator supaya bisa memanggil `showDialog`.
class DanaPermissionOnboarding extends ConsumerStatefulWidget {
  final Widget child;

  const DanaPermissionOnboarding({super.key, required this.child});

  @override
  ConsumerState<DanaPermissionOnboarding> createState() =>
      _DanaPermissionOnboardingState();
}

class _DanaPermissionOnboardingState
    extends ConsumerState<DanaPermissionOnboarding>
    with WidgetsBindingObserver {
  bool _promptedThisSession = false;
  bool _dialogOpen = false;
  bool _awaitingSettingsResult = false;
  bool _restrictedGuidanceShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    if (_awaitingSettingsResult) {
      _awaitingSettingsResult = false;
      _refreshAfterSettings();
      return;
    }

    // Listener bisa baru selesai start setelah layar ini tampil.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
  }

  @override
  Widget build(BuildContext context) {
    // Ikut berubah saat listener selesai start / izin berubah, sehingga
    // prompt tetap muncul walau statusnya belum siap ketika layar dibuka.
    ref.watch(danaListenerProvider.select((s) => s.isStarted));
    ref.watch(danaListenerProvider.select((s) => s.isPermissionGranted));

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());

    return widget.child;
  }

  void _maybePrompt() {
    if (!mounted || _dialogOpen || _promptedThisSession) return;

    final listener = ref.read(danaListenerProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final snoozedRaw = prefs.getInt(Constants.danaListenerPromptSnoozedUntil);

    final shouldPrompt = shouldPromptDanaAccess(
      isAndroid: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      listenerEnabled: listener.isEnabled,
      listenerStarted: listener.isStarted,
      permissionGranted: listener.isPermissionGranted,
      alreadyPromptedThisSession: _promptedThisSession,
      now: DateTime.now(),
      snoozedUntil: snoozedRaw == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(snoozedRaw),
    );

    if (!shouldPrompt) return;

    _promptedThisSession = true;
    prefs.setBool(Constants.danaListenerPromptShown, true);
    _showIntroDialog();
  }

  Future<void> _showIntroDialog() async {
    if (!mounted) return;

    _dialogOpen = true;

    final action = await showDialog<_PromptAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AppDialogWidget(
          title: 'Aktifkan Akses Notifikasi',
          dismissible: false,
          leftButtonText: 'Nanti',
          rightButtonText: 'Buka Pengaturan',
          onTapLeftButton: (context) =>
              Navigator.of(context).pop(_PromptAction.later),
          onTapRightButton: (context) =>
              Navigator.of(context).pop(_PromptAction.settings),
          child: const _IntroContent(),
        ),
      ),
    );

    _dialogOpen = false;

    if (!mounted || action == null) return;

    switch (action) {
      case _PromptAction.later:
        await _snooze();
      case _PromptAction.settings:
        await _openPermissionSettings();
    }
  }

  Future<void> _snooze() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final until = DateTime.now().add(
      const Duration(hours: Constants.danaListenerPromptSnoozeHours),
    );

    await prefs.setInt(
      Constants.danaListenerPromptSnoozedUntil,
      until.millisecondsSinceEpoch,
    );
  }

  Future<void> _openPermissionSettings() async {
    _awaitingSettingsResult = true;
    await ref.read(danaListenerProvider.notifier).openPermissionSettings();
  }

  Future<void> _refreshAfterSettings() async {
    final notifier = ref.read(danaListenerProvider.notifier);

    try {
      await notifier.syncAfterResume();
    } catch (error) {
      debugPrint('[DANA] gagal menyegarkan status setelah Settings: $error');
    }

    if (!mounted) return;

    final listener = ref.read(danaListenerProvider);

    if (listener.isPermissionGranted) {
      // Izin baru diberikan: queue lama langsung diproses oleh syncAfterResume.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Akses notifikasi aktif. Pembayaran DANA akan terdeteksi otomatis.',
          ),
        ),
      );
      return;
    }

    if (_restrictedGuidanceShown) return;

    _restrictedGuidanceShown = true;
    await _showRestrictedDialog();
  }

  Future<void> _showRestrictedDialog() async {
    if (!mounted) return;

    _dialogOpen = true;

    final openAppDetails = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AppDialogWidget(
          title: 'Akses Masih Diblokir',
          dismissible: false,
          leftButtonText: 'Tutup',
          rightButtonText: 'Buka Info Aplikasi',
          onTapLeftButton: (context) => Navigator.of(context).pop(false),
          onTapRightButton: (context) => Navigator.of(context).pop(true),
          child: const _RestrictedContent(),
        ),
      ),
    );

    _dialogOpen = false;

    if (!mounted || openAppDetails != true) return;

    await ref.read(danaListenerProvider.notifier).openAppDetails();
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.notifications_active_rounded,
              color: scheme.primary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.padding / 1.5),
        Text(
          'MonoPOS perlu membaca notifikasi dari aplikasi DANA agar pembayaran '
          'masuk bisa menandai transaksi lunas secara otomatis.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.padding),
        const _Step(number: '1', text: 'Ketuk "Buka Pengaturan".'),
        const _Step(number: '2', text: 'Aktifkan "Mono POS - Listener DANA".'),
        const _Step(
          number: '3',
          text: 'Kembali ke aplikasi, status diperbarui otomatis.',
        ),
        const SizedBox(height: AppSizes.padding / 1.5),
        const _Note(
          'Android tidak menampilkan dialog izin biasa untuk akses ini, '
          'jadi pengaturan harus dibuka manual satu kali.',
        ),
      ],
    );
  }
}

class _RestrictedContent extends StatelessWidget {
  const _RestrictedContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Izin belum aktif. Sistem Android memblokir opsi ini karena aplikasi '
          'dipasang manual (bukan dari Play Store).',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSizes.padding),
        const _Step(number: '1', text: 'Buka Info Aplikasi Mono POS.'),
        const _Step(number: '2', text: 'Ketuk ⋮ di kanan atas.'),
        const _Step(
          number: '3',
          text:
              'Pilih "Allow restricted settings" / "Izinkan setelan terbatas".',
        ),
        const _Step(
          number: '4',
          text:
              'Konfirmasi PIN/pattern, lalu aktifkan listener di Notification access.',
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding / 1.5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}
