// lib/core/services/favorites_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the state of the user's favorite songs,
/// handling loading from and saving to persistent storage.
class FavoritesNotifier extends ChangeNotifier {
  /// The key used to store the list of favorites in SharedPreferences.
  static const String _favoritesKey = 'favorite_songs';

  List<String> _favorites = [];
  bool _isInitialized = false;

  /// A defensive copy of the favorites list to prevent outside modification.
  List<String> get favorites => List.unmodifiable(_favorites);

  /// Returns true if the notifier has been initialized with data from storage.
  bool get isInitialized => _isInitialized;

  /// The number of favorite songs.
  int get favoritesCount => _favorites.length;

  /// Initializes the notifier by loading favorites from SharedPreferences.
  /// This must be called once when the app starts.
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent multiple initializations

    try {
      final prefs = await SharedPreferences.getInstance();
      _favorites = prefs.getStringList(_favoritesKey) ?? [];
    } catch (e) {
      // If there's an error reading from storage, default to an empty list.
      // In a real-world app, you might want to log this error.
      debugPrint("Error loading favorites: $e");
      _favorites = [];
    } finally {
      _isInitialized = true;
      // No need to call notifyListeners() here, as this method should be
      // awaited in main.dart before the UI is built.
    }
  }

  /// Checks if a song is in the favorites list.
  bool isFavorite(String songId) {
    return _favorites.contains(songId);
  }

  /// Adds a song to favorites if it's not already there.
  Future<void> addFavorite(String songId) async {
    if (!_favorites.contains(songId)) {
      _favorites.add(songId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  /// Removes a song from favorites if it exists.
  Future<void> removeFavorite(String songId) async {
    if (_favorites.contains(songId)) {
      _favorites.remove(songId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  /// Adds a song to favorites if it's not there, otherwise removes it.
  Future<void> toggleFavorite(String songId) async {
    if (isFavorite(songId)) {
      _favorites.remove(songId);
    } else {
      _favorites.add(songId);
    }
    await _saveFavorites();
    notifyListeners();
  }

  /// Clears all songs from the favorites list.
  Future<void> clearFavorites() async {
    if (_favorites.isNotEmpty) {
      _favorites.clear();
      await _saveFavorites();
      notifyListeners();
    }
  }

  /// Saves the current list of favorites to SharedPreferences.
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favorites);
    } catch (e) {
      // In a real-world app, you should handle this error, for example,
      // by showing a toast to the user or logging it to a crash reporting service.
      debugPrint("Error saving favorites: $e");
    }
  }
}
