import '../../../core/api/api_client.dart';
import '../../products/models/product.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.totalProducts,
    required this.activeProducts,
    required this.passiveProducts,
    required this.totalSuppliers,
    required this.recentProducts,
  });

  final int totalProducts;
  final int activeProducts;
  final int passiveProducts;
  final int totalSuppliers;
  final List<Product> recentProducts;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    List<dynamic> recent = const [];
    if (json['recent_products'] is List) {
      recent = json['recent_products'] as List<dynamic>;
    } else if (json['last_products'] is List) {
      recent = json['last_products'] as List<dynamic>;
    }

    return DashboardSummary(
      totalProducts: _int(json['total_products'] ?? json['product_total']),
      activeProducts: _int(json['active_products']),
      passiveProducts: _int(json['passive_products']),
      totalSuppliers: _int(json['total_suppliers'] ?? json['supplier_total']),
      recentProducts: recent
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(),
    );
  }

  static int _int(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}

class DashboardRepository {
  DashboardRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<DashboardSummary> summary() async {
    final response = await _apiClient.post('dashboard.summary');
    return DashboardSummary.fromJson(response.data);
  }
}
