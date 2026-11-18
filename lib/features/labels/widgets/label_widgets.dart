import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/product_label.dart';

/// Runs a write action and reports the outcome with a SnackBar.
Future<bool> runLabelAction(
  BuildContext context,
  Future<void> Function() action,
  String successMessage,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    return true;
  } on ApiException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('İşlem tamamlanamadı. Tekrar deneyin.')),
    );
  }
  return false;
}

/// Floor choice from the panel's managed list ('' = no floor).
/// A legacy value outside the list stays visible so it is not lost silently.
class FloorPicker extends StatelessWidget {
  const FloorPicker({
    required this.floors,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<String> floors;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final options = [
      ...floors,
      if (selected.isNotEmpty && !floors.contains(selected)) selected,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.layers_rounded, size: 16, color: col.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Kat bilgisi',
              style: TextStyle(
                color: col.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _FloorChip(
              label: 'Kat yok',
              selected: selected.isEmpty,
              onTap: () => onChanged(''),
            ),
            for (final floor in options)
              _FloorChip(
                label: floor,
                selected: selected == floor,
                onTap: () => onChanged(floor),
              ),
          ],
        ),
        if (floors.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Kat listesi boş. Katlar panelde Ürün Etiketleri → Katlar '
            'bölümünden eklenir.',
            style: TextStyle(color: col.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _FloorChip extends StatelessWidget {
  const _FloorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gold.withValues(alpha: 0.14) : col.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppTheme.gold.withValues(alpha: 0.5) : col.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.gold : col.textPrimary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Returns the new floor ('' clears it) or null when cancelled.
Future<String?> showFloorDialog(
  BuildContext context, {
  required ProductLabel label,
  required List<String> floors,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _FloorDialog(label: label, floors: floors),
  );
}

class _FloorDialog extends StatefulWidget {
  const _FloorDialog({required this.label, required this.floors});

  final ProductLabel label;
  final List<String> floors;

  @override
  State<_FloorDialog> createState() => _FloorDialogState();
}

class _FloorDialogState extends State<_FloorDialog> {
  late String _selected = widget.label.floor;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return AlertDialog(
      backgroundColor: col.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: col.border),
      ),
      title: Text(
        'Kat bilgisini değiştir',
        style: TextStyle(color: col.textPrimary, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label.name,
                style: TextStyle(color: col.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              FloorPicker(
                floors: widget.floors,
                selected: _selected,
                onChanged: (floor) => setState(() => _selected = floor),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Vazgeç', style: TextStyle(color: col.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

Future<bool> confirmRemoveLabel(BuildContext context, ProductLabel label) async {
  final col = context.col;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: col.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: col.border),
      ),
      title: Text(
        'Etiketi kaldır',
        style: TextStyle(color: col.textPrimary, fontWeight: FontWeight.w800),
      ),
      content: Text(
        '"${label.name}" etiketi listeden kaldırılacak. Etiket geçmişi '
        'silinmez; ürünün etiketi yeniden basılırsa listeye geri döner.',
        style: TextStyle(color: col.textSecondary, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Vazgeç', style: TextStyle(color: col.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: col.errorColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 40),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Kaldır'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

enum LabelAction { floor, reprint, product, remove }

Future<LabelAction?> showLabelActionsSheet(
  BuildContext context,
  ProductLabel label,
) {
  final col = context.col;
  return showModalBottomSheet<LabelAction>(
    context: context,
    useSafeArea: true,
    backgroundColor: col.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      Widget tile(
        LabelAction action,
        IconData icon,
        String title,
        String subtitle, {
        Color? color,
      }) {
        final tint = color ?? col.textPrimary;
        return ListTile(
          onTap: () => Navigator.of(ctx).pop(action),
          leading: Icon(icon, color: color ?? AppTheme.gold),
          title: Text(
            title,
            style: TextStyle(color: tint, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: col.textSecondary, fontSize: 12),
          ),
        );
      }

      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.name,
                    style: TextStyle(
                      color: col.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      label.supplier,
                      label.hasFloor ? label.floor : 'Kat girilmemiş',
                    ].join(' · '),
                    style: TextStyle(color: col.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: col.border),
            tile(
              LabelAction.floor,
              Icons.layers_rounded,
              'Kat bilgisini değiştir',
              label.hasFloor ? 'Şu an: ${label.floor}' : 'Kat girilmemiş',
            ),
            tile(
              LabelAction.reprint,
              Icons.print_rounded,
              'Yeniden basım talebi gönder',
              'Etiketi basacak kişiye talep düşer',
            ),
            if (label.productId > 0 && !label.isCustom)
              tile(
                LabelAction.product,
                Icons.open_in_new_rounded,
                'Ürün detayını aç',
                'Modüller, fiyatlar ve tedarikçi',
              ),
            tile(
              LabelAction.remove,
              Icons.delete_outline_rounded,
              'Etiketi listeden kaldır',
              'Ürün mağazadan kalktıysa',
              color: col.errorColor,
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
