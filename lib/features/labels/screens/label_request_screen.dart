import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../products/providers/products_provider.dart';
import '../../suppliers/models/supplier.dart';
import '../models/label_request.dart';
import '../providers/labels_provider.dart';
import '../widgets/label_widgets.dart';

class _PickedProduct {
  const _PickedProduct({
    required this.id,
    required this.name,
    required this.code,
    required this.supplierId,
    required this.supplierName,
  });

  final int id;
  final String name;
  final String code;
  final int? supplierId;
  final String supplierName;
}

/// "Bunun etiketini çıkarın" request, for a product on the website or not.
class LabelRequestScreen extends ConsumerStatefulWidget {
  const LabelRequestScreen({this.productId, this.labelKey, super.key});

  /// Opened from a product detail page.
  final int? productId;

  /// Opened from an existing label (reprint request).
  final String? labelKey;

  @override
  ConsumerState<LabelRequestScreen> createState() => _LabelRequestScreenState();
}

class _LabelRequestScreenState extends ConsumerState<LabelRequestScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _noteController = TextEditingController();
  String _floor = '';
  Timer? _debounce;

  bool _onSite = true;
  LabelRequestReason _reason = LabelRequestReason.newProduct;
  _PickedProduct? _product;
  Supplier? _supplier;
  bool _manualSupplier = false;
  String _query = '';
  bool _loadingProduct = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final key = widget.labelKey;
    if (key != null) _prefillFromLabel(key);
    final productId = widget.productId;
    if (productId != null && productId > 0) _prefillFromProduct(productId);
  }

  void _prefillFromLabel(String key) {
    final labels = ref.read(labelsProvider).valueOrNull ?? const [];
    final label = labels.where((l) => l.key == key).firstOrNull;
    if (label == null) return;
    _reason = LabelRequestReason.reprint;
    _floor = label.floor;
    if (label.productId > 0 && !label.isCustom) {
      _product = _PickedProduct(
        id: label.productId,
        name: label.name,
        code: label.productCode ?? '',
        supplierId: label.supplierId > 0 ? label.supplierId : null,
        supplierName: label.supplier,
      );
    } else {
      _onSite = false;
      _nameController.text = label.name;
      _manualSupplier = true;
      _supplierNameController.text = label.supplier;
    }
  }

  Future<void> _prefillFromProduct(int id) async {
    setState(() => _loadingProduct = true);
    try {
      final detail = await ref.read(productDetailProvider(id).future);
      if (!mounted) return;
      setState(() => _product = _PickedProduct(
            id: detail.id,
            name: detail.name,
            code: detail.code,
            supplierId: detail.supplierId,
            supplierName: detail.supplierName ?? '',
          ));
    } catch (_) {
      // Leave the search open; the user can pick the product manually.
    } finally {
      if (mounted) setState(() => _loadingProduct = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _supplierNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _pickSupplier() async {
    final choice = await showModalBottomSheet<_SupplierChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.col.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SupplierSearchSheet(),
    );
    if (choice == null) return;
    setState(() {
      _supplier = choice.supplier;
      _manualSupplier = choice.supplier == null;
    });
  }

  String? _validate() {
    if (_onSite) {
      return _product == null ? 'Listeden bir ürün seçin.' : null;
    }
    if (_nameController.text.trim().isEmpty) return 'Ürün adını yazın.';
    final supplierName =
        _manualSupplier ? _supplierNameController.text.trim() : _supplier?.name;
    if ((supplierName ?? '').isEmpty) return 'Firmayı seçin veya yazın.';
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final product = _product;
    final draft = _onSite && product != null
        ? LabelRequestDraft(
            productId: product.id,
            productName: product.name,
            supplierId: product.supplierId,
            supplierName: product.supplierName,
            floor: _floor,
            note: _noteController.text,
            reason: _reason,
          )
        : LabelRequestDraft(
            productName: _nameController.text,
            supplierId: _manualSupplier ? null : _supplier?.id,
            supplierName: _manualSupplier
                ? _supplierNameController.text
                : (_supplier?.name ?? ''),
            floor: _floor,
            note: _noteController.text,
            reason: _reason,
          );

    setState(() => _sending = true);
    final ok = await runLabelAction(
      context,
      () => ref.read(labelActionsProvider).createRequest(draft),
      'Etiket talebi gönderildi.',
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final floors = ref.watch(labelFloorsProvider);

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        title: const Text('Etiket Talebi'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: col.border),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _SectionHeader(label: 'ÜRÜN'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ChoiceBox(
                  icon: Icons.language_rounded,
                  label: 'Sitedeki ürün',
                  selected: _onSite,
                  onTap: () => setState(() => _onSite = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChoiceBox(
                  icon: Icons.add_box_outlined,
                  label: 'Sitede olmayan ürün',
                  selected: !_onSite,
                  onTap: () => setState(() => _onSite = false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_onSite) ..._siteProductFields() else ..._customProductFields(),
          const SizedBox(height: 20),
          const _SectionHeader(label: 'TALEP'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ChoiceBox(
                  icon: Icons.fiber_new_rounded,
                  label: 'Yeni ürün',
                  selected: _reason == LabelRequestReason.newProduct,
                  onTap: () =>
                      setState(() => _reason = LabelRequestReason.newProduct),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChoiceBox(
                  icon: Icons.print_rounded,
                  label: 'Yeniden basım',
                  selected: _reason == LabelRequestReason.reprint,
                  onTap: () =>
                      setState(() => _reason = LabelRequestReason.reprint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          floors.when(
            data: (items) => FloorPicker(
              floors: items,
              selected: _floor,
              onChanged: (floor) => setState(() => _floor = floor),
            ),
            loading: () => const SizedBox(height: 56, child: LoadingView()),
            error: (error, stackTrace) => TextButton.icon(
              onPressed: () => ref.invalidate(labelFloorsProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Kat listesi yüklenemedi, tekrar dene'),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _noteController,
            maxLines: 3,
            maxLength: 300,
            style: TextStyle(color: col.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Not (opsiyonel)',
              hintText: 'Örn. Ürün bugün geldi, merdiven yanına kondu.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _sending ? null : _submit,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: const Text('Talebi gönder'),
          ),
          const SizedBox(height: 10),
          Text(
            'Talep, etiketleri basan kişinin "Talepler" listesine düşer. '
            'Etiket basılınca talep kapatılır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: col.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  List<Widget> _siteProductFields() {
    final col = context.col;
    final product = _product;
    if (_loadingProduct) {
      return const [SizedBox(height: 80, child: LoadingView())];
    }
    if (product != null) {
      return [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: col.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [product.code, product.supplierName]
                          .where((v) => v.isNotEmpty)
                          .join(' · '),
                      style: TextStyle(color: col.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _product = null),
                child: const Text('Değiştir'),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: col.textPrimary),
        decoration: const InputDecoration(
          hintText: 'Ürün adı veya kod ara...',
          prefixIcon: Icon(Icons.search_rounded),
        ),
        onChanged: _onSearchChanged,
      ),
      if (_query.isNotEmpty) ...[
        const SizedBox(height: 8),
        _ProductResults(
          query: _query,
          onPick: (product) => setState(() {
            _product = product;
            _searchController.clear();
            _query = '';
          }),
        ),
      ],
    ];
  }

  List<Widget> _customProductFields() {
    final col = context.col;
    return [
      TextField(
        controller: _nameController,
        maxLength: 200,
        style: TextStyle(color: col.textPrimary),
        decoration: const InputDecoration(
          labelText: 'Ürün adı',
          hintText: 'Örn. Lavin Yatak Odası Takımı',
          prefixIcon: Icon(Icons.chair_alt_rounded),
          counterText: '',
        ),
      ),
      const SizedBox(height: 12),
      if (_manualSupplier)
        TextField(
          controller: _supplierNameController,
          maxLength: 200,
          style: TextStyle(color: col.textPrimary),
          decoration: InputDecoration(
            labelText: 'Firma adı (listede yok)',
            prefixIcon: const Icon(Icons.store_rounded),
            counterText: '',
            suffixIcon: IconButton(
              tooltip: 'Listeden seç',
              onPressed: _pickSupplier,
              icon: const Icon(Icons.list_rounded),
            ),
          ),
        )
      else
        InkWell(
          onTap: _pickSupplier,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Firma',
              prefixIcon: Icon(Icons.store_rounded),
              suffixIcon: Icon(Icons.arrow_drop_down_rounded),
            ),
            child: Text(
              _supplier?.name ?? 'Firma seçin',
              style: TextStyle(
                color: _supplier == null ? col.textMuted : col.textPrimary,
              ),
            ),
          ),
        ),
    ];
  }
}

class _ProductResults extends ConsumerWidget {
  const _ProductResults({required this.query, required this.onPick});

  final String query;
  final ValueChanged<_PickedProduct> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final results = ref.watch(productSearchProvider(query));
    return results.when(
      loading: () => const SizedBox(height: 80, child: LoadingView()),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Ürünler yüklenemedi.',
            style: TextStyle(color: col.errorColor)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Sitede bulunamadı. Ürün sitede yoksa "Sitede olmayan ürün" '
              'seçeneğini kullanın.',
              style: TextStyle(color: col.textSecondary, fontSize: 12),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: col.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: col.border),
          ),
          child: Column(
            children: [
              for (final product in items.take(8))
                ListTile(
                  dense: true,
                  onTap: () => onPick(_PickedProduct(
                    id: product.id,
                    name: product.name,
                    code: product.code,
                    supplierId: product.supplierId,
                    supplierName: product.supplierName ?? '',
                  )),
                  title: Text(
                    product.name,
                    style: TextStyle(
                      color: col.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    [product.code, product.supplierName ?? '']
                        .where((v) => v.isNotEmpty)
                        .join(' · '),
                    style: TextStyle(color: col.textSecondary, fontSize: 12),
                  ),
                  trailing: Icon(Icons.add_circle_outline_rounded,
                      color: col.textSecondary),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SupplierChoice {
  const _SupplierChoice(this.supplier);

  /// null = "firma listede yok", typed by hand.
  final Supplier? supplier;
}

class _SupplierSearchSheet extends ConsumerStatefulWidget {
  const _SupplierSearchSheet();

  @override
  ConsumerState<_SupplierSearchSheet> createState() =>
      _SupplierSearchSheetState();
}

class _SupplierSearchSheetState extends ConsumerState<_SupplierSearchSheet> {
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final results = ref.watch(labelSupplierSearchProvider(_query));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
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
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: TextField(
              autofocus: true,
              style: TextStyle(color: col.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Firma ara...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() => _query = value.trim());
                });
              },
            ),
          ),
          ListTile(
            onTap: () => Navigator.of(context).pop(const _SupplierChoice(null)),
            leading: const Icon(Icons.edit_rounded, color: AppTheme.gold),
            title: Text(
              'Firma listede yok, elle yaz',
              style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(height: 1, color: col.border),
          Expanded(
            child: results.when(
              loading: () => const LoadingView(),
              error: (error, stackTrace) => ErrorStateView(
                message: 'Firmalar yüklenemedi.',
                onRetry: () =>
                    ref.invalidate(labelSupplierSearchProvider(_query)),
              ),
              data: (items) => ListView(
                controller: scrollController,
                children: [
                  for (final supplier in items)
                    ListTile(
                      onTap: () =>
                          Navigator.of(context).pop(_SupplierChoice(supplier)),
                      title: Text(
                        supplier.name,
                        style: TextStyle(color: col.textPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
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

class _ChoiceBox extends StatelessWidget {
  const _ChoiceBox({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.gold.withValues(alpha: 0.14) : col.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.gold.withValues(alpha: 0.5) : col.border,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected ? AppTheme.gold : col.textSecondary),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppTheme.gold : col.textPrimary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
