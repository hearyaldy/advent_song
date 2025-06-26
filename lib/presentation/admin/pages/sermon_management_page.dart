// lib/presentation/admin/pages/sermon_management_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/sermon_service.dart';

class SermonManagementPage extends StatefulWidget {
  const SermonManagementPage({super.key});

  @override
  State<SermonManagementPage> createState() => _SermonManagementPageState();
}

class _SermonManagementPageState extends State<SermonManagementPage> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    }

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

    filtered.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return filtered;
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) context.go('/');
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
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final wasSuccessful = await SermonService.deleteSermon(sermonId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(wasSuccessful
                  ? 'Sermon deleted successfully!'
                  : 'Error: Failed to delete sermon')),
        );
      }
    }
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
            _buildSearchBarAndFilter(context),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/admin/sermons/add'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        tooltip: 'Add Sermon',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- UI HELPER METHODS FOR A CLEANER BUILD METHOD ---

  Widget _buildSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      title: const Text('Sermon Management'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/'),
        tooltip: 'Back to Dashboard',
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
          onSelected: (value) {
            if (value == 'logout') _handleLogout();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Text('Signed in as ${AuthService.userName}',
                  style: theme.textTheme.labelSmall),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(children: [
                Icon(Icons.logout),
                SizedBox(width: 8),
                Text('Logout')
              ]),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBarAndFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _filterSermons,
              decoration: InputDecoration(
                hintText: 'Search sermons...',
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
            icon: Icon(Icons.filter_list, color: Colors.orange.shade700),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: sermons.length,
      itemBuilder: (context, index) {
        final sermon = sermons[index];
        return _buildSermonCard(context, sermon);
      },
    );
  }

  Widget _buildSermonCard(BuildContext context, Map<String, dynamic> sermon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
                          size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(sermon['pastor'] ?? 'N/A',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today,
                          size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                          DateFormat('MMM d, yyyy')
                              .format(sermon['date'] as DateTime),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(sermon['series'] ?? 'General'),
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        labelStyle: TextStyle(
                            color: Colors.orange.shade800, fontSize: 12),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      if (sermon['hasAudio'] == true)
                        Chip(
                            label: const Text('Audio'),
                            avatar: Icon(Icons.audiotrack,
                                size: 16, color: Colors.green.shade700),
                            visualDensity: VisualDensity.compact),
                      if (sermon['hasVideo'] == true)
                        Chip(
                            label: const Text('Video'),
                            avatar: Icon(Icons.videocam,
                                size: 16, color: Colors.blue.shade700),
                            visualDensity: VisualDensity.compact),
                    ],
                  )
                ],
              ),
            ),
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
                    child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
              icon: Icon(Icons.more_vert,
                  size: 20, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      String value, IconData icon, String text) {
    final isSelected = _selectedFilter == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isSelected ? Colors.orange : null),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : null,
              color: isSelected ? Colors.orange : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
              _searchQuery.isNotEmpty
                  ? 'No Sermons Found'
                  : 'No Sermons Available',
              style: Theme.of(context).textTheme.titleMedium),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add the first sermon.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
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
            Text('Failed to Load Sermons',
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
}
