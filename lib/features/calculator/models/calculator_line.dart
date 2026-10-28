import '../../products/models/product_detail.dart';

enum ShippingMode { included, separate }

/// One selected module in the calculator.
/// listPrice = supplier list price (no discount), netPrice = discounted
/// purchase price. Cost is always based on netPrice.
class CalculatorLine {
  const CalculatorLine({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.supplierName,
    required this.moduleIndex,
    required this.moduleName,
    required this.measurement,
    required this.listPrice,
    required this.netPrice,
    required this.quantity,
  });

  final int productId;
  final String productName;
  final String productCode;
  final String? supplierName;
  final int moduleIndex;
  final String moduleName;
  final String measurement;
  final num listPrice;
  final num netPrice;
  final int quantity;

  /// Keyed by module position, since the same module id can appear twice
  /// in one product.
  String get key => lineKey(productId, moduleIndex);
  num get listTotal => listPrice * quantity;
  num get netTotal => netPrice * quantity;

  static String lineKey(int productId, int moduleIndex) =>
      '$productId:$moduleIndex';

  factory CalculatorLine.fromModule(
    ProductDetail product,
    int moduleIndex,
    int quantity,
  ) {
    final module = product.modules[moduleIndex];
    final listPrice = module.purchasePrice ?? 0;
    return CalculatorLine(
      productId: product.id,
      productName: product.name,
      productCode: product.code,
      supplierName: product.supplierName,
      moduleIndex: moduleIndex,
      moduleName: module.name ?? 'Modül #${module.moduleId}',
      measurement: moduleMeasurement(module),
      listPrice: listPrice,
      netPrice: module.discountedPurchasePrice ?? listPrice,
      quantity: quantity,
    );
  }

  CalculatorLine copyWith({int? quantity}) {
    return CalculatorLine(
      productId: productId,
      productName: productName,
      productCode: productCode,
      supplierName: supplierName,
      moduleIndex: moduleIndex,
      moduleName: moduleName,
      measurement: measurement,
      listPrice: listPrice,
      netPrice: netPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Selected lines of a single product.
class CalculatorGroup {
  const CalculatorGroup({
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.supplierName,
    required this.lines,
  });

  final int productId;
  final String productName;
  final String productCode;
  final String? supplierName;
  final List<CalculatorLine> lines;

  num get listTotal => lines.fold<num>(0, (sum, l) => sum + l.listTotal);
  num get netTotal => lines.fold<num>(0, (sum, l) => sum + l.netTotal);
  int get quantity => lines.fold<int>(0, (sum, l) => sum + l.quantity);
}

class CalculatorTotals {
  const CalculatorTotals({
    required this.listTotal,
    required this.costTotal,
    required this.shipping,
    required this.multiplier,
    required this.mode,
  });

  final num listTotal;
  final num costTotal;
  final num shipping;
  final num multiplier;
  final ShippingMode mode;

  /// included: (cost + shipping) × multiplier
  /// separate: cost × multiplier + shipping
  num get salePrice => mode == ShippingMode.included
      ? (costTotal + shipping) * multiplier
      : costTotal * multiplier + shipping;

  num get profit => salePrice - costTotal - shipping;
}

String moduleMeasurement(ProductModule module) {
  final size = [module.width, module.height]
      .where((v) => v != null && v.isNotEmpty)
      .join(' / ');
  if ((module.depth ?? '').isEmpty) return size;
  return size.isEmpty ? module.depth! : '$size / ${module.depth}';
}

/// Parses user input written in Turkish or plain format.
/// "3.500" → 3500, "2.500,50" → 2500.5, "1,65" → 1.65, "1.6" → 1.6.
/// With [dotIsThousands] false a lone dot is always a decimal separator.
num? parseLocalizedNumber(String input, {bool dotIsThousands = true}) {
  var value = input.replaceAll(RegExp(r'[\s₺]'), '');
  if (value.isEmpty) return null;
  if (value.contains(',')) {
    value = value.replaceAll('.', '').replaceAll(',', '.');
  } else if (dotIsThousands &&
      RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(value)) {
    value = value.replaceAll('.', '');
  }
  return num.tryParse(value);
}
