import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for theme mode, language, and base currency.
/// MaterialApp listens to this directly, so changing any setting rebuilds
/// the whole app live — no restart needed.
class AppSettingsController extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const _localeKey = 'locale'; // 'en' | 'zh'
  static const _baseCurrencyKey = 'base_currency'; // ISO 4217, e.g. 'SGD' — used for aggregates only
  static const _fundApiKey = 'fund_api_url'; // base URL of the web app that serves /api/fund-quote
  static const _lockKey = 'lock_enabled'; // ask for biometrics / device passcode on launch

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  String _baseCurrency = 'SGD';
  String _fundApiBaseUrl = '';
  bool _lockEnabled = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get baseCurrency => _baseCurrency;

  /// Where unit-trust prices come from. Empty = not set up yet.
  String get fundApiBaseUrl => _fundApiBaseUrl;

  bool get lockEnabled => _lockEnabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _parseThemeMode(prefs.getString(_themeModeKey));
    _locale = Locale(prefs.getString(_localeKey) ?? 'en');
    _baseCurrency = prefs.getString(_baseCurrencyKey) ?? 'SGD';
    _fundApiBaseUrl = prefs.getString(_fundApiKey) ?? '';
    _lockEnabled = prefs.getBool(_lockKey) ?? false;
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

  Future<void> setFundApiBaseUrl(String url) async {
    _fundApiBaseUrl = url.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fundApiKey, _fundApiBaseUrl);
  }

  Future<void> setLockEnabled(bool value) async {
    _lockEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockKey, value);
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
