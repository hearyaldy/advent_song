// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';
import '../../data/models/song_collection.dart';

class AppConstants {
  static const String appName = 'Song Lyrics App';

  static const Map<String, CollectionMetadata> collections = {
    'lpmi': CollectionMetadata(
      id: 'lpmi',
      name: 'LPMI',
      displayName: 'Lagu Pujian Masa Ini',
      description: 'Collection of short spiritual songs',
      fileName: 'lpmi.json',
      colorTheme: Color(0xFF4CAF50),
      coverImage: 'assets/images/collection_covers/lpmi_cover.jpg',
    ),
    'srd': CollectionMetadata(
      id: 'srd',
      name: 'SRD',
      displayName: 'Syair Rindu Dendam',
      description: 'Traditional praise songs collection',
      fileName: 'srd.json',
      colorTheme: Color(0xFF2196F3),
      coverImage: 'assets/images/collection_covers/srd_cover.jpg',
    ),
    'lagu_iban': CollectionMetadata(
      id: 'lagu_iban',
      name: 'lagu_iban',
      displayName: 'Lagu Iban',
      description: 'Special religious devotion songs',
      fileName: 'iban.json',
      colorTheme: Color(0xFFFF9800),
      coverImage: 'assets/images/collection_covers/iban_cover.jpg',
    ),
    'pandak': CollectionMetadata(
      id: 'pandak',
      name: 'LAGU_PANDAK',
      displayName: 'Lagu Pandak',
      description: 'Traditional Iban songs collection',
      fileName:
          'pandak.json', // ✅ Fixed: Changed from 'lagu_iban.json' to 'iban.json'
      colorTheme: Color(0xFF9C27B0),
      coverImage: 'assets/images/collection_covers/pandak_cover.jpg',
    ),
  };

  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
}
