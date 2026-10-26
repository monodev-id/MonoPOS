class SupplierFormState {
  final String? id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;
  final bool isLoaded;
  final bool isSaving;

  const SupplierFormState({
    this.id,
    this.name = '',
    this.phone,
    this.address,
    this.note,
    this.isLoaded = false,
    this.isSaving = false,
  });

  SupplierFormState copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? note,
    bool? isLoaded,
    bool? isSaving,
  }) {
    return SupplierFormState(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      note: note ?? this.note,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
