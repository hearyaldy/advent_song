// lib/main.dart - UPDATED
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'core/services/theme_notifier.dart';
import 'core/services/favorites_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
    }

    try {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      print('Firebase offline persistence enabled');
    } catch (e) {
      print('Failed to enable offline persistence: $e');
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print('Firebase already initialized');
      try {
        FirebaseDatabase.instance.setPersistenceEnabled(true);
      } catch (persistenceError) {
        print('Failed to enable offline persistence: $persistenceError');
      }
    } else {
      print('Firebase initialization error: $e');
      runApp(FirebaseErrorApp(error: e.toString()));
      return;
    }
  } catch (e) {
    print('Firebase initialization error: $e');
    runApp(FirebaseErrorApp(error: e.toString()));
    return;
  }

  // Create and initialize notifiers
  final themeNotifier = ThemeNotifier();
  final favoritesNotifier = FavoritesNotifier();

  // CRITICAL: Ensure migration runs before app starts
  try {
    await Future.wait([
      themeNotifier.initialize(),
      favoritesNotifier.initialize(), // Migration happens here
    ]);

    // Validate favorites after initialization
    await favoritesNotifier.validateFavorites();

    // Log diagnostic info in debug mode
    if (kDebugMode) {
      final diagnosticInfo = await favoritesNotifier.getDiagnosticInfo();
      print('Favorites diagnostic info: $diagnosticInfo');
    }

    print('App initialization completed successfully');
  } catch (e) {
    print('Error during app initialization: $e');
    // Try to restore from backup if favorites failed to load
    if (favoritesNotifier.favoritesCount == 0) {
      print('Attempting to restore favorites from backup...');
      final restored = await favoritesNotifier.restoreFromBackup();
      if (restored) {
        print('Successfully restored favorites from backup');
      }
    }
    // Continue with app launch even if initialization fails
  }

  runApp(SongLyricsApp(
    themeNotifier: themeNotifier,
    favoritesNotifier: favoritesNotifier,
  ));
}

class FirebaseErrorApp extends StatelessWidget {
  final String error;

  const FirebaseErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Error',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Firebase Initialization Failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('Error: $error',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                    onPressed: () => main(), child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
