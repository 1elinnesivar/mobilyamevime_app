import '../../../core/api/api_client.dart';
import '../models/product.dart';
import '../models/product_detail.dart';

class PaginatedProducts {
  const PaginatedProducts({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<Product> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

class ProductsRepository {
  ProductsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedProducts> list({
    required int page,
    String search = '',
  }) async {
    final response = await _apiClient.post(
      'products.list',
      payload: {
        'page': page,
        'limit': 20,
        'search': search,
        'category_id': null,
        'supplier_id': null,
        'status': '',
      },
    );

    final itemsRaw = response.data['items'];
    final pagination = response.data['pagination'];

    return PaginatedProducts(
      items: itemsRaw is List
          ? itemsRaw.whereType<Map<String, dynamic>>().map(Product.fromJson).toList()
          : [],
      page: pagination is Map<String, dynamic>
          ? _int(pagination['page'], page)
          : page,
      totalPages: pagination is Map<String, dynamic>
          ? _int(pagination['total_pages'], page)
          : page,
    );
  }

  Future<ProductDetail> detail(int id) async {
    final response = await _apiClient.post(
      'products.detail',
      payload: {'id': id},
    );

    final item = response.data['item'];
    if (item is Map<String, dynamic>) {
      return ProductDetail.fromJson(item);
    }
    throw Exception('Urun detayi okunamadi.');
  }

  static int _int(dynamic value, int fallback) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }
}
