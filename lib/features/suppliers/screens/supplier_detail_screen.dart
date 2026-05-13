import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../models/supplier.dart';
import '../providers/suppliers_provider.dart';

class SupplierDetailScreen extends ConsumerWidget {
  const SupplierDetailScreen({required this.supplierId, super.key});
  final int supplierId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(supplierDetailProvider(supplierId));
    final col = context.col;

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        title: const Text('Tedarikçi Detayı'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: col.border),
        ),
      ),
      body: detail.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorStateView(
          message: 'Tedarikçi detayı yüklenemedi.',
          onRetry: () =>
              ref.invalidate(supplierDetailProvider(supplierId)),
        ),
        data: (supplier) => DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: col.surface,
                child: const TabBar(
                  tabs: [
                    Tab(text: 'Genel Bilgiler'),
                    Tab(text: 'Fiyat Listeleri'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _GeneralInfoTab(supplier: supplier),
                    _PriceListsTab(supplier: supplier),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GeneralInfoTab extends StatelessWidget {
  const _GeneralInfoTab({required this.supplier});
  final SupplierDetail supplier;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _CompanyHeader(supplier: supplier),
        const SizedBox(height: 12),
        _ContactCard(supplier: supplier, col: col),
        const SizedBox(height: 12),
        _DiscountCard(supplier: supplier),
        const SizedBox(height: 12),
        _NoteCard(supplier: supplier),
      ],
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({required this.supplier});
  final SupplierDetail supplier;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = supplier.companyName.isNotEmpty
        ? supplier.companyName
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0])
            .join()
            .toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(18),
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
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF818CF8).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF818CF8).withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplier.companyName,
                  style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if ((supplier.companyCode ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    supplier.companyCode!,
                    style: TextStyle(
                        color: col.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.supplier, required this.col});
  final SupplierDetail supplier;
  final AppColors col;

  @override
  Widget build(BuildContext context) {
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
          Text('İletişim Bilgileri',
              style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _InfoRow('Firma Yetkilisi', supplier.authorizedPerson, col),
          _ActionRow(
            label: 'Telefon',
            value: supplier.phone,
            icon: Icons.phone_rounded,
            col: col,
            onTap: supplier.phone == null
                ? null
                : () => _launchUri(context, 'tel:${supplier.phone}'),
          ),
          _ActionRow(
            label: 'E-posta',
            value: supplier.email,
            icon: Icons.mail_rounded,
            col: col,
            onTap: supplier.email == null
                ? null
                : () => _launchUri(context, 'mailto:${supplier.email}'),
          ),
          _InfoRow('Son Fiyat Liste Tarihi', supplier.priceListDate, col),
        ],
      ),
    );
  }
}

class _DiscountCard extends StatelessWidget {
  const _DiscountCard({required this.supplier});
  final SupplierDetail supplier;

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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.percent_rounded,
                color: AppTheme.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tedarikçi İskontosu',
                    style: TextStyle(
                        color: col.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  _discountText(supplier.discountRate),
                  style: TextStyle(
                    color: col.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
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

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.supplier});
  final SupplierDetail supplier;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final hasNote = (supplier.note ?? '').isNotEmpty;
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
          Text('Not',
              style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            hasNote ? supplier.note! : 'Not bulunmuyor.',
            style: TextStyle(
                color: col.textSecondary, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, this.col);
  final String label;
  final String? value;
  final AppColors col;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Text(
              (value ?? '').isEmpty ? '-' : value!,
              style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.col,
    required this.onTap,
  });
  final String label;
  final String? value;
  final IconData icon;
  final AppColors col;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = (value ?? '').isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
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
              child: Text(
                hasValue ? value! : '-',
                style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ),
            if (hasValue && onTap != null)
              Icon(icon, size: 16, color: AppTheme.gold),
          ],
        ),
      ),
    );
  }
}

class _PriceListsTab extends StatelessWidget {
  const _PriceListsTab({required this.supplier});
  final SupplierDetail supplier;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final current = supplier.currentPriceList;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _CurrentPriceListCard(current: current),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                  color: AppTheme.gold,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text(
              'TÜM FİYAT LİSTELERİ',
              style: TextStyle(
                color: col.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (supplier.priceLists.isEmpty)
          const EmptyStateView(
            message: 'Fiyat listesi bulunamadı.',
            icon: Icons.description_outlined,
          )
        else
          ...supplier.priceLists.map((file) => _PriceListCard(file: file)),
      ],
    );
  }
}

class _CurrentPriceListCard extends StatelessWidget {
  const _CurrentPriceListCard({required this.current});
  final SupplierCurrentPriceList current;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: current.exists
              ? AppTheme.gold.withValues(alpha: 0.3)
              : col.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: current.exists
                  ? AppTheme.gold.withValues(alpha: 0.14)
                  : col.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.description_rounded,
              color: current.exists ? AppTheme.gold : col.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current.fileName ?? 'Güncel fiyat listesi yok',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: col.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  current.exists
                      ? 'Güncel fiyat listesi'
                      : 'Fiyat listesi bulunamadı',
                  style: TextStyle(
                    color: current.exists ? AppTheme.gold : col.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (current.exists && current.url != null)
            IconButton(
              onPressed: () => _launchUrl(context, current.url),
              icon: const Icon(Icons.open_in_new_rounded,
                  color: AppTheme.gold, size: 20),
            ),
        ],
      ),
    );
  }
}

class _PriceListCard extends StatelessWidget {
  const _PriceListCard({required this.file});
  final SupplierPriceListFile file;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: file.isCurrent
              ? AppTheme.gold.withValues(alpha: 0.3)
              : col.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: file.url == null
              ? () => _showMissing(context)
              : () => _launchUrl(context, file.url),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: file.isCurrent
                        ? AppTheme.gold.withValues(alpha: 0.14)
                        : col.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.file_present_rounded,
                    color: file.isCurrent ? AppTheme.gold : col.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(file.fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: col.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(
                        [
                          _formatSize(file.size),
                          if ((file.modifiedAt ?? '').isNotEmpty)
                            file.modifiedAt,
                        ].whereType<String>().join(' · '),
                        style: TextStyle(
                            color: col.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (file.isCurrent) _GuncelBadge(),
                    IconButton(
                      onPressed: file.url == null
                          ? () => _showMissing(context)
                          : () => _launchUrl(context, file.url),
                      icon: Icon(Icons.open_in_new_rounded,
                          size: 18, color: col.textSecondary),
                    ),
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

class _GuncelBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'Güncel',
        style: TextStyle(
            color: AppTheme.gold, fontWeight: FontWeight.w700, fontSize: 10),
      ),
    );
  }
}

String _discountText(num? value) {
  if (value == null || value == 0) return 'İskonto yok';
  return '%$value';
}

String _formatSize(int bytes) {
  if (bytes <= 0) return '-';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

Future<void> _launchUrl(BuildContext context, String? url) async {
  if (url == null || url.isEmpty) {
    _showMissing(context);
    return;
  }
  await _launchUri(context, url);
}

Future<void> _launchUri(BuildContext context, String uri) async {
  final parsed = Uri.tryParse(uri);
  if (parsed == null ||
      !await launchUrl(parsed, mode: LaunchMode.externalApplication)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bağlantı açılamadı.')),
      );
    }
  }
}

void _showMissing(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Fiyat listesi bulunamadı.')),
  );
}
