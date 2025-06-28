// lib/core/services/favorites_notifier.dart - ENHANCED WITH BETTER PERSISTENCE
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'json_loader_service.dart';

class FavoritesNotifier extends ChangeNotifier {
  static const String _favoritesKey = 'favorite_songs';
  static const String _migrationKey =
      'favorites_migrated_v3'; // Updated version
  static const String _backupKey = 'favorite_songs_backup';
  static const String _lastSaveTimeKey = 'favorites_last_save_time';
  static const String _favoritesVersionKey = 'favorites_version';

  // Current version for favorites format
  static const int _currentVersion = 3;

  List<String> _favorites = [];
  bool _isInitialized = false;
  DateTime? _lastSaveTime;

  List<String> get favorites => List.unmodifiable(_favorites);
  bool get isInitialized => _isInitialized;
  int get favoritesCount => _favorites.length;
  DateTime? get lastSaveTime => _lastSaveTime;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load last save time
      final lastSaveMillis = prefs.getInt(_lastSaveTimeKey);
      if (lastSaveMillis != null) {
        _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(lastSaveMillis);
        debugPrint("Favorites last saved: $_lastSaveTime");
      }

      // Check version
      final storedVersion = prefs.getInt(_favoritesVersionKey) ?? 0;
      debugPrint(
          "Stored favorites version: $storedVersion, Current version: $_currentVersion");

      // Try to load favorites
      _favorites = prefs.getStringList(_favoritesKey) ?? [];
      debugPrint("Loaded ${_favorites.length} favorites from storage");

      // If favorites are empty, try to restore from backup
      if (_favorites.isEmpty) {
        final backup = prefs.getStringList(_backupKey);
        if (backup != null && backup.isNotEmpty) {
          debugPrint("Restoring ${backup.length} favorites from backup");
          _favorites = List.from(backup);
          await _saveFavorites();
        }
      }

      // Check if migration is needed
      final migrationCompleted = prefs.getBool(_migrationKey) ?? false;

      if (!migrationCompleted && _favorites.isNotEmpty ||
          storedVersion < _currentVersion) {
        await _migrateFavoritesToNewFormat(prefs);
      }

      // Update version
      await prefs.setInt(_favoritesVersionKey, _currentVersion);

      // Create backup after successful load
      if (_favorites.isNotEmpty) {
        await prefs.setStringList(_backupKey, List.from(_favorites));
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
      _favorites = [];
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Enhanced migration with better error handling
  Future<void> _migrateFavoritesToNewFormat(SharedPreferences prefs) async {
    debugPrint("Starting favorites migration...");

    // Backup current favorites before migration
    final backupBeforeMigration = List<String>.from(_favorites);
    await prefs.setStringList(
        '${_backupKey}_pre_migration', backupBeforeMigration);

    final oldFavorites = List<String>.from(_favorites);
    final newFavorites = <String>[];

    // Separate already migrated favorites from old format
    final oldFormatFavorites = <String>[];
    for (final favorite in oldFavorites) {
      if (favorite.contains(':')) {
        // Already in new format, validate it
        final parts = favorite.split(':');
        if (parts.length == 2 &&
            AppConstants.collections.containsKey(parts[0])) {
          newFavorites.add(favorite);
        } else {
          debugPrint("Invalid favorite format: $favorite");
          // Try to recover
          oldFormatFavorites.add(parts.length > 1 ? parts[1] : favorite);
        }
      } else {
        // Old format - needs migration
        oldFormatFavorites.add(favorite);
      }
    }

    if (oldFormatFavorites.isEmpty) {
      // No migration needed, but ensure we save the validated favorites
      _favorites = newFavorites;
      await prefs.setStringList(_favoritesKey, _favorites);
      await prefs.setBool(_migrationKey, true);
      debugPrint(
          "No migration needed. Validated ${newFavorites.length} favorites.");
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
    final notFoundSongs = <String>[];

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
        notFoundSongs.add(songNumber);
        // Song not found in any collection - assume 'srd' as default
        debugPrint(
            'Warning: Song $songNumber not found in any collection during migration, defaulting to srd');
        migratedFavorites.add('srd:$songNumber');
      }
    }

    if (notFoundSongs.isNotEmpty) {
      debugPrint(
          'Songs not found during migration: ${notFoundSongs.join(", ")}');
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
      // Create backup before clearing
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          '${_backupKey}_before_clear', List.from(_favorites));

      _favorites.clear();
      await _saveFavorites();
      notifyListeners();
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save favorites
      await prefs.setStringList(_favoritesKey, _favorites);

      // Save timestamp
      final now = DateTime.now();
      await prefs.setInt(_lastSaveTimeKey, now.millisecondsSinceEpoch);
      _lastSaveTime = now;

      // Create backup
      if (_favorites.isNotEmpty) {
        await prefs.setStringList(_backupKey, List.from(_favorites));
      }

      debugPrint("Saved ${_favorites.length} favorites at $_lastSaveTime");
    } catch (e) {
      debugPrint("Error saving favorites: $e");
    }
  }

  // Method to restore from backup
  Future<bool> restoreFromBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backup = prefs.getStringList(_backupKey);

      if (backup != null && backup.isNotEmpty) {
        _favorites = List.from(backup);
        await _saveFavorites();
        notifyListeners();
        debugPrint("Restored ${backup.length} favorites from backup");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error restoring from backup: $e");
      return false;
    }
  }

  // Method to check data integrity
  Future<void> validateFavorites() async {
    debugPrint("Validating favorites...");
    final validFavorites = <String>[];
    final invalidFavorites = <String>[];

    for (final favorite in _favorites) {
      final parts = favorite.split(':');
      if (parts.length == 2 && AppConstants.collections.containsKey(parts[0])) {
        validFavorites.add(favorite);
      } else {
        invalidFavorites.add(favorite);
      }
    }

    if (invalidFavorites.isNotEmpty) {
      debugPrint(
          "Found ${invalidFavorites.length} invalid favorites: $invalidFavorites");
      _favorites = validFavorites;
      await _saveFavorites();
      notifyListeners();
    } else {
      debugPrint("All ${_favorites.length} favorites are valid");
    }
  }

  // DEBUG: Method to manually trigger migration (for testing)
  Future<void> forceMigration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey, false);
    await _migrateFavoritesToNewFormat(prefs);
    notifyListeners();
  }

  // Method to get diagnostic info
  Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'favorites_count': _favorites.length,
      'last_save_time': _lastSaveTime?.toIso8601String() ?? 'Never',
      'migration_completed': prefs.getBool(_migrationKey) ?? false,
      'favorites_version': prefs.getInt(_favoritesVersionKey) ?? 0,
      'has_backup': (prefs.getStringList(_backupKey)?.isNotEmpty ?? false),
      'favorites_sample': _favorites.take(5).toList(),
    };
  }
}
