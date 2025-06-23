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
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          metadata?.colorTheme ?? Colors.blue,
                                    ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              verse.lyrics.replaceAll('\\n', '\n'),
                              style: TextStyle(
                                fontSize: _fontSize,
                                height: 1.6,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
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
