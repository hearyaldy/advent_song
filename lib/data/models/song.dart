// lib/data/models/song.dart - UPDATED
import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final String? collectionId;
  final String songNumber;
  final String songTitle;
  final List<Verse> verses;

  const Song({
    this.collectionId,
    required this.songNumber,
    required this.songTitle,
    required this.verses,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      collectionId: json['collection_id'] as String?, // FIXED: Added this line
      songNumber: json['song_number'] as String,
      songTitle: json['song_title'] as String,
      verses: (json['verses'] as List<dynamic>)
          .map((verse) => Verse.fromJson(verse as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'collection_id': collectionId,
      'song_number': songNumber,
      'song_title': songTitle,
      'verses': verses.map((verse) => verse.toJson()).toList(),
    };
  }

  Song copyWith({
    String? collectionId,
  }) {
    return Song(
      collectionId: collectionId ?? this.collectionId,
      songNumber: songNumber,
      songTitle: songTitle,
      verses: verses,
    );
  }

  @override
  List<Object?> get props => [collectionId, songNumber, songTitle, verses];
}

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
