class PaymentSettingsState {
  final String apiKey;
  final String merchantId;
  final bool isSandbox;
  final bool ttsEnabled;
  final bool isLoaded;
  final bool isSaving;
  final bool hasChanges;

  const PaymentSettingsState({
    this.apiKey = '',
    this.merchantId = '',
    this.isSandbox = false,
    this.ttsEnabled = true,
    this.isLoaded = false,
    this.isSaving = false,
    this.hasChanges = false,
  });

  PaymentSettingsState copyWith({
    String? apiKey,
    String? merchantId,
    bool? isSandbox,
    bool? ttsEnabled,
    bool? isLoaded,
    bool? isSaving,
    bool? hasChanges,
  }) {
    return PaymentSettingsState(
      apiKey: apiKey ?? this.apiKey,
      merchantId: merchantId ?? this.merchantId,
      isSandbox: isSandbox ?? this.isSandbox,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }
}
