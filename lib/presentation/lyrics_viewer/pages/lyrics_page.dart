// lib/presentation/lyrics_viewer/pages/lyrics_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String _fontFamily = 'Roboto';
  TextAlign _textAlign = TextAlign.left;
  bool _isFavorite = false;
  bool _isLoading = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSong();
    _loadSettings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadSong() {
    _songFuture = JsonLoaderService.loadSongsFromCollection(widget.collectionId)
        .then((songs) => JsonLoaderService.findSongById(songs, widget.songId));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteSongs = prefs.getStringList('favorites') ?? [];

    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? AppConstants.defaultFontSize;
      _fontFamily = prefs.getString('fontFamily') ?? 'Roboto';
      _textAlign = TextAlign.values[prefs.getInt('textAlign') ?? 0];
      _isFavorite = favoriteSongs.contains(widget.songId);
      _isLoading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteSongs = prefs.getStringList('favorites') ?? [];

    if (_isFavorite) {
      favoriteSongs.remove(widget.songId);
    } else {
      favoriteSongs.add(widget.songId);
    }

    await prefs.setStringList('favorites', favoriteSongs);
    setState(() {
      _isFavorite = !_isFavorite;
    });

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _shareSong(Song song) async {
    final lyrics = song.verses
        .map((verse) => 'Verse ${verse.verseNumber}:\n${verse.lyrics}')
        .join('\n\n');

    final metadata = AppConstants.collections[widget.collectionId];
    final shareText = '''${song.songTitle}
From: ${metadata?.displayName ?? 'Unknown Collection'}
Song #${song.songNumber}

$lyrics

Shared from ${AppConstants.appName}''';

    await Clipboard.setData(ClipboardData(text: shareText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyToClipboard(Song song) async {
    final lyrics = song.verses
        .map((verse) => '${verse.verseNumber}\n${verse.lyrics}')
        .join('\n\n');

    final metadata = AppConstants.collections[widget.collectionId];
    final songText = '''${song.songTitle}
From: ${metadata?.displayName ?? 'Unknown Collection'}
Song #${song.songNumber}

$lyrics''';

    await Clipboard.setData(ClipboardData(text: songText));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Song copied to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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

  @override
  Widget build(BuildContext context) {
    final metadata = AppConstants.collections[widget.collectionId];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
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

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App bar with header image
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: metadata?.colorTheme ?? colorScheme.primary,
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      context.go('/collection/${widget.collectionId}'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              metadata?.colorTheme ?? colorScheme.primary,
                              colorScheme.secondary,
                            ],
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/header_image.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    metadata?.colorTheme ?? colorScheme.primary,
                                    colorScheme.secondary,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${song.songNumber} | ${metadata?.displayName ?? 'Unknown Collection'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              song.songTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                    ),
                    onPressed: _toggleFavorite,
                    tooltip: _isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'share':
                          _shareSong(song);
                          break;
                        case 'copy':
                          _copyToClipboard(song);
                          break;
                        case 'settings':
                          context.go('/settings');
                          break;
                        case 'font_increase':
                          _increaseFontSize();
                          break;
                        case 'font_decrease':
                          _decreaseFontSize();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'font_decrease',
                        child: ListTile(
                          leading: Icon(Icons.text_decrease),
                          title: Text('Decrease Font'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'font_increase',
                        child: ListTile(
                          leading: Icon(Icons.text_increase),
                          title: Text('Increase Font'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share),
                          title: Text('Share'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('Copy'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Settings'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Font Size Indicator
              SliverToBoxAdapter(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ),

              // Song verses
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 16.0,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final verse = song.verses[index];
                      final isKorus =
                          verse.verseNumber.toLowerCase() == 'korus';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Verse number/title
                            if (song.verses.length > 1)
                              Text(
                                verse.verseNumber,
                                style: TextStyle(
                                  fontSize: _fontSize + 6,
                                  fontFamily: _fontFamily,
                                  fontStyle: isKorus
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                  fontWeight: FontWeight.bold,
                                  color: isKorus
                                      ? colorScheme.secondary
                                      : (metadata?.colorTheme ??
                                          colorScheme.primary),
                                ),
                              ),
                            if (song.verses.length > 1)
                              const SizedBox(height: 12),
                            // Verse lyrics
                            SelectableText(
                              verse.lyrics.replaceAll('\\n', '\n'),
                              style: TextStyle(
                                fontSize: _fontSize,
                                fontFamily: _fontFamily,
                                fontStyle: isKorus
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                color: colorScheme.onSurface,
                                height: 1.8,
                                letterSpacing: 0.3,
                              ),
                              textAlign: _textAlign,
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: song.verses.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToTop,
        tooltip: 'Scroll to top',
        mini: true,
        child: const Icon(Icons.keyboard_arrow_up),
      ),
      bottomNavigationBar: FutureBuilder<Song?>(
        future: _songFuture,
        builder: (context, snapshot) {
          if (snapshot.data == null) return const SizedBox();
          final song = snapshot.data!;

          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                      ),
                      label:
                          Text(_isFavorite ? 'Favorited' : 'Add to Favorites'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _isFavorite
                            ? colorScheme.error
                            : (metadata?.colorTheme ?? colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonal(
                    onPressed: () => _shareSong(song),
                    child: const Icon(Icons.share),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () => _copyToClipboard(song),
                    child: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
