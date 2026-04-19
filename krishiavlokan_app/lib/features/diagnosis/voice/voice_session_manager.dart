import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

typedef VoiceChunkHandler = Future<void> Function(File audioChunk);
typedef VoiceSessionErrorHandler = void Function(Object error, StackTrace stack);

class VoiceSessionManager {
  VoiceSessionManager({
    AudioRecorder? recorder,
    this.chunkDuration = const Duration(seconds: 4),
    this.silenceTimeout = const Duration(seconds: 6),
    this.amplitudeWindow = const Duration(milliseconds: 600),
    this.silenceThresholdDb = -38,
  }) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final Duration chunkDuration;
  final Duration silenceTimeout;
  final Duration amplitudeWindow;
  final double silenceThresholdDb;

  bool _isRunning = false;
  bool _isRotatingChunk = false;
  VoiceChunkHandler? _onChunkReady;
  VoidCallback? _onSilenceTimeout;
  VoiceSessionErrorHandler? _onError;
  Timer? _chunkTimer;
  Timer? _silenceTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  bool get isRunning => _isRunning;

  Future<void> start({
    required VoiceChunkHandler onChunkReady,
    VoidCallback? onSilenceTimeout,
    VoiceSessionErrorHandler? onError,
  }) async {
    if (_isRunning) {
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw const VoiceSessionException('Microphone permission not granted.');
    }

    _onChunkReady = onChunkReady;
    _onSilenceTimeout = onSilenceTimeout;
    _onError = onError;
    _isRunning = true;

    _resetSilenceTimer();
    await _startFreshChunk();
  }

  Future<void> stop({bool emitFinalChunk = true}) async {
    if (!_isRunning && !_isRotatingChunk) {
      return;
    }

    _isRunning = false;
    _chunkTimer?.cancel();
    _chunkTimer = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    final chunkPath = await _stopRecorderSafely();
    if (emitFinalChunk && chunkPath != null) {
      await _emitChunk(chunkPath);
    }
  }

  void dispose() {
    unawaited(stop(emitFinalChunk: false));
    _recorder.dispose();
  }

  Future<void> _startFreshChunk() async {
    if (!_isRunning) {
      return;
    }

    final path = _buildChunkPath();
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      await _attachAmplitudeStream();
      _chunkTimer?.cancel();
      _chunkTimer = Timer(chunkDuration, () {
        unawaited(_rotateChunk());
      });
    } catch (error, stack) {
      _handleError(error, stack);
      await stop(emitFinalChunk: false);
    }
  }

  Future<void> _rotateChunk() async {
    if (!_isRunning || _isRotatingChunk) {
      return;
    }

    _isRotatingChunk = true;
    try {
      final chunkPath = await _stopRecorderSafely();
      if (chunkPath != null) {
        await _emitChunk(chunkPath);
      }
    } finally {
      _isRotatingChunk = false;
    }

    if (_isRunning) {
      await _startFreshChunk();
    }
  }

  Future<void> _attachAmplitudeStream() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(amplitudeWindow)
        .listen(_handleAmplitude, onError: _handleError);
  }

  void _handleAmplitude(Amplitude amplitude) {
    if (!_isRunning) {
      return;
    }

    if (amplitude.current >= silenceThresholdDb) {
      _resetSilenceTimer();
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(silenceTimeout, () {
      _onSilenceTimeout?.call();
    });
  }

  Future<String?> _stopRecorderSafely() async {
    try {
      return await _recorder.stop();
    } catch (_) {
      return null;
    }
  }

  Future<void> _emitChunk(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return;
    }

    final length = await file.length();
    if (length == 0) {
      await file.delete().catchError((_) {});
      return;
    }

    try {
      await _onChunkReady?.call(file);
    } catch (error, stack) {
      _handleError(error, stack);
    }
  }

  void _handleError(Object error, [StackTrace? stack]) {
    final trace = stack ?? StackTrace.current;
    _onError?.call(error, trace);
  }

  String _buildChunkPath() {
    final fileName =
        'voice_${DateTime.now().microsecondsSinceEpoch.toString()}.wav';
    return '${Directory.systemTemp.path}${Platform.pathSeparator}$fileName';
  }
}

class VoiceSessionException implements Exception {
  const VoiceSessionException(this.message);

  final String message;

  @override
  String toString() => message;
}
