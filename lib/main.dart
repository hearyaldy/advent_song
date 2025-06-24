// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'core/services/theme_notifier.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Create and initialize theme notifier
  final themeNotifier = ThemeNotifier();
  await themeNotifier.initialize();

  runApp(SongLyricsApp(themeNotifier: themeNotifier));
}
