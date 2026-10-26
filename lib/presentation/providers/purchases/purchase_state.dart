import '../../../domain/entities/purchase_entity.dart';

class PurchaseState {
  final List<PurchaseEntity> purchases;
  final bool isLoading;
  final bool isLoaded;
  final String query;
  final String? month;

  const PurchaseState({
    this.purchases = const [],
    this.isLoading = false,
    this.isLoaded = false,
    this.query = '',
    this.month,
  });

  PurchaseState copyWith({
    List<PurchaseEntity>? purchases,
    bool? isLoading,
    bool? isLoaded,
    String? query,
    String? month,
  }) {
    return PurchaseState(
      purchases: purchases ?? this.purchases,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      query: query ?? this.query,
      month: month ?? this.month,
    );
  }
}
