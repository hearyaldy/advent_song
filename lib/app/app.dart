// lib/app/app.dart - UPDATED WITH ROUTE VALIDATION
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/services/theme_notifier.dart';
import '../core/services/favorites_notifier.dart';
import '../core/constants/app_constants.dart';
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
import '../presentation/shared/pages/not_found_page.dart';

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
    _router = _createRouter();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.themeNotifier,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Song Lyrics App',
          theme: widget.themeNotifier.lightTheme,
          darkTheme: widget.themeNotifier.darkTheme,
          themeMode: widget.themeNotifier.themeMode,
          routerConfig: _router,
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
        // UPDATED: Collection route with validation
        GoRoute(
          path: '/collection/:collectionId',
          builder: (context, state) {
            final collectionId = state.pathParameters['collectionId']!;

            // Validate collection exists
            if (!AppConstants.collections.containsKey(collectionId)) {
              return NotFoundPage(
                title: 'Collection Not Found',
                message: 'The collection "$collectionId" does not exist.',
                actionText: 'View Collections',
                onAction: () => context.go('/'),
              );
            }

            final openSearch = state.uri.queryParameters['search'] == 'true';
            return SongListPage(
              collectionId: collectionId,
              openSearch: openSearch,
              favoritesNotifier: widget.favoritesNotifier,
            );
          },
        ),
        // UPDATED: Lyrics route with validation
        GoRoute(
          path: '/lyrics/:collectionId/:songId',
          builder: (context, state) {
            final collectionId = state.pathParameters['collectionId']!;
            final songId = state.pathParameters['songId']!;

            // Validate collection exists
            if (!AppConstants.collections.containsKey(collectionId)) {
              return NotFoundPage(
                title: 'Collection Not Found',
                message: 'The collection "$collectionId" does not exist.',
                actionText: 'View Collections',
                onAction: () => context.go('/'),
              );
            }

            // Note: Song validation happens in LyricsPage since it requires async loading
            return LyricsPage(
              collectionId: collectionId,
              songId: songId,
              favoritesNotifier: widget.favoritesNotifier,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => SettingsPage(
            themeNotifier: widget.themeNotifier,
            favoritesNotifier: widget.favoritesNotifier,
          ),
        ),
        GoRoute(
          path: '/sermons',
          builder: (context, state) => const SermonPage(),
        ),
        // Admin Routes with validation
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
            final sermonId = state.pathParameters['sermonId'];
            if (sermonId == null || sermonId.isEmpty) {
              return const NotFoundPage(
                title: 'Invalid Sermon',
                message: 'Sermon ID is required for editing.',
              );
            }

            final sermonData = state.extra as Map<String, dynamic>?;
            return AddEditSermonPage(sermon: sermonData);
          },
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => FavoritesPage(
            favoritesNotifier: widget.favoritesNotifier,
          ),
        ),
        // UPDATED: Search redirect with validation
        GoRoute(
          path: '/search',
          redirect: (context, state) {
            // Ensure SRD collection exists before redirecting
            if (AppConstants.collections.containsKey('srd')) {
              return '/collection/srd?search=true';
            }
            // Fallback to first available collection
            final firstCollection = AppConstants.collections.keys.first;
            return '/collection/$firstCollection?search=true';
          },
        ),
      ],
      // UPDATED: Better error handling
      errorBuilder: (context, state) => NotFoundPage(
        title: 'Page Not Found',
        message: 'The page "${state.uri.path}" could not be found.',
        actionText: 'Go Home',
        onAction: () => context.go('/'),
      ),
      // Add redirect for invalid routes
      redirect: (context, state) {
        // Handle any additional redirect logic here if needed
        return null;
      },
    );
  }
}
