import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/constants.dart';
import '../qris/qris_converter.dart';
import '../qris/qris_merchant_info.dart';
import '../qris/qris_normalizer.dart';
import '../qris/qris_validator.dart';

/// Service QRIS DANA Bisnis: menyimpan QRIS statis dan mengubahnya menjadi
/// QRIS dinamis bernominal saat checkout.
class DanaQrisPaymentService {
  final SharedPreferences _prefs;

  DanaQrisPaymentService(this._prefs);

  String get rawStaticQris => _prefs.getString(Constants.danaQrisStatic) ?? '';

  String get staticQris => rawStaticQris.trim();

  bool get hasStaticQris => staticQris.isNotEmpty;

  QrisValidationResult get validation =>
      validateQris(staticQris, requireStatic: true);

  bool get isConfigured => hasStaticQris && validation.isValid;

  QrisMerchantInfo? get merchantInfo =>
      hasStaticQris ? QrisMerchantInfo.tryParse(staticQris) : null;

  bool get uniqueCodeEnabled =>
      _prefs.getBool(Constants.danaUniqueCodeEnabled) ?? true;

  int get expiryMinutes {
    final value = _prefs.getInt(Constants.danaExpiryMinutes) ?? 15;
    return value <= 0 ? 15 : value;
  }

  bool get isTtsEnabled {
    final dana = _prefs.getBool(Constants.danaTtsEnabled);
    if (dana != null) return dana;
    return _prefs.getBool(Constants.klikQrisTtsEnabled) ?? true;
  }

  Future<void> saveStaticQris(String qris) async {
    final normalized = sanitizeQrisInput(qris);
    await _prefs.setString(Constants.danaQrisStatic, normalized);
  }

  Future<void> clearStaticQris() async {
    await _prefs.remove(Constants.danaQrisStatic);
  }

  Future<void> setUniqueCodeEnabled(bool value) =>
      _prefs.setBool(Constants.danaUniqueCodeEnabled, value);

  Future<void> setExpiryMinutes(int value) =>
      _prefs.setInt(Constants.danaExpiryMinutes, value);

  Future<void> setTtsEnabled(bool value) =>
      _prefs.setBool(Constants.danaTtsEnabled, value);

  /// Bangun payload QRIS dinamis untuk nominal [amount].
  String buildDynamicPayload(int amount) {
    if (!isConfigured) {
      throw const QrisConvertException(
        'QRIS DANA Bisnis belum diatur atau tidak valid',
      );
    }

    return convertQris(staticQris, amount: amount);
  }
}
