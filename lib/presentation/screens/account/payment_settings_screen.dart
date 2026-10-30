import 'dart:io';

import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/qris/qris_normalizer.dart';
import '../../../core/themes/app_sizes.dart';
import '../../providers/account/payment_settings_notifier.dart';
import '../../providers/account/payment_settings_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_success_overlay.dart';
import '../../widgets/app_text_field.dart';

class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  ConsumerState<PaymentSettingsScreen> createState() =>
      _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends ConsumerState<PaymentSettingsScreen> {
  late final TextEditingController _qrisController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(paymentSettingsNotifierProvider);
    _qrisController = TextEditingController(text: state.staticQris);
  }

  @override
  void dispose() {
    _qrisController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final notifier = ref.read(paymentSettingsNotifierProvider.notifier);
    await notifier.save();

    if (!mounted) return;
    final state = ref.read(paymentSettingsNotifierProvider);

    if (state.qrisError != null &&
        state.staticQris.isNotEmpty &&
        !state.isQrisValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.qrisError!)),
      );
      return;
    }

    AppSuccessOverlay.show('Pengaturan pembayaran tersimpan');
  }

  Future<void> _pasteFromClipboard() async {
    final notifier = ref.read(paymentSettingsNotifierProvider.notifier);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';

    if (!mounted) return;

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard kosong')),
      );
      return;
    }

    _qrisController.text = text;
    notifier.applyQrisText(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentSettingsNotifierProvider);
    final notifier = ref.read(paymentSettingsNotifierProvider.notifier);

    ref.listen(paymentSettingsNotifierProvider.select((s) => s.staticQris), (
      previous,
      next,
    ) {
      final normalized = sanitizeQrisInput(_qrisController.text);
      if (normalized != next && _qrisController.text != next) {
        _qrisController.text = next;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Pembayaran'),
        titleSpacing: 0,
      ),
      body: !state.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(text: 'QRIS DANA Bisnis'),
                  const SizedBox(height: AppSizes.padding / 2),
                  _QrisCard(
                    state: state,
                    isDecoding: state.isDecoding,
                    onPickGallery: () =>
                        notifier.pickQrisImage(source: ImageSource.gallery),
                    onPickCamera: () =>
                        notifier.pickQrisImage(source: ImageSource.camera),
                    onClear: notifier.clearQris,
                  ),
                  const SizedBox(height: AppSizes.padding),
                  AppTextField(
                    controller: _qrisController,
                    labelText: 'Kode QRIS statis',
                    hintText:
                        'Tempel kode QRIS dari DANA Bisnis bila upload gagal',
                    minLines: 3,
                    maxLines: 5,
                    onChanged: notifier.applyQrisText,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Icons.content_paste_go, size: 18),
                      label: const Text('Tempel dari clipboard'),
                    ),
                  ),
                  const SizedBox(height: AppSizes.padding / 2),
                  _MerchantInfoCard(state: state),
                  const SizedBox(height: AppSizes.padding * 1.5),
                  const _SectionTitle(text: 'Listener Pembayaran DANA'),
                  const SizedBox(height: AppSizes.padding / 2),
                  _ListenerCard(
                    state: state,
                    onOpenSettings: notifier.openNotificationSettings,
                    onRefresh: notifier.refreshListener,
                    onClearHistory: notifier.clearNotificationHistory,
                  ),
                  const SizedBox(height: AppSizes.padding * 1.5),
                  const _SectionTitle(text: 'Preferensi'),
                  const SizedBox(height: AppSizes.padding / 2),
                  _SwitchTile(
                    title: 'Kode unik otomatis',
                    subtitle:
                        'Tambahkan kode 1-99 pada nominal agar pembayaran bisa dicocokkan dengan tepat',
                    value: state.uniqueCodeEnabled,
                    onChanged: notifier.onChangedUniqueCode,
                  ),
                  const SizedBox(height: AppSizes.padding / 2),
                  _SwitchTile(
                    title: 'Listener notifikasi',
                    subtitle:
                        'Tandai transaksi lunas otomatis dari notifikasi aplikasi DANA',
                    value: state.listenerEnabled,
                    onChanged: notifier.onChangedListenerEnabled,
                  ),
                  const SizedBox(height: AppSizes.padding / 2),
                  _SwitchTile(
                    title: 'Suara TTS pembayaran',
                    subtitle: 'Bacakan nominal saat pembayaran diterima',
                    value: state.ttsEnabled,
                    onChanged: notifier.onChangedTtsEnabled,
                  ),
                  const SizedBox(height: AppSizes.padding / 2),
                  _ExpiryTile(
                    value: state.expiryMinutes,
                    onChanged: notifier.onChangedExpiryMinutes,
                  ),
                  const SizedBox(height: AppSizes.padding * 1.5),
                  AppButton(
                    text: state.isSaving ? 'Menyimpan...' : 'Simpan Pengaturan',
                    enabled: state.hasChanges && !state.isSaving,
                    onTap: _onSave,
                  ),
                  const SizedBox(height: AppSizes.padding),
                ],
              ),
            ),
    );
  }
}

class _QrisCard extends StatelessWidget {
  final PaymentSettingsState state;
  final bool isDecoding;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onClear;

