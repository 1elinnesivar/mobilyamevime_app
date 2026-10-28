import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/product_image_view.dart';
import '../../products/models/product.dart';
import '../models/calculator_line.dart';
import '../providers/calculator_provider.dart';
import '../widgets/module_picker_sheet.dart';
import '../widgets/quantity_stepper.dart';

final _amountFormat = NumberFormat('#,##0', 'tr_TR');
final _multiplierFormat = NumberFormat('0.##', 'tr_TR');

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _searchController = TextEditingController();
  final _shippingController = TextEditingController();
  final _multiplierController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _customMultiplier = false;

  @override
  void initState() {
    super.initState();
    // Calculator state outlives this screen; restore the inputs from it.
    final calc = ref.read(calculatorControllerProvider);
    if (calc.shipping > 0) {
      _shippingController.text = _amountFormat.format(calc.shipping);
    }
    _customMultiplier =
        !CalculatorController.presetMultipliers.contains(calc.multiplier);
    if (_customMultiplier) {
      _multiplierController.text = _multiplierFormat.format(calc.multiplier);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _shippingController.dispose();
    _multiplierController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  Future<void> _openPicker(int productId) async {
    FocusScope.of(context).unfocus();
    await showModulePickerSheet(context, productId);
    if (!mounted) return;
    // Show the calculator once something from this product was selected.
    if (_query.isNotEmpty &&
        ref.read(calculatorControllerProvider).hasProduct(productId)) {
      _clearSearch();
    }
  }

  void _selectPreset(num value) {
    setState(() => _customMultiplier = false);
    ref.read(calculatorControllerProvider).setMultiplier(value);
  }

  void _selectCustom() {
    final calc = ref.read(calculatorControllerProvider);
    setState(() {
      _customMultiplier = true;
      _multiplierController.text = _multiplierFormat.format(calc.multiplier);
    });
  }

  void _onMultiplierChanged(String value) {
    final parsed = parseLocalizedNumber(value, dotIsThousands: false);
    if (parsed != null && parsed > 0) {
      ref.read(calculatorControllerProvider).setMultiplier(parsed);
    }
  }

  void _onShippingChanged(String value) {
    ref
        .read(calculatorControllerProvider)
        .setShipping(parseLocalizedNumber(value) ?? 0);
  }

  void _confirmClear() {
    final col = context.col;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: col.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: col.border),
        ),
        title: Text(
          'Hesabı Temizle',
          style:
              TextStyle(color: col.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Seçilen tüm ürünler ve nakliye tutarı silinecek.',
          style: TextStyle(color: col.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                Text('Vazgeç', style: TextStyle(color: col.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: col.errorColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(calculatorControllerProvider).clear();
              _shippingController.clear();
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calc = ref.watch(calculatorControllerProvider);
    final col = context.col;

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        title: const Text('Maliyet Hesapla'),
        actions: [
          if (!calc.isEmpty)
            IconButton(
              tooltip: 'Temizle',
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
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
                hintText: 'Ürün adı veya kod ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear_rounded),
                ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (value) {
                _debounce?.cancel();
                setState(() => _query = value.trim());
              },
            ),
          ),
          Expanded(
            child: _query.isNotEmpty
                ? _SearchResults(query: _query, onSelect: _openPicker)
                : calc.isEmpty
                    ? const EmptyStateView(
                        message:
                            'Ürün arayıp modüllerini seçin.\nSeçtikleriniz burada hesaplanır.',
                        icon: Icons.calculate_outlined,
                      )
                    : ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [
                          _SectionHeader(
                            label: 'SEÇİLEN ÜRÜNLER',
                            trailing: '${calc.totalQuantity} modül',
                          ),
                          const SizedBox(height: 10),
                          ...calc.groups.map(
                            (group) => _GroupCard(
                              group: group,
                              onEdit: () => _openPicker(group.productId),
                              onRemove: () => ref
                                  .read(calculatorControllerProvider)
                                  .removeProduct(group.productId),
                              onQuantityChanged: (line, value) => ref
                                  .read(calculatorControllerProvider)
                                  .setLineQuantity(line.key, value),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const _SectionHeader(label: 'HESAPLAMA'),
                          const SizedBox(height: 10),
                          _PricingCard(
                            calc: calc,
                            customMultiplier: _customMultiplier,
                            multiplierController: _multiplierController,
                            shippingController: _shippingController,
                            onPreset: _selectPreset,
                            onCustom: _selectCustom,
                            onMultiplierChanged: _onMultiplierChanged,
                            onShippingChanged: _onShippingChanged,
                          ),
                          const SizedBox(height: 12),
                          _ResultCard(totals: calc.totals),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.trailing});
  final String label;
  final String? trailing;

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
        if (trailing != null) ...[
          const Spacer(),
          Text(trailing!,
              style: TextStyle(color: col.textSecondary, fontSize: 12)),
        ],
      ],
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.onSelect});

  final String query;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(calculatorSearchProvider(query));
    final calc = ref.watch(calculatorControllerProvider);

    return results.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => ErrorStateView(
        message: 'Ürünler yüklenemedi.',
        onRetry: () => ref.invalidate(calculatorSearchProvider(query)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyStateView(
            message: 'Ürün bulunamadı.',
            icon: Icons.inventory_2_outlined,
          );
        }
        return ListView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final product = items[index];
            return _SearchResultTile(
              product: product,
              added: calc.hasProduct(product.id),
              onTap: () => onSelect(product.id),
            );
          },
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.product,
    required this.added,
    required this.onTap,
  });

  final Product product;
  final bool added;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: added ? AppTheme.gold.withValues(alpha: 0.45) : col.border,
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
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ProductImageView(
                    imageUrl: product.image, width: 52, height: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.3,
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
                const SizedBox(width: 8),
                Icon(
                  added
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  color: added ? AppTheme.gold : col.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _listColumnWidth = 74.0;
const _netColumnWidth = 78.0;

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.onEdit,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  final CalculatorGroup group;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final void Function(CalculatorLine line, int value) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final headerStyle = TextStyle(
      color: col.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: col.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [group.productCode, group.supplierName]
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
                IconButton(
                  tooltip: 'Modülleri düzenle',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Ürünü kaldır',
                  onPressed: onRemove,
                  icon: Icon(Icons.close_rounded,
                      size: 20, color: col.errorColor),
                ),
              ],
            ),
          ),
          Container(height: 1, color: col.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(
              children: [
                Expanded(child: Text('MODÜL', style: headerStyle)),
                SizedBox(
                  width: _listColumnWidth,
                  child: Text('LİSTE',
                      textAlign: TextAlign.right, style: headerStyle),
                ),
                SizedBox(
                  width: _netColumnWidth,
                  child: Text('ALIŞ',
                      textAlign: TextAlign.right, style: headerStyle),
                ),
              ],
            ),
          ),
          ...group.lines.map(
            (line) => _LineRow(
              line: line,
              onChanged: (value) => onQuantityChanged(line, value),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: col.surface,
              border: Border(top: BorderSide(color: col.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ara toplam',
                    style: TextStyle(
                      color: col.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _AmountCell(
                  width: _listColumnWidth,
                  value: group.listTotal,
                  color: col.textSecondary,
                ),
                _AmountCell(
                  width: _netColumnWidth,
                  value: group.netTotal,
                  color: col.textPrimary,
                  bold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.onChanged});

  final CalculatorLine line;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.moduleName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    QuantityStepper(value: line.quantity, onChanged: onChanged),
                    if (line.quantity > 1) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Birim ${CurrencyFormatter.format(line.netPrice)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: col.textSecondary, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _AmountCell(
            width: _listColumnWidth,
            value: line.listTotal,
            color: col.textSecondary,
          ),
          _AmountCell(
            width: _netColumnWidth,
            value: line.netTotal,
            color: col.textPrimary,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _AmountCell extends StatelessWidget {
  const _AmountCell({
    required this.width,
    required this.value,
    required this.color,
    this.bold = false,
  });

  final double width;
  final num value;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          CurrencyFormatter.format(value),
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.calc,
    required this.customMultiplier,
    required this.multiplierController,
    required this.shippingController,
    required this.onPreset,
    required this.onCustom,
    required this.onMultiplierChanged,
    required this.onShippingChanged,
  });

  final CalculatorController calc;
  final bool customMultiplier;
  final TextEditingController multiplierController;
  final TextEditingController shippingController;
  final ValueChanged<num> onPreset;
  final VoidCallback onCustom;
  final ValueChanged<String> onMultiplierChanged;
  final ValueChanged<String> onShippingChanged;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final totals = calc.totals;
    final labelStyle = TextStyle(
      color: col.textPrimary,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(label: 'Toplam Liste', value: totals.listTotal),
          _SummaryRow(
            label: 'Toplam Alış (Maliyet)',
            value: totals.costTotal,
            highlighted: true,
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: col.border),
          const SizedBox(height: 14),
          Text('Çarpan', style: labelStyle),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final preset in CalculatorController.presetMultipliers) ...[
                Expanded(
                  child: _OptionBox(
                    label: '×${_multiplierFormat.format(preset)}',
                    selected: !customMultiplier && calc.multiplier == preset,
                    onTap: () => onPreset(preset),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _OptionBox(
                  label: 'Özel',
                  selected: customMultiplier,
                  onTap: onCustom,
                ),
              ),
            ],
          ),
          if (customMultiplier) ...[
            const SizedBox(height: 10),
            TextField(
              controller: multiplierController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: TextStyle(color: col.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Özel çarpan',
                hintText: 'örn. 1,65',
                prefixText: '× ',
              ),
              onChanged: onMultiplierChanged,
            ),
          ],
          const SizedBox(height: 16),
          Text('Nakliye', style: labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: shippingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: TextStyle(color: col.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Nakliye tutarı (opsiyonel)',
              prefixIcon: Icon(Icons.local_shipping_outlined),
              suffixText: '₺',
            ),
            onChanged: onShippingChanged,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _OptionBox(
                  label: 'Maliyete dahil',
                  caption: '(Maliyet + Nakliye) × Çarpan',
                  selected: calc.shippingMode == ShippingMode.included,
                  onTap: () => calc.setShippingMode(ShippingMode.included),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OptionBox(
                  label: 'Ayrı ekle',
                  caption: 'Maliyet × Çarpan + Nakliye',
                  selected: calc.shippingMode == ShippingMode.separate,
                  onTap: () => calc.setShippingMode(ShippingMode.separate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final num value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: highlighted ? col.textPrimary : col.textSecondary,
                fontSize: 13,
                fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            CurrencyFormatter.format(value),
            style: TextStyle(
              color: highlighted ? col.textPrimary : col.textSecondary,
              fontSize: highlighted ? 16 : 13,
              fontWeight: highlighted ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionBox extends StatelessWidget {
  const _OptionBox({
    required this.label,
    required this.selected,
    required this.onTap,
    this.caption,
  });

  final String label;
  final String? caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.gold.withValues(alpha: 0.14)
                : col.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppTheme.gold.withValues(alpha: 0.5)
                  : col.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppTheme.gold : col.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 3),
                Text(
                  caption!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: col.textSecondary, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.totals});

  final CalculatorTotals totals;

  String get _formula {
    final cost = _amountFormat.format(totals.costTotal);
    final multiplier = _multiplierFormat.format(totals.multiplier);
    if (totals.shipping <= 0) return '$cost × $multiplier';
    final shipping = _amountFormat.format(totals.shipping);
    return totals.mode == ShippingMode.included
        ? '($cost + $shipping) × $multiplier'
        : '$cost × $multiplier + $shipping';
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SATIŞ FİYATI',
            style: TextStyle(
              color: AppTheme.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(totals.salePrice),
              style: const TextStyle(
                color: AppTheme.gold,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formula,
            style: TextStyle(
              color: col.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppTheme.gold.withValues(alpha: 0.25)),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Maliyet', value: totals.costTotal),
          if (totals.shipping > 0)
            _SummaryRow(label: 'Nakliye', value: totals.shipping),
          _SummaryRow(label: 'Kâr', value: totals.profit, highlighted: true),
        ],
      ),
    );
  }
}
