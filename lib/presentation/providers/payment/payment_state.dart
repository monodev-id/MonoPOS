import '../../../domain/entities/transaction_entity.dart';

class KlikQrisPaymentState {
  final TransactionEntity? transaction;
  final String qrCode;
  final String paymentStatus;
  final String? errorMessage;
  final bool isPolling;
  final int elapsedSeconds;
  final bool autoCheckDone;
  final bool isManualChecking;
  final bool manualCheckPending;
  final String orderId;
  final String signature;
  final int totalAmount;
  final bool isDirect;

  const KlikQrisPaymentState({
    this.transaction,
    this.qrCode = '',
    this.paymentStatus = 'pending',
    this.errorMessage,
    this.isPolling = false,
    this.elapsedSeconds = 0,
    this.autoCheckDone = false,
    this.isManualChecking = false,
    this.manualCheckPending = false,
    this.orderId = '',
    this.signature = '',
    this.totalAmount = 0,
    this.isDirect = false,
  });

  KlikQrisPaymentState copyWith({
    TransactionEntity? transaction,
    String? qrCode,
    String? paymentStatus,
    String? errorMessage,
    bool clearError = false,
    bool? isPolling,
    int? elapsedSeconds,
    bool? autoCheckDone,
    bool? isManualChecking,
    bool? manualCheckPending,
    String? orderId,
    String? signature,
    int? totalAmount,
    bool? isDirect,
  }) {
    return KlikQrisPaymentState(
      transaction: transaction ?? this.transaction,
      qrCode: qrCode ?? this.qrCode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPolling: isPolling ?? this.isPolling,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      autoCheckDone: autoCheckDone ?? this.autoCheckDone,
      isManualChecking: isManualChecking ?? this.isManualChecking,
      manualCheckPending: manualCheckPending ?? this.manualCheckPending,
      orderId: orderId ?? this.orderId,
      signature: signature ?? this.signature,
      totalAmount: totalAmount ?? this.totalAmount,
      isDirect: isDirect ?? this.isDirect,
    );
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isFailed => paymentStatus == 'failed';
  bool get isExpired => paymentStatus == 'expired';
  bool get isPending => paymentStatus == 'pending';
}
