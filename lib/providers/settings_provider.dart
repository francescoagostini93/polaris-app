import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Manages app settings with persistence
class SettingsProvider extends ChangeNotifier {
  String _email = '';
  int _defaultDifficulty = AppConfig.defaultDifficulty;
  String _language = AppConfig.defaultLanguage;
  double _ttsSpeed = AppConfig.defaultTtsSpeed;
  String _apiKey = AppConfig.geminiApiKey;
  String _gender = 'maschio'; // maschio or femmina
  ThemeMode _themeMode = ThemeMode.system;

  String get email => _email;
  int get defaultDifficulty => _defaultDifficulty;
  String get language => _language;
  double get ttsSpeed => _ttsSpeed;
  String get apiKey => _apiKey;
  String get gender => _gender;
  ThemeMode get themeMode => _themeMode;
  bool get isEmailConfigured => _email.isNotEmpty;

  /// Load settings from SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _email = prefs.getString('email') ?? '';
    _defaultDifficulty = prefs.getInt('defaultDifficulty') ?? AppConfig.defaultDifficulty;
    _language = prefs.getString('language') ?? AppConfig.defaultLanguage;
    _ttsSpeed = prefs.getDouble('ttsSpeed') ?? AppConfig.defaultTtsSpeed;
    _apiKey = prefs.getString('apiKey') ?? AppConfig.geminiApiKey;
    _gender = prefs.getString('gender') ?? 'maschio';
    final themeModeStr = prefs.getString('themeMode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == themeModeStr,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> setEmail(String value) async {
    _email = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', value);
    notifyListeners();
  }

  Future<void> setDefaultDifficulty(int value) async {
    _defaultDifficulty = value.clamp(1, 10);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultDifficulty', _defaultDifficulty);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> setTtsSpeed(double value) async {
    _ttsSpeed = value.clamp(0.1, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ttsSpeed', _ttsSpeed);
    notifyListeners();
  }

  Future<void> setApiKey(String value) async {
    _apiKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', value);
    notifyListeners();
  }

  Future<void> setGender(String value) async {
    _gender = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gender', value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    notifyListeners();
  }
}
