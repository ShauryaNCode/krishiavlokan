import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../providers/diagnosis_provider.dart';
import 'voice_api_service.dart';
import 'voice_session_manager.dart';

class VoiceController {
  VoiceController({
    required DiagnosisProvider provider,
    VoiceApiService? apiService,
    VoiceSessionManager? sessionManager,
    this.extractDebounce = const Duration(milliseconds: 900),
  })  : _provider = provider,
        _apiService = apiService ?? VoiceApiService(),
        _sessionManager = sessionManager ?? VoiceSessionManager();

  final DiagnosisProvider _provider;
  final VoiceApiService _apiService;
  final VoiceSessionManager _sessionManager;
  final Duration extractDebounce;

  final List<File> _pendingChunks = <File>[];
  final List<String> _transcriptBuffer = <String>[];
  final Set<String> _processedTranscriptHashes = <String>{};

  Timer? _extractTimer;
  String _sessionId = _nextSessionId();
  bool _isDisposed = false;
  bool _isStopping = false;
  bool _isProcessingChunks = false;
  bool _isExtracting = false;

  bool get isRunning => _sessionManager.isRunning;

  Future<void> start() async {
    if (_isDisposed || _provider.isContinuousListening) {
      return;
    }

    _sessionId = _nextSessionId();
    _pendingChunks.clear();
    _transcriptBuffer.clear();
    _processedTranscriptHashes.clear();
    _extractTimer?.cancel();
    _extractTimer = null;

    _provider.startVoiceDetectionSession();

    try {
      await _sessionManager.start(
        onChunkReady: _queueChunk,
        onSilenceTimeout: () {
          unawaited(stop(manual: false));
        },
        onError: (_, __) {
          unawaited(stop(manual: false));
        },
      );
    } catch (_) {
      _provider.endVoiceDetectionSession();
    }
  }

  Future<void> stop({bool manual = true}) async {
    if (_isDisposed || _isStopping) {
      return;
    }

    _isStopping = true;
    _extractTimer?.cancel();
    _extractTimer = null;

    try {
      await _sessionManager.stop(emitFinalChunk: true);
      await _drainChunkQueue();
      await _flushTranscriptBuffer();
    } finally {
      _provider.endVoiceDetectionSession();
      _isStopping = false;
    }
  }

  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _extractTimer?.cancel();
    _extractTimer = null;
    unawaited(_sessionManager.stop(emitFinalChunk: false));
    _sessionManager.dispose();
    _apiService.dispose();
  }

  Future<void> _queueChunk(File chunkFile) async {
    if (_isDisposed) {
      await _deleteFile(chunkFile);
      return;
    }

    _pendingChunks.add(chunkFile);
    unawaited(_drainChunkQueue());
  }

  Future<void> _drainChunkQueue() async {
    if (_isProcessingChunks || _isDisposed) {
      return;
    }

    _isProcessingChunks = true;
    try {
      while (_pendingChunks.isNotEmpty && !_isDisposed) {
        final file = _pendingChunks.removeAt(0);
        try {
          final transcript = await _apiService.transcribeAudio(
            file,
            sessionId: _sessionId,
            languageCode: _provider.selectedLanguage,
          );

          if (transcript == null || transcript.trim().isEmpty) {
            continue;
          }

          final normalized = _normalizeTranscript(transcript);
          if (normalized.isEmpty) {
            continue;
          }

          final fingerprint = base64Encode(utf8.encode(normalized));
          if (_processedTranscriptHashes.contains(fingerprint)) {
            continue;
          }

          _processedTranscriptHashes.add(fingerprint);
          _transcriptBuffer.add(transcript.trim());
          _scheduleExtraction();
        } finally {
          await _deleteFile(file);
        }
      }
    } finally {
      _isProcessingChunks = false;
    }
  }

  void _scheduleExtraction() {
    _extractTimer?.cancel();
    _extractTimer = Timer(extractDebounce, () {
      unawaited(_flushTranscriptBuffer());
    });
  }

  Future<void> _flushTranscriptBuffer() async {
    if (_isDisposed || _isExtracting || _transcriptBuffer.isEmpty) {
      return;
    }

    _isExtracting = true;
    final transcriptBatch = List<String>.from(_transcriptBuffer);
    _transcriptBuffer.clear();

    try {
      final symptoms = await _apiService.extractSymptoms(
        transcriptBatch.join(' '),
        sessionId: _sessionId,
      );
      if (symptoms.isNotEmpty) {
        _provider.applyVoiceDetectedSymptoms(symptoms);
      }
    } finally {
      _isExtracting = false;
      if (_transcriptBuffer.isNotEmpty) {
        _scheduleExtraction();
      }
    }
  }

  String _normalizeTranscript(String transcript) {
    return transcript.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _deleteFile(File file) async {
    if (await file.exists()) {
      await file.delete().catchError((_) {});
    }
  }

  static String _nextSessionId() =>
      DateTime.now().microsecondsSinceEpoch.toString();
}
