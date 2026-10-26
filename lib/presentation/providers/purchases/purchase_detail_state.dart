import '../../../domain/entities/purchase_entity.dart';

class PurchaseDetailState {
  final PurchaseEntity? purchase;
  final bool isLoading;

  const PurchaseDetailState({this.purchase, this.isLoading = true});

  PurchaseDetailState copyWith({PurchaseEntity? purchase, bool? isLoading}) {
    return PurchaseDetailState(
      purchase: purchase ?? this.purchase,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
