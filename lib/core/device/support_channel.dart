import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// The fixed places "Support Libre Tab" can open. The native side maps each
/// to its one URL (an allow-list: nothing else can be opened through it).
enum SupportLink {
  /// buymeacoffee.com/brunux — shown only where the store allows it.
  coffee,

  /// The project on GitHub.
  github,
}

/// Ways to support the project that need the platform: which App Store
/// storefront the app came from (a tip link is only allowed in some), the
/// system's review prompt, and opening a link in the browser. Behind a
/// provider so tests can fake it.
final supportChannelProvider = Provider<SupportChannel>(
  (ref) => const MethodSupportChannel(),
);

abstract interface class SupportChannel {
  /// The App Store storefront's country (ISO 3166-1 alpha-3, "USA"), or
  /// null when unknown or not on iOS.
  Future<String?> storefront();

  /// Opens [link] in the browser. Whether it opened.
  Future<bool> open(SupportLink link);

  /// Asks the store to show its rating prompt (iOS), or opens the app's
  /// store page to rate it (Android).
  Future<void> rate();

  /// Shares [text] (a word about the app) through the system share sheet.
  Future<void> share(String text);
}

/// ios/Runner/AppDelegate.swift and android/…/MainActivity.kt.
class MethodSupportChannel implements SupportChannel {
  const MethodSupportChannel();

  static const _channel = MethodChannel('libre_tab/support');

  @override
  Future<String?> storefront() => _call<String>('storefront');

  @override
  Future<bool> open(SupportLink link) async =>
      await _call<bool>('open', link.name) ?? false;

  @override
  Future<void> rate() => _call<void>('rate');

  @override
  Future<void> share(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  static Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
