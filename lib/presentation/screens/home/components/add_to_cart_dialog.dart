import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di/app_providers.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../domain/entities/product_tier_entity.dart';
import '../../../../domain/entities/product_unit_entity.dart';
import '../../../../domain/usecases/product_usecases.dart';
import 'order_card.dart';

class AddToCartDialog extends ConsumerStatefulWidget {
  final ProductEntity product;
  final double initialQuantity;
  final bool isGrosir;
  final List<ProductUnitEntity> effectiveUnits;

  const AddToCartDialog({
    super.key,
    required this.product,
    required this.initialQuantity,
    required this.isGrosir,
    required this.effectiveUnits,
  });

  @override
  ConsumerState<AddToCartDialog> createState() => AddToCartDialogState();
}

class AddToCartDialogState extends ConsumerState<AddToCartDialog> {
  late double _quantity;
  late String _selectedUnit;
  late int _conversionValue;
  late int _price;
  late String _priceType;
  bool _isTieredPrice = false;
  final Map<int, List<ProductTierEntity>> _unitTiers = {};

  double get quantity => _quantity;
  String get selectedUnit => _selectedUnit;
  int get conversionValue => _conversionValue;
  int get price => _price;
  String get priceType => _priceType;
  bool get isTieredPrice => _isTieredPrice;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity == 0 ? 1 : widget.initialQuantity;
    _priceType = widget.isGrosir ? 'grosir' : 'retail';

    var defaultUnit = widget.effectiveUnits.firstWhere(
      (u) => u.unitName == widget.product.unit,
      orElse: () => widget.effectiveUnits.first,
    );
    _selectedUnit = defaultUnit.unitName;
    _conversionValue = defaultUnit.conversionValue;
    _recomputePrice();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    final productRepository = ref.read(productRepositoryProvider);
    for (final unit in widget.effectiveUnits) {
      if (unit.id != null && unit.id! > 0 && !_unitTiers.containsKey(unit.id)) {
        final res = await GetProductTiersUsecase(productRepository).call(unit.id!);
        if (res.isSuccess && res.data != null && res.data!.isNotEmpty) {
          _unitTiers[unit.id!] = res.data!;
        }
      }
    }
    _recomputePrice();
    if (mounted) setState(() {});
  }

  void _recomputePrice() {
    final unit = widget.effectiveUnits.firstWhere((u) => u.unitName == _selectedUnit);
    final basePrice = _priceType == 'grosir' && unit.wholesalePrice != null ? unit.wholesalePrice! : unit.price;

    final tiers = unit.id != null ? _unitTiers[unit.id] : null;
    if (tiers != null && tiers.isNotEmpty) {
      final intQty = _quantity.round();
      for (final tier in tiers) {
        if (intQty >= tier.minQty && intQty % tier.minQty == 0) {
          final bundles = intQty ~/ tier.minQty;
          _price = bundles * tier.price;
          _isTieredPrice = true;
          return;
        }
      }
    }

    _price = basePrice;
    _isTieredPrice = false;
  }

  void _onChangedUnit(String? val) {
    if (val == null) return;
    var unit = widget.effectiveUnits.firstWhere((u) => u.unitName == val);
    setState(() {
      _selectedUnit = unit.unitName;
      _conversionValue = unit.conversionValue;
      _recomputePrice();
    });
  }

  void _onChangedPriceType(String value) {
    setState(() {
      _priceType = value;
      _recomputePrice();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrderCard(
      name: widget.product.name,
      imageUrl: widget.product.imageUrl,
      stock: widget.product.stock,
      price: _price,
      priceType: _priceType,
      unit: widget.product.unit,
      initialQuantity: _quantity,
      selectedUnit: _selectedUnit,
      availableUnits: widget.effectiveUnits.map((u) => u.unitName).toList(),
      conversionValue: _conversionValue,
      onChangedUnit: _onChangedUnit,
      onChangedPriceType: _onChangedPriceType,
      isTieredPrice: _isTieredPrice,
      onChangedQuantity: (val) async {
        _quantity = val;
        _recomputePrice();
        if (mounted) setState(() {});
      },
    );
  }
}
