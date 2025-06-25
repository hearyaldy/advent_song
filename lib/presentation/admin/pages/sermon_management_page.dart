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

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> sermons) {
    List<Map<String, dynamic>> filtered = sermons;

    // Apply search filter
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

    // Apply category filter
    switch (_selectedFilter) {
      case 'All':
        break;
      case 'Recent':
        filtered = filtered
            .where((sermon) =>
                DateTime.now().difference(sermon['date'] as DateTime).inDays <=
                30)
            .toList();
        break;
      case 'Audio':
        filtered =
            filtered.where((sermon) => sermon['hasAudio'] == true).toList();
        break;
      case 'Video':
        filtered =
            filtered.where((sermon) => sermon['hasVideo'] == true).toList();
        break;
    }

    return filtered;
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    context.go('/admin/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange,
                  Colors.deepOrange.shade700,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with back button and logout
                    Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.go('/'),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.account_circle,
                              color: Colors.white, size: 28),
                          onSelected: (value) {
                            if (value == 'logout') {
                              _handleLogout();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'info',
                              child: Row(
                                children: [
                                  const Icon(Icons.person),
                                  const SizedBox(width: 8),
                                  Text(AuthService.userName),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Logout',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title and admin badge
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings,
                            color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'Sermon Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.filter_list, color: Colors.orange),
                  ),
                  onSelected: _onFilterChanged,
                  itemBuilder: (context) => [
                    _buildPopupMenuItem('All', Icons.list, 'All Sermons'),
                    _buildPopupMenuItem('Recent', Icons.schedule, 'Recent'),
                    const PopupMenuDivider(),
                    _buildPopupMenuItem(
                        'Audio', Icons.audiotrack, 'Audio Only'),
                    _buildPopupMenuItem(
                        'Video', Icons.videocam, 'Video Available'),
                  ],
                ),
              ],
            ),
          ),

          // Sermon list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: SermonService.getSermons(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allSermons = snapshot.data ?? [];
                final filteredSermons = _applyFilters(allSermons);

                return Column(
                  children: [
                    // Stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.church, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Total: ${allSermons.length} sermons',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Showing: ${filteredSermons.length}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Sermon list
                    Expanded(
                      child: filteredSermons.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: filteredSermons.length,
                              itemBuilder: (context, index) {
                                final sermon = filteredSermons[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header row
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                sermon['title'] ?? 'Untitled',
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (sermon['isNew'] == true)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  'NEW',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            PopupMenuButton<String>(
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  context.go(
                                                      '/admin/sermons/edit/${sermon['id']}',
                                                      extra: sermon);
                                                } else if (value == 'delete') {
                                                  _deleteSermon(sermon['id']);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit,
                                                          size: 16),
                                                      SizedBox(width: 8),
                                                      Text('Edit'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete,
                                                          size: 16,
                                                          color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Delete',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              child: const Icon(Icons.more_vert,
                                                  size: 20),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        // Pastor and date
                                        Row(
                                          children: [
                                            Icon(Icons.person,
                                                size: 16,
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.6)),
                                            const SizedBox(width: 4),
                                            Text(sermon['pastor'] ??
                                                'Unknown Pastor'),
                                            const SizedBox(width: 16),
                                            Icon(Icons.calendar_today,
                                                size: 16,
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.6)),
                                            const SizedBox(width: 4),
                                            Text(DateFormat('MMM d, yyyy')
                                                .format(sermon['date']
                                                    as DateTime)),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        Text(
                                          sermon['description'] ??
                                              'No description',
                                          style: theme.textTheme.bodyMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        const SizedBox(height: 12),

                                        // Footer row
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.orange
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                sermon['series'] ?? 'General',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                                '${sermon['duration'] ?? 0} min'),
                                            const Spacer(),
                                            if (sermon['hasAudio'] == true)
                                              const Icon(Icons.audiotrack,
                                                  size: 20,
                                                  color: Colors.green),
                                            if (sermon['hasVideo'] == true) ...[
                                              const SizedBox(width: 8),
                                              const Icon(Icons.videocam,
                                                  size: 20, color: Colors.blue),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/sermons/add'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Sermon'),
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
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, color: Colors.orange),
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
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.church,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No sermons found for "$_searchQuery"'
                : 'No sermons available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first sermon',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteSermon(String sermonId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sermon'),
        content: const Text(
            'Are you sure you want to delete this sermon? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sermon deleted!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete sermon')),
        );
      }
    }
  }
}
