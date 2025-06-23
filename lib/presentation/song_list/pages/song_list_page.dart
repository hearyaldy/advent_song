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
                  _collectionFuture =
                      JsonLoaderService.loadCollection(widget.collectionId);
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
                          context.go(
                              '/lyrics/${widget.collectionId}/${song.songNumber}');
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
