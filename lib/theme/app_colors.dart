import 'package:flutter/material.dart';

/// The colour schemes a person can choose between. Each has a dark and a light
/// version, picked so text stays easy to read on every background.
enum AppScheme { gold, ocean, forest, rose, violet }

extension AppSchemeX on AppScheme {
  String get label {
    switch (this) {
      case AppScheme.gold:
        return 'Black & Gold';
      case AppScheme.ocean:
        return 'Ocean Blue';
      case AppScheme.forest:
        return 'Forest Green';
      case AppScheme.rose:
        return 'Berry Rose';
      case AppScheme.violet:
        return 'Royal Violet';
    }
  }

  /// The accent colour as shown in the picker.
  Color get swatch => _palettes[this]!.dark.accent;
}

class _Tone {
  const _Tone({
    required this.accent,
    required this.accentDark,
    required this.accentLight,
    required this.onAccent,
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.sidebar,
    required this.text,
    required this.muted,
    required this.border,
    required this.gradient,
  });

  final Color accent, accentDark, accentLight, onAccent;
  final Color bg, surface, surfaceHigh, sidebar, text, muted, border;
  final List<Color> gradient;
}

class _Palette {
  const _Palette(this.dark, this.light);
  final _Tone dark;
  final _Tone light;
}

const _palettes = <AppScheme, _Palette>{
  AppScheme.gold: _Palette(
    _Tone(
      accent: Color(0xFFD4AF37),
      accentDark: Color(0xFFB8921F),
      accentLight: Color(0xFFF0D77A),
      onAccent: Color(0xFF111111),
      bg: Color(0xFF0A0A0A),
      surface: Color(0xFF161616),
      surfaceHigh: Color(0xFF211E16),
      sidebar: Color(0xFF0E0E0E),
      text: Color(0xFFF5EFDC),
      muted: Color(0xFF9C9684),
      border: Color(0xFF2E2A1E),
      gradient: [Color(0xFF241C06), Color(0xFF0A0A0A)],
    ),
    _Tone(
      accent: Color(0xFFB8860B),
      accentDark: Color(0xFF8F6A08),
      accentLight: Color(0xFFD4AF37),
      onAccent: Color(0xFF111111),
      bg: Color(0xFFF8F4EA),
      surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFF1EADA),
      sidebar: Color(0xFFFFFFFF),
      text: Color(0xFF1B1A17),
      muted: Color(0xFF6D6858),
      border: Color(0xFFE4DCC8),
      gradient: [Color(0xFFF3E6BA), Color(0xFFF8F4EA)],
    ),
  ),
  AppScheme.ocean: _Palette(
    _Tone(
      accent: Color(0xFF5AB0FF),
      accentDark: Color(0xFF3C93E6),
      accentLight: Color(0xFF9CD0FF),
      onAccent: Color(0xFF08121F),
      bg: Color(0xFF0A111C),
      surface: Color(0xFF121C2D),
      surfaceHigh: Color(0xFF1A2740),
      sidebar: Color(0xFF0D1522),
      text: Color(0xFFEFF5FC),
      muted: Color(0xFF9DAEC6),
      border: Color(0xFF243553),
      gradient: [Color(0xFF12284A), Color(0xFF0A111C)],
    ),
    _Tone(
      accent: Color(0xFF1B64C4),
      accentDark: Color(0xFF134E9C),
      accentLight: Color(0xFF4F93E6),
      onAccent: Color(0xFFFFFFFF),
      bg: Color(0xFFEEF4FB),
      surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFE3EDF9),
      sidebar: Color(0xFFFFFFFF),
      text: Color(0xFF10202F),
      muted: Color(0xFF55657A),
      border: Color(0xFFD3E0F0),
      gradient: [Color(0xFFCFE2F8), Color(0xFFEEF4FB)],
    ),
  ),
  AppScheme.forest: _Palette(
    _Tone(
      accent: Color(0xFF45C788),
      accentDark: Color(0xFF2FA86D),
      accentLight: Color(0xFF8BE3B9),
      onAccent: Color(0xFF07140D),
      bg: Color(0xFF09130E),
      surface: Color(0xFF111F18),
      surfaceHigh: Color(0xFF192D22),
      sidebar: Color(0xFF0C1812),
      text: Color(0xFFEEF8F2),
      muted: Color(0xFF98B3A5),
      border: Color(0xFF23402F),
      gradient: [Color(0xFF123322), Color(0xFF09130E)],
    ),
    _Tone(
      accent: Color(0xFF1C7443),
      accentDark: Color(0xFF14592F),
      accentLight: Color(0xFF3FA06B),
      onAccent: Color(0xFFFFFFFF),
      bg: Color(0xFFF0F7F2),
      surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFE2F0E6),
      sidebar: Color(0xFFFFFFFF),
      text: Color(0xFF12241A),
      muted: Color(0xFF55695C),
      border: Color(0xFFCFE3D6),
      gradient: [Color(0xFFCDE9D7), Color(0xFFF0F7F2)],
    ),
  ),
  AppScheme.rose: _Palette(
    _Tone(
      accent: Color(0xFFF277AC),
      accentDark: Color(0xFFD95B93),
      accentLight: Color(0xFFF9AACB),
      onAccent: Color(0xFF1A0A12),
      bg: Color(0xFF140A11),
      surface: Color(0xFF211320),
      surfaceHigh: Color(0xFF2D1B2B),
      sidebar: Color(0xFF190D15),
      text: Color(0xFFFBEFF5),
      muted: Color(0xFFBE9DB0),
      border: Color(0xFF45283F),
      gradient: [Color(0xFF3A1230), Color(0xFF140A11)],
    ),
    _Tone(
      accent: Color(0xFFB0215F),
      accentDark: Color(0xFF8C1A4C),
      accentLight: Color(0xFFD9548C),
      onAccent: Color(0xFFFFFFFF),
      bg: Color(0xFFFBF1F5),
      surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFF6E2EA),
      sidebar: Color(0xFFFFFFFF),
      text: Color(0xFF2A1220),
      muted: Color(0xFF75596A),
      border: Color(0xFFEBD3DE),
      gradient: [Color(0xFFF6D3E1), Color(0xFFFBF1F5)],
    ),
  ),
  AppScheme.violet: _Palette(
    _Tone(
      accent: Color(0xFFB39DFB),
      accentDark: Color(0xFF9279EE),
      accentLight: Color(0xFFD2C5FD),
      onAccent: Color(0xFF110B22),
      bg: Color(0xFF0F0B1B),
      surface: Color(0xFF191430),
      surfaceHigh: Color(0xFF241D42),
      sidebar: Color(0xFF130F23),
      text: Color(0xFFF2EFFC),
      muted: Color(0xFFA9A0C8),
      border: Color(0xFF30285A),
      gradient: [Color(0xFF241A4F), Color(0xFF0F0B1B)],
    ),
    _Tone(
      accent: Color(0xFF6538CC),
      accentDark: Color(0xFF4F2AA6),
      accentLight: Color(0xFF8F68E6),
      onAccent: Color(0xFFFFFFFF),
      bg: Color(0xFFF4F1FB),
      surface: Color(0xFFFFFFFF),
      surfaceHigh: Color(0xFFE9E3F7),
      sidebar: Color(0xFFFFFFFF),
      text: Color(0xFF1C1530),
      muted: Color(0xFF605878),
      border: Color(0xFFDDD5F0),
      gradient: [Color(0xFFDDD2F7), Color(0xFFF4F1FB)],
    ),
  ),
};

