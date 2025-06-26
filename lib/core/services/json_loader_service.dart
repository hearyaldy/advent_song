// lib/core/services/json_loader_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../data/models/song.dart';
import '../../data/models/song_collection.dart';
import '../constants/app_constants.dart';

class JsonLoaderService {
  // Your existing method - no changes
  static Future<List<Song>> loadSongsFromCollection(String collectionId) async {
    try {
      final metadata = AppConstants.collections[collectionId];
      if (metadata == null) {
        throw Exception('Collection not found: $collectionId');
      }

      final String jsonString = await rootBundle.loadString(
        'assets/data/${metadata.fileName}',
      );

      final List<dynamic> jsonData = json.decode(jsonString);

      return jsonData
          .map((json) => Song.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load songs: $e');
    }
  }

  // Your existing method - no changes
  static Future<SongCollection> loadCollection(String collectionId) async {
    try {
      final metadata = AppConstants.collections[collectionId];
      if (metadata == null) {
        throw Exception('Collection not found: $collectionId');
      }

      final songs = await loadSongsFromCollection(collectionId);

      return SongCollection(
        id: metadata.id,
        name: metadata.name,
        displayName: metadata.displayName,
        description: metadata.description,
        colorTheme: metadata.colorTheme,
        coverImage: metadata.coverImage,
        songs: songs,
      );
    } catch (e) {
      throw Exception('Failed to load collection: $e');
    }
  }

  // Your existing method - no changes
  static Song? findSongById(List<Song> songs, String songId) {
    try {
      return songs.firstWhere((song) => song.songNumber == songId);
    } catch (e) {
      return null;
    }
  }

  // --- NEW METHOD ADDED HERE ---
  // This is the missing function that your FavoritesPage needs.
  static Future<List<Song>> findSongsByNumbers(List<String> songNumbers) async {
    final List<Song> foundSongs = [];
    final Set<String> numbersToFind = songNumbers.toSet();

    // It uses your AppConstants to loop through all available collections correctly.
    for (final collectionId in AppConstants.collections.keys) {
      // If we've already found all the songs, we can stop early.
      if (numbersToFind.isEmpty) break;

      try {
        // We can reuse your existing method here!
        final songsInCollection = await loadSongsFromCollection(collectionId);

        for (final song in songsInCollection) {
          if (numbersToFind.contains(song.songNumber)) {
            // Found a match! Add it to our list.
            foundSongs.add(song);
            // And remove it from the list of songs we're still looking for.
            numbersToFind.remove(song.songNumber);
          }
        }
      } catch (e) {
        // If one collection file fails to load, we can print an error
        // but continue searching in the other collections.
        print('Could not search collection $collectionId: $e');
      }
    }
    return foundSongs;
  }
}
