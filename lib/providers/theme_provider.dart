import 'package:bangla_hub/widgets/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemeData _currentTheme = AppTheme.lightTheme;

  ThemeMode get themeMode => _themeMode;
  ThemeData get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('themeMode') ?? 0;
      
      switch (themeIndex) {
        case 0:
          _themeMode = ThemeMode.light;
          _currentTheme = AppTheme.lightTheme;
          break;
        case 1:
          _themeMode = ThemeMode.dark;
          _currentTheme = AppTheme.darkTheme;
          break;
        case 2:
          _themeMode = ThemeMode.system;
          _currentTheme = AppTheme.lightTheme; // Default to light for system
          break;
      }
      notifyListeners();
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    switch (mode) {
      case ThemeMode.light:
        _currentTheme = AppTheme.lightTheme;
        break;
      case ThemeMode.dark:
        _currentTheme = AppTheme.darkTheme;
        break;
      case ThemeMode.system:
        // You might want to check system theme here
        _currentTheme = AppTheme.lightTheme;
        break;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      int themeIndex;
      switch (mode) {
        case ThemeMode.light:
          themeIndex = 0;
          break;
        case ThemeMode.dark:
          themeIndex = 1;
          break;
        case ThemeMode.system:
          themeIndex = 2;
          break;
      }
      await prefs.setInt('themeMode', themeIndex);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
    
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}