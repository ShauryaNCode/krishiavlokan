// lib/services/voice_service.dart
//
// Upgraded voice service with two distinct operating modes:
//
//   MODE A — listenOnce()
//     Single-shot listen used by Steps 1–3.
//     Returns one string then stops. Behaviour unchanged.
//
//   MODE B — startContinuous() / stopContinuous()
//     Used by Step 4 (symptom selection).
//     Emits speech chunks via [transcriptStream] indefinitely.
//     The stream stays open until stopContinuous() is called.
//     Each partial/final STT result is broadcast as a chunk.
//     Silence timeout is handled by the CALLER (DiagnosisProvider),
//     not here — this layer only manages the mic.

import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  // ── TTS ───────────────────────────────────────────────────────────────────
  final FlutterTts _tts          = FlutterTts();
  bool             _ttsReady     = false;
  bool             _loopCancelled = false;

  // ── STT ───────────────────────────────────────────────────────────────────
  final stt.SpeechToText _stt            = stt.SpeechToText();
  bool                   _sttAvailable   = false;
  bool                   _sttInitialised = false;

  // ── Continuous-mode stream ─────────────────────────────────────────────────
  // Broadcast so multiple listeners are safe (provider + screen).
  StreamController<String>? _transcriptController;

  /// Emits every speech chunk (partial or final) while continuous mode is on.
  /// Yields empty stream when not in continuous mode.
  Stream<String> get transcriptStream =>
      _transcriptController?.stream ?? const Stream.empty();

  bool get isContinuousActive =>
      _transcriptController != null && !(_transcriptController!.isClosed);

  // ── Shared init ───────────────────────────────────────────────────────────

  Future<void> init() async {
    if (!_ttsReady) {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ttsReady = true;
    }
    if (!_sttInitialised) {
      _sttAvailable   = await _stt.initialize(
        onError:  (_) => _onSttError(),
        onStatus: (s) => _onSttStatus(s),
      );
      _sttInitialised = true;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TTS LOOP  (unchanged from previous version)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> startLoop({
    required String question,
    Duration pauseBetween = const Duration(milliseconds: 1800),
    int maxLoops          = 8,
    bool enabled          = true,
  }) async {
    if (!enabled) return;
    await init();
    _loopCancelled = false;
    _runLoop(question, pauseBetween, maxLoops);
  }

  Future<void> _runLoop(String question, Duration pause, int maxLoops) async {
    for (int i = 0; i < maxLoops; i++) {
      if (_loopCancelled) break;
      await _tts.speak(question);
      await _waitForTtsComplete();
      if (_loopCancelled) break;
      await Future.delayed(pause);
    }
  }

  Future<void> _waitForTtsComplete() async {
    final completer = Completer<void>();
    bool  completed = false;
    _tts.setCompletionHandler(() {
      if (!completed) {
        completed = true;
        if (!completer.isCompleted) completer.complete();
      }
    });
    Future.delayed(const Duration(seconds: 12), () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  Future<void> cancelLoop() async {
    _loopCancelled = true;
    await _tts.stop();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODE A — listenOnce  (used by Steps 1–3, unchanged)
  // ══════════════════════════════════════════════════════════════════════════

  Future<String?> listenOnce({
    Duration timeout = const Duration(seconds: 6),
    String localeId  = 'en-US',
  }) async {
    await init();
    if (!_sttAvailable) return null;
    if (_stt.isListening) await _stt.stop();

    final completer = Completer<String?>();
    final timer = Timer(timeout + const Duration(seconds: 2), () {
      if (!completer.isCompleted) {
        _stt.stop();
        completer.complete(null);
      }
    });

    await _stt.listen(
      localeId:      localeId,
      listenFor:     timeout,
      pauseFor:      const Duration(seconds: 3),
      listenMode:    stt.ListenMode.confirmation,
      cancelOnError: true,
      onResult: (result) {
        if (result.finalResult && !completer.isCompleted) {
          timer.cancel();
          _stt.stop();
          final text = result.recognizedWords.trim().toLowerCase();
          completer.complete(text.isEmpty ? null : text);
        }
      },
    );
    return completer.future;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MODE B — continuous stream  (used by Step 4)
  //
  // How it works:
  //   • Opens a fresh broadcast StreamController.
  //   • Calls _stt.listen in dictation mode with a long listenFor window.
  //   • Every STT result (partial + final) is pushed to the stream.
  //   • When STT auto-pauses (pauseFor elapsed), _restartContinuous() kicks
  //     it off again immediately — this is what makes it truly continuous.
  //   • stopContinuous() closes the controller and stops the mic.
  // ══════════════════════════════════════════════════════════════════════════

  bool _continuousShouldRun = false;

  /// Start continuous listening. Returns immediately.
  /// Listen to [transcriptStream] for results.
  Future<void> startContinuous({String localeId = 'en-US'}) async {
    await init();
    if (!_sttAvailable) return;

    // Close any previous session cleanly
    await _closeContinuousController();

    _transcriptController    = StreamController<String>.broadcast();
    _continuousShouldRun     = true;

    await _runContinuousSession(localeId);
  }

  Future<void> _runContinuousSession(String localeId) async {
    if (!_continuousShouldRun) return;
    if (_stt.isListening) await _stt.stop();

    // Each session listens for up to 30s.
    // pauseFor is set very short so we get results quickly.
    // When this session ends naturally, _onSttStatus detects 'done'
    // and restarts if _continuousShouldRun is still true.
    await _stt.listen(
      localeId:      localeId,
      listenFor:     const Duration(seconds: 30),
      pauseFor:      const Duration(milliseconds: 1500),
      listenMode:    stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
      onResult: (result) {
        if (!_continuousShouldRun) return;
        final text = result.recognizedWords.trim().toLowerCase();
        if (text.isNotEmpty) {
          // Emit every partial + final chunk so provider can process live
          _transcriptController?.add(text);
        }
      },
    );
  }

  void _onSttStatus(String status) {
    // When STT session ends (paused/done), restart automatically
    // if continuous mode is still required.
    if ((status == 'done' || status == 'notListening') &&
        _continuousShouldRun) {
      // Small gap to avoid tight restart loop
      Future.delayed(const Duration(milliseconds: 120), () {
        if (_continuousShouldRun) {
          _runContinuousSession('en-US');
        }
      });
    }
  }

  void _onSttError() {
    // On error in continuous mode, restart after brief delay
    if (_continuousShouldRun) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_continuousShouldRun) {
          _runContinuousSession('en-US');
        }
      });
    }
  }

  /// Stop continuous listening and close the stream.
  Future<void> stopContinuous() async {
    _continuousShouldRun = false;
    if (_stt.isListening) await _stt.stop();
    await _closeContinuousController();
  }

  Future<void> _closeContinuousController() async {
    if (_transcriptController != null && !_transcriptController!.isClosed) {
      await _transcriptController!.close();
    }
    _transcriptController = null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED STOP
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> stopListening() async {
    if (_stt.isListening) await _stt.stop();
  }

  Future<void> stopAll() async {
    _loopCancelled = true;
    await _tts.stop();
    await stopContinuous();
    if (_stt.isListening) await _stt.stop();
  }

  bool get isListening        => _stt.isListening;
}