import '../../../domain/entities/supplier_entity.dart';

class SupplierState {
  final List<SupplierEntity> suppliers;
  final bool isLoading;
  final bool isLoaded;
  final String query;

  const SupplierState({
    this.suppliers = const [],
    this.isLoading = false,
    this.isLoaded = false,
    this.query = '',
  });

  SupplierState copyWith({
    List<SupplierEntity>? suppliers,
    bool? isLoading,
    bool? isLoaded,
    String? query,
  }) {
    return SupplierState(
      suppliers: suppliers ?? this.suppliers,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      query: query ?? this.query,
    );
  }
}
