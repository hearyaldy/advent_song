// lib/core/services/theme_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../themes/app_theme.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _isDarkModeKey = 'isDarkMode';
  static const String _colorThemeKey = 'selectedColorTheme';

  bool _isDarkMode = false;
  String _selectedColorTheme = 'default';
  bool _isInitialized = false;

  // Define color themes directly in ThemeNotifier
  static const Map<String, Map<String, Color>> _colorThemes = {
    'default': {
      'primary': Color(0xFF6366F1),
      'secondary': Color(0xFF8B5CF6),
    },
    'emerald': {
      'primary': Color(0xFF059669),
      'secondary': Color(0xFF10B981),
    },
    'rose': {
      'primary': Color(0xFFE11D48),
      'secondary': Color(0xFFF43F5E),
    },
    'amber': {
      'primary': Color(0xFFF59E0B),
      'secondary': Color(0xFFFBBF24),
    },
    'violet': {
      'primary': Color(0xFF7C3AED),
      'secondary': Color(0xFF8B5CF6),
    },
    'teal': {
      'primary': Color(0xFF0D9488),
      'secondary': Color(0xFF14B8A6),
    },
    'burgundy': {
      'primary': Color(0xFF991B1B),
      'secondary': Color(0xFFDC2626),
    },
    'forest': {
      'primary': Color(0xFF166534),
      'secondary': Color(0xFF15803D),
    },
  };

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get selectedColorTheme => _selectedColorTheme;
  bool get isInitialized => _isInitialized;

  // Get current theme based on settings
  ThemeData get lightTheme {
    final colors =
        _colorThemes[_selectedColorTheme] ?? _colorThemes['default']!;
    return AppTheme.lightTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors['primary']!,
        brightness: Brightness.light,
        primary: colors['primary'],
        secondary: colors['secondary'],
      ),
    );
  }

  ThemeData get darkTheme {
    final colors =
        _colorThemes[_selectedColorTheme] ?? _colorThemes['default']!;
    return AppTheme.darkTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors['primary']!,
        brightness: Brightness.dark,
        primary: colors['primary'],
        secondary: colors['secondary'],
      ),
    );
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // Initialize theme settings from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_isDarkModeKey) ?? false;
      _selectedColorTheme = prefs.getString(_colorThemeKey) ?? 'default';
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Handle error silently, use defaults
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode() async {
    await updateDarkMode(!_isDarkMode);
  }

  // Update dark mode setting
  Future<void> updateDarkMode(bool isDarkMode) async {
    if (_isDarkMode == isDarkMode) return;

    _isDarkMode = isDarkMode;
    notifyListeners(); // This will immediately update the UI

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isDarkModeKey, isDarkMode);
    } catch (e) {
      // Handle error - could revert the change if saving failed
    }
  }

  // Update color theme
  Future<void> updateColorTheme(String colorThemeKey) async {
    if (_selectedColorTheme == colorThemeKey) return;

    _selectedColorTheme = colorThemeKey;
    notifyListeners(); // This will immediately update the UI

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_colorThemeKey, colorThemeKey);
    } catch (e) {
      // Handle error - could revert the change if saving failed
    }
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    _isDarkMode = false;
    _selectedColorTheme = 'default';
    notifyListeners(); // This will immediately update the UI

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isDarkModeKey);
      await prefs.remove(_colorThemeKey);
    } catch (e) {
      // Handle error
    }
  }

  // Get color theme data for UI
  Map<String, dynamic>? getColorThemeData(String? key) {
    final themeKey = key ?? _selectedColorTheme;
    final colors = _colorThemes[themeKey];
    if (colors == null) return null;

    return {
      'name': _getColorThemeName(themeKey),
      'primary': colors['primary'],
      'secondary': colors['secondary'],
    };
  }

  // Get all available color themes
  List<String> get availableColorThemes => _colorThemes.keys.toList();

  // Helper method to get theme names
  String _getColorThemeName(String key) {
    switch (key) {
      case 'default':
        return 'Default Blue';
      case 'emerald':
        return 'Emerald Green';
      case 'rose':
        return 'Rose Pink';
      case 'amber':
        return 'Amber Orange';
      case 'violet':
        return 'Deep Violet';
      case 'teal':
        return 'Ocean Teal';
      case 'burgundy':
        return 'Burgundy Red';
      case 'forest':
        return 'Forest Green';
      default:
        return 'Unknown Theme';
    }
  }
}
