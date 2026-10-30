import 'qris_crc16.dart';
import 'qris_tlv.dart';

/// Informasi merchant yang bisa ditampilkan setelah QRIS statis di-upload.
class QrisMerchantInfo {
  final String merchantName;
  final String merchantCity;
  final String nmid;
  final String merchantId;
  final String acquirer;
  final bool crcValid;

  const QrisMerchantInfo({
    this.merchantName = '',
    this.merchantCity = '',
    this.nmid = '',
    this.merchantId = '',
    this.acquirer = '',
    this.crcValid = false,
  });

  bool get isEmpty =>
      merchantName.isEmpty && nmid.isEmpty && merchantId.isEmpty;

  static QrisMerchantInfo? tryParse(String qris) {
    try {
      final elements = parseTlv(qris.trim());
      if (elements.isEmpty) return null;

      String? valueOf(String tag) {
        for (final element in elements) {
          if (element.tag == tag) return element.value;
        }
        return null;
      }

      var acquirer = '';
      var nmid = '';
      var merchantId = '';

      for (final element in elements) {
        final tagNumber = int.tryParse(element.tag);
        if (tagNumber == null || tagNumber < 26 || tagNumber > 51) continue;

        final children = element.children;
        if (children == null || children.isEmpty) continue;

        // Acquirer diambil dari merchant account info pertama (biasanya tag 26).
        // Tag 51 (ID.CO.QRIS.WWW) hanya template switch nasional.
        if (acquirer.isEmpty) {
          acquirer =
              children
                  .where((c) => c.tag == '00')
                  .map((c) => c.value)
                  .firstOrNull ??
              '';
        }

        // NMID nasional selalu diawali "ID"; nilai lain (mis. nomor merchant
        // internal acquirer) tidak dipakai.
        final childNmid = children
            .where((c) => c.tag == '02')
            .map((c) => c.value)
            .firstOrNull;
        if (childNmid != null && childNmid.isNotEmpty) {
          if (childNmid.startsWith('ID') || nmid.isEmpty) {
            nmid = childNmid;
          }
        }

        if (merchantId.isEmpty) {
          merchantId =
              children
                  .where((c) => c.tag == '01')
                  .map((c) => c.value)
                  .firstOrNull ??
              '';
        }
      }

      return QrisMerchantInfo(
        merchantName: valueOf('59') ?? '',
        merchantCity: valueOf('60') ?? '',
        nmid: nmid,
        merchantId: merchantId,
        acquirer: acquirer,
        crcValid: isCrcValid(qris),
      );
    } catch (_) {
      return null;
    }
  }
}
