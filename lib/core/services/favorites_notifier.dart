// lib/core/services/favorites_notifier.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends ChangeNotifier {
  static const String _favoritesKey = 'favorites';

  List<String> _favorites = [];
  bool _isInitialized = false;

  List<String> get favorites => List.from(_favorites);
  bool get isInitialized => _isInitialized;

  // Initialize favorites from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favorites = prefs.getStringList(_favoritesKey) ?? [];
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Check if a song is favorite
  bool isFavorite(String songId) {
    return _favorites.contains(songId);
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String songId) async {
    if (_favorites.contains(songId)) {
      await removeFavorite(songId);
    } else {
      await addFavorite(songId);
    }
  }

  // Add to favorites
  Future<void> addFavorite(String songId) async {
    if (!_favorites.contains(songId)) {
      _favorites.add(songId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  // Remove from favorites
  Future<void> removeFavorite(String songId) async {
    if (_favorites.contains(songId)) {
      _favorites.remove(songId);
      await _saveFavorites();
      notifyListeners();
    }
  }

  // Clear all favorites
  Future<void> clearFavorites() async {
    _favorites.clear();
    await _saveFavorites();
    notifyListeners();
  }

  // Get favorites count
  int get favoritesCount => _favorites.length;

  // Save to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favorites);
    } catch (e) {
      // Handle error silently
    }
  }
}
