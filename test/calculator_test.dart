import 'package:flutter_test/flutter_test.dart';

import 'package:mobilyamevime_app/features/calculator/models/calculator_line.dart';
import 'package:mobilyamevime_app/features/calculator/providers/calculator_provider.dart';
import 'package:mobilyamevime_app/features/products/models/product_detail.dart';

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
    width: null,
    height: null,
    depth: null,
  );
}

ProductDetail _product() {
  return ProductDetail(
    id: 7,
    code: 'LZB-01',
    name: 'Lizbon Koltuk Takımı',
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
      _module(1, "3'lü", 20000, 16000, 1),
      _module(2, "2'li", 15000, 12000, 1),
      _module(3, 'Berjer', 8000, 6400, 1),
      _module(4, 'Puf', 3000, 2400, 0),
    ],
  );
}

void main() {
  group('CalculatorTotals', () {
    test('shipping included: (cost + shipping) × multiplier', () {
      const totals = CalculatorTotals(
        listTotal: 43000,
        costTotal: 34400,
        shipping: 3500,
        multiplier: 1.6,
        mode: ShippingMode.included,
      );
      expect(totals.salePrice, closeTo(60640, 0.001));
      expect(totals.profit, closeTo(60640 - 34400 - 3500, 0.001));
    });

    test('shipping separate: cost × multiplier + shipping', () {
      const totals = CalculatorTotals(
        listTotal: 43000,
        costTotal: 34400,
        shipping: 3500,
        multiplier: 1.6,
        mode: ShippingMode.separate,
      );
      expect(totals.salePrice, closeTo(58540, 0.001));
      expect(totals.profit, closeTo(55040 - 34400, 0.001));
    });
  });

  group('parseLocalizedNumber', () {
    test('amounts', () {
      expect(parseLocalizedNumber('3.500'), 3500);
      expect(parseLocalizedNumber('1.250.000'), 1250000);
      expect(parseLocalizedNumber('2.500,50'), 2500.5);
      expect(parseLocalizedNumber('3500'), 3500);
      expect(parseLocalizedNumber(' 3 500 ₺'), 3500);
      expect(parseLocalizedNumber(''), isNull);
      expect(parseLocalizedNumber(','), isNull);
    });

    test('multipliers', () {
      expect(parseLocalizedNumber('1,65', dotIsThousands: false), 1.65);
      expect(parseLocalizedNumber('1.6', dotIsThousands: false), 1.6);
      expect(parseLocalizedNumber('1.650', dotIsThousands: false), 1.65);
      expect(parseLocalizedNumber('2', dotIsThousands: false), 2);
    });
  });

  group('CalculatorController', () {
    test('standard set uses list and discounted purchase prices', () {
      final calc = CalculatorController()..addStandardSet(_product());

      expect(calc.totalQuantity, 3);
      expect(calc.quantityOf(7, 3), 0);
      expect(calc.totals.listTotal, 43000);
      expect(calc.totals.costTotal, 34400);
    });

    test('quantities, removal and multiplier', () {
      final product = _product();
      final calc = CalculatorController()
        ..setModuleQuantity(product, 3, 2)
        ..setModuleQuantity(product, 0, 1)
        ..setMultiplier(1.5);

      expect(calc.groups.single.lines.map((l) => l.moduleIndex), [0, 3]);
      expect(calc.totals.costTotal, 16000 + 2 * 2400);
      expect(calc.totals.salePrice, closeTo((16000 + 4800) * 1.5, 0.001));

      calc.setLineQuantity(CalculatorLine.lineKey(7, 3), 0);
      expect(calc.totalQuantity, 1);

      calc.removeProduct(7);
      expect(calc.isEmpty, isTrue);
    });

    test('clear keeps multiplier and mode, resets shipping', () {
      final calc = CalculatorController()
        ..addStandardSet(_product())
        ..setMultiplier(1.7)
        ..setShipping(3500)
        ..setShippingMode(ShippingMode.included)
        ..clear();

      expect(calc.isEmpty, isTrue);
      expect(calc.shipping, 0);
      expect(calc.multiplier, 1.7);
      expect(calc.shippingMode, ShippingMode.included);
    });

    test('ignores invalid multiplier and negative shipping', () {
      final calc = CalculatorController()
        ..setMultiplier(0)
        ..setShipping(-50);

      expect(calc.multiplier, 1.5);
      expect(calc.shipping, 0);
    });
  });
}
