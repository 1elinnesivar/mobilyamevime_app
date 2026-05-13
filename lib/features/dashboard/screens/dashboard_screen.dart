import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/product_image_view.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final col = context.col;

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.chair_alt_rounded, color: AppTheme.gold, size: 18),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Panel'),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: col.border),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.gold,
        backgroundColor: col.card,
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          await ref.read(dashboardSummaryProvider.future);
        },
        child: summary.when(
          loading: () => const LoadingView(),
          error: (error, stackTrace) => ErrorStateView(
            message: 'Dashboard yüklenemedi.',
            onRetry: () => ref.invalidate(dashboardSummaryProvider),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              _DashboardHeader(data: data),
              const SizedBox(height: 20),
              _SectionLabel(
                label: 'ÖZET',
                trailing: Text(
                  '${data.totalProducts} toplam ürün',
                  style: TextStyle(
                      color: col.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount =
                      constraints.maxWidth > 700 ? 4 : 2;
                  return GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: 112,
                    ),
                    children: [
                      _MetricCard(
                        label: 'Toplam Ürün',
                        value: data.totalProducts.toString(),
                        icon: Icons.inventory_2_rounded,
                        color: AppTheme.gold,
                      ),
                      _MetricCard(
                        label: 'Aktif Ürün',
                        value: data.activeProducts.toString(),
                        icon: Icons.check_circle_rounded,
                        color: AppTheme.success,
                      ),
                      _MetricCard(
                        label: 'Pasif Ürün',
                        value: data.passiveProducts.toString(),
                        icon: Icons.pause_circle_rounded,
                        color: const Color(0xFF94A3B8),
                      ),
                      _MetricCard(
                        label: 'Tedarikçi',
                        value: data.totalSuppliers.toString(),
                        icon: Icons.store_rounded,
                        color: const Color(0xFF818CF8),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: _SectionLabel(label: 'SON EKLENEN ÜRÜNLER'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/products'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Tümünü gör'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 15),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (data.recentProducts.isEmpty)
                const EmptyStateView(message: 'Son ürün bulunamadı.')
              else
                ...data.recentProducts.map(
                  (product) => _RecentProductTile(
                    product: product,
                    onTap: () =>
                        context.push('/products/${product.id}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.data});
  final dynamic data;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF1A1D33), Color(0xFF0E1220)]
              : [col.card, col.cardElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Çevrimiçi',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Hoş Geldiniz',
                  style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bugünkü genel durum',
                  style: TextStyle(
                    color: col.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.25)),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                  Icons.chair_alt_rounded, color: AppTheme.gold, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: col.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: col.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentProductTile extends StatelessWidget {
  const _RecentProductTile({required this.product, required this.onTap});
  final dynamic product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
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
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ProductImageView(
                      imageUrl: product.image, width: 52, height: 52),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [product.code, product.supplierName]
                            .where((v) => (v ?? '').isNotEmpty)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: col.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(product.salePrice),
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
