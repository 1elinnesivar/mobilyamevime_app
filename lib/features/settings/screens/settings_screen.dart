import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final col = context.col;

    final user = auth.user;
    final displayName =
        user?.name.isNotEmpty == true ? user!.name : 'Mobil Admin';
    final displaySub = user?.email ?? user?.username ?? '';
    final initials = displayName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: col.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Profil kartı
          _ProfileCard(
            initials: initials,
            displayName: displayName,
            displaySub: displaySub,
            col: col,
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'GÖRÜNÜM', col: col),
          const SizedBox(height: 10),
          // Tema toggle kartı
          Container(
            decoration: BoxDecoration(
              color: col.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: col.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: (isDark
                              ? const Color(0xFF818CF8)
                              : AppTheme.gold)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: isDark
                          ? const Color(0xFF818CF8)
                          : AppTheme.goldDark,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tema',
                          style: TextStyle(
                            color: col.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          isDark ? 'Koyu mod' : 'Açık mod',
                          style: TextStyle(
                            color: col.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isDark,
                    onChanged: (_) => themeNotifier.toggle(),
                    activeThumbColor: AppTheme.gold,
                    activeTrackColor: AppTheme.gold.withValues(alpha: 0.3),
                    inactiveThumbColor: col.textSecondary,
                    inactiveTrackColor: col.border,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'HESAP', col: col),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF818CF8),
            label: 'Profil Bilgileri',
            col: col,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'UYGULAMA', col: col),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: col.textSecondary,
            label: 'Hakkında',
            subtitle: 'v1.0.0',
            col: col,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'OTURUM', col: col),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.logout_rounded,
            iconColor: col.errorColor,
            label: 'Çıkış Yap',
            labelColor: col.errorColor,
            col: col,
            onTap: () => _showLogoutDialog(context, ref, col),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
      BuildContext context, WidgetRef ref, AppColors col) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: col.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: col.border),
        ),
        title: Text(
          'Çıkış Yap',
          style: TextStyle(
              color: col.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Oturumunuzu kapatmak istediğinizden emin misiniz?',
          style: TextStyle(color: col.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Vazgeç',
                style: TextStyle(color: col.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: col.errorColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authControllerProvider).logout();
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.initials,
    required this.displayName,
    required this.displaySub,
    required this.col,
  });

  final String initials;
  final String displayName;
  final String displaySub;
  final AppColors col;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: isDark ? 0.08 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppTheme.gold,
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
                  displayName,
                  style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                if (displaySub.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    displaySub,
                    style: TextStyle(
                        color: col.textSecondary, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: AppTheme.success.withValues(alpha: 0.3)),
            ),
            child: const Text(
              'Admin',
              style: TextStyle(
                color: AppTheme.success,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.col});
  final String label;
  final AppColors col;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
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
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.col,
    required this.onTap,
    this.subtitle,
    this.labelColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final Color? labelColor;
  final AppColors col;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: col.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          splashColor: iconColor.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: labelColor ?? col.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                              color: col.textSecondary, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: col.textMuted, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
