import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for theme mode, language, and base currency.
/// MaterialApp listens to this directly, so changing any setting rebuilds
/// the whole app live — no restart needed.
class AppSettingsController extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const _localeKey = 'locale'; // 'en' | 'zh'
  static const _baseCurrencyKey = 'base_currency'; // ISO 4217, e.g. 'SGD' — used for aggregates only

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  String _baseCurrency = 'SGD';

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get baseCurrency => _baseCurrency;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _parseThemeMode(prefs.getString(_themeModeKey));
    _locale = Locale(prefs.getString(_localeKey) ?? 'en');
    _baseCurrency = prefs.getString(_baseCurrencyKey) ?? 'SGD';
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> setBaseCurrency(String currencyCode) async {
    _baseCurrency = currencyCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseCurrencyKey, currencyCode);
  }

  ThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