/// Palette for Family Circle, read through getters so one switch
/// ([setLook]) restyles the whole app. Screens still just write
/// `AppColors.gold` (the accent colour, whatever scheme is chosen); they are
/// rebuilt when the theme changes (see ThemeModeProvider / app.dart).
class AppColors {
  AppColors._();

  static bool _dark = true;
  static AppScheme _scheme = AppScheme.gold;

  /// Set once per theme change, before the widget tree rebuilds.
  static void setLook(Brightness b, AppScheme scheme) {
    _dark = b == Brightness.dark;
    _scheme = scheme;
  }

  static Brightness get brightness =>
      _dark ? Brightness.dark : Brightness.light;
  static bool get isDark => _dark;

  static _Tone get _t {
    final p = _palettes[_scheme]!;
    return _dark ? p.dark : p.light;
  }

  // The accent ("gold" is the historic name).
  static Color get gold => _t.accent;
  static Color get goldDark => _t.accentDark;
  static Color get goldLight => _t.accentLight;

  static Color get bg => _t.bg;
  static Color get surface => _t.surface;
  static Color get surfaceHigh => _t.surfaceHigh;
  static Color get sidebar => _t.sidebar;
  static Color get text => _t.text;
  static Color get onGold => _t.onAccent;
  static Color get muted => _t.muted;
  static Color get border => _t.border;

  static Color get success =>
      _dark ? const Color(0xFF5CB88A) : const Color(0xFF2E8B57);
  static Color get danger =>
      _dark ? const Color(0xFFE5675A) : const Color(0xFFC0392B);

  /// Sign-in brand panel gradient.
  static List<Color> get brandGradient => _t.gradient;
}
