import 'package:flutter/material.dart';
import 'package:ekride_frontend/core/app_strings.dart';

class AppSettingsProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  String _language = 'en'; // 'en' or 'bn'

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get isBangla => _language == 'bn';
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool val) {
    if (_isDarkMode != val) {
      _isDarkMode = val;
      notifyListeners();
    }
  }

  void toggleLanguage() {
    _language = _language == 'en' ? 'bn' : 'en';
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (_language != lang && (lang == 'en' || lang == 'bn')) {
      _language = lang;
      notifyListeners();
    }
  }

  String tr(String key, [Map<String, String>? params]) {
    String text = AppStrings.t(key, isBangla);
    if (params != null) {
      params.forEach((placeholder, value) {
        text = text.replaceAll('{$placeholder}', value);
      });
    }
    return text;
  }
}
