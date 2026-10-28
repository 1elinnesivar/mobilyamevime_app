import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobilyamevime_app/core/theme/app_theme.dart';
import 'package:mobilyamevime_app/core/utils/currency_formatter.dart';
import 'package:mobilyamevime_app/features/calculator/providers/calculator_provider.dart';
import 'package:mobilyamevime_app/features/calculator/screens/calculator_screen.dart';
import 'package:mobilyamevime_app/features/calculator/widgets/module_picker_sheet.dart';
import 'package:mobilyamevime_app/features/products/models/product_detail.dart';
import 'package:mobilyamevime_app/features/products/providers/products_provider.dart';

ProductModule _module(int id, String name, num list, num net, int quantity) {
  return ProductModule(
    moduleId: id,
    name: name,
    nameEn: null,
    icon: null,
    quantity: quantity,
    salePrice: list * 2,
    purchasePrice: list,
    discountRate: 20,
    discountAmount: list - net,
    discountedPurchasePrice: net,
    width: '230',
    height: '90',
    depth: '95',
  );
}

final _product = ProductDetail(
  id: 7,
  code: 'LZB-01',
  name: 'Lizbon Köşe Koltuk Takımı Uzun İsimli Model',
  salePrice: 86000,
  purchasePrice: 34400,
  stock: 0,
  status: 'active',
  supplierId: 3,
  supplierName: 'Tedarikçi A',
  image: null,
  categoryName: null,
  description: null,
  images: const [],
  supplierDiscountRate: 20,
  modules: [
    _module(1, "3'lü Koltuk", 20000, 16000, 1),
    _module(2, "2'li Koltuk", 15000, 12000, 1),
    _module(3, 'Berjer', 8000, 6400, 1),
    _module(4, 'Puf', 3000, 2400, 0),
  ],
);

void _phoneViewport(WidgetTester tester, {double height = 2200}) {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = Size(360 * 3, height * 3);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('calculator renders at phone width and updates totals',
      (tester) async {
    _phoneViewport(tester);
    final calc = CalculatorController()
      ..addStandardSet(_product)
      ..setShipping(3500);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [calculatorControllerProvider.overrideWith((ref) => calc)],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const CalculatorScreen(),
        ),
      ),
    );

    expect(find.text('SATIŞ FİYATI'), findsOneWidget);
    // 34.400 × 1,5 + 3.500
    expect(find.text(CurrencyFormatter.format(55100)), findsOneWidget);
    expect(find.text('34.400 × 1,5 + 3.500'), findsOneWidget);

    await tester.tap(find.text('Maliyete dahil'));
    await tester.pump();
    expect(find.text('(34.400 + 3.500) × 1,5'), findsOneWidget);
    expect(find.text(CurrencyFormatter.format(56850)), findsOneWidget);

    await tester.tap(find.text('Özel'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, '1,5'), '1,65');
    await tester.pump();
    expect(calc.multiplier, 1.65);
    expect(find.text('(34.400 + 3.500) × 1,65'), findsOneWidget);

    await tester.tap(find.text('×1,7'));
    await tester.pump();
    expect(calc.multiplier, 1.7);
  });

  testWidgets('module picker adds the standard set', (tester) async {
    _phoneViewport(tester, height: 780);
    final calc = CalculatorController();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          calculatorControllerProvider.overrideWith((ref) => calc),
          productDetailProvider(7).overrideWith((ref) async => _product),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showModulePickerSheet(context, 7),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Berjer'), findsOneWidget);
    await tester.tap(find.text('Standart seti ekle'));
    await tester.pump();

    expect(calc.totalQuantity, 3);
    expect(
      find.text('Tamam · 3 modül · Alış ${CurrencyFormatter.format(34400)}'),
      findsOneWidget,
    );
  });
}
