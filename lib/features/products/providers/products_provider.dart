import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/products_repository.dart';
import '../models/product.dart';
import '../models/product_detail.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepository(ref.watch(apiClientProvider));
});

final productDetailProvider =
    FutureProvider.autoDispose.family<ProductDetail, int>((ref, id) {
  return _loadDetail(ref, id);
});

Future<ProductDetail> _loadDetail(Ref ref, int id) async {
  try {
    return await ref.watch(productsRepositoryProvider).detail(id);
  } on ApiException catch (error) {
    if (error.isUnauthorized) {
      await ref.read(authControllerProvider).forceLogout();
    }
    rethrow;
  }
}

final productsControllerProvider =
    ChangeNotifierProvider.autoDispose<ProductsController>((ref) {
  return ProductsController(
    repository: ref.watch(productsRepositoryProvider),
    onUnauthorized: () => ref.read(authControllerProvider).forceLogout(),
  )..loadFirstPage();
});

class ProductsController extends ChangeNotifier {
  ProductsController({
    required ProductsRepository repository,
    required Future<void> Function() onUnauthorized,
  })  : _repository = repository,
        _onUnauthorized = onUnauthorized;

  final ProductsRepository _repository;
  final Future<void> Function() _onUnauthorized;

  final List<Product> items = [];
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
      errorMessage = 'Urunler yuklenemedi.';
    }
  }
}
