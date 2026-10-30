class Constants {
  // Prevents instantiation and extension
  Constants._();

  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static const String selectedDeviceIdKey = 'selected_device_id';
  static const String selectedConnectionTypeKey = 'selected_connection_type';
  static const String selectedPaperSizeKey = 'selected_paper_size';
  static const String selectedBrightnessKey = 'selected_brightness';
  static const String storeNameKey = 'store_name';
  static const String storeAddressKey = 'store_address';
  static const String receiptFooterKey = 'receipt_footer';

  // KlikQRIS Payment Gateway settings
  static const String klikQrisApiKey = 'klikqris_api_key';
  static const String klikQrisMerchantId = 'klikqris_merchant_id';
  static const String klikQrisIsSandbox = 'klikqris_is_sandbox';
  static const String klikQrisTtsEnabled = 'klikqris_tts_enabled';

  // DANA Bisnis QRIS (statis → dinamis) + listener notifikasi
  static const String danaQrisStatic = 'dana_qris_static';
  static const String danaTtsEnabled = 'dana_tts_enabled';
  static const String danaUniqueCodeEnabled = 'dana_unique_code_enabled';
  static const String danaExpiryMinutes = 'dana_expiry_minutes';
  static const String danaListenerEnabled = 'dana_listener_enabled';
  static const String danaListenerPackages = 'dana_listener_packages';
  static const String danaLastListenerSync = 'dana_last_listener_sync';

  static const String danaProviderStatic = 'dana_static';

  static const int minSyncIntervalToleranceForCriticalInMinutes = 5;
  static const int minSyncIntervalToleranceForLessCriticalInMinutes = 100;

  // Google OAuth scopes required for user authentication
  static const List<String> authScopes = [
    'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/userinfo.email',
  ];

  // Non-critical error libraries that should be logged but not navigate to error screen
  static const nonCriticalErrorLibraries = {
    'image resource service',
    'gestures library',
    'scheduler library',
    'rendering library',
    'widgets library',
  };
}
