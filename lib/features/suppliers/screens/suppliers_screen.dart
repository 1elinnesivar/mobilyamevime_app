import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../providers/suppliers_provider.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
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
      ref.read(suppliersControllerProvider).loadFirstPage(query: value.trim());
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 320) {
      ref.read(suppliersControllerProvider).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(suppliersControllerProvider);
    final col = context.col;

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        title: const Text('Tedarikçiler'),
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
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: col.textPrimary),
              decoration: InputDecoration(
                hintText: 'Firma ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _debounce?.cancel();
                    ref
                        .read(suppliersControllerProvider)
                        .loadFirstPage(query: '');
                  },
                  icon: const Icon(Icons.clear_rounded),
                ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                ref
                    .read(suppliersControllerProvider)
                    .loadFirstPage(query: value.trim());
              },
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
                        .read(suppliersControllerProvider)
                        .loadFirstPage(),
                  );
                }
                if (controller.items.isEmpty) {
                  return const EmptyStateView(
                    message: 'Tedarikçi bulunamadı.',
                    icon: Icons.store_outlined,
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.gold,
                  backgroundColor: col.card,
                  onRefresh: () =>
                      ref.read(suppliersControllerProvider).loadFirstPage(),
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
                      final supplier = controller.items[index];
                      return _SupplierTile(
                        name: supplier.name,
                        phone: supplier.phone,
                        email: supplier.email,
                        balance:
                            CurrencyFormatter.format(supplier.balance),
                        onTap: () =>
                            context.push('/suppliers/${supplier.id}'),
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

class _SupplierTile extends StatelessWidget {
  const _SupplierTile({
    required this.name,
    required this.balance,
    required this.onTap,
    this.phone,
    this.email,
  });

  final String name;
  final String? phone;
  final String? email;
  final String balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final subtitle = [
      if ((phone ?? '').isNotEmpty) phone,
      if ((email ?? '').isNotEmpty) email,
    ].whereType<String>().join('  ·  ');

    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: AppTheme.gold.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFF818CF8).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF818CF8)
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: col.textSecondary, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      balance,
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: col.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
