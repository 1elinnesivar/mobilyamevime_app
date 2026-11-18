import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/utils/provider_cache.dart';
import '../../auth/providers/auth_provider.dart';
import '../../suppliers/models/supplier.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../data/labels_repository.dart';
import '../models/label_request.dart';
import '../models/product_label.dart';

final labelsRepositoryProvider = Provider<LabelsRepository>((ref) {
  return LabelsRepository(ref.watch(apiClientProvider));
});

final labelsProvider =
    FutureProvider.autoDispose<List<ProductLabel>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  return _guard(ref, () => ref.watch(labelsRepositoryProvider).list());
});

final labelFloorsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  return _guard(ref, () => ref.watch(labelsRepositoryProvider).floors());
});

final labelRequestsProvider =
    FutureProvider.autoDispose<List<LabelRequest>>((ref) async {
  ref.cacheFor(const Duration(minutes: 2));
  return _guard(ref, () => ref.watch(labelsRepositoryProvider).requests());
});

/// Supplier search for requests about products that are not on the website.
final labelSupplierSearchProvider =
    FutureProvider.autoDispose.family<List<Supplier>, String>((ref, query) {
  ref.cacheFor(const Duration(minutes: 2));
  return _guard(ref, () async {
    final result = await ref
        .watch(suppliersRepositoryProvider)
        .list(page: 1, search: query);
    return result.items;
  });
});

final labelActionsProvider = Provider<LabelActions>(LabelActions.new);

/// Write operations; each one refreshes the lists it affects.
class LabelActions {
  LabelActions(this._ref);

  final Ref _ref;

  LabelsRepository get _repository => _ref.read(labelsRepositoryProvider);

  Future<void> updateFloor(String key, String floor) async {
    await _guard(_ref, () => _repository.updateFloor(key, floor));
    _ref.invalidate(labelsProvider);
  }

  Future<void> remove(String key) async {
    await _guard(_ref, () => _repository.remove(key));
    _ref.invalidate(labelsProvider);
  }

  Future<void> createRequest(LabelRequestDraft draft) async {
    await _guard(_ref, () => _repository.createRequest(draft));
    _ref.invalidate(labelRequestsProvider);
  }

  Future<void> updateRequest(int id, LabelRequestStatus status) async {
    await _guard(_ref, () => _repository.updateRequest(id, status));
    _ref.invalidate(labelRequestsProvider);
  }
}

Future<T> _guard<T>(Ref ref, Future<T> Function() run) async {
  try {
    return await run();
  } on ApiException catch (error) {
    if (error.isUnauthorized) {
      await ref.read(authControllerProvider).forceLogout();
    }
    rethrow;
  }
}
