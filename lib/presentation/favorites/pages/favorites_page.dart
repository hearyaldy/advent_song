// lib/presentation/favorites/pages/favorites_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/favorites_notifier.dart';
import '../../../core/services/json_loader_service.dart';
import '../../../data/models/song.dart';

class FavoritesPage extends StatefulWidget {
  final FavoritesNotifier favoritesNotifier;

  const FavoritesPage({super.key, required this.favoritesNotifier});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Song>> _favoriteSongsFuture;

  @override
  void initState() {
    super.initState();
    // Use the notifier to rebuild when favorites change
    widget.favoritesNotifier.addListener(_loadFavorites);
    _loadFavorites();
  }

  @override
  void dispose() {
    widget.favoritesNotifier.removeListener(_loadFavorites);
    super.dispose();
  }

  void _loadFavorites() {
    setState(() {
      _favoriteSongsFuture = JsonLoaderService.findSongsByNumbers(
        widget.favoritesNotifier.favorites,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Songs'),
      ),
      body: FutureBuilder<List<Song>>(
        future: _favoriteSongsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final favoriteSongs = snapshot.data ?? [];

          if (favoriteSongs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Favorites Yet',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any song to add it here.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: favoriteSongs.length,
            itemBuilder: (context, index) {
              final song = favoriteSongs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(song.songTitle),
                  // We need to know the collection name. This highlights the need
                  // to add `collectionId` to your Song model in the future.
                  // For now, we can leave it blank or show the number.
                  subtitle: Text('Song No. ${song.songNumber}'),
                  trailing: const Icon(Icons.favorite, color: Colors.redAccent),
                  onTap: () {
                    // This navigation will fail until we add collectionId to the Song model.
                    // A task for our next step!
                    // context.go('/lyrics/${song.collectionId}/${song.songNumber}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
