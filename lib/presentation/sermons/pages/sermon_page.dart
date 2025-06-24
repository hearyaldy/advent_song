// lib/presentation/sermons/pages/sermon_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  // Sample sermon data - replace with actual data source
  final List<Map<String, dynamic>> _sermons = [
    {
      'id': '1',
      'title': 'Walking in Faith',
      'pastor': 'Pastor John Smith',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'duration': '45 min',
      'series': 'Living by Faith',
      'description':
          'A powerful message about trusting God in uncertain times and walking boldly in faith.',
      'tags': ['Faith', 'Trust', 'Christian Living'],
      'hasAudio': true,
      'hasVideo': false,
      'isNew': true,
    },
    {
      'id': '2',
      'title': 'The Power of Prayer',
      'pastor': 'Pastor Mary Johnson',
      'date': DateTime.now().subtract(const Duration(days: 14)),
      'duration': '38 min',
      'series': 'Spiritual Disciplines',
      'description':
          'Understanding the importance and impact of prayer in our daily spiritual journey.',
      'tags': ['Prayer', 'Spiritual Growth', 'Devotion'],
      'hasAudio': true,
      'hasVideo': true,
      'isNew': false,
    },
    {
      'id': '3',
      'title': 'Love Your Neighbor',
      'pastor': 'Pastor David Lee',
      'date': DateTime.now().subtract(const Duration(days: 21)),
      'duration': '42 min',
      'series': 'Christian Community',
      'description':
          'Exploring what it means to love our neighbors as ourselves in modern society.',
      'tags': ['Love', 'Community', 'Service'],
      'hasAudio': true,
      'hasVideo': true,
      'isNew': false,
    },
    {
      'id': '4',
      'title': 'Hope in Difficult Times',
      'pastor': 'Pastor Sarah Wilson',
      'date': DateTime.now().subtract(const Duration(days: 28)),
      'duration': '50 min',
      'series': 'Finding Hope',
      'description':
          'How to maintain hope and find strength during life\'s most challenging moments.',
      'tags': ['Hope', 'Encouragement', 'Perseverance'],
      'hasAudio': true,
      'hasVideo': false,
      'isNew': false,
    },
  ];

  List<Map<String, dynamic>> _filteredSermons = [];

  @override
  void initState() {
    super.initState();
    _getCurrentDate();
    _filteredSermons = _sermons;
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
                  DateTime.now().difference(sermon['date']).inDays <= 30)
              .toList();
          break;
        case 'Audio':
          _filteredSermons =
              _sermons.where((sermon) => sermon['hasAudio']).toList();
          break;
        case 'Video':
          _filteredSermons =
              _sermons.where((sermon) => sermon['hasVideo']).toList();
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
                      child: const Text(
                        'Spiritual Growth',
                        style: TextStyle(
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
            child: _filteredSermons.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
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
                                        sermon['title'],
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (sermon['isNew'])
                                      Container(
                                        padding: const EdgeInsets.symmetric(
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
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Pastor and date
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      sermon['pastor'],
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('MMM d, yyyy')
                                          .format(sermon['date']),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Description
                                Text(
                                  sermon['description'],
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
                                        sermon['series'],
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
                                      sermon['duration'],
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                    const Spacer(),
                                    // Media indicators
                                    if (sermon['hasAudio'])
                                      Icon(
                                        Icons.audiotrack,
                                        size: 20,
                                        color: Colors.green,
                                      ),
                                    if (sermon['hasVideo'])
                                      const SizedBox(width: 8),
                                    if (sermon['hasVideo'])
                                      Icon(
                                        Icons.videocam,
                                        size: 20,
                                        color: Colors.blue,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new sermon functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add sermon feature coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
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
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Sermon messages will appear here',
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
                sermon['title'],
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
                  Text(sermon['pastor']),
                  const SizedBox(width: 16),
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text(DateFormat('MMMM d, yyyy').format(sermon['date'])),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                sermon['description'],
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              // Tags
              Wrap(
                spacing: 8,
                children: (sermon['tags'] as List<String>)
                    .map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          labelStyle: const TextStyle(color: Colors.purple),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                children: [
                  if (sermon['hasAudio'])
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Play audio
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
                  if (sermon['hasAudio'] && sermon['hasVideo'])
                    const SizedBox(width: 12),
                  if (sermon['hasVideo'])
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Play video
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
