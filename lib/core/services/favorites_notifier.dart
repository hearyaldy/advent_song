// lib/core/services/favorites_notifier.dart - IMPROVED VERSION
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesNotifier extends ChangeNotifier {
  static const String _favoritesKey = 'favorite_songs';

  // Change to store collection_id:song_number pairs instead of just song numbers
  List<String> _favorites = [];
  bool _isInitialized = false;

  List<String> get favorites => List.unmodifiable(_favorites);
  bool get isInitialized => _isInitialized;
  int get favoritesCount => _favorites.length;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _favorites = prefs.getStringList(_favoritesKey) ?? [];
    } catch (e) {
      debugPrint("Error loading favorites: $e");
      _favorites = [];
    } finally {
      _isInitialized = true;
    }
  }

  // NEW: Use collection_id:song_number format for unique identification
  String _createFavoriteKey(String collectionId, String songNumber) {
    return '$collectionId:$songNumber';
  }

  // NEW: Check if a song from specific collection is favorite
  bool isFavoriteInCollection(String collectionId, String songNumber) {
    final key = _createFavoriteKey(collectionId, songNumber);
    return _favorites.contains(key);
  }

  // UPDATED: For backward compatibility, check any collection
  bool isFavorite(String songNumber) {
    return _favorites.any((fav) => fav.endsWith(':$songNumber'));
  }

  // NEW: Add favorite with collection context
  Future<void> addFavoriteFromCollection(
      String collectionId, String songNumber) async {
    final key = _createFavoriteKey(collectionId, songNumber);
    if (!_favorites.contains(key)) {
      _favorites.add(key);
      await _saveFavorites();
      notifyListeners();
    }
  }

  // NEW: Remove favorite with collection context
  Future<void> removeFavoriteFromCollection(
      String collectionId, String songNumber) async {
    final key = _createFavoriteKey(collectionId, songNumber);
    if (_favorites.contains(key)) {
      _favorites.remove(key);
      await _saveFavorites();
      notifyListeners();
    }
  }

  // NEW: Toggle favorite with collection context
  Future<void> toggleFavoriteFromCollection(
      String collectionId, String songNumber) async {
    final key = _createFavoriteKey(collectionId, songNumber);
    if (_favorites.contains(key)) {
      _favorites.remove(key);
    } else {
      _favorites.add(key);
    }
    await _saveFavorites();
    notifyListeners();
  }

  // BACKWARD COMPATIBILITY: Keep old methods for existing code
  Future<void> addFavorite(String songId) async {
    // This is less precise but maintains compatibility
    if (!_favorites.any((fav) => fav.endsWith(':$songId'))) {
      // For backward compatibility, assume 'srd' collection
      await addFavoriteFromCollection('srd', songId);
    }
  }

  Future<void> removeFavorite(String songId) async {
    // Remove from any collection
    _favorites.removeWhere((fav) => fav.endsWith(':$songId'));
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> toggleFavorite(String songId) async {
    if (isFavorite(songId)) {
      await removeFavorite(songId);
    } else {
      await addFavorite(songId);
    }
  }

  // NEW: Get favorites grouped by collection
  Map<String, List<String>> getFavoritesByCollection() {
    final Map<String, List<String>> result = {};

    for (final favorite in _favorites) {
      final parts = favorite.split(':');
      if (parts.length == 2) {
        final collectionId = parts[0];
        final songNumber = parts[1];

        result.putIfAbsent(collectionId, () => []);
        result[collectionId]!.add(songNumber);
      }
    }

    return result;
  }

  // NEW: Get recent favorites (last 5) with collection info
  List<Map<String, String>> getRecentFavoritesWithCollection() {
    return _favorites.reversed.take(5).map((favorite) {
      final parts = favorite.split(':');
      if (parts.length == 2) {
        return {
          'collectionId': parts[0],
          'songNumber': parts[1],
        };
      }
      return {
        'collectionId': 'srd', // fallback
        'songNumber': favorite,
      };
    }).toList();
  }

  Future<void> clearFavorites() async {
    if (_favorites.isNotEmpty) {
      _favorites.clear();
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favorites);
    } catch (e) {
      debugPrint("Error saving favorites: $e");
    }
  }
}
