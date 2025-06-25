// lib/presentation/song_list/pages/song_list_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/json_loader_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/song.dart';

class SongListPage extends StatefulWidget {
  final String collectionId;
  final bool showFavoritesOnly;
  final bool openSearch;

  const SongListPage({
    super.key,
    required this.collectionId,
    this.showFavoritesOnly = false,
    this.openSearch = false,
  });

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  List<String> _favorites = [];
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _currentDate = '';
  bool _isLoading = true;
  int _selectedNavIndex = 1; // Song List is the middle tab (index 1)
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
    if (widget.openSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Focus on search field if openSearch is true
        FocusScope.of(context).requestFocus(FocusNode());
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadCollection();
    await _loadFavorites();
    _getCurrentDate();
    setState(() {
      _isLoading = false;
    });
  }

  void _getCurrentDate() {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE | MMMM d, yyyy').format(now);
    setState(() {
      _currentDate = formattedDate;
    });
  }

  Future<void> _loadCollection() async {
    try {
      final collection =
          await JsonLoaderService.loadCollection(widget.collectionId);
      setState(() {
        _songs = collection.songs;
        _filteredSongs = _songs;
      });

      // Apply initial filter if showing favorites only
      if (widget.showFavoritesOnly) {
        _selectedFilter = 'Favorites';
        _applyCurrentFilter();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favorites = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<void> _toggleFavorite(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteSongs = prefs.getStringList('favorites') ?? [];

    setState(() {
      if (favoriteSongs.contains(song.songNumber)) {
        favoriteSongs.remove(song.songNumber);
        _favorites.remove(song.songNumber);
      } else {
        favoriteSongs.add(song.songNumber);
        _favorites.add(song.songNumber);
      }
    });

    await prefs.setStringList('favorites', favoriteSongs);

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_favorites.contains(song.songNumber)
              ? 'Added to favorites'
              : 'Removed from favorites'),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // Refresh filter if showing favorites
    if (_selectedFilter == 'Favorites') {
      _applyCurrentFilter();
    }
  }

  void _filterSongs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _applyCurrentFilter();
      } else {
        _filteredSongs = _songs
            .where((song) =>
                song.songTitle.toLowerCase().contains(query.toLowerCase()) ||
                song.songNumber.contains(query) ||
                song.verses.any((verse) =>
                    verse.lyrics.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  void _applyCurrentFilter() {
    setState(() {
      switch (_selectedFilter) {
        case 'All':
          _filteredSongs = _songs;
          break;
        case 'Favorites':
          _filteredSongs = _songs
              .where((song) => _favorites.contains(song.songNumber))
              .toList();
          break;
        case 'Alphabet':
          _filteredSongs = List.from(_songs)
            ..sort((a, b) =>
                a.songTitle.toLowerCase().compareTo(b.songTitle.toLowerCase()));
          break;
        case 'Number':
          _filteredSongs = List.from(_songs)
            ..sort((a, b) =>
                int.tryParse(a.songNumber)
                    ?.compareTo(int.tryParse(b.songNumber) ?? 0) ??
                0);
          break;
      }
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _applyCurrentFilter();
  }

  @override
  Widget build(BuildContext context) {
    final metadata = AppConstants.collections[widget.collectionId];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Header with collection cover image
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 120,
                child: ClipRect(
                  child: Stack(
                    children: [
                      // Collection-specific cover image
                      Positioned.fill(
                        child: Image.asset(
                          metadata?.coverImage ??
                              'assets/images/header_image.png',
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to gradient if image fails to load
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
                      // Dark overlay for better text readability
                      Positioned.fill(
                        child: Container(
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
                      ),
                    ],
                  ),
                ),
              ),

              // Settings button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => context.go('/settings'),
                  ),
                ),
              ),
              // Title and date
              Positioned(
                bottom: 10,
                left: 20,
                right: 60, // Adjusted to give space for settings button
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        metadata?.name ?? 'Collection',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metadata?.displayName ?? 'Songs',
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
                    ),
                    Text(
                      _currentDate,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Collection info
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(Icons.library_music,
                    color: metadata?.colorTheme ?? colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.showFavoritesOnly
                        ? 'Favorite Songs'
                        : (metadata?.displayName ?? 'Songs'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (metadata?.colorTheme ?? colorScheme.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredSongs.length} songs',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: metadata?.colorTheme ?? colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar with sort options
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSongs,
                    decoration: InputDecoration(
                      hintText: 'Search by title or number...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterSongs('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Sort button
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (metadata?.colorTheme ?? colorScheme.primary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (metadata?.colorTheme ?? colorScheme.primary)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.sort,
                      color: metadata?.colorTheme ?? colorScheme.primary,
                    ),
                  ),
                  tooltip: 'Sort options',
                  onSelected: _onFilterChanged,
                  itemBuilder: (context) => [
                    _buildPopupMenuItem('All', Icons.list, 'All Songs'),
                    _buildPopupMenuItem(
                        'Favorites', Icons.favorite, 'Favorites'),
                    const PopupMenuDivider(),
                    _buildPopupMenuItem(
                        'Alphabet', Icons.sort_by_alpha, 'Sort A-Z'),
                    _buildPopupMenuItem(
                        'Number', Icons.format_list_numbered, 'Sort by Number'),
                  ],
                ),
              ],
            ),
          ),

          // Song list
          Expanded(
            child: _filteredSongs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = _filteredSongs[index];
                      final isFavorite = _favorites.contains(song.songNumber);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                metadata?.colorTheme ?? colorScheme.primary,
                            child: Text(
                              song.songNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            song.songTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${song.verses.length} verse${song.verses.length > 1 ? 's' : ''}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : null,
                            ),
                            onPressed: () => _toggleFavorite(song),
                          ),
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
      ),
      floatingActionButton: !widget.showFavoritesOnly
          ? FloatingActionButton.extended(
              onPressed: _showCollectionMenu,
              tooltip: 'Switch Collection',
              icon: const Icon(Icons.library_music),
              label: Text(_getShortCollectionName()),
              backgroundColor: metadata?.colorTheme ?? colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      String value, IconData icon, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    final metadata = AppConstants.collections[widget.collectionId];
    final isSelected = _selectedFilter == value;

    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected
                ? (metadata?.colorTheme ?? colorScheme.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : null,
              color: isSelected
                  ? (metadata?.colorTheme ?? colorScheme.primary)
                  : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check,
                color: metadata?.colorTheme ?? colorScheme.primary),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedFilter == 'Favorites'
                ? Icons.favorite_border
                : Icons.search_off,
            size: 64,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'Favorites'
                ? 'No favorite songs yet'
                : _searchQuery.isNotEmpty
                    ? 'No songs found for "$_searchQuery"'
                    : 'No songs available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),
          if (_selectedFilter == 'Favorites') ...[
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on songs to add them to favorites',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _getShortCollectionName() {
    final metadata = AppConstants.collections[widget.collectionId];
    if (metadata == null) return 'Songs';

    switch (metadata.id) {
      case 'lpmi':
        return 'LPMI';
      case 'srd':
        return 'SRD';
      case 'lagu_iban':
        return 'Iban';
      case 'pandak':
        return 'Pandak';
      default:
        return metadata.displayName;
    }
  }

  void _showCollectionMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Icon(
                    Icons.library_music,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Collection',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose from available song collections',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 16),

              // Collection options
              Flexible(
                child: ListView.builder(
                  controller: scrollController,
                  shrinkWrap: true,
                  itemCount: AppConstants.collections.length,
                  itemBuilder: (context, index) {
                    final collection =
                        AppConstants.collections.values.elementAt(index);
                    final isSelected = collection.id == widget.collectionId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? collection.colorTheme.withValues(alpha: 0.1)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: collection.colorTheme
                                    .withValues(alpha: 0.3))
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? collection.colorTheme
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          collection.displayName,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? collection.colorTheme : null,
                          ),
                        ),
                        subtitle: Text(
                          collection.description,
                          style: TextStyle(
                            color: isSelected
                                ? collection.colorTheme.withValues(alpha: 0.7)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: collection.colorTheme)
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.pop(context);
                          if (!isSelected) {
                            context.go('/collection/${collection.id}');
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: _onBottomNavTapped,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music),
          label: 'Songs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info_outline),
          label: 'About',
        ),
      ],
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == _selectedNavIndex) {
      return; // Don't navigate if already on this tab
    }

    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0: // Dashboard
        context.go('/');
        break;
      case 1: // Songs (current page)
        // Already on songs page, no action needed
        break;
      case 2: // Settings
        context.go('/settings');
        break;
      case 3: // About
        _showAboutDialog();
        // Reset selection back to Songs since About is a dialog, not navigation
        setState(() {
          _selectedNavIndex = 1;
        });
        break;
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.music_note,
          size: 32,
          color: Colors.white,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
            'A beautiful collection of spiritual songs for worship and praise.'),
        const SizedBox(height: 16),
        Text(
          'Features:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        const Text('• Multiple song collections (LPMI, SRD, Iban, Pandak)'),
        const Text('• Advanced search and filtering'),
        const Text('• Favorites management'),
        const Text('• Customizable text display settings'),
        const Text('• Share and copy song lyrics'),
        const Text('• Dark mode and color themes'),
        const Text('• Verse of the day feature'),
        const SizedBox(height: 16),
        Text(
          'Collections:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...AppConstants.collections.values.map(
          (collection) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: collection.colorTheme,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${collection.displayName} - ${collection.description}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
