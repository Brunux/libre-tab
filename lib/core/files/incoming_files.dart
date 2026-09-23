import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Files other apps hand to Libre Tab: "Open in Libre Tab" from Files,
/// Safari, Mail or a chat app, or "Share to" on Android. Behind a provider
/// so tests can fake it.
final incomingFilesProvider = Provider<IncomingFiles>((ref) {
  final files = ChannelIncomingFiles();
  ref.onDispose(files.dispose);
  return files;
});

/// One file handed to the app.
typedef ReceivedFile = ({String name, Uint8List bytes});

abstract interface class IncomingFiles {
  /// Calls [onFile] for every file received, including the one the app was
  /// launched with.
  void listen(void Function(ReceivedFile file) onFile);

  void dispose();
}

/// Talks to the host apps (ios/Runner/IncomingFiles.swift,
/// android/…/MainActivity.kt). They queue files as they arrive and say
/// `filesAvailable`; Dart collects them with `takePending`, so a file that
/// arrives before Flutter is listening isn't lost.
class ChannelIncomingFiles implements IncomingFiles {
  ChannelIncomingFiles([
    this._channel = const MethodChannel('libre_tab/incoming_files'),
  ]);

  final MethodChannel _channel;
  void Function(ReceivedFile file)? _onFile;

  @override
  void listen(void Function(ReceivedFile file) onFile) {
    _onFile = onFile;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'filesAvailable') await _take();
    });
    unawaited(_take());
  }

  Future<void> _take() async {
    try {
      final pending = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'takePending',
      );
      for (final file in pending ?? const <Map<Object?, Object?>>[]) {
        final name = file['name'];
        final bytes = file['bytes'];
        if (name is String && bytes is Uint8List) {
          _onFile?.call((name: name, bytes: bytes));
        }
      }
    } on MissingPluginException {
      // No host side (desktop, widget tests): nothing can arrive.
    } on PlatformException {
      // The host couldn't read a file; nothing to show for it.
    }
  }

  @override
  void dispose() {
    _onFile = null;
    _channel.setMethodCallHandler(null);
  }
}
