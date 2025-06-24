// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:song_lyrics_app/themes/app_theme.dart';
import '../presentation/dashboard/pages/dashboard_page.dart';
import '../presentation/song_list/pages/song_list_page.dart';
import '../presentation/lyrics_viewer/pages/lyrics_page.dart';
import '../presentation/settings/pages/settings_page.dart';

class SongLyricsApp extends StatelessWidget {
  const SongLyricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Song Lyrics App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  static final GoRouter _router = GoRouter(
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
        builder: (context, state) => const SettingsPage(),
      ),
      // Additional routes for quick actions
      GoRoute(
        path: '/favorites',
        redirect: (context, state) => '/collection/lpmi?favorites=true',
      ),
      GoRoute(
        path: '/search',
        redirect: (context, state) => '/collection/lpmi?search=true',
      ),
    ],
    // Handle unknown routes
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
