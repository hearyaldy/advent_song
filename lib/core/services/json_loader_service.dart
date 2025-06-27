// lib/core/services/json_loader_service.dart - UPDATED
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/song.dart';
import '../../data/models/song_collection.dart';
import '../constants/app_constants.dart';

class JsonLoaderService {
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

      return jsonData.map((json) {
        final songJson = json as Map<String, dynamic>;
        songJson['collection_id'] = collectionId; // Inject collection ID
        return Song.fromJson(songJson);
      }).toList();
    } catch (e) {
      debugPrint('Failed to load collection $collectionId: $e');
      return []; // Return empty list instead of throwing
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

  // UPDATED: Better error handling for migration
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
        debugPrint('Could not search collection $collectionId: $e');
        // Continue with other collections instead of failing completely
      }
    }

    if (foundSongs.isEmpty && songNumbers.isNotEmpty) {
      debugPrint('Warning: No songs found for numbers: $songNumbers');
    }

    return foundSongs;
  }

  // NEW: Helper method for migration to find song in specific collections
  static Future<Map<String, String>> findSongCollections(
      List<String> songNumbers) async {
    final Map<String, String> songToCollection = {};

    for (final collectionId in AppConstants.collections.keys) {
      if (collectionId == 'lpmi') continue;

      try {
        final songs = await loadSongsFromCollection(collectionId);
        for (final song in songs) {
          if (songNumbers.contains(song.songNumber)) {
            songToCollection[song.songNumber] = collectionId;
          }
        }
      } catch (e) {
        debugPrint('Error searching collection $collectionId: $e');
      }
    }

    return songToCollection;
  }
}
