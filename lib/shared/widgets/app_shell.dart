import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final location = GoRouterState.of(context).matchedLocation;
    final index = switch (location) {
      '/products' => 1,
      '/suppliers' => 2,
      '/settings' => 3,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: col.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) {
            switch (value) {
              case 0:
                context.go('/');
              case 1:
                context.go('/products');
              case 2:
                context.go('/suppliers');
              case 3:
                context.go('/settings');
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Panel',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Ürünler',
            ),
            NavigationDestination(
              icon: Icon(Icons.store_outlined),
              selectedIcon: Icon(Icons.store_rounded),
              label: 'Tedarikçi',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }
}
