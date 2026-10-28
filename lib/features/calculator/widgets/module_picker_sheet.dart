import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../products/models/product_detail.dart';
import '../../products/providers/products_provider.dart';
import '../models/calculator_line.dart';
import '../providers/calculator_provider.dart';
import 'quantity_stepper.dart';

Future<void> showModulePickerSheet(BuildContext context, int productId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.col.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ModulePickerSheet(productId: productId),
  );
}

class ModulePickerSheet extends ConsumerWidget {
  const ModulePickerSheet({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(productDetailProvider(productId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          const _SheetHandle(),
          Expanded(
            child: detail.when(
              loading: () => const LoadingView(),
              error: (error, stackTrace) => ErrorStateView(
                message: 'Modüller yüklenemedi.',
                onRetry: () => ref.invalidate(productDetailProvider(productId)),
              ),
              data: (product) => _SheetContent(
                product: product,
                scrollController: scrollController,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.col.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetContent extends ConsumerWidget {
  const _SheetContent({required this.product, required this.scrollController});

  final ProductDetail product;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final calc = ref.watch(calculatorControllerProvider);
    final group = calc.groupOf(product.id);
    final hasStandardSet =
        product.modules.any((m) => (m.quantity ?? 0) > 0);
    final discount = product.supplierDiscountRate ?? 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  product.code,
                  product.supplierName,
                  if (discount > 0) 'İskonto %$discount',
                ].where((v) => (v ?? '').isNotEmpty).join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: col.textSecondary, fontSize: 12),
              ),
              if (hasStandardSet) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ref
                      .read(calculatorControllerProvider)
                      .addStandardSet(product),
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: const Text('Standart seti ekle'),
                ),
              ],
            ],
          ),
        ),
        Container(height: 1, color: col.border),
        Expanded(
          child: product.modules.isEmpty
              ? const EmptyStateView(
                  message: 'Bu ürün için tanımlı modül bulunmuyor.',
                  icon: Icons.view_module_outlined,
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: product.modules.length,
                  itemBuilder: (context, index) => _ModuleRow(
                    module: product.modules[index],
                    quantity: calc.quantityOf(product.id, index),
                    onChanged: (value) => ref
                        .read(calculatorControllerProvider)
                        .setModuleQuantity(product, index, value),
                  ),
                ),
        ),
        Container(
          decoration: BoxDecoration(
            color: col.surface,
            border: Border(top: BorderSide(color: col.border)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SafeArea(
            top: false,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                group == null
                    ? 'Kapat'
                    : 'Tamam · ${group.quantity} modül · '
                        'Alış ${CurrencyFormatter.format(group.netTotal)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({
    required this.module,
    required this.quantity,
    required this.onChanged,
  });

  final ProductModule module;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final selected = quantity > 0;
    final listPrice = module.purchasePrice ?? 0;
    final netPrice = module.discountedPurchasePrice ?? listPrice;
    final measurement = moduleMeasurement(module);
    final standard = module.quantity ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppTheme.gold.withValues(alpha: 0.45) : col.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.name ?? 'Modül #${module.moduleId}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (measurement.isNotEmpty || standard > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (measurement.isNotEmpty) measurement,
                      if (standard > 0) 'Standart: $standard adet',
                    ].join(' · '),
                    style: TextStyle(color: col.textSecondary, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _PriceText(
                        label: 'Liste',
                        value: CurrencyFormatter.format(listPrice)),
                    _PriceText(
                      label: 'Alış',
                      value: CurrencyFormatter.format(netPrice),
                      strong: true,
                    ),
                  ],
                ),
                if (listPrice <= 0) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Alış fiyatı tanımlı değil',
                    style: TextStyle(
                      color: AppTheme.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          QuantityStepper(value: quantity, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PriceText extends StatelessWidget {
  const _PriceText({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: TextStyle(
                color: col.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: strong ? col.textPrimary : col.textSecondary,
              fontSize: 13,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
