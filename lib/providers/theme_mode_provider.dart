import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      final loaded = ThemeMode.values.where((m) => m.name == saved);
      if (loaded.isNotEmpty && loaded.first != _mode) {
        _mode = loaded.first;
        notifyListeners();
      }
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
