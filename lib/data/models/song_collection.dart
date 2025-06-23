import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import 'song.dart';

class SongCollection extends Equatable {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final Color colorTheme;
  final String coverImage;
  final List<Song> songs;

  const SongCollection({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.colorTheme,
    required this.coverImage,
    required this.songs,
  });

  int get songCount => songs.length;

  @override
  List<Object?> get props => [
        id,
        name,
        displayName,
        description,
        colorTheme,
        coverImage,
        songs,
      ];
}

class CollectionMetadata {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String fileName;
  final Color colorTheme;
  final String coverImage;

  const CollectionMetadata({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.fileName,
    required this.colorTheme,
    required this.coverImage,
  });
}
