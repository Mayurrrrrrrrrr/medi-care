import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static SettingsProvider? _instance;
  static SettingsProvider get instance => _instance!;

  bool _largeTextMode = false;
  String _language = 'en';

  bool get largeTextMode => _largeTextMode;
  String get language => _language;

  SettingsProvider() {
    _instance = this;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _largeTextMode = prefs.getBool('large_text_mode') ?? false;
    _language = prefs.getString('app_language') ?? 'en';
    notifyListeners();
  }

  Future<void> setLargeTextMode(bool value) async {
    _largeTextMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('large_text_mode', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', value);
    notifyListeners();
  }
}
