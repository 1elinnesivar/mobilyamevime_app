import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'app_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final value = await _storage.read(key: _key);
    state = value == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> toggle() async {
    final next =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await _storage.write(
        key: _key, value: next == ThemeMode.light ? 'light' : 'dark');
  }

  bool get isDark => state == ThemeMode.dark;
}
