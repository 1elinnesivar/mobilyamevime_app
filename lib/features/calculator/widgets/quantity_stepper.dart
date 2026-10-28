import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final active = value > 0;

    return Container(
      decoration: BoxDecoration(
        color: active ? AppTheme.gold.withValues(alpha: 0.12) : col.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppTheme.gold.withValues(alpha: 0.3) : col.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: value == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
            onTap: active ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? AppTheme.gold : col.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 36,
        height: 34,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? col.textMuted : col.textPrimary,
        ),
      ),
    );
  }
}
