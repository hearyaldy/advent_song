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
  String _currentDate = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAdmin = false;

  List<Map<String, dynamic>> _sermons = [];
  List<Map<String, dynamic>> _filteredSermons = [];

  @override
  void initState() {
    super.initState();
    _getCurrentDate();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _getCurrentDate() {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE | MMMM d, yyyy').format(now);
    setState(() {
      _currentDate = formattedDate;
    });
  }

  Future<void> _checkAdminStatus() async {
    _isAdmin = await AuthService.isAdmin;
    setState(() {});
  }

  void _filterSermons(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _applyCurrentFilter();
      } else {
        _filteredSermons = _sermons
            .where((sermon) =>
                sermon['title'].toLowerCase().contains(query.toLowerCase()) ||
                sermon['pastor'].toLowerCase().contains(query.toLowerCase()) ||
                sermon['series'].toLowerCase().contains(query.toLowerCase()) ||
                sermon['description']
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _applyCurrentFilter() {
    setState(() {
      switch (_selectedFilter) {
        case 'All':
          _filteredSermons = _sermons;
          break;
        case 'Recent':
          _filteredSermons = _sermons
              .where((sermon) =>
                  DateTime.now().difference(sermon['date'].toDate()).inDays <=
                  30)
              .toList();
          break;
        case 'Audio':
          _filteredSermons =
              _sermons.where((sermon) => sermon['hasAudio'] == true).toList();
          break;
        case 'Video':
          _filteredSermons =
              _sermons.where((sermon) => sermon['hasVideo'] == true).toList();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Header with image
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple,
                      Colors.purple.shade700,
                    ],
                  ),
                ),
                child: Image.asset(
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
                            Colors.purple,
                            Colors.purple.shade700,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Dark overlay
              Container(
                width: double.infinity,
                height: 120,
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
              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.go('/'),
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
                        _isAdmin ? 'Admin Access' : 'Spiritual Growth',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sermons',
                      style: TextStyle(
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

          // Sermon info
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.church, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sermon Messages',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (_isAdmin)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      'ADMIN',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredSermons.length} sermons',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.purple,
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
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter button
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.filter_list,
                      color: Colors.purple,
                    ),
                  ),
                  tooltip: 'Filter options',
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
                        Text('Error loading sermons: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                _sermons = snapshot.data ?? [];
                _applyCurrentFilter();

                if (_filteredSermons.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _filteredSermons.length,
                  itemBuilder: (context, index) {
                    final sermon = _filteredSermons[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _showSermonDetails(sermon);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sermon['title'] ?? 'Untitled',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (sermon['isNew'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
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
                                  if (_isAdmin) ...[
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showAddEditDialog(sermon);
                                        } else if (value == 'delete') {
                                          _deleteSermon(sermon['id']);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 16),
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
                                                  size: 16, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      child:
                                          const Icon(Icons.more_vert, size: 20),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Pastor and date
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    sermon['pastor'] ?? 'Unknown Pastor',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d, yyyy')
                                        .format(sermon['date'].toDate()),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Description
                              Text(
                                sermon['description'] ??
                                    'No description available',
                                style: theme.textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              // Footer row
                              Row(
                                children: [
                                  // Series tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      sermon['series'] ?? 'General',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.purple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Duration
                                  Text(
                                    '${sermon['duration'] ?? 0} min',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                  const Spacer(),
                                  // Media indicators
                                  if (sermon['hasAudio'] == true)
                                    const Icon(
                                      Icons.audiotrack,
                                      size: 20,
                                      color: Colors.green,
                                    ),
                                  if (sermon['hasVideo'] == true) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.videocam,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () => _showAddEditDialog(null),
              backgroundColor: Colors.purple,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
      String value, IconData icon, String text) {
    final isSelected = _selectedFilter == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.purple : null,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : null,
              color: isSelected ? Colors.purple : null,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, color: Colors.purple),
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
          if (_searchQuery.isEmpty && _isAdmin) ...[
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

  void _showSermonDetails(Map<String, dynamic> sermon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
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
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Text(
                sermon['title'] ?? 'Untitled',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              // Pastor and date
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text(sermon['pastor'] ?? 'Unknown Pastor'),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text(DateFormat('MMMM d, yyyy')
                      .format(sermon['date'].toDate())),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                sermon['description'] ?? 'No description available',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              // Tags
              if (sermon['tags'] != null && (sermon['tags'] as List).isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: (sermon['tags'] as List<dynamic>)
                      .map((tag) => Chip(
                            label: Text(tag.toString()),
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            labelStyle: const TextStyle(color: Colors.purple),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  if (sermon['hasAudio'] == true)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Audio player coming soon!')),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play Audio'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                      ),
                    ),
                  if (sermon['hasAudio'] == true && sermon['hasVideo'] == true)
                    const SizedBox(width: 12),
                  if (sermon['hasVideo'] == true)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Video player coming soon!')),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Watch Video'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue),
                      ),
                    ),
                  if (sermon['hasAudio'] != true && sermon['hasVideo'] != true)
                    Expanded(
                      child: Text(
                        'No media available for this sermon',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog(Map<String, dynamic>? sermon) {
    final isEdit = sermon != null;
    final titleController = TextEditingController(text: sermon?['title'] ?? '');
    final pastorController =
        TextEditingController(text: sermon?['pastor'] ?? '');
    final seriesController =
        TextEditingController(text: sermon?['series'] ?? '');
    final descriptionController =
        TextEditingController(text: sermon?['description'] ?? '');
    final durationController =
        TextEditingController(text: sermon?['duration']?.toString() ?? '');
    final audioUrlController =
        TextEditingController(text: sermon?['audioUrl'] ?? '');
    final videoUrlController =
        TextEditingController(text: sermon?['videoUrl'] ?? '');

    DateTime selectedDate =
        sermon != null ? sermon['date'].toDate() : DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Sermon' : 'Add New Sermon'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pastorController,
                decoration: const InputDecoration(labelText: 'Pastor *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: seriesController,
                decoration: const InputDecoration(labelText: 'Series'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durationController,
                decoration:
                    const InputDecoration(labelText: 'Duration (minutes)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: audioUrlController,
                decoration:
                    const InputDecoration(labelText: 'Audio URL (optional)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: videoUrlController,
                decoration:
                    const InputDecoration(labelText: 'Video URL (optional)'),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(
                    'Date: ${DateFormat('MMM d, yyyy').format(selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  pastorController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Title and Pastor are required')),
                );
                return;
              }

              final success = isEdit
                  ? await SermonService.updateSermon(sermon['id'], {
                      'title': titleController.text.trim(),
                      'pastor': pastorController.text.trim(),
                      'series': seriesController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'duration': int.tryParse(durationController.text) ?? 30,
                      'audioUrl': audioUrlController.text.trim(),
                      'videoUrl': videoUrlController.text.trim(),
                      'hasAudio': audioUrlController.text.trim().isNotEmpty,
                      'hasVideo': videoUrlController.text.trim().isNotEmpty,
                      'date': selectedDate,
                    })
                  : await SermonService.addSermon(
                      title: titleController.text.trim(),
                      pastor: pastorController.text.trim(),
                      date: selectedDate,
                      series: seriesController.text.trim(),
                      description: descriptionController.text.trim(),
                      duration: int.tryParse(durationController.text) ?? 30,
                      audioUrl: audioUrlController.text.trim(),
                      videoUrl: videoUrlController.text.trim(),
                    );

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(isEdit ? 'Sermon updated!' : 'Sermon added!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to save sermon')),
                );
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
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
