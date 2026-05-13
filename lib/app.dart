import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/products/screens/product_detail_screen.dart';
import 'features/products/screens/products_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/suppliers/screens/supplier_detail_screen.dart';
import 'features/suppliers/screens/suppliers_screen.dart';
import 'shared/widgets/app_shell.dart';
import 'shared/widgets/async_state_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final isLogin = state.matchedLocation == '/login';
      final isSplash = state.matchedLocation == '/splash';
      if (auth.status == AuthStatus.loading) {
        return isSplash ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        return isLogin ? null : '/login';
      }
      if (isLogin || isSplash) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => const ProductsScreen(),
          ),
          GoRoute(
            path: '/suppliers',
            builder: (context, state) => const SuppliersScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) {
          final id =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/suppliers/:id',
        builder: (context, state) {
          final id =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return SupplierDetailScreen(supplierId: id);
        },
      ),
    ],
  );
});

class MobilyamevimeApp extends ConsumerWidget {
  const MobilyamevimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Mobilyamevime Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.chair_alt_rounded, size: 64, color: AppTheme.gold),
            ),
            const SizedBox(height: 28),
            const LoadingView(),
          ],
        ),
      ),
    );
  }
}
