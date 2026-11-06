import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/themes/app_sizes.dart';
import '../../../../domain/entities/ai_insight_entity.dart';
import '../../../../generated/app_localizations.dart';

class InsightCard extends StatelessWidget {
  final AiInsightEntity insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var l10n = AppLocalizations.of(context)!;
    var style = _style(theme);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.surfaceContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(style.icon, size: 20, color: style.color),
            ),
            const SizedBox(width: AppSizes.padding / 1.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(l10n),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _message(l10n),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_actionLabel(l10n) != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _onAction(context),
                      child: Text(
                        _actionLabel(l10n)!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _InsightStyle _style(ThemeData theme) {
    var icon = _icon();

    switch (insight.severity) {
      case AiInsightSeverity.critical:
        return _InsightStyle(icon, theme.colorScheme.error);
      case AiInsightSeverity.warning:
        return _InsightStyle(icon, Colors.orange);
      case AiInsightSeverity.success:
        return _InsightStyle(icon, Colors.green);
      case AiInsightSeverity.info:
        return _InsightStyle(icon, theme.colorScheme.primary);
    }
  }

  IconData _icon() {
    switch (insight.type) {
      case AiInsightType.trend:
        return insight.primaryValue >= 0 ? Icons.trending_up : Icons.trending_down;
      case AiInsightType.bestSeller:
        return Icons.star_outline;
      case AiInsightType.deadStock:
        return Icons.inventory_2_outlined;
      case AiInsightType.margin:
        return Icons.percent;
      case AiInsightType.restock:
        return Icons.shopping_cart_outlined;
      case AiInsightType.peakTime:
        return Icons.schedule;
      case AiInsightType.paymentMix:
        return Icons.qr_code_2;
      case AiInsightType.priceMix:
        return Icons.compare_arrows;
      case AiInsightType.lowData:
        return Icons.info_outline;
    }
  }

  String _title(AppLocalizations l10n) {
    switch (insight.type) {
      case AiInsightType.trend:
        return l10n.insight_trendTitle;
      case AiInsightType.bestSeller:
        return l10n.insight_bestSellerTitle(insight.productName ?? '');
      case AiInsightType.deadStock:
        return l10n.insight_deadStockTitle(insight.productName ?? '');
      case AiInsightType.margin:
        return l10n.insight_marginTitle(insight.productName ?? '');
      case AiInsightType.restock:
        return l10n.insight_restockTitle(insight.productName ?? '');
      case AiInsightType.peakTime:
        return l10n.insight_peakTitle;
      case AiInsightType.paymentMix:
        return l10n.insight_paymentTitle;
      case AiInsightType.priceMix:
        return l10n.insight_priceMixTitle;
      case AiInsightType.lowData:
        return l10n.insight_lowDataTitle;
    }
  }

  String _message(AppLocalizations l10n) {
    switch (insight.type) {
      case AiInsightType.trend:
        return l10n.insight_trendMessage(
          '${insight.primaryValue >= 0 ? '+' : ''}${insight.primaryValue.toStringAsFixed(1)}%',
        );
      case AiInsightType.bestSeller:
        return l10n.insight_bestSellerMessage(
          insight.primaryValue.round(),
          insight.secondaryValue.round(),
        );
      case AiInsightType.deadStock:
        return l10n.insight_deadStockMessage(
          insight.primaryValue.round(),
          insight.secondaryValue.round(),
        );
      case AiInsightType.margin:
        if (insight.primaryValue == 0) return l10n.insight_marginMissing;
        return l10n.insight_marginLow(insight.primaryValue.toStringAsFixed(1));
      case AiInsightType.restock:
        return l10n.insight_restockMessage(
          insight.primaryValue.toStringAsFixed(1),
          insight.secondaryValue.round(),
        );
      case AiInsightType.peakTime:
        return l10n.insight_peakMessage(
          insight.primaryValue.round(),
          _dayName(l10n, insight.secondaryValue.round()),
          insight.extra,
        );
      case AiInsightType.paymentMix:
        return l10n.insight_paymentMessage(insight.primaryValue.toStringAsFixed(0));
      case AiInsightType.priceMix:
        return l10n.insight_priceMixMessage(
          insight.primaryValue.toStringAsFixed(0),
          insight.secondaryValue.toStringAsFixed(0),
        );
      case AiInsightType.lowData:
        return l10n.insight_lowDataMessage;
    }
  }

  String _dayName(AppLocalizations l10n, int weekday) {
    var names = [
      '',
      l10n.insight_monday,
      l10n.insight_tuesday,
      l10n.insight_wednesday,
      l10n.insight_thursday,
      l10n.insight_friday,
      l10n.insight_saturday,
      l10n.insight_sunday,
    ];
    if (weekday < 1 || weekday > 7) return '';
    return names[weekday];
  }

  String? _actionLabel(AppLocalizations l10n) {
    switch (insight.type) {
      case AiInsightType.restock:
      case AiInsightType.deadStock:
      case AiInsightType.bestSeller:
        return insight.productId == null ? null : l10n.insight_viewProduct;
      case AiInsightType.margin:
        return insight.productId == null ? null : l10n.insight_viewProduct;
      default:
        return null;
    }
  }

  void _onAction(BuildContext context) {
    if (insight.productId == null) return;
    context.push('/products/product-detail/${insight.productId}');
  }
}

class _InsightStyle {
  final IconData icon;
  final Color color;

  const _InsightStyle(this.icon, this.color);
}
