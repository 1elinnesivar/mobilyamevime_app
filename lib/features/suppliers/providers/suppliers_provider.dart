import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/suppliers_repository.dart';
import '../models/supplier.dart';

final suppliersRepositoryProvider = Provider<SuppliersRepository>((ref) {
  return SuppliersRepository(ref.watch(apiClientProvider));
});

final suppliersControllerProvider =
    ChangeNotifierProvider.autoDispose<SuppliersController>((ref) {
  return SuppliersController(
    repository: ref.watch(suppliersRepositoryProvider),
    onUnauthorized: () => ref.read(authControllerProvider).forceLogout(),
  )..loadFirstPage();
});

final supplierDetailProvider =
    FutureProvider.autoDispose.family<SupplierDetail, int>((ref, id) {
  return _loadDetail(ref, id);
});

Future<SupplierDetail> _loadDetail(Ref ref, int id) async {
  try {
    return await ref.watch(suppliersRepositoryProvider).detail(id);
  } on ApiException catch (error) {
    if (error.isUnauthorized) {
      await ref.read(authControllerProvider).forceLogout();
    }
    rethrow;
  }
}

class SuppliersController extends ChangeNotifier {
  SuppliersController({
    required SuppliersRepository repository,
    required Future<void> Function() onUnauthorized,
  })  : _repository = repository,
        _onUnauthorized = onUnauthorized;

  final SuppliersRepository _repository;
  final Future<void> Function() _onUnauthorized;

  final List<Supplier> items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? errorMessage;
  String search = '';
  int _page = 1;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  Future<void> loadFirstPage({String? query}) async {
    search = query ?? search;
    _page = 1;
    _hasMore = true;
    items.clear();
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    await _load();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !_hasMore) {
      return;
    }
    isLoadingMore = true;
    notifyListeners();
    await _load();
    isLoadingMore = false;
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      final result = await _repository.list(page: _page, search: search);
      items.addAll(result.items);
      _hasMore = result.hasMore;
      _page = result.page + 1;
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _onUnauthorized();
      }
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Tedarikciler yuklenemedi.';
    }
  }
}
