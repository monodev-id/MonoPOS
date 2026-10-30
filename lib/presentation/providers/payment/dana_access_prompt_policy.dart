/// Aturan kapan dialog izin akses notifikasi DANA boleh ditampilkan.
///
/// Android tidak menyediakan dialog izin runtime untuk Notification Listener,
/// jadi aplikasi menampilkan dialog sendiri. Supaya tidak mengganggu, prompt
/// hanya muncul saat listener aktif, izin belum diberikan, dan pengguna belum
/// menekan "Nanti" (masa snooze belum lewat).
bool shouldPromptDanaAccess({
  required bool isAndroid,
  required bool listenerEnabled,
  required bool listenerStarted,
  required bool permissionGranted,
  required bool alreadyPromptedThisSession,
  required DateTime now,
  DateTime? snoozedUntil,
}) {
  if (!isAndroid) return false;
  if (!listenerEnabled || !listenerStarted) return false;
  if (permissionGranted) return false;
  if (alreadyPromptedThisSession) return false;
  if (snoozedUntil != null && snoozedUntil.isAfter(now)) return false;

  return true;
}

/// True bila listener punya izin tetapi service belum terhubung ke sistem.
bool shouldPromptDanaRebind({
  required bool listenerEnabled,
  required bool permissionGranted,
  required bool serviceConnected,
}) {
  if (!listenerEnabled) return false;

  return permissionGranted && !serviceConnected;
}
