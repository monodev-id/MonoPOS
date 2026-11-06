import 'package:equatable/equatable.dart';

enum AiInsightType {
  trend,
  bestSeller,
  deadStock,
  margin,
  restock,
  peakTime,
  paymentMix,
  priceMix,
  lowData,
}

enum AiInsightSeverity {
  info,
  success,
  warning,
  critical,
}

class AiInsightEntity extends Equatable {
  final String id;
  final AiInsightType type;
  final AiInsightSeverity severity;
  final int? productId;
  final String? productName;
  final double primaryValue;
  final double secondaryValue;
  final String extra;

  const AiInsightEntity({
    required this.id,
    required this.type,
    required this.severity,
    this.productId,
    this.productName,
    this.primaryValue = 0,
    this.secondaryValue = 0,
    this.extra = '',
  });

  @override
  List<Object?> get props => [
    id,
    type,
    severity,
    productId,
    productName,
    primaryValue,
    secondaryValue,
    extra,
  ];
}

class AiInsightSummary extends Equatable {
  final int totalAmount;
  final int transactionCount;
  final int totalProducts;
  final double avgTicket;
  final double trendPercent;
  final double retailShare;
  final double qrisShare;

  const AiInsightSummary({
    this.totalAmount = 0,
    this.transactionCount = 0,
    this.totalProducts = 0,
    this.avgTicket = 0,
    this.trendPercent = 0,
    this.retailShare = 0,
    this.qrisShare = 0,
  });

  @override
  List<Object> get props => [
    totalAmount,
    transactionCount,
    totalProducts,
    avgTicket,
    trendPercent,
    retailShare,
    qrisShare,
  ];
}

class AiInsightReport extends Equatable {
  final AiInsightSummary summary;
  final List<AiInsightEntity> insights;

  const AiInsightReport({
    required this.summary,
    required this.insights,
  });

  @override
  List<Object> get props => [summary, insights];
}
