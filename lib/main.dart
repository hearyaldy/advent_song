// lib/main.dart
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/theme_notifier.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Create and initialize theme notifier
  final themeNotifier = ThemeNotifier();
  await themeNotifier.initialize();

  runApp(SongLyricsApp(themeNotifier: themeNotifier));
}
