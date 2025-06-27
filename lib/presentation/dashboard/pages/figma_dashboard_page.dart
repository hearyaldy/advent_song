// lib/presentation/dashboard/pages/figma_dashboard_page.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/json_loader_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/favorites_notifier.dart';

class FigmaDashboardPage extends StatefulWidget {
  final FavoritesNotifier favoritesNotifier;

  const FigmaDashboardPage({super.key, required this.favoritesNotifier});

  @override
  State<FigmaDashboardPage> createState() => _FigmaDashboardPageState();
}

class _FigmaDashboardPageState extends State<FigmaDashboardPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _verseOfTheDay;
  List<Map<String, dynamic>> _recentFavorites = [];
  final Map<String, int> _collectionCounts = {};
  bool _isLoading = true;
  String _currentDate = '';
  String _greeting = '';
  IconData _greetingIcon = Icons.wb_sunny_rounded;
  String _userName = 'Guest';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _initializePage();
    widget.favoritesNotifier.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.favoritesNotifier.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    _loadRecentFavorites().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializePage() async {
    await Future.wait([
      _loadCollectionCounts(),
      _loadRecentFavorites(),
      _loadVerseOfTheDay(),
      _loadUserInfo(),
    ]);
    _setGreetingAndDate();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  Future<void> _loadUserInfo() async {
    if (AuthService.isLoggedIn) {
      _userName = AuthService.userName;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('userName') ?? 'Guest';
    }
  }

  void _setGreetingAndDate() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour < 12) {
      _greeting = 'Good Morning';
      _greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
      _greetingIcon = Icons.wb_sunny_rounded;
    } else {
      _greeting = 'Good Evening';
      _greetingIcon = Icons.nightlight_round;
    }
    _currentDate = DateFormat('EEEE, MMMM d').format(now);
  }

  Future<void> _loadCollectionCounts() async {
    for (final entry in AppConstants.collections.entries) {
      if (entry.key == 'lpmi') continue;
      try {
        final songs =
            await JsonLoaderService.loadSongsFromCollection(entry.key);
        _collectionCounts[entry.key] = songs.length;
      } catch (e) {
        _collectionCounts[entry.key] = 0;
      }
    }
  }

  Future<void> _loadRecentFavorites() async {
    final favoriteSongNumbers =
        widget.favoritesNotifier.favorites.reversed.take(3).toList();
    if (favoriteSongNumbers.isEmpty) {
      if (mounted) {
        setState(() {
          _recentFavorites = [];
        });
      }
      return;
    }

    final foundSongs =
        await JsonLoaderService.findSongsByNumbers(favoriteSongNumbers);

    final validSongs = foundSongs
        .where(
            (song) => AppConstants.collections.containsKey(song.collectionId))
        .toList();

    _recentFavorites = validSongs.map((song) {
      final collectionInfo = AppConstants.collections[song.collectionId]!;
      return {
        'song_number': song.songNumber,
        'song_title': song.songTitle,
        'collection': collectionInfo.displayName,
        'collection_id': song.collectionId,
      };
    }).toList();
  }

  Future<void> _loadVerseOfTheDay() async {
    try {
      final allVerses = <Map<String, dynamic>>[];
      for (final entry in AppConstants.collections.entries) {
        if (entry.key == 'lpmi') continue;
        try {
          final songs =
              await JsonLoaderService.loadSongsFromCollection(entry.key);
          for (var song in songs) {
            if (song.verses.isNotEmpty) {
              final randomVerse =
                  song.verses[Random().nextInt(song.verses.length)];
              allVerses.add({
                'song_title': song.songTitle,
                'song_number': song.songNumber,
                'collection_id': entry.key,
                'lyrics': randomVerse.lyrics,
              });
            }
          }
        } catch (e) {}
      }

      if (allVerses.isNotEmpty) {
        final today = DateTime.now();
        final seed = today.year * 10000 + today.month * 100 + today.day;
        final random = Random(seed);
        _verseOfTheDay = allVerses[random.nextInt(allVerses.length)];
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader('Verse of the Day'),
                  const SizedBox(height: 16),
                  if (_verseOfTheDay != null) _buildVerseOfTheDayCard(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Quick Access'),
                  const SizedBox(height: 16),
                  _buildQuickAccessCarousel(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Explore Collections'),
                  const SizedBox(height: 16),
                  _buildCollectionsCarousel(),
                  const SizedBox(height: 32),
                  if (_recentFavorites.isNotEmpty) ...[
                    _buildSectionHeader(
                      'Recent Favorites',
                      onViewAll: () => context.go('/favorites'),
                    ),
                    const SizedBox(height: 16),
                    _buildRecentFavoritesList(),
                  ]
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 240,
      floating: false,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 1,
      surfaceTintColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/header_image.png',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(_greetingIcon,
                                  color: Colors.white, size: 32),
                              const SizedBox(width: 12),
                              Text(
                                _greeting,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 44.0),
                            child: Text(
                              _userName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => context
                            .go(AuthService.isLoggedIn ? '/profile' : '/login'),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Icon(
                            AuthService.isLoggedIn ? Icons.person : Icons.login,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.go('/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Text(
                            'Search songs and sermons...',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildVerseOfTheDayCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final collectionId = _verseOfTheDay!['collection_id'];
          final songNumber = _verseOfTheDay!['song_number'];
          if (collectionId != null && songNumber != null) {
            context.go('/lyrics/$collectionId/$songNumber');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${_verseOfTheDay!['lyrics']?.toString() ?? 'No lyrics available'}"',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                '— ${_verseOfTheDay!['song_title']?.toString() ?? 'Unknown'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessCarousel() {
    final theme = Theme.of(context);
    final actions = [
      {
        'icon': Icons.favorite_rounded,
        'label': 'Favorites',
        'route': '/favorites',
        'color': Colors.red.shade400
      },
      {
        'icon': Icons.music_note_rounded,
        'label': 'Songs',
        'route': '/collection/srd',
        'color': Colors.blue.shade400
      },
      {
        'icon': Icons.church_rounded,
        'label': 'Sermons',
        'route': '/sermons',
        'color': Colors.purple.shade400
      },
      {
        'icon': Icons.settings_rounded,
        'label': 'Settings',
        'route': '/settings',
        'color': Colors.orange.shade400
      },
    ];

    return SizedBox(
      height: 95,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        padding: const EdgeInsets.symmetric(horizontal: 1),
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final action = actions[index];
          final color = action['color'] as Color;

          return AspectRatio(
            aspectRatio: 1,
            child: Card(
              elevation: 4,
              shadowColor: color.withOpacity(0.3),
              color: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.go(action['route'] as String),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action['label'] as String,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCollectionsCarousel() {
    final collections =
        AppConstants.collections.values.where((c) => c.id != 'lpmi').toList();
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: collections.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final collection = collections[index];
          return AspectRatio(
            aspectRatio: 4 / 5,
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () => context.go('/collection/${collection.id}'),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(collection.coverImage, fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.6)
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCollectionIcon(collection.id),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Text(
                        collection.displayName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4)
                            ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentFavoritesList() {
    final theme = Theme.of(context);
    return Column(
      children: _recentFavorites.map((song) {
        return Card(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              song['song_title']?.toString() ?? 'Unknown',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(song['collection']?.toString() ?? 'Unknown'),
            leading: Icon(Icons.music_note, color: theme.colorScheme.primary),
            trailing: const Icon(Icons.favorite, color: Colors.redAccent),
            onTap: () {
              final collectionId = song['collection_id'];
              final songNumber = song['song_number'];
              if (collectionId != null && songNumber != null) {
                context.go('/lyrics/$collectionId/$songNumber');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Error: Could not find song details.')),
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }

  IconData _getCollectionIcon(String collectionId) {
    switch (collectionId) {
      case 'srd':
        return Icons.auto_stories_rounded;
      case 'lagu_iban':
        return Icons.language_rounded;
      case 'pandak':
        return Icons.celebration_rounded;
      default:
        return Icons.library_music_rounded;
    }
  }
}
