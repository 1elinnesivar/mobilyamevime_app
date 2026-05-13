import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) {
  return _loadSummary(ref);
});

Future<DashboardSummary> _loadSummary(Ref ref) async {
  try {
    return await ref.watch(dashboardRepositoryProvider).summary();
  } on ApiException catch (error) {
    if (error.isUnauthorized) {
      await ref.read(authControllerProvider).forceLogout();
    }
    rethrow;
  }
}
