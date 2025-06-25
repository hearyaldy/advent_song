// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'core/services/theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with proper error handling
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app(); // Use existing app
    }
    print('Firebase initialized successfully');
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      print('Firebase already initialized, using existing instance');
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

  // Create and initialize theme notifier
  final themeNotifier = ThemeNotifier();
  await themeNotifier.initialize();

  runApp(SongLyricsApp(themeNotifier: themeNotifier));
}

// Error app for Firebase initialization failures
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
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Firebase Initialization Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $error',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
