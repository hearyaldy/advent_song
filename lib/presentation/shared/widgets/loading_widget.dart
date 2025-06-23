# Complete Flutter Song Lyrics App Code

## 📄 pubspec.yaml
```yaml
name: song_lyrics_app
description: A Flutter app for song lyrics collection
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  go_router: ^12.1.3
  shared_preferences: ^2.2.2
  cupertino_icons: ^1.0.2
  equatable: ^2.0.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/data/
    - assets/images/
    - assets/images/collection_covers/
```

## 📱 lib/main.dart
```dart
import 'package:flutter/material.dart';
import 'app/app.dart';

void main() {
  runApp(const SongLyricsApp());
}
```

## 🎨 lib/app/app.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/dashboard/pages/dashboard_page.dart';
import '../presentation/song_list/pages/song_list_page.dart';
import '../presentation/lyrics_viewer/pages/lyrics_page.dart';
import 'themes/app_theme.dart';

class SongLyricsApp extends StatelessWidget {
  const SongLyricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Song Lyrics App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  static final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/collection/:collectionId',
        builder: (context, state) {
          final collectionId = state.pathParameters['collectionId']!;
          return SongListPage(collectionId: collectionId);
        },
      ),
      GoRoute(
        path: '/lyrics/:collectionId/:songId',
        builder: (context, state) {
          final collectionId = state.pathParameters['collectionId']!;
          final songId = state.pathParameters['songId']!;
          return LyricsPage(
            collectionId: collectionId,
            songId: songId,
          );
        },
      ),
    ],
  );
}
```

## 🎨 lib/app/themes/app_theme.dart
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
```

## 📊 lib/data/models/song.dart
```dart
import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final String songNumber;
  final String songTitle;
  final List<Verse> verses;

  const Song({
    required this.songNumber,
    required this.songTitle,
    required this.verses,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      songNumber: json['song_number'] as String,
      songTitle: json['song_title'] as String,
      verses: (json['verses'] as List<dynamic>)
          .map((verse) => Verse.fromJson(verse as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'song_number': songNumber,
      'song_title': songTitle,
      'verses': verses.map((verse) => verse.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [songNumber, songTitle, verses];
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
```

## 📊 lib/data/models/song_collection.dart
```dart
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
```

## 🔧 lib/core/services/json_loader_service.dart
```dart
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
```

## 📝 lib/core/constants/app_constants.dart
```dart
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
```

## 🏠 lib/presentation/dashboard/pages/dashboard_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/collection_card.dart';
import '../widgets/collapsible_header.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          CollapsibleHeader(
            title: AppConstants.appName,
            subtitle: 'Spiritual Songs Collection',
            scrollController: _scrollController,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final collections = AppConstants.collections.values.toList();
                  final collection = collections[index];
                  
                  return CollectionCard(
                    metadata: collection,
                    onTap: () {
                      context.go('/collection/${collection.id}');
                    },
                  );
                },
                childCount: AppConstants.collections.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

## 🎨 lib/presentation/dashboard/widgets/collapsible_header.dart
```dart
import 'package:flutter/material.dart';

class CollapsibleHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final ScrollController scrollController;

  const CollapsibleHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Icon(
                Icons.music_note,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 🎴 lib/presentation/dashboard/widgets/collection_card.dart
```dart
import 'package:flutter/material.dart';
import '../../../data/models/song_collection.dart';

class CollectionCard extends StatelessWidget {
  final CollectionMetadata metadata;
  final VoidCallback onTap;

