// lib/presentation/sermons/pages/sermon_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sermon_service.dart';

class SermonPage extends StatefulWidget {
  const SermonPage({super.key});

  @override
  State<SermonPage> createState() => _SermonPageState();
}

class _SermonPageState extends State<SermonPage> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAdmin = false;
  int _selectedNavIndex = 2; // Sermons tab

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final status = await AuthService.isAdmin;
    if (mounted) {
      setState(() {
        _isAdmin = status;
      });
    }
  }

  void _filterSermons(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> sermons) {
    List<Map<String, dynamic>> filtered = List.from(sermons);

    // Apply main filter
    switch (_selectedFilter) {
      case 'Recent':
        filtered = filtered
            .where((s) =>
                DateTime.now().difference(s['date'] as DateTime).inDays <= 30)
            .toList();
        break;
      case 'Audio':
        filtered = filtered.where((s) => s['hasAudio'] == true).toList();
        break;
      case 'Video':
        filtered = filtered.where((s) => s['hasVideo'] == true).toList();
        break;
      default: // 'All'
        break;
    }

    // Apply search query on top of the filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((sermon) =>
              sermon['title']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              sermon['pastor']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              sermon['series']
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort by date, most recent first
    filtered.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(context),
        ],
        body: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SermonService.getSermons(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildErrorState('Error: ${snapshot.error}');
                  }

                  final allSermons = snapshot.data ?? [];
                  final filteredSermons = _applyFilters(allSermons);

                  if (filteredSermons.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildSermonList(filteredSermons);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => context.go('/admin/sermons/add'),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              tooltip: 'Add Sermon',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // --- UI HELPER WIDGETS ---

  SliverAppBar _buildSliverAppBar(BuildContext context) {
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
        // --- FIX APPLIED: Text color is now white ---
        title: Text(
          'Sermons',
          style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white, // Explicitly set color to white
              shadows: [
                // Adding a subtle shadow for better readability
                const Shadow(
                    color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
              ]),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/header_image.png', // Or a sermon-specific one
              fit: BoxFit.cover,
              color: Colors.purple.withOpacity(0.5),
              colorBlendMode: BlendMode.multiply,
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
        if (_isAdmin)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded),
            onPressed: () => context.go('/admin/sermons'),
            tooltip: 'Admin Panel',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _filterSermons,
              decoration: InputDecoration(
                hintText: 'Search title, pastor, series...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterSermons('');
                        },
                      )
                    : null,
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list,
                color: Theme.of(context).colorScheme.primary),
            onSelected: _onFilterChanged,
            itemBuilder: (context) => [
              _buildPopupMenuItem('All', Icons.list, 'All Sermons'),
              _buildPopupMenuItem('Recent', Icons.schedule, 'Last 30 Days'),
              const PopupMenuDivider(),
              _buildPopupMenuItem('Audio', Icons.audiotrack, 'Audio Only'),
              _buildPopupMenuItem('Video', Icons.videocam, 'Video Available'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSermonList(List<Map<String, dynamic>> sermons) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: sermons.length,
      itemBuilder: (context, index) {
        final sermon = sermons[index];
        return _buildSermonCard(sermon);
      },
    );
  }

  Widget _buildSermonCard(Map<String, dynamic> sermon) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSermonDetails(sermon),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sermon['title'] ?? 'Untitled Sermon',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(sermon['pastor'] ?? 'N/A',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Icon(Icons.calendar_today,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                      DateFormat('MMM d, yyyy')
                          .format(sermon['date'] as DateTime),
                      style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sermon['description'] ?? 'No description.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text(sermon['series'] ?? 'General'),
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(
                        color: theme.colorScheme.primary, fontSize: 12),
                    padding: EdgeInsets.zero,
                  ),
                  const Spacer(),
                  if (sermon['hasAudio'] == true)
                    Icon(Icons.audiotrack,
                        size: 20, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  if (sermon['hasVideo'] == true)
                    Icon(Icons.videocam, size: 20, color: Colors.blue.shade600),
                  if (_isAdmin)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.go('/admin/sermons/edit/${sermon['id']}',
                              extra: sermon);
                        } else if (value == 'delete') {
                          _deleteSermon(sermon['id']);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete',
                                style: TextStyle(color: Colors.red))),
                      ],
                      child: const Icon(Icons.more_vert, size: 20),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No Results Found'
                : 'No Sermons Available',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_searchQuery.isEmpty && _isAdmin) ...[
            const SizedBox(height: 8),
            Text('Tap the + button to add the first sermon.',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load sermons',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => setState(() {}), child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, color: _selectedFilter == value ? Colors.purple : null),
        const SizedBox(width: 12),
        Text(text,
            style: TextStyle(
                fontWeight: _selectedFilter == value ? FontWeight.bold : null)),
      ]),
    );
  }

  BottomNavigationBar _buildBottomNavBar(BuildContext context) {
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
            context.go('/collection/lpmi');
            break;
          case 2:
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

  void _showSermonDetails(Map<String, dynamic> sermon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(sermon['title'] ?? 'Untitled',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.person, size: 16, color: Colors.purple),
                const SizedBox(width: 4),
                Text(sermon['pastor'] ?? 'N/A'),
                const SizedBox(width: 16),
                const Icon(Icons.calendar_today,
                    size: 16, color: Colors.purple),
                const SizedBox(width: 4),
                Text(DateFormat('MMMM d, yyyy')
                    .format(sermon['date'] as DateTime)),
              ]),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(sermon['description'] ?? 'No description available.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.5)),
              const SizedBox(height: 24),
              Row(children: [
                if (sermon['hasAudio'] == true)
                  Expanded(
                      child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play Audio'))),
                if (sermon['hasAudio'] == true && sermon['hasVideo'] == true)
                  const SizedBox(width: 12),
                if (sermon['hasVideo'] == true)
                  Expanded(
                      child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.videocam),
                          label: const Text('Watch Video'))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteSermon(String sermonId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sermon'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await SermonService.deleteSermon(sermonId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  success ? 'Sermon deleted!' : 'Failed to delete sermon')),
        );
      }
    }
  }
}
