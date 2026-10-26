import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pos/domain/entities/product_entity.dart';
import 'package:mono_pos/presentation/providers/purchases/purchase_form_state.dart';
import 'package:mono_pos/presentation/screens/purchases/components/purchase_item_editor.dart';

void main() {
  testWidgets('PurchaseItemEditor handles a product without unit rows', (tester) async {
    final product = ProductEntity(
      id: 1,
      createdById: 'user-1',
      name: 'Indomie Goreng',
      imageUrl: '',
      stock: 10,
      price: 3500,
      unit: 'pcs',
    );
    final item = PurchaseDraftItem(
      product: product,
      unitName: 'pcs',
      conversionValue: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: PurchaseItemEditor(item: item)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('pcs'), findsOneWidget);
    expect(find.text('Indomie Goreng'), findsOneWidget);
  });
}
