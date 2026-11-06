import '../../../domain/entities/ai_insight_entity.dart';
import '../../../domain/entities/ordered_product_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

class InsightCalculator {
  InsightCalculator._();

  static const int trendWindowDays = 7;
  static const int deadStockDays = 14;
  static const double dropThresholdPercent = -20;
  static const double riseThresholdPercent = 10;
  static const double lowMarginPercent = 10;
  static const int restockCriticalDays = 7;
  static const int restockWarningDays = 14;
  static const double lowQrisShare = 0.1;
  static const int minTransactionsForMix = 5;

  static AiInsightReport calculate({
    required List<TransactionEntity> transactions,
    required List<ProductEntity> products,
    required DateTime now,
    int periodDays = 30,
  }) {
    var paid = transactions.where((t) => t.paymentStatus.toLowerCase() == 'paid').toList();

    var periodStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: periodDays - 1));
    var inPeriod = paid.where((t) {
      var d = _parseDate(t.createdAt);
      return d != null && !d.isBefore(periodStart) && !d.isAfter(now);
    }).toList();

    var totalAmount = 0;
    var totalQty = 0;
    var retailQty = 0;
    var qrisCount = 0;

    for (var t in inPeriod) {
      totalAmount += t.totalAmount;

      if (t.paymentMethod.toLowerCase() == 'qris') qrisCount++;

      for (var item in t.orderedProducts ?? const <OrderedProductEntity>[]) {
        var qty = item.quantity.round();
        totalQty += qty;

        if (item.priceType.toLowerCase() != 'grosir') {
          retailQty += qty;
        }
      }
    }

    var trendPercent = _trendPercent(paid, now);
    var summary = AiInsightSummary(
      totalAmount: totalAmount,
      transactionCount: inPeriod.length,
      totalProducts: totalQty,
      avgTicket: inPeriod.isEmpty ? 0 : totalAmount / inPeriod.length,
      trendPercent: trendPercent,
      retailShare: totalQty == 0 ? 0 : retailQty / totalQty,
      qrisShare: inPeriod.isEmpty ? 0 : qrisCount / inPeriod.length,
    );

    if (inPeriod.length < minTransactionsForMix && totalQty < 10) {
      return AiInsightReport(
        summary: summary,
        insights: const [
          AiInsightEntity(
            id: 'low-data',
            type: AiInsightType.lowData,
            severity: AiInsightSeverity.info,
          ),
        ],
      );
    }

    var insights = <AiInsightEntity>[];
    insights.add(_trendInsight(trendPercent));

    var salesByProduct = _salesByProduct(inPeriod);
    insights.addAll(_bestSellerInsights(salesByProduct));
    insights.addAll(_restockInsights(salesByProduct, products, periodDays));
    insights.addAll(_deadStockInsights(salesByProduct, products, now, periodDays));
    insights.addAll(_marginInsights(salesByProduct, products));
    insights.add(_peakTimeInsight(inPeriod));
    insights.addAll(_mixInsights(summary, inPeriod.length));

    insights.sort((a, b) {
      var rank = _severityRank(a.severity).compareTo(_severityRank(b.severity));
      return rank;
    });

    return AiInsightReport(summary: summary, insights: insights.take(12).toList());
  }

  static int _severityRank(AiInsightSeverity s) {
    switch (s) {
      case AiInsightSeverity.critical:
        return 0;
      case AiInsightSeverity.warning:
        return 1;
      case AiInsightSeverity.success:
        return 2;
      case AiInsightSeverity.info:
        return 3;
    }
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static double _trendPercent(List<TransactionEntity> paid, DateTime now) {
    var today = DateTime(now.year, now.month, now.day);
    var curStart = today.subtract(const Duration(days: trendWindowDays - 1));
    var prevStart = curStart.subtract(const Duration(days: trendWindowDays));
    var prevEnd = curStart.subtract(const Duration(days: 1));

    var cur = 0;
    var prev = 0;

    for (var t in paid) {
      var d = _parseDate(t.createdAt);
      if (d == null) continue;
      var day = DateTime(d.year, d.month, d.day);

      if (!day.isBefore(curStart) && !day.isAfter(today)) {
        cur += t.totalAmount;
      } else if (!day.isBefore(prevStart) && !day.isAfter(prevEnd)) {
        prev += t.totalAmount;
      }
    }

    if (prev <= 0) return cur > 0 ? 100 : 0;
    return (cur - prev) / prev * 100;
  }

  static AiInsightEntity _trendInsight(double percent) {
    var severity = AiInsightSeverity.info;

    if (percent <= dropThresholdPercent) {
      severity = AiInsightSeverity.warning;
    } else if (percent >= riseThresholdPercent) {
      severity = AiInsightSeverity.success;
    }

    return AiInsightEntity(
      id: 'trend',
      type: AiInsightType.trend,
      severity: severity,
      primaryValue: percent,
    );
  }

  static Map<int, _ProductSales> _salesByProduct(List<TransactionEntity> transactions) {
    var map = <int, _ProductSales>{};

    for (var t in transactions) {
      var date = _parseDate(t.createdAt);

      for (var item in t.orderedProducts ?? const <OrderedProductEntity>[]) {
        var entry = map[item.productId] ?? _ProductSales(name: item.name);
        entry.qty += item.quantity.round();
        entry.revenue += (item.price * item.quantity).round();
        entry.retailQty += item.priceType.toLowerCase() == 'grosir' ? 0 : item.quantity.round();
        entry.grosirQty += item.priceType.toLowerCase() == 'grosir' ? item.quantity.round() : 0;

        if (date != null && (entry.lastSoldAt == null || date.isAfter(entry.lastSoldAt!))) {
          entry.lastSoldAt = date;
        }

        map[item.productId] = entry;
      }
    }

    return map;
  }

  static List<AiInsightEntity> _bestSellerInsights(Map<int, _ProductSales> sales) {
    var sorted = sales.entries.toList()..sort((a, b) => b.value.qty.compareTo(a.value.qty));
    return sorted.take(3).map((e) {
      return AiInsightEntity(
        id: 'best-${e.key}',
        type: AiInsightType.bestSeller,
        severity: AiInsightSeverity.success,
        productId: e.key,
        productName: e.value.name,
        primaryValue: e.value.qty.toDouble(),
        secondaryValue: e.value.revenue.toDouble(),
      );
    }).toList();
  }

  static List<AiInsightEntity> _restockInsights(
    Map<int, _ProductSales> sales,
    List<ProductEntity> products,
    int periodDays,
  ) {
    var result = <AiInsightEntity>[];
    var byId = {for (var p in products) p.id: p};

    for (var entry in sales.entries) {
      var product = byId[entry.key];
      if (product == null) continue;

      var velocity = entry.value.qty / periodDays;
      if (velocity <= 0) continue;

      var daysLeft = product.stock / velocity;
      if (daysLeft < restockCriticalDays) {
        result.add(
          AiInsightEntity(
            id: 'restock-critical-${entry.key}',
            type: AiInsightType.restock,
            severity: AiInsightSeverity.critical,
            productId: entry.key,
            productName: product.name,
            primaryValue: daysLeft,
            secondaryValue: product.stock.toDouble(),
          ),
        );
      } else if (daysLeft < restockWarningDays) {
        result.add(
          AiInsightEntity(
            id: 'restock-warning-${entry.key}',
            type: AiInsightType.restock,
            severity: AiInsightSeverity.warning,
            productId: entry.key,
            productName: product.name,
            primaryValue: daysLeft,
            secondaryValue: product.stock.toDouble(),
          ),
        );
      }
    }

    result.sort((a, b) => a.primaryValue.compareTo(b.primaryValue));
    return result.take(3).toList();
  }

  static List<AiInsightEntity> _deadStockInsights(
    Map<int, _ProductSales> sales,
    List<ProductEntity> products,
    DateTime now,
    int periodDays,
  ) {
    var result = <AiInsightEntity>[];

    for (var p in products) {
      if (p.id == null || (p.stock) <= 0) continue;
      if (sales.containsKey(p.id)) {
        var last = sales[p.id]!.lastSoldAt;
        if (last != null && now.difference(last).inDays < deadStockDays) continue;
      }

      var daysIdle = sales.containsKey(p.id) && sales[p.id]!.lastSoldAt != null
          ? now.difference(sales[p.id]!.lastSoldAt!).inDays.toDouble()
          : periodDays.toDouble();

      if (daysIdle >= deadStockDays) {
        result.add(
          AiInsightEntity(
            id: 'dead-${p.id}',
            type: AiInsightType.deadStock,
            severity: AiInsightSeverity.warning,
            productId: p.id,
            productName: p.name,
            primaryValue: daysIdle,
            secondaryValue: p.stock.toDouble(),
          ),
        );
      }
    }

    result.sort((a, b) => b.secondaryValue.compareTo(a.secondaryValue));
    return result.take(3).toList();
  }

  static List<AiInsightEntity> _marginInsights(
    Map<int, _ProductSales> sales,
    List<ProductEntity> products,
  ) {
    var result = <AiInsightEntity>[];
    var byId = {for (var p in products) p.id: p};
    var sorted = sales.entries.toList()..sort((a, b) => b.value.qty.compareTo(a.value.qty));

    for (var e in sorted.take(5)) {
      var product = byId[e.key];
      if (product == null) continue;

      if (product.costPrice <= 0 || product.price <= 0) {
        result.add(
          AiInsightEntity(
            id: 'margin-missing-${e.key}',
            type: AiInsightType.margin,
            severity: AiInsightSeverity.info,
            productId: e.key,
            productName: product.name,
          ),
        );
        continue;
      }

      var margin = (product.price - product.costPrice) / product.price * 100;
      if (margin < lowMarginPercent) {
        result.add(
          AiInsightEntity(
            id: 'margin-low-${e.key}',
            type: AiInsightType.margin,
            severity: AiInsightSeverity.warning,
            productId: e.key,
            productName: product.name,
            primaryValue: margin,
            secondaryValue: product.costPrice.toDouble(),
          ),
        );
      }
    }

    return result.take(2).toList();
  }

  static AiInsightEntity _peakTimeInsight(List<TransactionEntity> transactions) {
    var byHour = List.filled(24, 0);
    var byDay = List.filled(8, 0);

    for (var t in transactions) {
      var d = _parseDate(t.createdAt);
      if (d == null) continue;
      byHour[d.hour]++;
      byDay[d.weekday]++;
    }

    var bestHour = 0;
    for (var i = 1; i < 24; i++) {
      if (byHour[i] > byHour[bestHour]) bestHour = i;
    }

    var bestDay = 1;
    for (var i = 2; i <= 7; i++) {
      if (byDay[i] > byDay[bestDay]) bestDay = i;
    }

    return AiInsightEntity(
      id: 'peak-time',
      type: AiInsightType.peakTime,
      severity: AiInsightSeverity.info,
      primaryValue: bestHour.toDouble(),
      secondaryValue: bestDay.toDouble(),
      extra: '${byHour[bestHour]}',
    );
  }

  static List<AiInsightEntity> _mixInsights(AiInsightSummary summary, int count) {
    var result = <AiInsightEntity>[];

    if (count >= minTransactionsForMix && summary.qrisShare < lowQrisShare) {
      result.add(
        AiInsightEntity(
          id: 'payment-mix',
          type: AiInsightType.paymentMix,
          severity: AiInsightSeverity.info,
          primaryValue: summary.qrisShare * 100,
        ),
      );
    }

    if (summary.totalProducts > 0) {
      var grosirShare = 1 - summary.retailShare;
      result.add(
        AiInsightEntity(
          id: 'price-mix',
          type: AiInsightType.priceMix,
          severity: AiInsightSeverity.info,
          primaryValue: summary.retailShare * 100,
          secondaryValue: grosirShare * 100,
        ),
      );
    }

    return result;
  }
}

class _ProductSales {
  _ProductSales({required this.name});

  final String name;
  int qty = 0;
  int revenue = 0;
  int retailQty = 0;
  int grosirQty = 0;
  DateTime? lastSoldAt;
}
