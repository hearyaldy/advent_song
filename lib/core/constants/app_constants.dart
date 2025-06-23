import 'package:flutter/material.dart';
import '../../data/models/song_collection.dart';

class AppConstants {
  static const String appName = 'Song Lyrics App';

  static const Map<String, CollectionMetadata> collections = {
    'pandak': CollectionMetadata(
      id: 'pandak',
      name: 'LAGU_PANDAK',
      displayName: 'Lagu Pandak',
      description: 'Collection of short spiritual songs',
      fileName: 'pandak.json',
      colorTheme: Color(0xFF4CAF50),
      coverImage: 'assets/images/collection_covers/pandak_cover.png',
    ),
    'lpmi': CollectionMetadata(
      id: 'lpmi',
      name: 'LPMI',
      displayName: 'Lagu Pujian Malayu Iban',
      description: 'Traditional praise songs collection',
      fileName: 'lpmi.json',
      colorTheme: Color(0xFF2196F3),
      coverImage: 'assets/images/collection_covers/lpmi_cover.png',
    ),
    'srd': CollectionMetadata(
      id: 'srd',
      name: 'SRD',
      displayName: 'SRD Collection',
      description: 'Special religious devotion songs',
      fileName: 'srd.json',
      colorTheme: Color(0xFFFF9800),
      coverImage: 'assets/images/collection_covers/srd_cover.png',
    ),
    'lagu_iban': CollectionMetadata(
      id: 'lagu_iban',
      name: 'LAGU_IBAN',
      displayName: 'Lagu Iban',
      description: 'Traditional Iban songs collection',
      fileName: 'lagu_iban.json',
      colorTheme: Color(0xFF9C27B0),
      coverImage: 'assets/images/collection_covers/lagu_iban_cover.png',
    ),
  };

  static const double defaultFontSize = 16.0;
  static const double minFontSize = 12.0;
  static const double maxFontSize = 24.0;
}
