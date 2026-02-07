import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// Unified speech service handling both STT and TTS
class SpeechService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  bool _inContinuousMode = false;
  double _ttsSpeed = 0.5;

  // Callbacks
  VoidCallback? onListeningStarted;
  VoidCallback? onListeningStopped;
  VoidCallback? onSpeakingStarted;
  VoidCallback? onSpeakingStopped;
  ValueChanged<String>? onPartialResult;
  ValueChanged<String>? onFinalResult;
  ValueChanged<double>? onSoundLevel;
  /// Called with (startOffset, endOffset) as TTS reads each word
  void Function(int start, int end)? onSpeechProgress;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  /// Initialize both STT and TTS
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    // Initialize STT
    final sttAvailable = await _speechToText.initialize(
      onStatus: _onSttStatus,
      onError: _onSttError,
    );

    // Initialize TTS
    await _flutterTts.setLanguage('it-IT');
    await _flutterTts.setSpeechRate(_ttsSpeed);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      onSpeakingStarted?.call();
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      onSpeakingStopped?.call();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      onSpeakingStopped?.call();
      debugPrint('TTS Error: $msg');
    });

    _flutterTts.setProgressHandler((String text, int start, int end, String word) {
      onSpeechProgress?.call(start, end);
    });

    _isInitialized = sttAvailable;
    return sttAvailable;
  }

  /// Set TTS speech rate (0.0 to 1.0)
  Future<void> setSpeed(double speed) async {
    _ttsSpeed = speed;
    await _flutterTts.setSpeechRate(speed);
  }

  /// Set TTS language
  Future<void> setLanguage(String lang) async {
    await _flutterTts.setLanguage(lang);
  }

  // ==================== TTS Methods ====================

  /// Clean markdown formatting from text before speaking
  static String cleanForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\*+'), '') // remove asterisks
        .replaceAll(RegExp(r'_+'), '')  // remove underscores
        .replaceAll(RegExp(r'#+\s*'), '') // remove heading markers
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1') // links -> text only
        .replaceAll(RegExp(r'`+'), '')  // remove backticks
        .replaceAll(RegExp(r'~+'), '')  // remove tildes
        .trim();
  }

  /// Speak the given text. Completes when speech is finished.
  /// Automatically cleans markdown formatting.
  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    final cleanText = cleanForSpeech(text);
    if (cleanText.isEmpty) return;

    // Stop listening if active
    if (_isListening) {
      await stopListening();
    }

    final completer = Completer<void>();

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      onSpeakingStopped?.call();
      if (!completer.isCompleted) completer.complete();
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      onSpeakingStopped?.call();
      if (!completer.isCompleted) completer.complete();
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      onSpeakingStopped?.call();
      if (!completer.isCompleted) completer.complete();
    });

    _isSpeaking = true;
    onSpeakingStarted?.call();
    await _flutterTts.speak(cleanText);

    return completer.future;
  }

  /// Speak characters one by one with a delay between each.
  /// Used for reading hidden sequences slowly.
  Future<void> speakCharByChar(String text, {Duration delay = const Duration(milliseconds: 1000)}) async {
    if (text.isEmpty) return;

    // Stop listening if active
    if (_isListening) {
      await stopListening();
    }

    _isSpeaking = true;
    onSpeakingStarted?.call();

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char.trim().isEmpty) continue; // skip whitespace

      final completer = Completer<void>();

      _flutterTts.setCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      });

      _flutterTts.setErrorHandler((msg) {
        if (!completer.isCompleted) completer.complete();
      });

      await _flutterTts.speak(char);
      await completer.future;

      // Wait between characters
      if (i < text.length - 1) {
        await Future.delayed(delay);
      }
    }

    _isSpeaking = false;
    onSpeakingStopped?.call();
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    onSpeakingStopped?.call();
  }

  // ==================== STT Methods ====================

  /// Start listening for speech input. Returns the final recognized text.
  /// [pauseFor] controls how long silence before finalizing (default 3s).
  Future<String> listen({Duration? timeout, Duration? pauseFor}) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return '';
    }

    // Stop speaking if active
    if (_isSpeaking) {
      await stopSpeaking();
    }

    final completer = Completer<String>();
    String lastResult = '';

    _isListening = true;
    onListeningStarted?.call();

    await _speechToText.listen(
      onResult: (result) {
        lastResult = result.recognizedWords;
        if (result.finalResult) {
          onFinalResult?.call(lastResult);
          if (!completer.isCompleted) {
            completer.complete(lastResult);
          }
        } else {
          onPartialResult?.call(lastResult);
        }
      },
      localeId: 'it_IT',
      listenFor: timeout ?? const Duration(seconds: 30),
      pauseFor: pauseFor ?? const Duration(seconds: 3),
      onSoundLevelChange: (level) {
        onSoundLevel?.call(level);
      },
    );

    // Timeout safety
    final maxDuration = timeout ?? const Duration(seconds: 30);
    Future.delayed(maxDuration + const Duration(seconds: 2), () {
      if (!completer.isCompleted) {
        _isListening = false;
        onListeningStopped?.call();
        completer.complete(lastResult);
      }
    });

    final result = await completer.future;
    _isListening = false;
    onListeningStopped?.call();
    return result;
  }

  /// Listen continuously for a total duration, collecting all speech.
  /// Restarts listening after each pause so the user can think and continue.
  /// Used for timed exercises like verbal fluency (60 seconds).
  Future<String> listenContinuous({required Duration totalDuration}) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return '';
    }

    // Stop speaking if active
    if (_isSpeaking) {
      await stopSpeaking();
    }

    final allWords = <String>[];
    final stopwatch = Stopwatch()..start();

    // Enter continuous mode: suppress intermediate onListeningStopped signals
    _inContinuousMode = true;
    _isListening = true;
    onListeningStarted?.call();

    while (stopwatch.elapsed < totalDuration) {
      final remaining = totalDuration - stopwatch.elapsed;
      if (remaining.inSeconds < 2) break;

      // Stop previous round cleanly before restarting
      await _speechToText.stop();
      await Future.delayed(const Duration(milliseconds: 300));

      final completer = Completer<String>();
      String lastResult = '';

      await _speechToText.listen(
        onResult: (result) {
          lastResult = result.recognizedWords;
          if (result.finalResult) {
            onFinalResult?.call(lastResult);
            if (!completer.isCompleted) {
              completer.complete(lastResult);
            }
          } else {
            onPartialResult?.call(
              [...allWords, lastResult].where((w) => w.isNotEmpty).join(', '),
            );
          }
        },
        localeId: 'it_IT',
        listenFor: remaining,
        pauseFor: const Duration(seconds: 5),
        onSoundLevelChange: (level) {
          onSoundLevel?.call(level);
        },
      );

      // Safety timeout for this round
      Future.delayed(remaining + const Duration(seconds: 1), () {
        if (!completer.isCompleted) {
          completer.complete(lastResult);
        }
      });

      final result = await completer.future;
      if (result.isNotEmpty) {
        allWords.add(result);
        // Show accumulated words to the UI
        onPartialResult?.call(allWords.join(', '));
      }

      // Check if we still have time
      if (stopwatch.elapsed >= totalDuration) break;
    }

    // Exit continuous mode
    await _speechToText.stop();
    stopwatch.stop();
    _inContinuousMode = false;
    _isListening = false;
    onListeningStopped?.call();

    return allWords.join(', ');
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    onListeningStopped?.call();
  }

  // ==================== Private Handlers ====================

  void _onSttStatus(String status) {
    debugPrint('STT Status: $status');
    if (status == 'done' || status == 'notListening') {
      // In continuous mode, don't signal stop between rounds
      if (!_inContinuousMode) {
        _isListening = false;
        onListeningStopped?.call();
      }
    }
  }

  void _onSttError(dynamic error) {
    debugPrint('STT Error: $error');
    _isListening = false;
    onListeningStopped?.call();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopSpeaking();
    await stopListening();
    _speechToText.cancel();
  }
}
