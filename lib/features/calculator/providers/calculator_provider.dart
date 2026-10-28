import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/utils/provider_cache.dart';
import '../../auth/providers/auth_provider.dart';
import '../../products/models/product.dart';
import '../../products/models/product_detail.dart';
import '../../products/providers/products_provider.dart';
import '../models/calculator_line.dart';

/// Not autoDispose: the selection survives tab switches for the session.
final calculatorControllerProvider =
    ChangeNotifierProvider<CalculatorController>((ref) {
  return CalculatorController();
});

/// Separate from productsControllerProvider so searching here does not
/// change the Products tab's search state.
final calculatorSearchProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, query) async {
  ref.cacheFor(const Duration(minutes: 2));
  try {
    final result =
        await ref.watch(productsRepositoryProvider).list(page: 1, search: query);
    return result.items;
  } on ApiException catch (error) {
    if (error.isUnauthorized) {
      await ref.read(authControllerProvider).forceLogout();
    }
    rethrow;
  }
});

class CalculatorController extends ChangeNotifier {
  static const presetMultipliers = <num>[1.5, 1.6, 1.7];

  final Map<String, CalculatorLine> _lines = {};
  num multiplier = presetMultipliers.first;
  num shipping = 0;
  ShippingMode shippingMode = ShippingMode.separate;

  bool get isEmpty => _lines.isEmpty;

  int get totalQuantity =>
      _lines.values.fold<int>(0, (sum, l) => sum + l.quantity);

  bool hasProduct(int productId) =>
      _lines.values.any((l) => l.productId == productId);

  int quantityOf(int productId, int moduleIndex) =>
      _lines[CalculatorLine.lineKey(productId, moduleIndex)]?.quantity ?? 0;

  /// Products in the order they were first added, lines in module order.
  List<CalculatorGroup> get groups {
    final byProduct = <int, List<CalculatorLine>>{};
    for (final line in _lines.values) {
      byProduct.putIfAbsent(line.productId, () => []).add(line);
    }
    return byProduct.values.map((lines) {
      lines.sort((a, b) => a.moduleIndex.compareTo(b.moduleIndex));
      final first = lines.first;
      return CalculatorGroup(
        productId: first.productId,
        productName: first.productName,
        productCode: first.productCode,
        supplierName: first.supplierName,
        lines: lines,
      );
    }).toList();
  }

  CalculatorGroup? groupOf(int productId) {
    for (final group in groups) {
      if (group.productId == productId) return group;
    }
    return null;
  }

  CalculatorTotals get totals {
    num listTotal = 0;
    num costTotal = 0;
    for (final line in _lines.values) {
      listTotal += line.listTotal;
      costTotal += line.netTotal;
    }
    return CalculatorTotals(
      listTotal: listTotal,
      costTotal: costTotal,
      shipping: shipping,
      multiplier: multiplier,
      mode: shippingMode,
    );
  }

  void setModuleQuantity(ProductDetail product, int moduleIndex, int quantity) {
    if (moduleIndex < 0 || moduleIndex >= product.modules.length) return;
    final key = CalculatorLine.lineKey(product.id, moduleIndex);
    if (quantity <= 0) {
      _lines.remove(key);
    } else {
      _lines[key] = _lines[key]?.copyWith(quantity: quantity) ??
          CalculatorLine.fromModule(product, moduleIndex, quantity);
    }
    notifyListeners();
  }

  void setLineQuantity(String key, int quantity) {
    final line = _lines[key];
    if (line == null) return;
    if (quantity <= 0) {
      _lines.remove(key);
    } else {
      _lines[key] = line.copyWith(quantity: quantity);
    }
    notifyListeners();
  }

  /// Adds the modules that have a standard quantity on the product.
  void addStandardSet(ProductDetail product) {
    for (var i = 0; i < product.modules.length; i++) {
      final quantity = product.modules[i].quantity ?? 0;
      if (quantity <= 0) continue;
      final key = CalculatorLine.lineKey(product.id, i);
      _lines[key] = _lines[key]?.copyWith(quantity: quantity) ??
          CalculatorLine.fromModule(product, i, quantity);
    }
    notifyListeners();
  }

  void removeProduct(int productId) {
    _lines.removeWhere((_, line) => line.productId == productId);
    notifyListeners();
  }

  /// Clears the selection and shipping; multiplier and mode are kept since
  /// they are usually reused for the next quote.
  void clear() {
    _lines.clear();
    shipping = 0;
    notifyListeners();
  }

  void setMultiplier(num value) {
    if (value <= 0 || value == multiplier) return;
    multiplier = value;
    notifyListeners();
  }

  void setShipping(num value) {
    final next = value < 0 ? 0 : value;
    if (next == shipping) return;
    shipping = next;
    notifyListeners();
  }

  void setShippingMode(ShippingMode mode) {
    if (mode == shippingMode) return;
    shippingMode = mode;
    notifyListeners();
  }
}
