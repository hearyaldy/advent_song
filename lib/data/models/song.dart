import 'package:equatable/equatable.dart';

class Song extends Equatable {
  // --- 1. NEW FIELD ADDED ---
  // This will hold the ID of the collection the song belongs to.
  // It's nullable ('?') because it's not in the original JSON file.
  final String? collectionId;

  final String songNumber;
  final String songTitle;
  final List<Verse> verses;

  const Song({
    // --- 2. CONSTRUCTOR UPDATED ---
    this.collectionId,
    required this.songNumber,
    required this.songTitle,
    required this.verses,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      // The collectionId is not added here because it doesn't exist in the JSON.
      songNumber: json['song_number'] as String,
      songTitle: json['song_title'] as String,
      verses: (json['verses'] as List<dynamic>)
          .map((verse) => Verse.fromJson(verse as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // --- 5. toJson UPDATED (Good Practice) ---
      'collectionId': collectionId,
      'song_number': songNumber,
      'song_title': songTitle,
      'verses': verses.map((verse) => verse.toJson()).toList(),
    };
  }

  // --- 3. NEW HELPER METHOD ADDED ---
  // This allows us to create a copy of a song with new values.
  // We will use this in the JsonLoaderService to add the collectionId.
  Song copyWith({
    String? collectionId,
  }) {
    return Song(
      collectionId: collectionId ?? this.collectionId,
      songNumber: this.songNumber,
      songTitle: this.songTitle,
      verses: this.verses,
    );
  }

  @override
  // --- 4. PROPS UPDATED for Equatable ---
  // Add collectionId to the props list for correct object comparison.
  List<Object?> get props => [collectionId, songNumber, songTitle, verses];
}

// The Verse class remains unchanged.
class Verse extends Equatable {
  final String verseNumber;
  final String lyrics;

  const Verse({
    required this.verseNumber,
    required this.lyrics,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      verseNumber: json['verse_number'] as String,
      lyrics: json['lyrics'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verse_number': verseNumber,
      'lyrics': lyrics,
    };
  }

  @override
  List<Object?> get props => [verseNumber, lyrics];
}
