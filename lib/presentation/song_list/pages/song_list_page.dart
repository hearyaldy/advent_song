// lib/presentation/song_list/pages/song_list_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/json_loader_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/favorites_notifier.dart';
import '../../../data/models/song.dart';

class SongListPage extends StatefulWidget {
  final String collectionId;
  final bool showFavoritesOnly;
  final bool openSearch;
  final FavoritesNotifier favoritesNotifier;

  const SongListPage({
    super.key,
    required this.collectionId,
    this.showFavoritesOnly = false,
    this.openSearch = false,
    required this.favoritesNotifier,
  });

  @override
  State<SongListPage> createState() => _SongListPageState();
}

class _SongListPageState extends State<SongListPage> {
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _currentDate = '';
  bool _isLoading = true;
  int _selectedNavIndex = 1; // Songs tab
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
    widget.favoritesNotifier.addListener(_onFavoritesChanged);
    if (widget.openSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.favoritesNotifier.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  /// This method is called whenever the favorites list changes.
  /// It re-applies the filter if the user is currently viewing the favorites.
  void _onFavoritesChanged() {
    if (_selectedFilter == 'Favorites') {
      // Use setState to trigger a rebuild with the updated list.
      setState(() {
        _applyCurrentFilter();
      });
    }
    // No need to call setState for other filters as the icon will update automatically.
  }

  @override
  void didUpdateWidget(covariant SongListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.collectionId != oldWidget.collectionId) {
      _initializeApp();
    }
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
    });
    await _loadCollection();
    _getCurrentDate();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _getCurrentDate() {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE | MMMM d, yyyy').format(now);
    if (mounted) {
      setState(() {
        _currentDate = formattedDate;
      });
    }
  }

  Future<void> _loadCollection() async {
    try {
      final collection =
          await JsonLoaderService.loadCollection(widget.collectionId);
      if (mounted) {
        setState(() {
          _songs = collection.songs;
          _filteredSongs = _songs;
          _searchController.clear();
          _searchQuery = '';
          _selectedFilter = 'All';
        });
      }

      if (widget.showFavoritesOnly) {
        setState(() {
          _selectedFilter = 'Favorites';
        });
        _applyCurrentFilter();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading collection: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Song song) async {
    // We only need to update the favorite status.
    // The listener (_onFavoritesChanged) will handle the UI update if needed.
    await widget.favoritesNotifier.toggleFavorite(song.songNumber);
  }

  void _filterSongs(String query) {
    setState(() {
      _searchQuery = query;
      _applyCurrentFilter();
    });
  }

  void _applyCurrentFilter() {
    List<Song> tempSongs = List.from(_songs);

    switch (_selectedFilter) {
      case 'All':
        break;
      case 'Favorites':
        tempSongs = tempSongs
            .where(
                (song) => widget.favoritesNotifier.isFavorite(song.songNumber))
            .toList();
        break;
      case 'Alphabet':
        tempSongs.sort((a, b) =>
            a.songTitle.toLowerCase().compareTo(b.songTitle.toLowerCase()));
        break;
      case 'Number':
        tempSongs.sort((a, b) =>
            int.tryParse(a.songNumber)
                ?.compareTo(int.tryParse(b.songNumber) ?? 0) ??
            0);
        break;
    }

    if (_searchQuery.isNotEmpty) {
      tempSongs = tempSongs
          .where((song) =>
              song.songTitle
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              song.songNumber.contains(_searchQuery) ||
              song.verses.any((verse) => verse.lyrics
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase())))
          .toList();
    }

    // No need to call setState here, it's called by the methods that use this.
    _filteredSongs = tempSongs;
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyCurrentFilter();
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
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 120,
                child: ClipRect(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          metadata?.coverImage ??
                              'assets/images/header_image.png',
                          width: double.infinity,
                          height: 120,
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
              Positioned(
                bottom: 10,
                left: 20,
                right: 60,
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
                        .withAlpha(25),
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
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
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
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
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
          Expanded(
            child: _filteredSongs.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = _filteredSongs[index];
                      final isFavorite =
                          widget.favoritesNotifier.isFavorite(song.songNumber);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (metadata?.colorTheme ?? colorScheme.primary)
                                    .withAlpha(30),
                            child: Text(
                              song.songNumber,
                              style: TextStyle(
                                color:
                                    metadata?.colorTheme ?? colorScheme.primary,
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
                            icon: AnimatedBuilder(
                              animation: widget.favoritesNotifier,
                              builder: (context, child) => Icon(
                                widget.favoritesNotifier
                                        .isFavorite(song.songNumber)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: widget.favoritesNotifier
                                        .isFavorite(song.songNumber)
                                    ? Colors.redAccent
                                    : null,
                              ),
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
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedFilter == 'Favorites'
                  ? Icons.favorite_border
                  : Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(70),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'Favorites'
                  ? 'No favorite songs yet'
                  : _searchQuery.isNotEmpty
                      ? 'No songs found for "$_searchQuery"'
                      : 'No songs available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(180),
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
                          .withAlpha(130),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.onSurface.withAlpha(70),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
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
                          .withAlpha(180),
                    ),
              ),
              const SizedBox(height: 16),
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
                            ? collection.colorTheme.withAlpha(25)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: collection.colorTheme.withAlpha(80))
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
                                ? collection.colorTheme.withAlpha(180)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withAlpha(150),
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

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) {
        if (index == _selectedNavIndex) return;
        setState(() => _selectedNavIndex = index);
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
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
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.music_note_rounded),
          label: 'Songs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.church_rounded),
          label: 'Sermons',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}
