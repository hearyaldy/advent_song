// lib/presentation/lyrics_viewer/pages/lyrics_page.dart - UPDATED WITH SONG VALIDATION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/json_loader_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/favorites_notifier.dart';
import '../../../data/models/song.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_widget.dart';
import '../../shared/pages/not_found_page.dart';

class LyricsPage extends StatefulWidget {
  final String collectionId;
  final String songId;
  final FavoritesNotifier favoritesNotifier;

  const LyricsPage({
    super.key,
    required this.collectionId,
    required this.songId,
    required this.favoritesNotifier,
  });

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  late Future<Song?> _songFuture;
  double _fontSize = AppConstants.defaultFontSize;
  String _fontFamily = 'Roboto';
  TextAlign _textAlign = TextAlign.left;
  bool _isLoading = true;
  bool _songNotFound = false;

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
    _songFuture = _loadSongWithValidation();
  }

  // UPDATED: Enhanced song loading with validation
  Future<Song?> _loadSongWithValidation() async {
    try {
      final songs =
          await JsonLoaderService.loadSongsFromCollection(widget.collectionId);
      final song = JsonLoaderService.findSongById(songs, widget.songId);

      if (song == null) {
        if (mounted) {
          setState(() {
            _songNotFound = true;
          });
        }
      }

      return song;
    } catch (e) {
      debugPrint('Error loading song: $e');
      if (mounted) {
        setState(() {
          _songNotFound = true;
        });
      }
      return null;
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _fontSize =
              prefs.getDouble('fontSize') ?? AppConstants.defaultFontSize;
          _fontFamily = prefs.getString('fontFamily') ?? 'Roboto';
          _textAlign = TextAlign.values[prefs.getInt('textAlign') ?? 0];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      await widget.favoritesNotifier
          .toggleFavoriteFromCollection(widget.collectionId, widget.songId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.favoritesNotifier.isFavoriteInCollection(
                      widget.collectionId, widget.songId)
                  ? 'Added to favorites'
                  : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating favorites')),
        );
      }
    }
  }

  Future<void> _shareSong(Song song) async {
    try {
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
    } catch (e) {
      debugPrint('Error sharing song: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error sharing song')),
        );
      }
    }
  }

  Future<void> _copyToClipboard(Song song) async {
    try {
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
    } catch (e) {
      debugPrint('Error copying song: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error copying song')),
        );
      }
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
    if (mounted) {
      setState(() {
        if (_fontSize < AppConstants.maxFontSize) {
          _fontSize += 2;
        }
      });
    }
  }

  void _decreaseFontSize() {
    if (mounted) {
      setState(() {
        if (_fontSize > AppConstants.minFontSize) {
          _fontSize -= 2;
        }
      });
    }
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

    // UPDATED: Show not found page for invalid songs
    if (_songNotFound) {
      return NotFoundPage(
        title: 'Song Not Found',
        message:
            'Song "${widget.songId}" was not found in ${metadata?.displayName ?? 'this collection'}.',
        actionText: 'Browse Collection',
        onAction: () => context.go('/collection/${widget.collectionId}'),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: AnimatedBuilder(
        animation: widget.favoritesNotifier,
        builder: (context, child) {
          return FutureBuilder<Song?>(
            future: _songFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }

              if (snapshot.hasError) {
                return CustomErrorWidget(
                  message: 'Failed to load song: ${snapshot.error}',
                  onRetry: () {
                    if (mounted) {
                      setState(() {
                        _songNotFound = false;
                        _loadSong();
                      });
                    }
                  },
                );
              }

              final song = snapshot.data;
              if (song == null) {
                return NotFoundPage(
                  title: 'Song Not Found',
                  message:
                      'Song "${widget.songId}" was not found in ${metadata?.displayName ?? 'this collection'}.',
                  actionText: 'Browse Collection',
                  onAction: () =>
                      context.go('/collection/${widget.collectionId}'),
                );
              }

              final isFavorite = widget.favoritesNotifier
                  .isFavoriteInCollection(widget.collectionId, widget.songId);

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    expandedHeight: 200,
                    pinned: true,
                    backgroundColor:
                        metadata?.colorTheme ?? colorScheme.primary,
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
                          Image.asset(
                            metadata?.coverImage ??
                                'assets/images/header_image.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
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
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
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
                                          color: Colors.black54),
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
                        icon: Icon(isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border),
                        onPressed: _toggleFavorite,
                        tooltip: isFavorite
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
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.format_size, size: 16),
                          const SizedBox(width: 8),
                          Text('Font Size: ${_fontSize.toInt()}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 16.0),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToTop,
        tooltip: 'Scroll to top',
        mini: true,
        child: const Icon(Icons.keyboard_arrow_up),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: widget.favoritesNotifier,
        builder: (context, child) {
          return FutureBuilder<Song?>(
            future: _songFuture,
            builder: (context, snapshot) {
              if (snapshot.data == null) return const SizedBox();
              final song = snapshot.data!;
              final isFavorite = widget.favoritesNotifier
                  .isFavoriteInCollection(widget.collectionId, widget.songId);

              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top:
                        BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _toggleFavorite,
                          icon: Icon(isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border),
                          label: Text(
                              isFavorite ? 'Favorited' : 'Add to Favorites'),
                          style: FilledButton.styleFrom(
                            backgroundColor: isFavorite
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
          );
        },
      ),
    );
  }
}
