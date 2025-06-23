import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:song_lyrics_app/themes/app_theme.dart';
import '../presentation/dashboard/pages/dashboard_page.dart';
import '../presentation/song_list/pages/song_list_page.dart';
import '../presentation/lyrics_viewer/pages/lyrics_page.dart';

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
          return SongListPage(collectionId: collectionId);
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
    ],
  );
}
