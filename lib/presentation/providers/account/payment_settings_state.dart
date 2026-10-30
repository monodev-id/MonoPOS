import '../../../core/services/payment/dana_payment_store.dart';

class PaymentSettingsState {
  final String staticQris;
  final String merchantName;
  final String merchantCity;
  final String nmid;
  final String acquirer;
  final bool isQrisValid;
  final String? qrisError;
  final bool isLoaded;
  final bool isSaving;
  final bool isDecoding;
  final bool ttsEnabled;
  final bool uniqueCodeEnabled;
  final int expiryMinutes;
  final bool listenerEnabled;
  final bool listenerPermissionGranted;
  final bool listenerConnected;
  final List<DanaNotificationRecord> recentNotifications;
  final bool hasChanges;

  const PaymentSettingsState({
    this.staticQris = '',
    this.merchantName = '',
    this.merchantCity = '',
    this.nmid = '',
    this.acquirer = '',
    this.isQrisValid = false,
    this.qrisError,
    this.isLoaded = false,
    this.isSaving = false,
    this.isDecoding = false,
    this.ttsEnabled = true,
    this.uniqueCodeEnabled = true,
    this.expiryMinutes = 15,
    this.listenerEnabled = true,
    this.listenerPermissionGranted = false,
    this.listenerConnected = false,
    this.recentNotifications = const [],
    this.hasChanges = false,
  });

  bool get isConfigured => isQrisValid && staticQris.isNotEmpty;

  PaymentSettingsState copyWith({
    String? staticQris,
    String? merchantName,
    String? merchantCity,
    String? nmid,
    String? acquirer,
    bool? isQrisValid,
    String? qrisError,
    bool? isLoaded,
    bool? isSaving,
    bool? isDecoding,
    bool? ttsEnabled,
    bool? uniqueCodeEnabled,
    int? expiryMinutes,
    bool? listenerEnabled,
    bool? listenerPermissionGranted,
    bool? listenerConnected,
    List<DanaNotificationRecord>? recentNotifications,
    bool? hasChanges,
    bool clearQrisError = false,
  }) {
    return PaymentSettingsState(
      staticQris: staticQris ?? this.staticQris,
      merchantName: merchantName ?? this.merchantName,
      merchantCity: merchantCity ?? this.merchantCity,
      nmid: nmid ?? this.nmid,
      acquirer: acquirer ?? this.acquirer,
      isQrisValid: isQrisValid ?? this.isQrisValid,
      qrisError: clearQrisError ? null : (qrisError ?? this.qrisError),
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      isDecoding: isDecoding ?? this.isDecoding,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      uniqueCodeEnabled: uniqueCodeEnabled ?? this.uniqueCodeEnabled,
      expiryMinutes: expiryMinutes ?? this.expiryMinutes,
      listenerEnabled: listenerEnabled ?? this.listenerEnabled,
      listenerPermissionGranted: listenerPermissionGranted ?? this.listenerPermissionGranted,
      listenerConnected: listenerConnected ?? this.listenerConnected,
      recentNotifications: recentNotifications ?? this.recentNotifications,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }
}
