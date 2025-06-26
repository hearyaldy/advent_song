// lib/presentation/sermons/pages/sermon_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sermon_service.dart';
// The import for AppDialogs has been removed.

class SermonPage extends StatefulWidget {
  const SermonPage({super.key});

  @override
  State<SermonPage> createState() => _SermonPageState();
}

class _SermonPageState extends State<SermonPage> {
  bool _isAdmin = false;
  int _selectedNavIndex = 2;
  bool _showAllSermons = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final status = await AuthService.isAdmin;
    if (mounted) {
      setState(() {
        _isAdmin = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SermonService.getSermons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState('Error: ${snapshot.error}');
          }

          final allSermons = snapshot.data ?? [];
          if (allSermons.isEmpty) {
            return _buildEmptyState();
          }

          allSermons.sort((a, b) =>
              (b['date'] as DateTime).compareTo(a['date'] as DateTime));

          final latestSermon = allSermons.first;
          final otherSermons = allSermons.skip(1).toList();

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLatestSermonHero(latestSermon),
                    const SizedBox(height: 24),
                    if (otherSermons.isNotEmpty)
                      _buildOtherSermonsList(context, otherSermons),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      title: const Text('Sermons'),
      actions: [
        if (_isAdmin)
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded),
            onPressed: () => context.go('/admin/sermons'),
            tooltip: 'Sermon Management',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLatestSermonHero(Map<String, dynamic> sermon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Latest Message",
              style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            sermon['title'] ?? 'Untitled Sermon',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_rounded,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(sermon['pastor'] ?? 'N/A',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                  DateFormat('MMMM d, yyyy').format(sermon['date'] as DateTime),
                  style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sermon['description'] ?? 'No description.',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => _showSermonDetailsSheet(sermon),
            icon: const Icon(Icons.article_rounded),
            label: const Text('Read Full Content'),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherSermonsList(
      BuildContext context, List<Map<String, dynamic>> otherSermons) {
    final theme = Theme.of(context);
    final itemsToShow =
        _showAllSermons ? otherSermons : otherSermons.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 48, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("More Sermons",
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              if (otherSermons.length > 3)
                TextButton(
                  onPressed: () =>
                      setState(() => _showAllSermons = !_showAllSermons),
                  child: Text(_showAllSermons
                      ? 'Show Less'
                      : 'Show All (${otherSermons.length})'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          itemCount: itemsToShow.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sermon = itemsToShow[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: theme.colorScheme.surfaceContainerHighest,
              child: ListTile(
                title: Text(sermon['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(sermon['pastor']),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showSermonDetailsSheet(sermon),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSermonDetailsSheet(Map<String, dynamic> sermon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final theme = Theme.of(context);
        final fullTextToShare =
            "Check out this sermon:\n\n*${sermon['title']}*\nBy: ${sermon['pastor']}\n\n${sermon['description']}";
        final fullTextToCopy =
            "${sermon['title']}\nBy: ${sermon['pastor']}\n\n${sermon['description']}";

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Scaffold(
            body: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Text(sermon['title'],
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close)),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      sermon['description'] ?? 'No content available.',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(height: 1.6, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BottomAppBar(
              elevation: 0,
              color: theme.scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullTextToCopy));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Content copied to clipboard!')));
                      },
                      icon: const Icon(Icons.copy_rounded),
                      tooltip: 'Copy',
                    ),
                    IconButton.filledTonal(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Favorite feature for sermons coming soon!')));
                      },
                      icon: const Icon(Icons.favorite_border_rounded),
                      tooltip: 'Favorite',
                    ),
                    IconButton.filledTonal(
                      onPressed: () => Share.share(fullTextToShare),
                      icon: const Icon(Icons.share_rounded),
                      tooltip: 'Share',
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

  // --- THIS METHOD IS NOW CORRECTED AND COMPLETE ---
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
            break; // Current Page
          case 3:
            context.go('/settings');
            break; // Correctly navigates to Settings
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
        // This is now a Settings button, not an About button
        BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ],
    );
  }

  // --- THIS METHOD IS NOW CORRECTED AND COMPLETE ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No Sermons Available', style: TextStyle(fontSize: 18)),
          if (_isAdmin) ...[
            const SizedBox(height: 8),
            Text('Tap the "Admin Panel" to add the first sermon.',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }

  // --- THIS METHOD IS NOW CORRECTED AND COMPLETE ---
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to Load Sermons',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
