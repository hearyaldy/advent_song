// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/theme_notifier.dart';
import '../core/services/favorites_notifier.dart';
import '../presentation/dashboard/pages/figma_dashboard_page.dart';
import '../presentation/song_list/pages/song_list_page.dart';
import '../presentation/lyrics_viewer/pages/lyrics_page.dart';
import '../presentation/settings/pages/settings_page.dart';
import '../presentation/sermons/pages/sermon_page.dart';
import '../presentation/admin/pages/sermon_management_page.dart';
import '../presentation/admin/pages/add_edit_sermon_page.dart';
import '../presentation/auth/pages/login_page.dart';
import '../presentation/auth/pages/register_page.dart';
import '../presentation/auth/pages/profile_page.dart';
import '../presentation/favorites/pages/favorites_page.dart';

// The app widget is now a StatefulWidget to create a stable router instance.
class SongLyricsApp extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final FavoritesNotifier favoritesNotifier;

  const SongLyricsApp({
    super.key,
    required this.themeNotifier,
    required this.favoritesNotifier,
  });

  @override
  State<SongLyricsApp> createState() => _SongLyricsAppState();
}

class _SongLyricsAppState extends State<SongLyricsApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // The router is created once here and will not be rebuilt on state changes.
    _router = _createRouter();
  }

  @override
  Widget build(BuildContext context) {
    // The AnimatedBuilder now only rebuilds the MaterialApp, not the router itself.
    return AnimatedBuilder(
      animation: widget.themeNotifier,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Song Lyrics App',
          theme: widget.themeNotifier.lightTheme,
          darkTheme: widget.themeNotifier.darkTheme,
          themeMode: widget.themeNotifier.themeMode,
          routerConfig: _router, // Use the stable router instance.
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  // The router configuration is now defined in the state.
  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              FigmaDashboardPage(favoritesNotifier: widget.favoritesNotifier),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/collection/:collectionId',
          builder: (context, state) {
            final collectionId = state.pathParameters['collectionId']!;
            final openSearch = state.uri.queryParameters['search'] == 'true';
            return SongListPage(
              collectionId: collectionId,
              openSearch: openSearch,
              favoritesNotifier: widget.favoritesNotifier,
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
              favoritesNotifier: widget.favoritesNotifier,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) =>
              SettingsPage(themeNotifier: widget.themeNotifier),
        ),
        GoRoute(
          path: '/sermons',
          builder: (context, state) => const SermonPage(),
        ),
        // Admin Routes
        GoRoute(
          path: '/admin/sermons',
          builder: (context, state) => const SermonManagementPage(),
        ),
        GoRoute(
          path: '/admin/sermons/add',
          builder: (context, state) => const AddEditSermonPage(),
        ),
        GoRoute(
          path: '/admin/sermons/edit/:sermonId',
          builder: (context, state) {
            final sermonData = state.extra as Map<String, dynamic>?;
            return AddEditSermonPage(sermon: sermonData);
          },
        ),
        // Shortcuts
        GoRoute(
          path: '/favorites',
          builder: (context, state) => FavoritesPage(
            favoritesNotifier: widget.favoritesNotifier,
          ),
        ),
        GoRoute(
          path: '/search',
          // Changed default search collection from 'lpmi' to 'srd'
          redirect: (context, state) => '/collection/srd?search=true',
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(child: Text('Page not found: ${state.error}')),
      ),
    );
  }
}
