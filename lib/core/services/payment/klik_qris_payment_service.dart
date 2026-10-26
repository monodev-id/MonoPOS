import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/result.dart';
import '../../constants/constants.dart';
import '../../utilities/console_logger.dart';

enum KlikQrisPaymentStatus { paid, pending, expired }

class KlikQrisQrisResponse {
  final String orderId;
  final String qrUrl;
  final String qrImageBase64;
  final int totalAmount;
  final String status;
  final String signature;
  final String expiredAt;
  final int expiredMinutes;

  const KlikQrisQrisResponse({
    required this.orderId,
    required this.qrUrl,
    required this.qrImageBase64,
    required this.totalAmount,
    required this.status,
    required this.signature,
    required this.expiredAt,
    required this.expiredMinutes,
  });
}

class KlikQrisPaymentService {
  final SharedPreferences _prefs;

  KlikQrisPaymentService(this._prefs);

  String? get _apiKey => _prefs.getString(Constants.klikQrisApiKey);
  String? get _merchantId => _prefs.getString(Constants.klikQrisMerchantId);
  bool get _isSandbox => _prefs.getBool(Constants.klikQrisIsSandbox) ?? false;

  static const String _baseUrl = 'https://klikqris.com/api';

  String get _envBaseUrl => _isSandbox ? '$_baseUrl/sandbox' : _baseUrl;

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty && _merchantId != null && _merchantId!.isNotEmpty;

  bool get isSandbox => _isSandbox;

