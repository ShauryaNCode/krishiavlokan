// lib/providers/diagnosis_provider.dart
//
// Holds all state collected across the 4-step diagnosis flow.
// Also manages app-wide settings (offline mode, voice, language).

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/analysis_model.dart';
import '../services/diagnosis_service.dart';
import '../services/storage_service.dart';
import '../services/voice_service.dart';
import '../services/symptom_voice_processor.dart';
import '../services/history_api_service.dart';

enum DiagnosisStatus { idle, loading, success, error }

class DiagnosisProvider extends ChangeNotifier {
  final DiagnosisService _service = DiagnosisService();
  final StorageService _storage = StorageService.instance;

  // ── App-wide settings ──────────────────────────────────────────────────────
  String _selectedLanguage = 'hi';
  bool _voiceEnabled = true;
  bool _offlineMode = false;
  String _farmerName = '';
  String _farmerDistrict = '';
  double _textScale = 1.0;

  String get selectedLanguage => _selectedLanguage;
  bool get voiceEnabled => _voiceEnabled;
  bool get offlineMode => _offlineMode;
  String get farmerName => _farmerName;
  String get farmerDistrict => _farmerDistrict;
  double get textScale => _textScale;

  // ── Diagnosis step data ───────────────────────────────────────────────────
  String? _selectedCrop;
  String? _selectedState;
  String? _selectedDistrict;
  DateTime? _sowingDate;
  List<String> _selectedSymptoms = [];
  double _lat = 0.0; // resolved when location is set
  double _lon = 0.0;

  String? get selectedCrop => _selectedCrop;
  String? get selectedState => _selectedState;
  String? get selectedDistrict => _selectedDistrict;
  DateTime? get sowingDate => _sowingDate;
  List<String> get selectedSymptoms => List.unmodifiable(_selectedSymptoms);
  double get lat => _lat;
  double get lon => _lon;

  // ── Analysis result ───────────────────────────────────────────────────────
  DiagnosisStatus _status = DiagnosisStatus.idle;
  AnalysisResult? _currentResult;
  String? _errorMessage;

  DiagnosisStatus get status => _status;
  AnalysisResult? get currentResult => _currentResult;
  String? get errorMessage => _errorMessage;

  // ── History ───────────────────────────────────────────────────────────────
  //
  // _remoteHistory  → loaded from backend when HistoryScreen opens.
  // _storage.getHistory() → in-memory fallback for current session saves.
  //
  // history getter merges both, deduplicating by crop+causeKey+seasonYear.

  List<AnalysisResult> _remoteHistory = [];
  bool _historyLoading = false;
  String? _historyError;

  bool get historyLoading => _historyLoading;
  String? get historyError => _historyError;

  List<AnalysisResult> get history {
    final remoteKeys = _remoteHistory
        .map((r) => '\${r.crop}|\${r.causeKey}|\${r.seasonYear}')
        .toSet();
    final localOnly = _storage.getHistory().where(
          (r) => !remoteKeys
              .contains('\${r.crop}|\${r.causeKey}|\${r.seasonYear}'),
        );
    return [..._remoteHistory, ...localOnly];
  }

  AnalysisResult? get lastAnalysis => history.isNotEmpty ? history.first : null;

  // ─────────────────────────────────────────────────────────────────────────
  // Initialise from storage (call once on app startup)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _selectedLanguage = await _storage.getLanguage() ?? 'hi';
    _voiceEnabled = await _storage.getVoiceEnabled();
    _offlineMode = await _storage.getOfflineMode();
    _farmerName = await _storage.getFarmerName();
    _farmerDistrict = await _storage.getFarmerDistrict();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Settings setters
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> setLanguage(String code) async {
    _selectedLanguage = code;
    await _storage.saveLanguage(code);
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool val) async {
    _voiceEnabled = val;
    await _storage.saveVoiceEnabled(val);
    notifyListeners();
  }

  Future<void> setOfflineMode(bool val) async {
    _offlineMode = val;
    await _storage.saveOfflineMode(val);
    notifyListeners();
  }

  Future<void> setFarmerName(String name) async {
    _farmerName = name;
    await _storage.saveFarmerName(name);
    notifyListeners();
  }

  Future<void> setFarmerDistrict(String district) async {
    _farmerDistrict = district;
    await _storage.saveFarmerDistrict(district);
    notifyListeners();
  }

