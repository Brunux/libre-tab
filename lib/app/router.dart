import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:libre_tab/app/shell.dart';
import 'package:libre_tab/features/editor/presentation/add_song_screen.dart';
import 'package:libre_tab/features/library/presentation/library_screen.dart';
import 'package:libre_tab/features/settings/presentation/settings_screen.dart';
import 'package:libre_tab/features/song_view/presentation/song_view_screen.dart';
import 'package:libre_tab/features/tuner/presentation/tuner_screen.dart';

abstract final class Routes {
  static const songbook = '/songs';
  static const addSong = '/songs/new';
  static const tuner = '/tuner';
  static const settings = '/settings';
  static String song(String id) => '/songs/$id';
}

/// Two bottom tabs (Songbook, Tuner). Song view, Add song and Settings open
/// full screen on the root navigator, above the tab bar (docs/DESIGN.md).
final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.songbook,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.songbook,
                builder: (_, _) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: rootKey,
                    builder: (_, _) => const AddSongScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) =>
                        SongViewScreen(songId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.tuner,
                builder: (_, _) => const TunerScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const SettingsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
