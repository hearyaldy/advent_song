import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:song_lyrics_app/presentation/widgets/collapsible_header.dart';
import 'package:song_lyrics_app/presentation/widgets/collection_card.dart';
import '../../../core/constants/app_constants.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          CollapsibleHeader(
            title: AppConstants.appName,
            subtitle: 'Spiritual Songs Collection',
            scrollController: _scrollController,
            backgroundImage:
                'assets/images/header_image.png', // Add your header image here
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final collections = AppConstants.collections.values.toList();
                  final collection = collections[index];

                  return CollectionCard(
                    metadata: collection,
                    onTap: () {
                      context.go('/collection/${collection.id}');
                    },
                  );
                },
                childCount: AppConstants.collections.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
