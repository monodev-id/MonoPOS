class AppVersion {
  AppVersion._();

  static String normalize(String version) {
    var v = version.trim();

    if (v.startsWith('v') || v.startsWith('V')) v = v.substring(1);

    final plusIndex = v.indexOf('+');
    if (plusIndex != -1) v = v.substring(0, plusIndex);

    final dashIndex = v.indexOf('-');
    if (dashIndex != -1) v = v.substring(0, dashIndex);

    return v.trim();
  }

  static int compare(String a, String b) {
    final aParts = normalize(a).split('.');
    final bParts = normalize(b).split('.');

    final length = aParts.length > bParts.length ? aParts.length : bParts.length;

    for (var i = 0; i < length; i++) {
      final aPart = i < aParts.length ? int.tryParse(aParts[i]) ?? 0 : 0;
      final bPart = i < bParts.length ? int.tryParse(bParts[i]) ?? 0 : 0;

      if (aPart != bPart) return aPart.compareTo(bPart);
    }

    return 0;
  }

  static bool isNewer(String latest, String current) => compare(latest, current) > 0;
}
