import '../../../core/api/api_client.dart';
import '../models/supplier.dart';

class PaginatedSuppliers {
  const PaginatedSuppliers({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<Supplier> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

class SuppliersRepository {
  SuppliersRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PaginatedSuppliers> list({
    required int page,
    String search = '',
  }) async {
    final response = await _apiClient.post(
      'suppliers.list',
      payload: {
        'page': page,
        'limit': 20,
        'search': search,
      },
    );

    final itemsRaw = response.data['items'];
    final pagination = response.data['pagination'];

    return PaginatedSuppliers(
      items: itemsRaw is List
          ? itemsRaw.whereType<Map<String, dynamic>>().map(Supplier.fromJson).toList()
          : [],
      page: pagination is Map<String, dynamic>
          ? _int(pagination['page'], page)
          : page,
      totalPages: pagination is Map<String, dynamic>
          ? _int(pagination['total_pages'], page)
          : page,
    );
  }

  Future<SupplierDetail> detail(int id) async {
    final response = await _apiClient.post(
      'suppliers.detail',
      payload: {'id': id},
    );

    final item = response.data['item'];
    if (item is Map<String, dynamic>) {
      return SupplierDetail.fromJson(item);
    }
    throw Exception('Tedarikci detayi okunamadi.');
  }

  static int _int(dynamic value, int fallback) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }
}
