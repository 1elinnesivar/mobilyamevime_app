import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.card,
    required this.cardElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.successSurface,
    required this.errorColor,
    required this.errorSurface,
  });

  final Color bg;
  final Color surface;
  final Color card;
  final Color cardElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color successSurface;
  final Color errorColor;
  final Color errorSurface;

  static const dark = AppColors(
    bg: Color(0xFF070B18),
    surface: Color(0xFF0E1220),
    card: Color(0xFF141929),
    cardElevated: Color(0xFF1A2038),
    border: Color(0xFF1E2540),
    textPrimary: Color(0xFFF1F3FC),
    textSecondary: Color(0xFF7886B0),
    textMuted: Color(0xFF3B4268),
    successSurface: Color(0xFF0A2218),
    errorColor: Color(0xFFF87171),
    errorSurface: Color(0xFF2D0A0A),
  );

  static const light = AppColors(
    bg: Color(0xFFF2F4F8),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    cardElevated: Color(0xFFF8FAFE),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    textMuted: Color(0xFFB8C2D4),
    successSurface: Color(0xFFF0FDF4),
    errorColor: Color(0xFFDC2626),
    errorSurface: Color(0xFFFEF2F2),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? card,
    Color? cardElevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? successSurface,
    Color? errorColor,
    Color? errorSurface,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      successSurface: successSurface ?? this.successSurface,
      errorColor: errorColor ?? this.errorColor,
      errorSurface: errorSurface ?? this.errorSurface,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardElevated: Color.lerp(cardElevated, other.cardElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      errorSurface: Color.lerp(errorSurface, other.errorSurface, t)!,
    );
  }
}

extension AppColorsExt on BuildContext {
  AppColors get col =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
