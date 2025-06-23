import 'dart:convert';
import 'package:flutter/services.dart';
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

      return jsonData
          .map((json) => Song.fromJson(json as Map<String, dynamic>))
          .toList();
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
}
