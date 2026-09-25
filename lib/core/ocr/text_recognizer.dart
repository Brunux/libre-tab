import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:libre_tab/core/ocr/ocr_layout.dart';

/// Reads the words in a photo, on the device: Apple Vision on iOS, Tesseract
/// on Android (ios/Runner/AppDelegate.swift, android/…/TextRecognition.kt).
/// Behind a provider so tests can fake it.
final textRecognizerProvider = Provider<TextRecognizer>(
  (ref) => const ChannelTextRecognizer(),
);

// An interface, not a function, so tests can override the provider.
abstract interface class TextRecognizer {
  /// Every word in the image at [imagePath], with its box in pixels of the
  /// upright image. Throws [TextRecognitionException] if it can't be read.
  Future<List<RecognizedWord>> recognize(String imagePath);
}

class TextRecognitionException implements Exception {
  const TextRecognitionException(this.message);

  final String message;

  @override
  String toString() => 'TextRecognitionException: $message';
}

class ChannelTextRecognizer implements TextRecognizer {
  const ChannelTextRecognizer();

  static const _channel = MethodChannel('libre_tab/text_recognition');

  @override
  Future<List<RecognizedWord>> recognize(String imagePath) async {
    final List<Map<Object?, Object?>>? words;
    try {
      words = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'recognize',
        {'path': imagePath},
      );
    } on PlatformException catch (e) {
      throw TextRecognitionException(e.message ?? e.code);
    } on MissingPluginException {
      throw const TextRecognitionException('No text recognition here');
    }
    return [
      for (final w in words ?? const <Map<Object?, Object?>>[])
        if (w case {
          'text': final String text,
          'left': final num left,
          'top': final num top,
          'right': final num right,
          'bottom': final num bottom,
        })
          RecognizedWord(
            text,
            left: left.toDouble(),
            top: top.toDouble(),
            right: right.toDouble(),
            bottom: bottom.toDouble(),
          ),
    ];
  }
}