  const _QrisCard({
    required this.state,
    required this.isDecoding,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final supportsPick = Platform.isAndroid || Platform.isIOS;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: scheme.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(
                label: state.isQrisValid ? 'QRIS valid' : 'Belum ada QRIS',
                color: state.isQrisValid ? Colors.green : Colors.orange,
              ),
              const Spacer(),
              if (state.staticQris.isNotEmpty)
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.padding),
          if (state.staticQris.isNotEmpty)
            Center(
              child: Container(
                width: 170,
                height: 170,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radius),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: state.isQrisValid
                    ? bw.BarcodeWidget(
                        barcode: bw.Barcode.qrCode(),
                        data: state.staticQris,
                        width: 146,
                        height: 146,
                        color: Colors.black,
                        backgroundColor: Colors.white,
                      )
                    : const Icon(
                        Icons.qr_code_2,
                        size: 72,
                        color: Colors.black45,
                      ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.padding * 1.5,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppSizes.radius),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file_outlined,
                    size: 42,
                    color: scheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload gambar QRIS statis dari aplikasi DANA Bisnis',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                  ),
                ],
              ),
            ),
          if (state.qrisError != null) ...[
            const SizedBox(height: AppSizes.padding / 2),
            Text(
              state.qrisError!,
              style: TextStyle(fontSize: 12, color: scheme.error),
            ),
          ],
          if (state.qrisNotice != null) ...[
            const SizedBox(height: AppSizes.padding / 2),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    state.qrisNotice!,
                    style: TextStyle(fontSize: 12, color: scheme.primary),
                  ),
                ),
              ],
            ),
          ],
          if (supportsPick) ...[
            const SizedBox(height: AppSizes.padding),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: isDecoding ? 'Membaca...' : 'Upload Gambar',
                    enabled: !isDecoding,
                    onTap: onPickGallery,
                  ),
                ),
                const SizedBox(width: AppSizes.padding / 2),
                Expanded(
                  child: AppButton(
                    text: 'Scan Kamera',
                    buttonColor: scheme.surface,
                    borderColor: scheme.outline,
                    textColor: scheme.onSurface,
                    enabled: !isDecoding,
                    onTap: onPickCamera,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.padding / 2),
          Text(
            'Hanya kode QRIS yang disimpan. Gambar tidak dikirim ke server.',
            style: TextStyle(fontSize: 11, color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _MerchantInfoCard extends StatelessWidget {
  final PaymentSettingsState state;

  const _MerchantInfoCard({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.staticQris.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Merchant', value: state.merchantName),
          _InfoRow(label: 'Kota', value: state.merchantCity),
          _InfoRow(label: 'NMID', value: state.nmid),
          _InfoRow(label: 'Acquirer', value: state.acquirer),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListenerCard extends StatelessWidget {
  final PaymentSettingsState state;
  final VoidCallback onOpenSettings;
  final VoidCallback onRefresh;
  final VoidCallback onClearHistory;

  const _ListenerCard({
    required this.state,
    required this.onOpenSettings,
    required this.onRefresh,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = state.listenerPermissionGranted && state.listenerConnected;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: scheme.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(
                label: active ? 'Listener aktif' : 'Listener belum aktif',
                color: active ? Colors.green : Colors.orange,
              ),
              const Spacer(),
              IconButton(
                onPressed: onRefresh,
                tooltip: 'Muat ulang status',
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            state.listenerPermissionGranted
                ? 'Akses notifikasi diberikan. Pastikan aplikasi DANA terpasang di perangkat ini.'
                : 'Beri akses notifikasi agar MonoPOS bisa membaca pembayaran masuk dari aplikasi DANA.',
            style: TextStyle(fontSize: 12, color: scheme.outline),
          ),
          const SizedBox(height: AppSizes.padding / 2),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Buka Akses Notifikasi',
                  enabled: !state.listenerPermissionGranted,
                  onTap: onOpenSettings,
                ),
              ),
              const SizedBox(width: AppSizes.padding / 2),
              Expanded(
                child: AppButton(
                  text: 'Uji Listener',
                  buttonColor: scheme.surface,
                  borderColor: scheme.outline,
                  textColor: scheme.onSurface,
                  onTap: onRefresh,
                ),
              ),
            ],
          ),
          if (state.recentNotifications.isNotEmpty) ...[
            const SizedBox(height: AppSizes.padding),
            Row(
              children: [
                Text(
                  'Notifikasi terakhir',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onClearHistory,
                  child: const Text('Bersihkan'),
                ),
              ],
            ),
            for (final notif in state.recentNotifications.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title.isEmpty ? notif.packageName : notif.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      notif.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: scheme.outline),
                    ),
                    Text(
                      '${notif.status}${notif.amount != null ? ' • Rp${notif.amount}' : ''}',
                      style: TextStyle(fontSize: 10, color: scheme.outline),
                    ),
                    const Divider(height: 12),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ExpiryTile extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _ExpiryTile({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masa berlaku QRIS',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'QRIS dinamis kedaluwarsa setelah $value menit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<int>(
            value: value,
            underline: const SizedBox.shrink(),
            items:
                const [
                      5,
                      10,
                      15,
                      30,
                    ]
                    .map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text('$minutes mnt'),
                      ),
                    )
                    .toList(),
            onChanged: (minutes) {
              if (minutes != null) onChanged(minutes);
            },
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
