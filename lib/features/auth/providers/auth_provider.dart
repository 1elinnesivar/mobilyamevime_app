import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authControllerProvider = ChangeNotifierProvider<AuthController>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends ChangeNotifier {
  AuthController(this._repository) {
    restoreSession();
  }

  final AuthRepository _repository;

  AuthStatus status = AuthStatus.loading;
  AuthUser? user;
  String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  Future<void> restoreSession() async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();

    final hasToken = await _repository.hasToken();
    if (!hasToken) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      user = await _repository.me();
      status = AuthStatus.authenticated;
    } on ApiException catch (error) {
      errorMessage = error.message;
      await _repository.clearToken();
      status = AuthStatus.unauthenticated;
    } catch (_) {
      errorMessage = 'Oturum kontrol edilemedi.';
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      user = await _repository.login(username: username, password: password);
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Giris yapilamadi. Bilgileri kontrol edin.';
    }

    status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _repository.logout();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> forceLogout() async {
    await _repository.clearToken();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
