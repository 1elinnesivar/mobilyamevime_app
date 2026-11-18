import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../models/product_label.dart';
import '../providers/labels_provider.dart';
import '../widgets/label_requests_tab.dart';
import '../widgets/label_widgets.dart';

const _customColor = Color(0xFF818CF8);

const _sortLabels = {
  LabelSort.newest: 'Etiket tarihi (en yeni)',
  LabelSort.name: 'Ürün adı (A-Z)',
  LabelSort.supplier: 'Firma (A-Z)',
  LabelSort.floor: 'Kat',
};

class LabelsScreen extends ConsumerStatefulWidget {
  const LabelsScreen({
    this.initialFilter = const LabelFilter(),
    this.initialTab = 0,
    super.key,
  });

  final LabelFilter initialFilter;

  /// 0 = Etiketler, 1 = Talepler
  final int initialTab;

  @override
  ConsumerState<LabelsScreen> createState() => _LabelsScreenState();
}

class _LabelsScreenState extends ConsumerState<LabelsScreen>
    with SingleTickerProviderStateMixin {
  late final _searchController =
      TextEditingController(text: widget.initialFilter.query);
  late final _tabController = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 1),
  )..addListener(() => setState(() {}));
  late LabelFilter _filter = widget.initialFilter;

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _update(LabelFilter filter) => setState(() => _filter = filter);

  Future<void> _newRequest() async {
    final created = await context.push<bool>('/label-request');
    if (created == true && mounted) _tabController.animateTo(1);
  }

  Future<void> _onLabelTap(ProductLabel label) async {
    final action = await showLabelActionsSheet(context, label);
    if (action == null || !mounted) return;
    final actions = ref.read(labelActionsProvider);
    switch (action) {
      case LabelAction.floor:
        final List<String> floors;
        try {
          floors = await ref.read(labelFloorsProvider.future);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kat listesi yüklenemedi.')),
            );
          }
          return;
        }
        if (!mounted) return;
        final floor = await showFloorDialog(
          context,
          label: label,
          floors: floors,
        );
        if (floor == null || floor == label.floor || !mounted) return;
        await runLabelAction(
          context,
          () => actions.updateFloor(label.key, floor),
          floor.isEmpty ? 'Kat bilgisi silindi.' : 'Kat bilgisi: $floor',
        );
      case LabelAction.reprint:
        final created = await context.push<bool>(
            '/label-request?label=${Uri.encodeQueryComponent(label.key)}');
        if (created == true && mounted) _tabController.animateTo(1);
      case LabelAction.product:
        context.push('/products/${label.productId}');
      case LabelAction.remove:
        if (!await confirmRemoveLabel(context, label) || !mounted) return;
        await runLabelAction(
          context,
          () => actions.remove(label.key),
          'Etiket listeden kaldırıldı.',
        );
    }
  }

  Future<void> _pickSupplier(List<ProductLabel> labels) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.col.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _SupplierPickerSheet(labels: labels, selected: _filter.supplierId),
    );
    if (picked == null) return;
    _update(_filter.copyWith(supplierId: () => picked == 0 ? null : picked));
  }

  @override
  Widget build(BuildContext context) {
    final labels = ref.watch(labelsProvider);
    final openRequests = ref
            .watch(labelRequestsProvider)
            .valueOrNull
            ?.where((r) => r.isOpen)
            .length ??
        0;
    final col = context.col;

    return Scaffold(
      backgroundColor: col.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newRequest,
        backgroundColor: AppTheme.gold,
        foregroundColor: const Color(0xFF070B18),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Etiket talebi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      appBar: AppBar(
        title: const Text('Ürün Etiketleri'),
        actions: [
          if (_tabController.index == 0)
            PopupMenuButton<LabelSort>(
            tooltip: 'Sırala',
            icon: const Icon(Icons.sort_rounded),
            initialValue: _filter.sort,
            color: col.cardElevated,
            onSelected: (sort) => _update(_filter.copyWith(sort: sort)),
            itemBuilder: (context) => [
              for (final entry in _sortLabels.entries)
                PopupMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: entry.key == _filter.sort
                          ? AppTheme.gold
                          : col.textPrimary,
                      fontWeight: entry.key == _filter.sort
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          dividerColor: col.border,
          tabs: [
            const Tab(text: 'Etiketler'),
            Tab(text: openRequests > 0 ? 'Talepler ($openRequests)' : 'Talepler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          labels.when(
            loading: () => const LoadingView(),
            error: (error, stackTrace) => ErrorStateView(
              message: 'Etiketler yüklenemedi.',
              onRetry: () => ref.invalidate(labelsProvider),
            ),
            data: _buildContent,
          ),
          const LabelRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildContent(List<ProductLabel> all) {
    final col = context.col;
    final visible = _filter.apply(all);

    final floorCounts = <String, int>{};
    var withoutFloor = 0;
    for (final label in all) {
      if (label.hasFloor) {
        floorCounts.update(label.floor, (n) => n + 1, ifAbsent: () => 1);
      } else {
        withoutFloor++;
      }
    }
    final floors = floorCounts.keys.toList()..sort(compareFloors);
    final reprintCount = all.where((l) => l.needsReprint).length;
    final supplierName = _filter.supplierId == null
        ? null
        : all
            .firstWhere((l) => l.supplierId == _filter.supplierId,
                orElse: () => all.first)
            .supplier;

    return Column(
      children: [
        Container(
          color: col.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: col.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ürün, kod, firma veya kat ara...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _filter.query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _update(_filter.copyWith(query: ''));
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
                onChanged: (value) => _update(_filter.copyWith(query: value)),
              ),
              const SizedBox(height: 10),
              _ChipRow(
                children: [
                  _FilterPill(
                    label: 'Tüm katlar',
                    selected: _filter.floor == null,
                    onTap: () => _update(_filter.copyWith(floor: () => null)),
                  ),
                  for (final floor in floors)
                    _FilterPill(
                      icon: Icons.layers_rounded,
                      label: floor,
                      count: floorCounts[floor],
                      selected: _filter.floor == floor,
                      onTap: () => _update(_filter.copyWith(
                          floor: () => _filter.floor == floor ? null : floor)),
                    ),
                  if (withoutFloor > 0)
                    _FilterPill(
                      icon: Icons.help_outline_rounded,
                      label: 'Kat girilmemiş',
                      count: withoutFloor,
                      selected: _filter.floor == '',
                      onTap: () => _update(_filter.copyWith(
                          floor: () => _filter.floor == '' ? null : '')),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _ChipRow(
                children: [
                  _FilterPill(
                    icon: Icons.store_rounded,
                    label: supplierName ?? 'Tüm firmalar',
                    trailingIcon: Icons.arrow_drop_down_rounded,
                    selected: supplierName != null,
                    onTap: () => _pickSupplier(all),
                  ),
                  if (reprintCount > 0)
                    _FilterPill(
                      icon: Icons.warning_amber_rounded,
                      label: 'Yeniden basılacak',
                      count: reprintCount,
                      color: AppTheme.warning,
                      selected: _filter.onlyReprint,
                      onTap: () => _update(_filter.copyWith(
                          onlyReprint: !_filter.onlyReprint)),
                    ),
                ],
              ),
            ],
          ),
        ),
        Container(height: 1, color: col.border),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.gold,
            backgroundColor: col.card,
            onRefresh: () async {
              ref.invalidate(labelsProvider);
              await ref.read(labelsProvider.future);
            },
            child: visible.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 60),
                      EmptyStateView(
                        message: 'Filtreye uyan etiket bulunamadı.',
                        icon: Icons.sell_outlined,
                      ),
                    ],
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                    itemCount: visible.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _ResultHeader(
                          visible: visible.length,
                          total: all.length,
                          sort: _filter.sort,
                        );
                      }
                      final label = visible[index - 1];
                      return _LabelCard(
                        label: label,
                        onTap: () => _onLabelTap(label),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.trailingIcon,
    this.count,
    this.color = AppTheme.gold,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final IconData? trailingIcon;
  final int? count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final foreground = selected ? color : col.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : col.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.5) : col.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: foreground),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? color : col.textPrimary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (trailingIcon != null)
                Icon(trailingIcon, size: 18, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({
    required this.visible,
    required this.total,
    required this.sort,
  });

  final int visible;
  final int total;
  final LabelSort sort;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
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
            visible == total ? '$total ETİKET' : '$visible / $total ETİKET',
            style: TextStyle(
              color: col.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _sortLabels[sort]!,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: col.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelCard extends StatelessWidget {
  const _LabelCard({required this.label, required this.onTap});

  final ProductLabel label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final printedAt = label.printedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: label.needsReprint
              ? AppTheme.warning.withValues(alpha: 0.5)
              : col.border,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: AppTheme.gold.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: col.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(label: label),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [label.productCode, label.supplier]
                      .where((v) => (v ?? '').isNotEmpty)
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: col.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.layers_rounded,
                        title: 'Kat',
                        value: label.hasFloor ? label.floor : 'Girilmemiş',
                        highlighted: label.hasFloor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.event_rounded,
                        title: printedAt == null
                            ? 'Etiket tarihi'
                            : 'Etiket · ${labelAge(printedAt)}',
                        value: printedAt == null
                            ? '-'
                            : formatLabelDate(printedAt),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Etiketteki fiyat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: col.textSecondary, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(label.printedTotal),
                      style: TextStyle(
                        color: col.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (label.needsReprint && label.currentTotal > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Güncel fiyat ${CurrencyFormatter.format(label.currentTotal)}'
                      ' · etiket yeniden basılmalı',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.gold.withValues(alpha: 0.12) : col.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? AppTheme.gold.withValues(alpha: 0.35) : col.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: highlighted ? AppTheme.gold : col.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: col.textSecondary, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: highlighted ? AppTheme.gold : col.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final ProductLabel label;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final (text, color) = label.isCustom
        ? ('Özel ürün', _customColor)
        : label.needsReprint
            ? ('Yeniden basılacak', AppTheme.warning)
            : !label.isActive
                ? ('Ürün pasif', col.textSecondary)
                : ('Güncel', AppTheme.success);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SupplierPickerSheet extends StatefulWidget {
  const _SupplierPickerSheet({required this.labels, required this.selected});

  final List<ProductLabel> labels;
  final int? selected;

  @override
  State<_SupplierPickerSheet> createState() => _SupplierPickerSheetState();
}

class _SupplierPickerSheetState extends State<_SupplierPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final counts = <int, int>{};
    final names = <int, String>{};
    for (final label in widget.labels) {
      counts.update(label.supplierId, (n) => n + 1, ifAbsent: () => 1);
      names[label.supplierId] = label.supplier;
    }
    final folded = foldTurkish(_query);
    final ids = names.keys
        .where((id) => foldTurkish(names[id]!).contains(folded))
        .toList()
      ..sort((a, b) =>
          turkishSortKey(names[a]!).compareTo(turkishSortKey(names[b]!)));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: TextField(
              style: TextStyle(color: col.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Firma ara...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                if (_query.isEmpty)
                  _SupplierTile(
                    name: 'Tüm firmalar',
                    count: widget.labels.length,
                    selected: widget.selected == null,
                    onTap: () => Navigator.of(context).pop(0),
                  ),
                for (final id in ids)
                  _SupplierTile(
                    name: names[id]!,
                    count: counts[id]!,
                    selected: widget.selected == id,
                    onTap: () => Navigator.of(context).pop(id),
                  ),
              ],
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
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return ListTile(
      onTap: onTap,
      title: Text(
        name,
        style: TextStyle(
          color: selected ? AppTheme.gold : col.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: Text(
        '$count etiket',
        style: TextStyle(color: col.textSecondary, fontSize: 12),
      ),
    );
  }
}