  const CollectionCard({
    super.key,
    required this.metadata,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                metadata.colorTheme.withOpacity(0.8),
                metadata.colorTheme,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.library_music,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  metadata.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  metadata.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tap to explore',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

## 📃 lib/presentation/song_list/pages/song_list_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/json_loader_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/song.dart';
import '../../../data/models/song_collection.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';

class SongListPage extends StatefulWidget {
  final String collectionId;

  const SongListPage({
    super.key,
    required this.collectionId,
  });

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  late Future<SongCollection> _collectionFuture;
  List<Song> _filteredSongs = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _collectionFuture = JsonLoaderService.loadCollection(widget.collectionId);
  }

  void _filterSongs(List<Song> songs, String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSongs = songs;
      } else {
        _filteredSongs = songs.where((song) {
          return song.songTitle.toLowerCase().contains(query.toLowerCase()) ||
                 song.songNumber.contains(query) ||
                 song.verses.any((verse) => 
                   verse.lyrics.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final metadata = AppConstants.collections[widget.collectionId];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(metadata?.displayName ?? 'Songs'),
        backgroundColor: metadata?.colorTheme,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: FutureBuilder<SongCollection>(
        future: _collectionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return CustomErrorWidget(
              message: 'Failed to load songs: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _collectionFuture = JsonLoaderService.loadCollection(widget.collectionId);
                });
              },
            );
          }

          final collection = snapshot.data!;
          
          // Initialize filtered songs if not done yet
          if (_filteredSongs.isEmpty && _searchQuery.isEmpty) {
            _filteredSongs = collection.songs;
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterSongs(collection.songs, '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: (value) => _filterSongs(collection.songs, value),
                ),
              ),
              
              // Songs Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      '${_filteredSongs.length} songs',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      Text(
                        ' (filtered from ${collection.songs.length})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Songs List
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = _filteredSongs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: metadata?.colorTheme ?? Colors.blue,
                          child: Text(
                            song.songNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          song.songTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${song.verses.length} verse${song.verses.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.go('/lyrics/${widget.collectionId}/${song.songNumber}');
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
```

## 📖 lib/presentation/lyrics_viewer/pages/lyrics_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/json_loader_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/song.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';

class LyricsPage extends StatefulWidget {
  final String collectionId;
  final String songId;

  const LyricsPage({
    super.key,
    required this.collectionId,
    required this.songId,
  });

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  late Future<Song?> _songFuture;
  double _fontSize = AppConstants.defaultFontSize;

  @override
  void initState() {
    super.initState();
    _loadSong();
  }

  void _loadSong() {
    _songFuture = JsonLoaderService.loadSongsFromCollection(widget.collectionId)
        .then((songs) => JsonLoaderService.findSongById(songs, widget.songId));
  }

  void _increaseFontSize() {
    setState(() {
      if (_fontSize < AppConstants.maxFontSize) {
        _fontSize += 2;
      }
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > AppConstants.minFontSize) {
        _fontSize -= 2;
      }
    });
  }

  void _shareLyrics(Song song) {
    final lyrics = song.verses
        .map((verse) => 'Verse ${verse.verseNumber}:\n${verse.lyrics}')
        .join('\n\n');
    
    final shareText = '${song.songTitle} (#${song.songNumber})\n\n$lyrics';
    
    Clipboard.setData(ClipboardData(text: shareText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lyrics copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadata = AppConstants.collections[widget.collectionId];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Song #${widget.songId}'),
        backgroundColor: metadata?.colorTheme,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/collection/${widget.collectionId}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: _decreaseFontSize,
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: _increaseFontSize,
          ),
        ],
      ),
      body: FutureBuilder<Song?>(
        future: _songFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError || snapshot.data == null) {
            return CustomErrorWidget(
              message: snapshot.data == null 
                  ? 'Song not found'
                  : 'Failed to load song: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _loadSong();
                });
              },
            );
          }

          final song = snapshot.data!;

          return Column(
            children: [
              // Song Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: metadata?.colorTheme.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: metadata?.colorTheme ?? Colors.blue,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: metadata?.colorTheme ?? Colors.blue,
                          child: Text(
                            song.songNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            song.songTitle,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () => _shareLyrics(song),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${song.verses.length} verse${song.verses.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Font Size Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.format_size, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Font Size: ${_fontSize.toInt()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              
              // Lyrics Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: song.verses.asMap().entries.map((entry) {
                      final verse = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (song.verses.length > 1) ...[
                              Text(
                                'Verse ${verse.verseNumber}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: metadata?.colorTheme ?? Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              verse.lyrics.replaceAll('\\n', '\n'),
                              style: TextStyle(
                                fontSize: _fontSize,
                                height: 1.6,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

## 🔄 lib/presentation/shared/widgets/loading_widget.dart
```dart
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}
```

## ❌ lib/presentation/shared/widgets/error_widget.dart
```dart
import 'package:flutter/material.dart';

class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const CustomErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## 📋 Final Setup Steps

1. **Copy your JSON file:**
   ```bash
   cp path/to/your/pandak.json assets/data/
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run -d chrome  # For web testing
   ```

This complete code provides:
- ✅ Collapsible header dashboard
- ✅ Collection cards with your 4 collections
- ✅ Song list with search functionality
- ✅ Lyrics viewer with font size controls
- ✅ Navigation between pages
- ✅ Error handling and loading states
- ✅ Share/copy lyrics functionality
- ✅ Material Design 3 theming
- ✅ Responsive design