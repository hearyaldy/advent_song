// lib/core/services/json_loader_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../data/models/song.dart';
import '../../data/models/song_collection.dart';
import '../constants/app_constants.dart';

class JsonLoaderService {
  // --- THIS IS THE UPDATED METHOD ---
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

      // This now correctly adds the collectionId to each song as it's parsed.
      return jsonData.map((json) {
        final songJson = json as Map<String, dynamic>;
        // Inject the collectionId into the JSON before creating the Song object.
        songJson['collection_id'] = collectionId;
        return Song.fromJson(songJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load songs: $e');
    }
  }

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

  static Song? findSongById(List<Song> songs, String songId) {
    try {
      return songs.firstWhere((song) => song.songNumber == songId);
    } catch (e) {
      return null;
    }
  }

  static Future<List<Song>> findSongsByNumbers(List<String> songNumbers) async {
    final List<Song> foundSongs = [];
    final Set<String> numbersToFind = songNumbers.toSet();

    for (final collectionId in AppConstants.collections.keys) {
      if (collectionId == 'lpmi') continue;

      if (numbersToFind.isEmpty) break;

      try {
        final songsInCollection = await loadSongsFromCollection(collectionId);

        for (final song in songsInCollection) {
          if (numbersToFind.contains(song.songNumber)) {
            foundSongs.add(song);
            numbersToFind.remove(song.songNumber);
          }
        }
      } catch (e) {
        print('Could not search collection $collectionId: $e');
      }
    }
    return foundSongs;
  }
}
