import '../../../domain/entities/ai_insight_entity.dart';

class AiInsightState {
  final bool isLoading;
  final int periodDays;
  final AiInsightSummary? summary;
  final List<AiInsightEntity>? insights;

  const AiInsightState({
    this.isLoading = false,
    this.periodDays = 30,
    this.summary,
    this.insights,
  });

  AiInsightState copyWith({
    bool? isLoading,
    int? periodDays,
    AiInsightSummary? summary,
    List<AiInsightEntity>? insights,
  }) {
    return AiInsightState(
      isLoading: isLoading ?? this.isLoading,
      periodDays: periodDays ?? this.periodDays,
      summary: summary ?? this.summary,
      insights: insights ?? this.insights,
    );
  }
}
