class DirectQrisState {
  final int amount;
  final String description;
  final String customerName;
  final bool isConfigured;
  final bool isSandbox;

  const DirectQrisState({
    this.amount = 0,
    this.description = '',
    this.customerName = '',
    this.isConfigured = false,
    this.isSandbox = false,
  });

  bool get canSubmit => isConfigured && amount > 0;

  DirectQrisState copyWith({
    int? amount,
    String? description,
    String? customerName,
    bool? isConfigured,
    bool? isSandbox,
  }) {
    return DirectQrisState(
      amount: amount ?? this.amount,
      description: description ?? this.description,
      customerName: customerName ?? this.customerName,
      isConfigured: isConfigured ?? this.isConfigured,
      isSandbox: isSandbox ?? this.isSandbox,
    );
  }
}
