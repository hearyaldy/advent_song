// lib/presentation/favorites/pages/favorites_page.dart - UPDATED
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
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
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.favoritesNotifier.addListener(_loadFavorites);
    _loadFavorites();
  }

  @override
  void dispose() {
    widget.favoritesNotifier.removeListener(_loadFavorites);
    super.dispose();
  }

  void _loadFavorites() {
    if (mounted) {
      setState(() {
        _favoriteSongsFuture = _loadFavoriteSongs();
      });
    }
  }

  Future<List<Song>> _loadFavoriteSongs() async {
    final favoritesByCollection =
        widget.favoritesNotifier.getFavoritesByCollection();
    final List<Song> allFavoriteSongs = [];

    for (final entry in favoritesByCollection.entries) {
      final collectionId = entry.key;
      final songNumbers = entry.value;

      try {
        final songs =
            await JsonLoaderService.loadSongsFromCollection(collectionId);
        final favoriteSongs = songs
            .where((song) => songNumbers.contains(song.songNumber))
            .toList();

        allFavoriteSongs.addAll(favoriteSongs);
      } catch (e) {
        debugPrint('Error loading favorites from $collectionId: $e');
      }
    }

    allFavoriteSongs.sort((a, b) {
      final collectionCompare =
          (a.collectionId ?? '').compareTo(b.collectionId ?? '');
      if (collectionCompare != 0) return collectionCompare;

      final aNum = int.tryParse(a.songNumber) ?? 0;
      final bNum = int.tryParse(b.songNumber) ?? 0;
      return aNum.compareTo(bNum);
    });

    return allFavoriteSongs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Song>>(
        future: _favoriteSongsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading favorites: ${snapshot.error}'));
          }

          final favoriteSongs = snapshot.data ?? [];

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(context, favoriteSongs.length),
            ],
            body: favoriteSongs.isEmpty
                ? _buildEmptyState()
                : _buildFavoritesList(favoriteSongs),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, int count) {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surface,
      elevation: 1,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        centerTitle: false,
        title: Text(
          'Favorite Songs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              const Shadow(
                  color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/header_image.png',
              fit: BoxFit.cover,
              color: Colors.redAccent.withOpacity(0.3),
              colorBlendMode: BlendMode.multiply,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.redAccent.withOpacity(0.8),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(
            child: Chip(
              label: Text('$count Songs'),
              backgroundColor: theme.colorScheme.primaryContainer,
              labelStyle:
                  TextStyle(color: theme.colorScheme.onPrimaryContainer),
              side: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesList(List<Song> favoriteSongs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: favoriteSongs.length,
      itemBuilder: (context, index) {
        final song = favoriteSongs[index];
        return _buildFavoriteSongCard(song);
      },
    );
  }

  Widget _buildFavoriteSongCard(Song song) {
    final theme = Theme.of(context);
    final collectionMeta = AppConstants.collections[song.collectionId];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              (collectionMeta?.colorTheme ?? theme.colorScheme.primary)
                  .withAlpha(25),
          child: Text(
            song.songNumber,
            style: TextStyle(
              color: collectionMeta?.colorTheme ?? theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(song.songTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
          collectionMeta?.displayName ?? 'Unknown Collection',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.go('/lyrics/${song.collectionId}/${song.songNumber}');
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorites Yet',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any song to add it to this list.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) {
        if (mounted) {
          setState(() => _selectedNavIndex = index);
        }
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/collection/srd');
            break;
          case 2:
            context.go('/sermons');
            break;
          case 3:
            context.go('/settings');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(
            icon: Icon(Icons.music_note_rounded), label: 'Songs'),
        BottomNavigationBarItem(
            icon: Icon(Icons.church_rounded), label: 'Sermons'),
        BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ],
    );
  }
}
