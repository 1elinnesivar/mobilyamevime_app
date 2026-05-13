import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/product_image_view.dart';
import '../models/product_detail.dart';
import '../providers/products_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(productId));
    final col = context.col;

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: col.border),
        ),
      ),
      body: detail.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorStateView(
          message: 'Ürün detayı yüklenemedi.',
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (product) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _ProductHero(product: product),
            const SizedBox(height: 12),
            _PriceSection(product: product),
            const SizedBox(height: 12),
            _SupplierCard(product: product),
            const SizedBox(height: 12),
            _DescriptionCard(product: product),
            const SizedBox(height: 20),
            if (product.modules.isNotEmpty) ...[
              const _SectionHeader(label: 'ÜRÜN MODÜLLERİ'),
              const SizedBox(height: 10),
              ...product.modules
                  .map((module) => _ModuleCard(module: module)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
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
            color: context.col.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ProductHero extends StatelessWidget {
  const _ProductHero({required this.product});
  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final images = product.images.isNotEmpty
        ? product.images
        : product.image == null || product.image!.isEmpty
            ? <String>[]
            : [product.image!];
    final isActive = product.status.toLowerCase() == 'active';

    return Container(
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 240,
            child: images.isEmpty
                ? const ProductImageView(
                    imageUrl: null, width: double.infinity, height: 240)
                : PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) => ProductImageView(
                      imageUrl: images[index],
                      width: double.infinity,
                      height: 240,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          color: col.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.success.withValues(alpha: 0.14)
                            : col.textMuted.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isActive
                              ? AppTheme.success.withValues(alpha: 0.3)
                              : col.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        isActive ? 'Aktif' : 'Pasif',
                        style: TextStyle(
                          color: isActive
                              ? AppTheme.success
                              : col.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  product.code,
                  style: TextStyle(
                    color: col.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSection extends StatelessWidget {
  const _PriceSection({required this.product});
  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PriceBox(
                  label: 'Satış Fiyatı',
                  value: CurrencyFormatter.format(product.salePrice),
                  highlighted: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PriceBox(
                  label: 'Net Alış',
                  value: CurrencyFormatter.format(product.purchasePrice),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: col.border),
          const SizedBox(height: 14),
          _InfoRow(label: 'Kategori', value: product.categoryName ?? '-'),
          _InfoRow(
            label: 'Tedarikçi İskontosu',
            value: _discountText(product.supplierDiscountRate),
          ),
          _InfoRow(label: 'Stok', value: product.stock.toString()),
        ],
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  const _PriceBox({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.gold.withValues(alpha: 0.12)
            : col.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted
              ? AppTheme.gold.withValues(alpha: 0.3)
              : col.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlighted ? AppTheme.gold : col.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: highlighted ? AppTheme.gold : col.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.product});
  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return GestureDetector(
      onTap: product.supplierId == null
          ? null
          : () => context.push('/suppliers/${product.supplierId}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: col.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: col.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF818CF8).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.store_rounded,
                  color: Color(0xFF818CF8), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tedarikçi',
                      style: TextStyle(
                          color: col.textSecondary, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    product.supplierName ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: col.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (product.supplierId != null)
              Icon(Icons.chevron_right_rounded, color: col.textMuted),
          ],
        ),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.product});
  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final desc = (product.description ?? '').isEmpty
        ? 'Açıklama bulunmuyor.'
        : product.description!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Açıklama',
              style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(desc,
              style: TextStyle(
                  color: col.textSecondary, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: TextStyle(
                    color: col.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});
  final ProductModule module;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final selected = (module.quantity ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppTheme.gold.withValues(alpha: 0.3)
              : col.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  module.name ?? 'Modül #${module.moduleId}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.gold.withValues(alpha: 0.14)
                      : col.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? AppTheme.gold.withValues(alpha: 0.3)
                        : col.border,
                  ),
                ),
                child: Text(
                  selected ? 'Seçili' : 'Opsiyonel',
                  style: TextStyle(
                    color: selected ? AppTheme.gold : col.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPrice(
                  label: 'Satış',
                  value: CurrencyFormatter.format(module.salePrice)),
              _MiniPrice(
                  label: 'Alış',
                  value: CurrencyFormatter.format(module.purchasePrice)),
              _MiniPrice(
                label: 'İskontolu',
                value: (module.discountRate ?? 0) > 0
                    ? CurrencyFormatter.format(
                        module.discountedPurchasePrice)
                    : 'İskonto yok',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: col.border),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(
                  label: 'Adet',
                  value: module.quantity?.toString() ?? '-'),
              const SizedBox(width: 8),
              _InfoChip(label: 'Ölçü', value: _measurement(module)),
            ],
          ),
        ],
      ),
    );
  }

  String _measurement(ProductModule module) {
    final size = [module.width, module.height]
        .where((v) => v != null && v.isNotEmpty)
        .join(' / ');
    if ((module.depth ?? '').isEmpty) return size.isEmpty ? '-' : size;
    return size.isEmpty ? module.depth! : '$size / ${module.depth}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col.border),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: TextStyle(
                  color: col.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPrice extends StatelessWidget {
  const _MiniPrice({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: col.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: col.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

String _discountText(num? value) {
  if (value == null || value == 0) return 'İskonto yok';
  return '%$value';
}
