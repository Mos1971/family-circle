import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

/// Which look the person wants: follow their device, or force light / dark.
/// The choice is remembered on this device.
class ThemeModeProvider extends ChangeNotifier with WidgetsBindingObserver {
  ThemeModeProvider() {
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  static const _key = 'fc_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// What is actually shown right now (resolves "system" to light or dark).
  Brightness get effective {
    switch (_mode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  static const _schemeKey = 'fc_colour_scheme';

  AppScheme _scheme = AppScheme.gold;
  AppScheme get scheme => _scheme;

  Future<void> setScheme(AppScheme scheme) async {
    if (scheme == _scheme) return;
    _scheme = scheme;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_schemeKey, scheme.name);
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      final loaded = ThemeMode.values.where((m) => m.name == saved);
      final savedScheme = AppScheme.values.where(
        (s) => s.name == prefs.getString(_schemeKey),
      );
      var changed = false;
      if (loaded.isNotEmpty && loaded.first != _mode) {
        _mode = loaded.first;
        changed = true;
      }
      if (savedScheme.isNotEmpty && savedScheme.first != _scheme) {
        _scheme = savedScheme.first;
        changed = true;
      }
      if (changed) notifyListeners();
    } catch (_) {
      // Storage unavailable (e.g. private browsing, tests): stay on system.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }

  /// The device switched between light and dark.
  @override
  void didChangePlatformBrightness() {
    if (_mode == ThemeMode.system) notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
