import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  VoidCallback? onComplete;

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      onComplete?.call();
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint('TTS Error: $msg');
    });
  }

  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }

  Future<void> pause() async {
    _isSpeaking = false;
    await _tts.pause();
  }

  void dispose() {
    _tts.stop();
  }
}
