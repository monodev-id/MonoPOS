import 'dart:math';

class BarcodeGenerator {
  const BarcodeGenerator._();

  static String generateEan13({String prefix = '899', Random? random}) {
    final rand = random ?? Random.secure();
    final cleanPrefix = prefix.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPrefix.length > 12) {
      throw ArgumentError('Prefix maksimal 12 digit, dapat ${cleanPrefix.length}');
    }

    final buffer = StringBuffer(cleanPrefix);
    while (buffer.length < 12) {
      buffer.write(rand.nextInt(10).toString());
    }

    final body = buffer.toString().substring(0, 12);
    final check = computeEan13CheckDigit(body);

    return '$body$check';
  }

  static int computeEan13CheckDigit(String firstTwelve) {
    final digits = firstTwelve.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length != 12) {
      throw ArgumentError('EAN-13 butuh 12 digit awal, dapat ${digits.length}');
    }

    var sum = 0;
    for (var i = 0; i < 12; i++) {
      final d = int.parse(digits[i]);
      sum += i.isEven ? d : d * 3;
    }

    return (10 - (sum % 10)) % 10;
  }

  static bool isValidEan13(String code) {
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length != 13) return false;

    try {
      return computeEan13CheckDigit(digits.substring(0, 12)) == int.parse(digits[12]);
    } catch (_) {
      return false;
    }
  }

  static String formatDisplay(String code) {
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length != 13) return code;

    return '${digits.substring(0, 1)} ${digits.substring(1, 7)} ${digits.substring(7)}';
  }

  static List<String> displayGroups(String code) {
    final digits = code.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length != 13) return [code];

    return [digits.substring(0, 1), digits.substring(1, 7), digits.substring(7)];
  }

  static Future<String> generateUniqueEan13({
    required Future<bool> Function(String code) exists,
    String prefix = '899',
    int maxAttempts = 20,
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      final code = generateEan13(prefix: prefix);

      if (!await exists(code)) return code;
    }

    throw StateError('Gagal generate barcode unik setelah $maxAttempts percobaan');
  }
}
