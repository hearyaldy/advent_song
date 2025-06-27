// lib/core/services/favorites_notifier.dart - WITH MIGRATION FIX
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'json_loader_service.dart';

class FavoritesNotifier extends ChangeNotifier {
  static const String _favoritesKey = 'favorite_songs';
  static const String _migrationKey = 'favorites_migrated_v2';

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

      // Check if migration is needed
      final migrationCompleted = prefs.getBool(_migrationKey) ?? false;

      if (!migrationCompleted && _favorites.isNotEmpty) {
        await _migrateFavoritesToNewFormat(prefs);
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
      _favorites = [];
    } finally {
      _isInitialized = true;
    }
  }

  // MIGRATION: Convert old format to new collection-aware format
  Future<void> _migrateFavoritesToNewFormat(SharedPreferences prefs) async {
    debugPrint("Starting favorites migration...");

    final oldFavorites = List<String>.from(_favorites);
    final newFavorites = <String>[];

    // Separate already migrated favorites from old format
    final oldFormatFavorites = <String>[];
    for (final favorite in oldFavorites) {
      if (favorite.contains(':')) {
        // Already in new format
        newFavorites.add(favorite);
      } else {
        // Old format - needs migration
        oldFormatFavorites.add(favorite);
      }
    }

    if (oldFormatFavorites.isEmpty) {
      // No migration needed
      await prefs.setBool(_migrationKey, true);
      return;
    }

    // Find songs in collections to determine correct collection IDs
    final migratedFavorites = await _findSongsInCollections(oldFormatFavorites);
    newFavorites.addAll(migratedFavorites);

    // Update favorites list
    _favorites = newFavorites;

    // Save migrated data
    await prefs.setStringList(_favoritesKey, _favorites);
    await prefs.setBool(_migrationKey, true);

    debugPrint(
        "Migration completed. Migrated ${oldFormatFavorites.length} favorites to ${migratedFavorites.length} collection-aware favorites.");
  }

  // Helper method to find songs across collections during migration
  Future<List<String>> _findSongsInCollections(List<String> songNumbers) async {
    final migratedFavorites = <String>[];
    final foundSongs = <String, String>{}; // songNumber -> collectionId

    // Search through all collections (except lpmi)
    for (final collectionEntry in AppConstants.collections.entries) {
      if (collectionEntry.key == 'lpmi') continue;

      try {
        final songs = await JsonLoaderService.loadSongsFromCollection(
            collectionEntry.key);

        for (final song in songs) {
          if (songNumbers.contains(song.songNumber)) {
            foundSongs[song.songNumber] = collectionEntry.key;
          }
        }
      } catch (e) {
        debugPrint(
            'Error loading collection ${collectionEntry.key} during migration: $e');
      }
    }

    // Create migrated favorites in new format
    for (final songNumber in songNumbers) {
      final collectionId = foundSongs[songNumber];
      if (collectionId != null) {
        migratedFavorites.add('$collectionId:$songNumber');
      } else {
        // Song not found in any collection - assume 'srd' as default
        debugPrint(
            'Warning: Song $songNumber not found in any collection during migration, defaulting to srd');
        migratedFavorites.add('srd:$songNumber');
      }
    }

    return migratedFavorites;
  }

  String _createFavoriteKey(String collectionId, String songNumber) {
    return '$collectionId:$songNumber';
  }

  bool isFavoriteInCollection(String collectionId, String songNumber) {
    final key = _createFavoriteKey(collectionId, songNumber);
    return _favorites.contains(key);
  }

  // Backward compatibility - checks any collection
  bool isFavorite(String songNumber) {
    return _favorites.any((fav) => fav.endsWith(':$songNumber'));
  }

  Future<void> addFavoriteFromCollection(
      String collectionId, String songNumber) async {
    final key = _createFavoriteKey(collectionId, songNumber);
    if (!_favorites.contains(key)) {
      _favorites.add(key);
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> removeFavoriteFromCollection(
      String collectionId, String songNumber) async {
    final key = _createFavoriteKey(collectionId, songNumber);
    if (_favorites.contains(key)) {
      _favorites.remove(key);
      await _saveFavorites();
      notifyListeners();
    }
  }

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
    // For backward compatibility, try to find the song in collections
    bool added = false;

    for (final collectionId in AppConstants.collections.keys) {
      if (collectionId == 'lpmi') continue;

      try {
        final songs =
            await JsonLoaderService.loadSongsFromCollection(collectionId);
        if (songs.any((song) => song.songNumber == songId)) {
          await addFavoriteFromCollection(collectionId, songId);
          added = true;
          break; // Add to first collection found
        }
      } catch (e) {
        // Continue searching other collections
      }
    }

    if (!added) {
      // Fallback to 'srd' collection
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

  // DEBUG: Method to manually trigger migration (for testing)
  Future<void> forceMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, false);
    await _migrateFavoritesToNewFormat(prefs);
    notifyListeners();
  }
}