  void setTextScale(double scale) {
    _textScale = scale;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Diagnosis step setters
  // ─────────────────────────────────────────────────────────────────────────

  void setCrop(String crop) {
    _selectedCrop = crop;
    notifyListeners();
  }

  void setLocation(String state, String district,
      {double lat = 0.0, double lon = 0.0}) {
    _selectedState = state;
    _selectedDistrict = district;
    _lat = lat;
    _lon = lon;
    notifyListeners();
  }

  void setSowingDate(DateTime date) {
    _sowingDate = date;
    notifyListeners();
  }

  void toggleSymptom(String key) {
    if (_selectedSymptoms.contains(key)) {
      _selectedSymptoms.remove(key);
    } else {
      _selectedSymptoms.add(key);
    }
    notifyListeners();
  }

  bool isSymptomSelected(String key) => _selectedSymptoms.contains(key);

  // ─────────────────────────────────────────────────────────────────────────
  // Run diagnosis
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> runDiagnosis() async {
    if (_selectedCrop == null ||
        _selectedDistrict == null ||
        _sowingDate == null ||
        _selectedSymptoms.isEmpty) {
      _status = DiagnosisStatus.error;
      _errorMessage = 'Please complete all steps before analysing.';
      notifyListeners();
      return;
    }

    _status = DiagnosisStatus.loading;
    notifyListeners();

    try {
      final result = await _service.analyze(
        crop: _selectedCrop!,
        state: _selectedState ?? '',
        district: _selectedDistrict!,
        sowingDate: _sowingDate!,
        symptoms: _selectedSymptoms,
        lat: _lat,
        lon: _lon,
        isOffline: _offlineMode,
      );

      _currentResult = result;
      _status = DiagnosisStatus.success;
      notifyListeners();
    } catch (e) {
      _status = DiagnosisStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Saves the current result locally (instant) and to the backend (async).
  /// Local save happens immediately so UI updates without waiting for network.
  Future<void> saveCurrentToHistory() async {
    if (_currentResult == null) return;
    // 1. Local — instant
    _storage.saveAnalysis(_currentResult!);
    notifyListeners();
    // 2. Remote — fire-and-forget, silent on failure
    _saveRemoteQuietly(_currentResult!);
  }

  Future<void> _saveRemoteQuietly(AnalysisResult result) async {
    try {
      final userId = await _storage.getUserId();
      await HistoryApiService.instance.saveResult(
        userId: userId,
        result: result,
      );
    } catch (_) {
      // Silently ignored — local copy already saved
    }
  }

  /// Fetches history from backend. Called by HistoryScreen on init.
  Future<void> loadRemoteHistory() async {
    if (_historyLoading) return;
    _historyLoading = true;
    _historyError = null;
    notifyListeners();
    try {
      final userId = await _storage.getUserId();
      final results = await HistoryApiService.instance.fetchHistory(
        userId: userId,
      );
      _remoteHistory = results;
      _historyError = null;
    } on HistoryApiException catch (e) {
      _historyError = e.message;
    } catch (_) {
      _historyError = 'Could not load history.';
    } finally {
      _historyLoading = false;
      notifyListeners();
    }
  }

  /// Mark advice taken for a result
  void toggleAdviceTaken(AnalysisResult result) {
    result.adviceTaken = !result.adviceTaken;
    notifyListeners();
  }

  /// Reset diagnosis flow (called when starting a new analysis)
  void resetDiagnosis() {
    _selectedCrop = null;
    _selectedState = null;
    _selectedDistrict = null;
    _sowingDate = null;
    _selectedSymptoms = [];
    _lat = 0.0;
    _lon = 0.0;
    _status = DiagnosisStatus.idle;
    _currentResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VOICE ADDITIONS
  // All existing logic above this line is untouched.
  // ══════════════════════════════════════════════════════════════════════════

  // ── Step 1–3 voice state (single-shot) ────────────────────────────────────

  bool _isVoiceActive = false;
  bool _isVoiceProcessing = false;

  bool get isVoiceActive => _isVoiceActive;
  bool get isVoiceProcessing => _isVoiceProcessing;

  // ── Step 4 continuous voice state ─────────────────────────────────────────

  /// True while continuous mic is open (Step 4 mode).
  bool _isContinuousListening = false;
  bool get isContinuousListening => _isContinuousListening;

  /// All voice-detected keys accumulated across THIS session.
  /// Set gives O(1) duplicate check.
  final Set<String> _voiceDetectedSymptoms = {};
  Set<String> get voiceDetectedSymptoms =>
      Set.unmodifiable(_voiceDetectedSymptoms);

  StreamSubscription<String>? _transcriptSub;
  Timer? _silenceTimer;
  static const _silenceTimeout = Duration(seconds: 5);

  // ── Step 1–3: single-shot question loop & answer ───────────────────────────

  Future<void> startQuestionLoop(String question) async {
    if (!_voiceEnabled) return;
    await VoiceService.instance.cancelLoop();
    _isVoiceActive = true;
    _isVoiceProcessing = false;
    notifyListeners();
    await VoiceService.instance.startLoop(
      question: question,
      enabled: _voiceEnabled,
    );
  }

  Future<void> listenForAnswer({
    required String question,
    required String? Function(String spoken) matcher,
    required void Function(String matched) onMatch,
    required VoidCallback onNoMatch,
  }) async {
    if (!_voiceEnabled) return;
    await VoiceService.instance.cancelLoop();
    _isVoiceActive = true;
    _isVoiceProcessing = true;
    notifyListeners();

    final spoken = await VoiceService.instance.listenOnce(
      timeout: const Duration(seconds: 6),
    );

    if (spoken == null || spoken.isEmpty) {
      _isVoiceProcessing = false;
      notifyListeners();
      await startQuestionLoop(question);
      onNoMatch();
      return;
    }

    final matched = matcher(spoken);
    _isVoiceProcessing = false;
    notifyListeners();

    if (matched != null) {
      _isVoiceActive = false;
      notifyListeners();
      onMatch(matched);
    } else {
      await startQuestionLoop(question);
      onNoMatch();
    }
  }

  void startVoiceDetectionSession() {
    _voiceDetectedSymptoms.clear();
    _isContinuousListening = true;
    notifyListeners();
  }

  void endVoiceDetectionSession() {
    if (_isContinuousListening) {
      _isContinuousListening = false;
      notifyListeners();
    }
  }

  // ── applyVoiceSymptoms — kept for batch apply (backward compat) ────────────

  void applyVoiceSymptoms(List<String> detectedKeys) {
    const validKeys = {
      'drought',
      'waterlogging',
      'nutrient',
      'pest',
      'fungal',
      'heat'
    };
    final valid = detectedKeys.where(validKeys.contains).toList();
    if (valid.isEmpty) return;
    _selectedSymptoms = List.of(valid);
    notifyListeners();
  }

  void applyVoiceDetectedSymptoms(List<String> detectedKeys) {
    const validKeys = {
      'drought',
      'waterlogging',
      'nutrient',
      'pest',
      'fungal',
      'heat'
    };
    var shouldNotify = false;

    for (final key in detectedKeys) {
      if (!validKeys.contains(key)) continue;

      final wasAddedToVoiceSet = _voiceDetectedSymptoms.add(key);
      if (!_selectedSymptoms.contains(key)) {
        _selectedSymptoms.add(key);
        shouldNotify = true;
      } else if (wasAddedToVoiceSet) {
        // If it was already manually selected but just now voice-confirmed
        shouldNotify = true;
      }
    }
  }
  // ── Step 4: continuous listening ──────────────────────────────────────────

  /// Starts continuous mic. Each chunk is processed by SymptomVoiceProcessor.
  /// New symptoms are added incrementally; silence auto-stops after 5 s.
  Future<void> startContinuousListening() async {
    if (!_voiceEnabled) return;
    if (_isContinuousListening) return;

    _voiceDetectedSymptoms.clear();
    _isContinuousListening = true;
    notifyListeners();

    await VoiceService.instance.startContinuous();

    _transcriptSub = VoiceService.instance.transcriptStream.listen(
      (chunk) {
        _resetSilenceTimer();
        processVoiceChunk(chunk);
      },
      onDone: () => _onStreamDone(),
      onError: (_) => _onStreamDone(),
      cancelOnError: false,
    );

    _resetSilenceTimer();
  }

  /// Processes one speech chunk: detects symptoms, adds new ones only.
  void processVoiceChunk(String text) {
    final detected = SymptomVoiceProcessor().detectSymptoms(text);
    for (final key in detected) {
      if (_voiceDetectedSymptoms.contains(key)) continue; // duplicate
      if (_selectedSymptoms.contains(key)) {
        _voiceDetectedSymptoms.add(key);
        continue;
      }
      _voiceDetectedSymptoms.add(key);
      _selectedSymptoms.add(key);
      notifyListeners(); // live update per new symptom
    }
  }

  void _onStreamDone() {
    _silenceTimer?.cancel();
    if (_isContinuousListening) {
      _isContinuousListening = false;
      notifyListeners();
    }
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(_silenceTimeout, stopContinuousListening);
  }

  /// Manually stop continuous listening.
  Future<void> stopContinuousListening() async {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    await _transcriptSub?.cancel();
    _transcriptSub = null;
    await VoiceService.instance.stopContinuous();
    if (_isContinuousListening) {
      _isContinuousListening = false;
      notifyListeners();
    }
  }

  // ── Full stop — all screens call this on dispose / nav ─────────────────────

  Future<void> stopVoiceCompletely() async {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    await _transcriptSub?.cancel();
    _transcriptSub = null;
    await VoiceService.instance.stopAll();
    _isVoiceActive = false;
    _isVoiceProcessing = false;
    _isContinuousListening = false;
    notifyListeners();
  }
}
