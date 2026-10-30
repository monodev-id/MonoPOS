import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/di/app_providers.dart';
import '../../../core/constants/constants.dart';
import '../../../core/services/payment/dana_notification_service.dart';
import '../../../core/services/payment/qris_image_decoder.dart';
import '../../../core/services/qris/qris_merchant_info.dart';
import '../../../core/services/qris/qris_normalizer.dart';
import '../../../core/services/qris/qris_validator.dart';
import '../payment/dana_listener_notifier.dart';
import 'payment_settings_state.dart';

final paymentSettingsNotifierProvider =
    NotifierProvider.autoDispose<PaymentSettingsNotifier, PaymentSettingsState>(
      PaymentSettingsNotifier.new,
    );

class PaymentSettingsNotifier
    extends AutoDisposeNotifier<PaymentSettingsState> {
  String _originalQris = '';
  bool _originalTts = true;
  bool _originalUniqueCode = true;
  int _originalExpiry = 15;
  bool _originalListenerEnabled = true;

  @override
  PaymentSettingsState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(danaQrisPaymentServiceProvider);
    final listener = ref.read(danaListenerProvider);

    final qris = service.staticQris;
    final validation = validateQris(qris, requireStatic: true);
    final info = QrisMerchantInfo.tryParse(qris);
    final tts = service.isTtsEnabled;
    final uniqueCode = service.uniqueCodeEnabled;
    final expiry = service.expiryMinutes;
    final listenerEnabled =
        prefs.getBool(Constants.danaListenerEnabled) ?? true;

    _originalQris = qris;
    _originalTts = tts;
    _originalUniqueCode = uniqueCode;
    _originalExpiry = expiry;
    _originalListenerEnabled = listenerEnabled;

    return PaymentSettingsState(
      staticQris: qris,
      merchantName: info?.merchantName ?? '',
      merchantCity: info?.merchantCity ?? '',
      nmid: info?.nmid ?? '',
      acquirer: info?.acquirer ?? '',
      isQrisValid: validation.isValid,
      qrisError: validation.isValid ? null : _qrisErrorMessage(validation),
      isLoaded: true,
      ttsEnabled: tts,
      uniqueCodeEnabled: uniqueCode,
      expiryMinutes: expiry,
      listenerEnabled: listenerEnabled,
      listenerPermissionGranted: listener.isPermissionGranted,
      listenerConnected: listener.isServiceConnected,
      recentNotifications: listener.recentNotifications,
    );
  }

  String? _qrisErrorMessage(QrisValidationResult validation) {
    if (validation.isValid) return null;
    if (validation.errors.isEmpty) return 'QRIS tidak valid';
    return validation.errors.first;
  }

  Future<void> pickQrisImage({required ImageSource source}) async {
    state = state.copyWith(
      isDecoding: true,
      clearQrisError: true,
      clearQrisNotice: true,
    );

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2400,
        imageQuality: 100,
      );

      if (picked == null) {
        state = state.copyWith(isDecoding: false);
        return;
      }

      final result = await QrisImageDecoder().decodeFile(picked.path);

      if (!result.isSuccess) {
        state = state.copyWith(
          isDecoding: false,
          qrisError: result.error ?? 'Gagal membaca QRIS',
        );
        return;
      }

      _applyQris(result.payload!, wasDynamic: result.wasDynamic);
      state = state.copyWith(isDecoding: false, clearQrisError: true);
    } catch (e) {
      state = state.copyWith(isDecoding: false, qrisError: e.toString());
    }
  }

  void applyQrisText(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), '').trim();
    if (normalized.isEmpty) {
      state = state.copyWith(
        staticQris: '',
        isQrisValid: false,
        qrisError: 'QRIS masih kosong',
        clearQrisNotice: true,
      );
      _updateHasChanges();
      return;
    }

    _applyQris(normalized);
    _updateHasChanges();
  }

  void _applyQris(String qris, {bool wasDynamic = false}) {
    final normalized = qris.replaceAll(RegExp(r'\s+'), '').trim();

    // QRIS dinamis (tag 01 = 12 / ada nominal) dinormalisasi menjadi statis
    // supaya tetap bisa dipakai sebagai basis transaksi berikutnya.
    var candidate = normalized;
    var dynamicDetected = wasDynamic;
    final baseValidation = validateQris(normalized);
    if (baseValidation.isValid && isDynamicQris(normalized)) {
      candidate = toStaticQris(normalized);
      dynamicDetected = true;
    }

    final validation = validateQris(candidate, requireStatic: true);
    final info = QrisMerchantInfo.tryParse(candidate);

    state = state.copyWith(
      staticQris: candidate,
      isQrisValid: validation.isValid,
      qrisError: validation.isValid ? null : _qrisErrorMessage(validation),
      qrisNotice: validation.isValid && dynamicDetected
          ? 'QRIS dinamis terdeteksi dan otomatis dijadikan statis.'
          : null,
      merchantName: info?.merchantName ?? '',
      merchantCity: info?.merchantCity ?? '',
      nmid: info?.nmid ?? '',
      acquirer: info?.acquirer ?? '',
      clearQrisError: validation.isValid,
      clearQrisNotice: !(validation.isValid && dynamicDetected),
    );
  }

  void clearQris() {
    state = state.copyWith(
      staticQris: '',
      merchantName: '',
      merchantCity: '',
      nmid: '',
      acquirer: '',
      isQrisValid: false,
      qrisError: null,
      qrisNotice: null,
      clearQrisError: true,
      clearQrisNotice: true,
    );
    _updateHasChanges();
  }

  void onChangedTtsEnabled(bool value) {
    state = state.copyWith(ttsEnabled: value);
    _updateHasChanges();
  }

  void onChangedUniqueCode(bool value) {
    state = state.copyWith(uniqueCodeEnabled: value);
    _updateHasChanges();
  }

  void onChangedExpiryMinutes(int value) {
    state = state.copyWith(expiryMinutes: value);
    _updateHasChanges();
  }

  void onChangedListenerEnabled(bool value) {
    state = state.copyWith(listenerEnabled: value);
    _updateHasChanges();
  }

  void _updateHasChanges() {
    final hasChanges =
        state.staticQris != _originalQris ||
        state.ttsEnabled != _originalTts ||
        state.uniqueCodeEnabled != _originalUniqueCode ||
        state.expiryMinutes != _originalExpiry ||
        state.listenerEnabled != _originalListenerEnabled;

    if (hasChanges != state.hasChanges) {
      state = state.copyWith(hasChanges: hasChanges);
    }
  }

  Future<void> save() async {
    if (state.staticQris.isNotEmpty && !state.isQrisValid) {
      state = state.copyWith(qrisError: state.qrisError ?? 'QRIS tidak valid');
      return;
    }

    state = state.copyWith(isSaving: true);

    final service = ref.read(danaQrisPaymentServiceProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    if (state.staticQris.isEmpty) {
      await service.clearStaticQris();
    } else {
      await service.saveStaticQris(state.staticQris);
    }

    await service.setTtsEnabled(state.ttsEnabled);
    await service.setUniqueCodeEnabled(state.uniqueCodeEnabled);
    await service.setExpiryMinutes(state.expiryMinutes);

    // Nyalakan/matikan listener sekaligus, tidak hanya menyimpan preferensi.
    await ref
        .read(danaListenerProvider.notifier)
        .setEnabled(state.listenerEnabled);
    await refreshListener();

    // Samakan key lama supaya layar lain yang masih membacanya ikut berubah.
    await prefs.setBool(Constants.klikQrisTtsEnabled, state.ttsEnabled);

    _originalQris = state.staticQris;
    _originalTts = state.ttsEnabled;
    _originalUniqueCode = state.uniqueCodeEnabled;
    _originalExpiry = state.expiryMinutes;
    _originalListenerEnabled = state.listenerEnabled;

    state = state.copyWith(isSaving: false, hasChanges: false);
  }

  Future<void> openNotificationSettings() async {
    await DanaNotificationService().openPermissionSettings();
  }

  Future<void> refreshListener() async {
    final listener = ref.read(danaListenerProvider.notifier);
    await listener.refreshStatus();

    final current = ref.read(danaListenerProvider);
    state = state.copyWith(
      listenerPermissionGranted: current.isPermissionGranted,
      listenerConnected: current.isServiceConnected,
      recentNotifications: current.recentNotifications,
    );
  }

  Future<void> clearNotificationHistory() async {
    await ref.read(danaListenerProvider.notifier).clearHistory();
    await refreshListener();
  }

  bool get supportsImagePick => Platform.isAndroid || Platform.isIOS;
}
