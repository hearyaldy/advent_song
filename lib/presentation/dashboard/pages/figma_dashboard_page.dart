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
  String _userName = 'Guest';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializePage();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await Future.wait([
      _loadCollectionCounts(),
      _loadRecentFavorites(),
      _loadVerseOfTheDay(),
      _loadUserInfo(),
    ]);
    _setGreetingAndDate();
    setState(() {
      _isLoading = false;
    });
    _animationController.forward();
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
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }

    _currentDate = DateFormat('EEEE, MMMM d').format(now);
  }

  Future<void> _loadCollectionCounts() async {
    for (final entry in AppConstants.collections.entries) {
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
    final favoriteSongs = widget.favoritesNotifier.favorites;

    if (favoriteSongs.isEmpty) return;

    List<Map<String, dynamic>> allSongs = [];

    for (final entry in AppConstants.collections.entries) {
      try {
        final songs =
            await JsonLoaderService.loadSongsFromCollection(entry.key);
        for (var song in songs) {
          allSongs.add({
            'song_number': song.songNumber,
            'song_title': song.songTitle,
            'verses': song.verses
                .map((v) => {
                      'verse_number': v.verseNumber,
                      'lyrics': v.lyrics,
                    })
                .toList(),
            'collection': AppConstants.collections[entry.key]!.displayName,
            'collection_id': entry.key,
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }

    final recentFavoriteNumbers = favoriteSongs.take(3).toList();
    _recentFavorites = allSongs
        .where((song) => recentFavoriteNumbers.contains(song['song_number']))
        .toList();
  }

  Future<void> _loadVerseOfTheDay() async {
    try {
      final allVerses = <Map<String, dynamic>>[];

      for (final entry in AppConstants.collections.entries) {
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
                'collection': AppConstants.collections[entry.key]!.displayName,
                'collection_id': entry.key,
                'verse_number': randomVerse.verseNumber,
                'lyrics': randomVerse.lyrics,
                'full_song': song,
              });
            }
          }
        } catch (e) {
          // Handle error silently
        }
      }

      if (allVerses.isNotEmpty) {
        final today = DateTime.now();
        final seed = today.year * 10000 + today.month * 100 + today.day;
        final random = Random(seed);
        _verseOfTheDay = allVerses[random.nextInt(allVerses.length)];
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // Modern App Bar with Header Image
            SliverAppBar(
              expandedHeight: 160,
              floating: true,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Header Image
                    Image.asset(
                      'assets/images/header_image.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(0.8),
                                colorScheme.secondary,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Dark overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      bottom: 60,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$_greeting, $_userName',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentDate,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // User Profile/Login and Settings Icons
                          if (AuthService.isLoggedIn) ...[
                            IconButton(
                              icon: const Icon(Icons.person,
                                  color: Colors.white, size: 20),
                              onPressed: () => context.go('/profile'),
                              tooltip: 'Profile',
                            ),
                          ] else ...[
                            IconButton(
                              icon: const Icon(Icons.login,
                                  color: Colors.white, size: 20),
                              onPressed: () => context.go('/login'),
                              tooltip: 'Login',
                            ),
                          ],
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.settings,
                                color: Colors.white, size: 20),
                            onPressed: () => context.go('/settings'),
                            tooltip: 'Settings',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick Stats Grid
                  _buildStatsGrid(),
                  const SizedBox(height: 24),

                  // Verse of the Day
                  if (_verseOfTheDay != null) ...[
                    _buildVerseCard(),
                    const SizedBox(height: 24),
                  ],

                  // Collections Grid
                  _buildSectionHeader('Song Collections'),
                  const SizedBox(height: 16),
                  _buildCollectionsGrid(),
                  const SizedBox(height: 32),

                  // Recent Favorites
                  if (_recentFavorites.isNotEmpty) ...[
                    _buildSectionHeader('Recent Favorites'),
                    const SizedBox(height: 16),
                    _buildRecentFavorites(),
                    const SizedBox(height: 32),
                  ],

                  // Quick Actions
                  _buildSectionHeader('Quick Actions'),
                  const SizedBox(height: 16),
                  _buildQuickActions(),

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalSongs =
        _collectionCounts.values.fold<int>(0, (sum, count) => sum + count);
    final favoritesCount = _recentFavorites.length;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child:
                  _buildStatItem('$totalSongs', 'Songs', colorScheme.primary)),
          Container(
              width: 1,
              height: 40,
              color: colorScheme.outline.withOpacity(0.2)),
          Expanded(
              child: _buildStatItem('${_collectionCounts.length}',
                  'Collections', colorScheme.secondary)),
          Container(
              width: 1,
              height: 40,
              color: colorScheme.outline.withOpacity(0.2)),
          Expanded(
              child:
                  _buildStatItem('$favoritesCount', 'Favorites', Colors.red)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerseCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verse of the Day',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM d, yyyy').format(DateTime.now()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _verseOfTheDay!['lyrics']?.toString() ?? 'No lyrics available',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.6,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _verseOfTheDay!['song_title']?.toString() ?? 'Unknown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final collectionId = _verseOfTheDay!['collection_id'];
                  final songNumber = _verseOfTheDay!['song_number'];
                  if (collectionId != null && songNumber != null) {
                    context.go('/lyrics/$collectionId/$songNumber');
                  }
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Read More'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildCollectionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: AppConstants.collections.length,
      itemBuilder: (context, index) {
        final collection = AppConstants.collections.values.elementAt(index);
        final count = _collectionCounts[collection.id] ?? 0;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: collection.colorTheme.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.go('/collection/${collection.id}'),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Collection cover image
                    Image.asset(
                      collection.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                collection.colorTheme,
                                collection.colorTheme.withOpacity(0.8),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Dark overlay for better text readability
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
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              _getCollectionIcon(collection.id),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              collection.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$count songs',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              shadows: const [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentFavorites() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: _recentFavorites.map((song) {
          final index = _recentFavorites.indexOf(song);
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  song['song_number']?.toString() ?? '0',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              song['song_title']?.toString() ?? 'Unknown Song',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              song['collection']?.toString() ?? 'Unknown Collection',
              style: theme.textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.favorite, color: Colors.red, size: 20),
            onTap: () {
              final collectionId = song['collection_id'];
              final songNumber = song['song_number'];
              if (collectionId != null && songNumber != null) {
                context.go('/lyrics/$collectionId/$songNumber');
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.favorite,
        'label': 'Favorites',
        'color': Colors.red,
        'route': '/favorites'
      },
      {
        'icon': Icons.search,
        'label': 'Search',
        'color': Colors.blue,
        'route': '/search'
      },
      {
        'icon': Icons.church,
        'label': 'Sermons',
        'color': Colors.purple,
        'route': '/sermons'
      },
      {
        'icon': Icons.video_library,
        'label': 'Media',
        'color': Colors.orange,
        'route': null
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 3.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildActionCard(
          icon: action['icon'] as IconData,
          label: action['label'] as String,
          color: action['color'] as Color,
          onTap: () {
            final route = action['route'] as String?;
            if (route != null) {
              context.go(route);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon!')),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCollectionIcon(String collectionId) {
    switch (collectionId) {
      case 'lpmi':
        return Icons.music_note_rounded;
      case 'srd':
        return Icons.favorite_rounded;
      case 'lagu_iban':
        return Icons.language_rounded;
      case 'pandak':
        return Icons.celebration_rounded;
      default:
        return Icons.library_music_rounded;
    }
  }
}
