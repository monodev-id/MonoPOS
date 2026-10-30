import '../../../domain/entities/transaction_entity.dart';

class QrisPaymentState {
  final TransactionEntity? transaction;
  final String payload;
  final String paymentStatus;
  final String? errorMessage;
  final int totalAmount;
  final int uniqueCode;
  final int expectedAmount;
  final DateTime? expiresAt;
  final int remainingSeconds;
  final bool isDirect;
  final bool isStarting;
  final bool isManualChecking;

  const QrisPaymentState({
    this.transaction,
    this.payload = '',
    this.paymentStatus = 'pending',
    this.errorMessage,
    this.totalAmount = 0,
    this.uniqueCode = 0,
    this.expectedAmount = 0,
    this.expiresAt,
    this.remainingSeconds = 0,
    this.isDirect = false,
    this.isStarting = false,
    this.isManualChecking = false,
  });

  bool get hasQr => payload.isNotEmpty;

  bool get isPending => paymentStatus == 'pending';

  bool get isPaid => paymentStatus == 'paid';

  bool get isExpired => paymentStatus == 'expired';

  QrisPaymentState copyWith({
    TransactionEntity? transaction,
    String? payload,
    String? paymentStatus,
    String? errorMessage,
    int? totalAmount,
    int? uniqueCode,
    int? expectedAmount,
    DateTime? expiresAt,
    int? remainingSeconds,
    bool? isDirect,
    bool? isStarting,
    bool? isManualChecking,
    bool clearError = false,
  }) {
    return QrisPaymentState(
      transaction: transaction ?? this.transaction,
      payload: payload ?? this.payload,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      totalAmount: totalAmount ?? this.totalAmount,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      expiresAt: expiresAt ?? this.expiresAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isDirect: isDirect ?? this.isDirect,
      isStarting: isStarting ?? this.isStarting,
      isManualChecking: isManualChecking ?? this.isManualChecking,
    );
  }
}
