import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/app/router.dart';
import 'package:libre_tab/app/theme/app_theme.dart';
import 'package:libre_tab/app/theme/theme_controller.dart';
import 'package:libre_tab/core/files/incoming_files.dart';
import 'package:libre_tab/core/files/song_files.dart';
import 'package:libre_tab/features/library/data/song_repository.dart';
import 'package:libre_tab/features/settings/presentation/settings_screen.dart';
import 'package:libre_tab/l10n/l10n.dart';

class LibreTabApp extends ConsumerStatefulWidget {
  const LibreTabApp({super.key});

  @override
  ConsumerState<LibreTabApp> createState() => _LibreTabAppState();
}

class _LibreTabAppState extends ConsumerState<LibreTabApp> {
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    ref.read(incomingFilesProvider).listen(_received);
  }

  /// A file from another app opens in Add song, as if picked with "Open
  /// file" (docs/DESIGN.md § Add / edit song).
  void _received(ReceivedFile file) {
    // Wait for a frame: the app may still be starting.
    unawaited(
      SchedulerBinding.instance.endOfFrame.then((_) {
        if (!mounted) return;
        // A songbook export: add its songs (docs/SONG_FORMAT.md § Files).
        if (file.name.toLowerCase().endsWith('.zip')) {
          final messenger = _messenger.currentState;
          if (messenger == null) return;
          unawaited(
            importSongFile(
              ref.read(songRepositoryProvider),
              messenger,
              messenger.context.l10n,
              name: file.name,
              bytes: file.bytes,
            ),
          );
          return;
        }
        if (!SongFiles.isSongFile(file.name)) {
          final messenger = _messenger.currentState;
          if (messenger == null) return;
          messenger.showSnackBar(
            SnackBar(content: Text(messenger.context.l10n.notASongFile)),
          );
          return;
        }
        if (file.bytes.length > SongFiles.maxSongBytes) {
          final messenger = _messenger.currentState;
          messenger?.showSnackBar(
            SnackBar(content: Text(messenger.context.l10n.fileTooBig)),
          );
          return;
        }
        unawaited(
          ref
              .read(routerProvider)
              .push(Routes.addSong, extra: SongFiles.decode(file.bytes)),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final variant = ref.watch(themeVariantProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      theme: buildTheme(variant),
      routerConfig: ref.watch(routerProvider),
      scaffoldMessengerKey: _messenger,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}
