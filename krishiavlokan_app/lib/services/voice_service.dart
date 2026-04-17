// lib/services/voice_service.dart
//
// Self-contained voice service.
// Handles two responsibilities only:
//   1. TTS question loop  — speaks a question on repeat until cancelled.
//   2. STT answer listen  — listens once with a hard timeout, returns raw text.
//
// This service has NO dependency on DiagnosisProvider or any screen widget.
// It is used exclusively via DiagnosisProvider's voice-addition methods.

import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  // ── TTS ───────────────────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady       = false;
  bool _loopCancelled  = false;

  // ── STT ───────────────────────────────────────────────────────────────────
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttAvailable = false;
  bool _sttInitialised = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Initialise both engines once.
  // Safe to call multiple times — guards with flags.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (!_ttsReady) {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ttsReady = true;
    }

    if (!_sttInitialised) {
      _sttAvailable  = await _stt.initialize(
        onError: (_) {},    // errors handled at call-site
        onStatus: (_) {},
      );
      _sttInitialised = true;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TTS LOOP
  //
  // Speaks [question] repeatedly with a [pauseBetween] gap.
  // Stops after [maxLoops] iterations or when cancelLoop() is called.
  // Calls [onLoopEnd] after every completed speak (used to check cancel).
  // ─────────────────────────────────────────────────────────────────────────

  /// Start a looping TTS of [question]. Returns immediately;
  /// speaking happens asynchronously in the background.
  Future<void> startLoop({
    required String question,
    Duration pauseBetween  = const Duration(milliseconds: 1800),
    int maxLoops           = 8,
    bool enabled           = true,        // respect voiceEnabled setting
  }) async {
    if (!enabled) return;
    await init();

    _loopCancelled = false;

    // Run in background — deliberately not awaited by callers
    _runLoop(question, pauseBetween, maxLoops);
  }

  Future<void> _runLoop(
    String question,
    Duration pause,
    int maxLoops,
  ) async {
    for (int i = 0; i < maxLoops; i++) {
      if (_loopCancelled) break;

      await _tts.speak(question);

      // Wait for TTS to finish by polling completion
      await _waitForTtsComplete();

      if (_loopCancelled) break;

      // Pause between loops
      await Future.delayed(pause);
    }
  }

  /// Waits up to 12 seconds for TTS to finish speaking.
  Future<void> _waitForTtsComplete() async {
    final completer = Completer<void>();
    bool completed  = false;

    _tts.setCompletionHandler(() {
      if (!completed) {
        completed = true;
        if (!completer.isCompleted) completer.complete();
      }
    });

    // Safety timeout so we never hang
    Future.delayed(const Duration(seconds: 12), () {
      if (!completer.isCompleted) completer.complete();
    });

    return completer.future;
  }

  /// Cancel the running TTS loop and stop any current speech immediately.
  Future<void> cancelLoop() async {
    _loopCancelled = true;
    await _tts.stop();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STT LISTEN
  //
  // Listens once for up to [timeout] seconds.
  // Returns the recognised text string, or null on timeout / error / no input.
  // Always stops itself — will never leave the microphone hanging.
  // ─────────────────────────────────────────────────────────────────────────

  Future<String?> listenOnce({
    Duration timeout = const Duration(seconds: 6),
    String localeId  = 'en-US',
  }) async {
    await init();

    if (!_sttAvailable) return null;
    if (_stt.isListening) await _stt.stop();

    final completer = Completer<String?>();

    // Hard timeout — always completes the future even if STT hangs
    final timer = Timer(timeout + const Duration(seconds: 2), () {
      if (!completer.isCompleted) {
        _stt.stop();
        completer.complete(null);
      }
    });

    await _stt.listen(
      localeId: localeId,
      listenFor: timeout,
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        if (result.finalResult && !completer.isCompleted) {
          timer.cancel();
          _stt.stop();
          final text = result.recognizedWords.trim().toLowerCase();
          completer.complete(text.isEmpty ? null : text);
        }
      },
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: true,
    );

    // If STT fails to call onResult, the timer will resolve null safely
    return completer.future;
  }

  /// Stop listening immediately.
  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Full stop — call on screen dispose or manual nav
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> stopAll() async {
    _loopCancelled = true;
    await _tts.stop();
    if (_stt.isListening) await _stt.stop();
  }

  bool get isListening => _stt.isListening;
}
