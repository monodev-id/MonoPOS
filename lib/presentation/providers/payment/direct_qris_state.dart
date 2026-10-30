class DirectQrisState {
  final int amount;
  final String description;
  final String customerName;
  final bool isConfigured;
  final String merchantName;

  const DirectQrisState({
    this.amount = 0,
    this.description = '',
    this.customerName = '',
    this.isConfigured = false,
    this.merchantName = '',
  });

  bool get canSubmit => isConfigured && amount > 0;

  DirectQrisState copyWith({
    int? amount,
    String? description,
    String? customerName,
    bool? isConfigured,
    String? merchantName,
  }) {
    return DirectQrisState(
      amount: amount ?? this.amount,
      description: description ?? this.description,
      customerName: customerName ?? this.customerName,
      isConfigured: isConfigured ?? this.isConfigured,
      merchantName: merchantName ?? this.merchantName,
    );
  }
}
