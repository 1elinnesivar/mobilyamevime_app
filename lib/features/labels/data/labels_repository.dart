import '../../../core/api/api_client.dart';
import '../models/label_request.dart';
import '../models/product_label.dart';

class LabelsRepository {
  LabelsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<ProductLabel>> list() async {
    final response = await _apiClient.post('labels.list');
    return _items(response.data['items'], ProductLabel.fromJson);
  }

  /// Floor names managed in the panel ("Ürün Etiketleri → Katlar").
  Future<List<String>> floors() async {
    final response = await _apiClient.post('labels.floors');
    final raw = response.data['items'];
    return raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map((f) => (f['name'] ?? '').toString())
            .where((name) => name.isNotEmpty)
            .toList()
        : [];
  }

  Future<void> updateFloor(String key, String floor) async {
    await _apiClient.post(
      'labels.floor',
      payload: {'key': key, 'floor': floor.trim()},
    );
  }

  Future<void> remove(String key) async {
    await _apiClient.post('labels.remove', payload: {'key': key});
  }

  Future<List<LabelRequest>> requests() async {
    final response = await _apiClient.post('labels.requests');
    return _items(response.data['items'], LabelRequest.fromJson);
  }

  Future<void> createRequest(LabelRequestDraft draft) async {
    await _apiClient.post('labels.request.create', payload: draft.toPayload());
  }

  Future<void> updateRequest(int id, LabelRequestStatus status) async {
    await _apiClient.post(
      'labels.request.update',
      payload: {'id': id, 'status': requestStatusPayload(status)},
    );
  }

  static List<T> _items<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return raw is List
        ? raw.whereType<Map<String, dynamic>>().map(fromJson).toList()
        : <T>[];
  }
}
