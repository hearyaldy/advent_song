// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/theme_notifier.dart';
import '../presentation/dashboard/pages/dashboard_page.dart';
import '../presentation/song_list/pages/song_list_page.dart';
import '../presentation/lyrics_viewer/pages/lyrics_page.dart';
import '../presentation/settings/pages/settings_page.dart';

class SongLyricsApp extends StatelessWidget {
  final ThemeNotifier themeNotifier;

  const SongLyricsApp({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Song Lyrics App',
          theme: themeNotifier.lightTheme,
          darkTheme: themeNotifier.darkTheme,
          themeMode: themeNotifier.themeMode,
          routerConfig: _createRouter(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/collection/:collectionId',
          builder: (context, state) {
            final collectionId = state.pathParameters['collectionId']!;
            final showFavoritesOnly =
                state.uri.queryParameters['favorites'] == 'true';
            final openSearch = state.uri.queryParameters['search'] == 'true';

            return SongListPage(
              collectionId: collectionId,
              showFavoritesOnly: showFavoritesOnly,
              openSearch: openSearch,
            );
          },
        ),
        GoRoute(
          path: '/lyrics/:collectionId/:songId',
          builder: (context, state) {
            final collectionId = state.pathParameters['collectionId']!;
            final songId = state.pathParameters['songId']!;
            return LyricsPage(
              collectionId: collectionId,
              songId: songId,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) =>
              SettingsPage(themeNotifier: themeNotifier),
        ),
        GoRoute(
          path: '/favorites',
          redirect: (context, state) => '/collection/lpmi?favorites=true',
        ),
        GoRoute(
          path: '/search',
          redirect: (context, state) => '/collection/lpmi?search=true',
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Page Not Found'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Page Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'The page "${state.uri}" could not be found.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
