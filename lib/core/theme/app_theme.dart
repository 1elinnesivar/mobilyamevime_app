import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

class AppTheme {
  // Sabit semantik renkler (her iki temada da aynı)
  static const gold = Color(0xFFF5A623);
  static const goldLight = Color(0xFFFFD166);
  static const goldDark = Color(0xFFD4891A);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFFBBF24);

  // ─── DARK TEMA ────────────────────────────────────────────────────────────

  static ThemeData dark() {
    const col = AppColors.dark;
    const colorScheme = ColorScheme.dark(
      primary: gold,
      onPrimary: Color(0xFF070B18),
      secondary: goldDark,
      onSecondary: Color(0xFF070B18),
      error: Color(0xFFF87171),
      onError: Colors.white,
      surface: Color(0xFF141929),
      onSurface: Color(0xFFF1F3FC),
      outline: Color(0xFF1E2540),
      surfaceContainerHighest: Color(0xFF1A2038),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: col.bg,
      extensions: const [col],
      dividerColor: col.border,
      appBarTheme: AppBarTheme(
        backgroundColor: col.surface,
        foregroundColor: col.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: col.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: col.textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: col.textSecondary, size: 20),
      ),
      cardTheme: CardThemeData(
        color: col.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: col.border),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: col.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        height: 68,
        indicatorColor: gold.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? gold
                : col.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            fontSize: 11,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? gold
                : col.textSecondary,
            size: 22,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: const Color(0xFF070B18),
          disabledBackgroundColor: col.border,
          disabledForegroundColor: col.textMuted,
          textStyle: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: col.textSecondary,
          side: BorderSide(color: col.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: col.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: col.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: col.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: col.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: col.errorColor, width: 1.5),
        ),
        hintStyle: TextStyle(color: col.textMuted, fontSize: 14),
        labelStyle: TextStyle(color: col.textSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(
            color: gold, fontSize: 12, fontWeight: FontWeight.w600),
        prefixIconColor: col.textSecondary,
        suffixIconColor: col.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        errorStyle: TextStyle(color: col.errorColor, fontSize: 12),
      ),
      dividerTheme:
          DividerThemeData(color: col.border, thickness: 1, space: 1),
      tabBarTheme: const TabBarThemeData(
        labelColor: gold,
        unselectedLabelColor: Color(0xFF7886B0),
        indicatorColor: gold,
        labelStyle: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.2),
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: gold, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Color(0xFF1E2540),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: gold),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: col.cardElevated,
        contentTextStyle:
            TextStyle(color: col.textPrimary, fontSize: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      iconTheme: IconThemeData(color: col.textSecondary, size: 22),
    );
  }

  // ─── LIGHT TEMA ───────────────────────────────────────────────────────────

  static ThemeData light() {
    const col = AppColors.light;
    const colorScheme = ColorScheme.light(
      primary: gold,
      onPrimary: Color(0xFFFFFFFF),
      secondary: goldDark,
      onSecondary: Color(0xFFFFFFFF),
      error: Color(0xFFDC2626),
      onError: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F172A),
      outline: Color(0xFFE2E8F0),
      surfaceContainerHighest: Color(0xFFF8FAFE),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: col.bg,
      extensions: const [col],
      dividerColor: col.border,
      appBarTheme: AppBarTheme(
        backgroundColor: col.surface,
        foregroundColor: col.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: col.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: col.textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: col.textSecondary, size: 20),
      ),
      cardTheme: CardThemeData(
        color: col.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: col.border),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: col.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        height: 68,
        indicatorColor: gold.withValues(alpha: 0.14),
        indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? goldDark
                : col.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            fontSize: 11,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? goldDark
                : col.textSecondary,
            size: 22,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.white,
          disabledBackgroundColor: col.border,
          disabledForegroundColor: col.textMuted,
          textStyle: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: col.textSecondary,
          side: BorderSide(color: col.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: goldDark,
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: col.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: col.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: col.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: col.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: col.errorColor, width: 1.5),
        ),
        hintStyle: TextStyle(color: col.textMuted, fontSize: 14),
        labelStyle: TextStyle(color: col.textSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(
            color: gold, fontSize: 12, fontWeight: FontWeight.w600),
        prefixIconColor: col.textSecondary,
        suffixIconColor: col.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        errorStyle: TextStyle(color: col.errorColor, fontSize: 12),
      ),
      dividerTheme:
          DividerThemeData(color: col.border, thickness: 1, space: 1),
      tabBarTheme: const TabBarThemeData(
        labelColor: goldDark,
        unselectedLabelColor: Color(0xFF64748B),
        indicatorColor: goldDark,
        labelStyle: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.2),
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: goldDark, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Color(0xFFE2E8F0),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: gold),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: col.card,
        contentTextStyle:
            TextStyle(color: col.textPrimary, fontSize: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      iconTheme: IconThemeData(color: col.textSecondary, size: 22),
    );
  }
}