  bool get isMockMode => !isConfigured;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey!,
    'id_merchant': _merchantId!,
  };

  Future<Result<KlikQrisQrisResponse>> generateQris({
    required String orderId,
    required int grossAmount,
    String? description,
  }) async {
    if (isMockMode) {
      return _mockGenerateQris(orderId, grossAmount);
    }

    try {
      final trimmedDescription = description?.trim();
      final body = {
        'order_id': orderId,
        'id_merchant': _merchantId,
        'amount': grossAmount,
        'keterangan': trimmedDescription == null || trimmedDescription.isEmpty
            ? 'Pembayaran QRIS MonoPOS'
            : trimmedDescription,
      };

      final uri = Uri.parse('$_envBaseUrl/qris/create');
      final response = await http.post(uri, headers: _headers, body: jsonEncode(body));

      if (response.statusCode != 200 && response.statusCode != 201) {
        return Result.failure(error: 'KlikQRIS error (${response.statusCode}): ${_extractErrorMessage(response)}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as bool? ?? false;

      if (!status) {
        return Result.failure(error: json['message'] as String? ?? 'Gagal membuat QRIS');
      }

      final data = json['data'] as Map<String, dynamic>?;

      if (data == null) {
        return Result.failure(error: 'Respons KlikQRIS tidak valid');
      }

      final totalAmount = _parseAmount(data['total_amount'], fallback: grossAmount);
      final expiredMinutes = int.tryParse(data['expired_menit']?.toString() ?? '') ?? 60;

      final result = KlikQrisQrisResponse(
        orderId: data['order_id'] as String? ?? orderId,
        qrUrl: data['qris_url'] as String? ?? '',
        qrImageBase64: data['qris_image'] as String? ?? '',
        totalAmount: totalAmount,
        status: data['status'] as String? ?? 'PENDING',
        signature: data['signature'] as String? ?? '',
        expiredAt: data['expired_at'] as String? ?? '',
        expiredMinutes: expiredMinutes,
      );

      cl(
        '[KlikQRIS] generateQris ok: orderId=${result.orderId} '
        'qrImageBase64.len=${result.qrImageBase64.length} '
        'qrUrl=${result.qrUrl} totalAmount=${result.totalAmount}',
      );

      return Result.success(data: result);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<KlikQrisPaymentStatus>> queryQrisStatus({
    required String orderId,
    int? expectedTotalAmount,
  }) async {
    if (isMockMode) {
      return _mockQueryQrisStatus(orderId);
    }

    try {
      final uri = Uri.parse('$_envBaseUrl/qris/status/$orderId');
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode != 200 && response.statusCode != 201) {
        return Result.failure(
          error: 'KlikQRIS status error (${response.statusCode}): ${_extractErrorMessage(response)}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as bool? ?? false;

      if (!status) {
        return Result.failure(error: json['message'] as String? ?? 'Gagal cek status');
      }

      final data = json['data'] as Map<String, dynamic>?;

      if (data == null) {
        return Result.failure(error: 'Respons status KlikQRIS tidak valid');
      }

      final responseOrderId = data['order_id']?.toString();
      if (responseOrderId != null && responseOrderId.isNotEmpty && responseOrderId != orderId) {
        return Result.failure(
          error: 'Order ID tidak cocok: $responseOrderId (diharapkan $orderId)',
        );
      }

      if (expectedTotalAmount != null && expectedTotalAmount > 0) {
        final responseTotal = _parseAmount(data['total_amount'], fallback: -1);

        if (responseTotal != expectedTotalAmount) {
          return Result.failure(
            error:
                'Nominal tidak cocok: '
                '${responseTotal < 0 ? 'tidak tersedia' : responseTotal} '
                '(diharapkan $expectedTotalAmount)',
          );
        }
      }

      final transactionStatus = (data['status'] as String? ?? 'PENDING').toUpperCase();

      switch (transactionStatus) {
        case 'SUCCESS':
        case 'PAID':
          return Result.success(data: KlikQrisPaymentStatus.paid);
        case 'EXPIRED':
          return Result.success(data: KlikQrisPaymentStatus.expired);
        default:
          return Result.success(data: KlikQrisPaymentStatus.pending);
      }
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  int _parseAmount(dynamic value, {required int fallback}) {
    if (value is num) return value.round();

    return double.tryParse(value?.toString() ?? '')?.round() ?? fallback;
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final message = json['message'];

      if (message is String && message.trim().isNotEmpty) return message;

      final errors = json['errors'];

      if (errors is Map && errors.isNotEmpty) {
        return errors.values.map((e) => e is List ? e.join(', ') : e.toString()).join('; ');
      }
    } catch (_) {
      // Fall back to the raw response body.
    }

    return response.body;
  }

  // Mock implementation

  final Map<String, _MockQrisState> _mockStates = {};

  Result<KlikQrisQrisResponse> _mockGenerateQris(String orderId, int grossAmount) {
    final qrUrl = 'https://klikqris.com/storage/sandbox/qris_$orderId.png';
    final now = DateTime.now();

    _mockStates[orderId] = _MockQrisState(
      status: 'pending',
      createdAt: DateTime.now(),
    );

    cl('[KlikQrisMock] Generated QRIS for $orderId: amount=$grossAmount');

    return Result.success(
      data: KlikQrisQrisResponse(
        orderId: orderId,
        qrUrl: qrUrl,
        qrImageBase64: '',
        totalAmount: grossAmount + Random().nextInt(99),
        status: 'PENDING',
        signature: 'MOCK-SIGNATURE',
        expiredAt: now.toUtc().toIso8601String(),
        expiredMinutes: 60,
      ),
    );
  }

  Future<Result<KlikQrisPaymentStatus>> _mockQueryQrisStatus(String orderId) async {
    final state = _mockStates[orderId];
    if (state == null) {
      return Result.success(data: KlikQrisPaymentStatus.expired);
    }

    if (state.status == 'paid') {
      return Result.success(data: KlikQrisPaymentStatus.paid);
    }

    final elapsed = DateTime.now().difference(state.createdAt);
    if (elapsed.inSeconds >= 30) {
      _mockStates[orderId] = state.copyWith(status: 'paid');
      cl('[KlikQrisMock] Payment completed for $orderId');
      return Result.success(data: KlikQrisPaymentStatus.paid);
    }

    return Result.success(data: KlikQrisPaymentStatus.pending);
  }
}

class _MockQrisState {
  final String status;
  final DateTime createdAt;

  const _MockQrisState({required this.status, required this.createdAt});

  _MockQrisState copyWith({String? status}) {
    return _MockQrisState(status: status ?? this.status, createdAt: createdAt);
  }
}
