import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../providers/products_provider.dart';
import '../widgets/product_card.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(productsControllerProvider).loadFirstPage(query: value.trim());
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 320) {
      ref.read(productsControllerProvider).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(productsControllerProvider);
    final col = context.col;

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        title: const Text('Ürünler'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: col.border),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: col.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: col.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Ürün adı veya kod ara...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _debounce?.cancel();
                        ref
                            .read(productsControllerProvider)
                            .loadFirstPage(query: '');
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: (value) {
                    _debounce?.cancel();
                    ref
                        .read(productsControllerProvider)
                        .loadFirstPage(query: value.trim());
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.items.isEmpty
                            ? 'Ürün kataloğu'
                            : '${controller.items.length} ürün listeleniyor',
                        style: TextStyle(
                          color: col.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Filtrele'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (controller.isLoading) return const LoadingView();
                if (controller.errorMessage != null &&
                    controller.items.isEmpty) {
                  return ErrorStateView(
                    message: controller.errorMessage!,
                    onRetry: () => ref
                        .read(productsControllerProvider)
                        .loadFirstPage(),
                  );
                }
                if (controller.items.isEmpty) {
                  return const EmptyStateView(
                    message: 'Ürün bulunamadı.',
                    icon: Icons.inventory_2_outlined,
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.gold,
                  backgroundColor: col.card,
                  onRefresh: () =>
                      ref.read(productsControllerProvider).loadFirstPage(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    itemCount: controller.items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == controller.items.length) {
                        return controller.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.gold,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const SizedBox(height: 12);
                      }
                      final product = controller.items[index];
                      return ProductCard(
                        product: product,
                        onTap: () =>
                            context.push('/products/${product.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
