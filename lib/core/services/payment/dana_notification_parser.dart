/// Parser teks notifikasi DANA Bisnis untuk mendeteksi pembayaran masuk.
library;

enum DanaNotificationKind {
  incomingPayment,
  notPayment,
  ignored,
}

class DanaNotificationParseResult {
  final DanaNotificationKind kind;
  final int? amount;
  final String? reason;

  const DanaNotificationParseResult({
    required this.kind,
    this.amount,
    this.reason,
  });

  bool get isIncomingPayment => kind == DanaNotificationKind.incomingPayment && amount != null;
}

const Set<String> _outgoingKeywords = {
  'keluar',
  'transfer ke',
  'pembayaran ke',
  'kamu membayar',
  'berhasil dibayar',
  'tarik saldo',
  'tarik tunai',
  'top up',
  'topup',
  'isi saldo',
  'pembelian',
  'membayar',
  'dikirim ke',
  'mengirim',
};

const Set<String> _incomingKeywords = {
  'diterima',
  'menerima',
  'masuk',
  'terima',
};

const Set<String> _businessKeywords = {
  'dana bisnis',
  'pembayaran',
  'qris',
  'merchant',
  'kasir',
  'business',
  'toko',
};

final RegExp _amountWithPrefix = RegExp(r'rp\.?\s*([0-9][0-9.,]*)', caseSensitive: false);

/// Parse judul + isi notifikasi menjadi nominal pembayaran bila memenuhi syarat.
///
/// [packageName] `id.dana.kasir` dianggap konteks bisnis karena aplikasi
/// tersebut memang khusus merchant.
DanaNotificationParseResult parseDanaNotification({
  required String title,
  required String body,
  String packageName = 'id.dana',
}) {
  final text = '$title $body'.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();

  if (text.isEmpty) {
    return const DanaNotificationParseResult(
      kind: DanaNotificationKind.ignored,
      reason: 'Teks notifikasi kosong',
    );
  }

  for (final keyword in _outgoingKeywords) {
    if (text.contains(keyword)) {
      return DanaNotificationParseResult(
        kind: DanaNotificationKind.notPayment,
        reason: 'Konteks keluar: "$keyword"',
      );
    }
  }

  final hasIncoming = _incomingKeywords.any(text.contains);
  if (!hasIncoming) {
    return const DanaNotificationParseResult(
      kind: DanaNotificationKind.notPayment,
      reason: 'Tidak ada kata penerimaan',
    );
  }

  final isKasirApp = packageName.contains('kasir');
  final hasBusinessContext = isKasirApp || _businessKeywords.any(text.contains);

  if (!hasBusinessContext) {
    return const DanaNotificationParseResult(
      kind: DanaNotificationKind.notPayment,
      reason: 'Bukan notifikasi pembayaran bisnis',
    );
  }

  final match = _amountWithPrefix.firstMatch(text);
  if (match == null) {
    return const DanaNotificationParseResult(
      kind: DanaNotificationKind.notPayment,
      reason: 'Nominal tidak ditemukan',
    );
  }

  final amount = parseAmount(match.group(1)!);
  if (amount == null || amount <= 0) {
    return const DanaNotificationParseResult(
      kind: DanaNotificationKind.notPayment,
      reason: 'Nominal tidak valid',
    );
  }

  return DanaNotificationParseResult(
    kind: DanaNotificationKind.incomingPayment,
    amount: amount,
  );
}

/// Normalisasi nominal Indonesia: `1.426` → 1426, `25.000,00` → 25000.
int? parseAmount(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return null;

  value = value.replaceAll(RegExp(r'[^0-9.,]'), '');
  if (value.isEmpty) return null;

  final lastComma = value.lastIndexOf(',');
  if (lastComma >= 0) {
    final decimals = value.substring(lastComma + 1);
    final integerPart = value.substring(0, lastComma).replaceAll('.', '');
    if (decimals.length <= 2) {
      return int.tryParse(integerPart.isEmpty ? '0' : integerPart);
    }
    return int.tryParse(value.replaceAll(RegExp(r'[.,]'), ''));
  }

  return int.tryParse(value.replaceAll('.', ''));
}
