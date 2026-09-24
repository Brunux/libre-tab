import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens Libre Tab's page in the system Settings, where a refused
/// permission (microphone, camera) can be allowed again: the system never
/// asks twice. Behind a provider so tests can fake it.
final appSettingsProvider = Provider<AppSettings>(
  (ref) => const ChannelAppSettings(),
);

// An interface, not a function, so tests can override the provider.
// ignore: one_member_abstracts
abstract interface class AppSettings {
  /// Whether the settings page opened.
  Future<bool> open();
}

/// ios/Runner/AppDelegate.swift and android/…/MainActivity.kt.
class ChannelAppSettings implements AppSettings {
  const ChannelAppSettings();

  static const _channel = MethodChannel('libre_tab/app_settings');

  @override
  Future<bool> open() async {
    try {
      return await _channel.invokeMethod<bool>('open') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
