// lib/themes/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Color schemes for different themes
  static const Map<String, Map<String, Color>> colorThemes = {
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

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: colorThemes['default']!['primary'],
      brightness: Brightness.light,

      // Card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorThemes['default']!['primary']!,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Choice chip theme
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: colorThemes['default']!['primary'],
      brightness: Brightness.dark,

      // Card theme
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorThemes['default']!['primary']!,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Choice chip theme
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // Method to create a theme with custom colors
  static ThemeData createTheme({
    required String colorThemeKey,
    required Brightness brightness,
  }) {
    final colors = colorThemes[colorThemeKey] ?? colorThemes['default']!;

    final baseTheme = brightness == Brightness.light ? lightTheme : darkTheme;

    return baseTheme.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors['primary']!,
        brightness: brightness,
        primary: colors['primary'],
        secondary: colors['secondary'],
      ),
    );
  }

  // Helper method to get the current theme based on settings
  static ThemeData getThemeFromSettings({
    required bool isDarkMode,
    required String colorThemeKey,
  }) {
    return createTheme(
      colorThemeKey: colorThemeKey,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
    );
  }

  // Get available color theme names
  static List<String> get availableColorThemes => colorThemes.keys.toList();

  // Get color theme metadata
  static Map<String, dynamic>? getColorThemeData(String key) {
    final colors = colorThemes[key];
    if (colors == null) return null;

    return {
      'name': _getColorThemeName(key),
      'primary': colors['primary'],
      'secondary': colors['secondary'],
    };
  }

  static String _getColorThemeName(String key) {
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
