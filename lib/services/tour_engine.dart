import 'package:flutter/foundation.dart';
import '../models/tour_step.dart';
import '../controllers/lg_controller.dart';
import '../services/kml_builder_service.dart';
import '../services/tts_service.dart';

class TourEngine {
  final LGController lgController;
  final KmlBuilderService kmlBuilder;
  final TtsService ttsService;

  List<TourStep> _steps = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isPaused = false;
  VoidCallback? onStepChanged;
  VoidCallback? onTourComplete;

  TourEngine({
    required this.lgController,
    required this.kmlBuilder,
    required this.ttsService,
  });

  int get currentIndex => _currentIndex;
  int get totalSteps => _steps.length;
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  TourStep? get currentStep =>
      _currentIndex >= 0 && _currentIndex < _steps.length
      ? _steps[_currentIndex]
      : null;

  void loadTour(List<TourStep> steps) {
    _steps = steps;
    _currentIndex = -1;
    _isPlaying = false;
    _isPaused = false;
  }

  Future<void> play() async {
    if (_steps.isEmpty) return;

    _isPlaying = true;
    _isPaused = false;

    if (_currentIndex < 0) {
      _currentIndex = 0;
    }

    while (_currentIndex < _steps.length && _isPlaying) {
      if (_isPaused) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }

      final step = _steps[_currentIndex];
      onStepChanged?.call();

      try {
        // Clear previous KML
        // await lgController.safeExecute('> /var/www/html/kmls.txt');
        // await Future.delayed(const Duration(milliseconds: 300));

        // Send KML if this step has one
        if (step.kmlAction != null) {
          await lgController.sendKmlToMaster(step.kmlAction!);
        }

        // Fly to location
        await lgController.safeQuery(
          kmlBuilder.buildLookAt(
            lat: step.latitude,
            lng: step.longitude,
            range: step.range,
            tilt: step.tilt,
            heading: step.heading,
          ),
        );

        // Wait for camera to arrive
        await Future.delayed(const Duration(seconds: 1));

        await Future.delayed(const Duration(seconds: 5));

        // Speak narration and wait for it to finish
        await _speakAndWait(step.narration);

        // Small pause between steps
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        debugPrint('Tour step $_currentIndex failed: $e');
      }

      if (_isPlaying && !_isPaused) {
        _currentIndex++;
      }
    }

    if (_currentIndex >= _steps.length) {
      _isPlaying = false;
      _currentIndex = _steps.length - 1;
      onTourComplete?.call();
    }
  }

  Future<void> _speakAndWait(String text) async {
    final completer = ValueNotifier<bool>(false);

    ttsService.onComplete = () {
      completer.value = true;
    };

    await ttsService.speak(text);

    // Wait for TTS to complete or timeout after 30 seconds
    int waited = 0;
    while (!completer.value && waited < 300 && _isPlaying && !_isPaused) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited++;
    }

    ttsService.onComplete = null;
  }

  void pause() {
    _isPaused = true;
    ttsService.pause();
    onStepChanged?.call();
  }

  void resume() {
    _isPaused = false;
    onStepChanged?.call();
  }

  Future<void> stop() async {
    _isPlaying = false;
    _isPaused = false;
    _currentIndex = -1;
    await ttsService.stop();
    onStepChanged?.call();
  }

  Future<void> next() async {
    if (_currentIndex < _steps.length - 1) {
      await ttsService.stop();
      _currentIndex++;
      _isPaused = false;
      onStepChanged?.call();
    }
  }

  Future<void> previous() async {
    if (_currentIndex > 0) {
      await ttsService.stop();
      _currentIndex--;
      _isPaused = false;
      onStepChanged?.call();
    }
  }
}
