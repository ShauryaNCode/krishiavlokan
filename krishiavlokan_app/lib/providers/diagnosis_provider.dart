// lib/providers/diagnosis_provider.dart
//
// Holds all state collected across the 4-step diagnosis flow.
// Also manages app-wide settings (offline mode, voice, language).

import 'package:flutter/material.dart';
import '../models/analysis_model.dart';
import '../services/diagnosis_service.dart';
import '../services/storage_service.dart';
import '../services/voice_service.dart'; // VOICE ADDITION

enum DiagnosisStatus { idle, loading, success, error }

class DiagnosisProvider extends ChangeNotifier {
  final DiagnosisService _service = DiagnosisService();
  final StorageService   _storage = StorageService.instance;

  // ── App-wide settings ──────────────────────────────────────────────────────
  String  _selectedLanguage = 'hi';
  bool    _voiceEnabled     = true;
  bool    _offlineMode      = false;
  String  _farmerName       = '';
  String  _farmerDistrict   = '';
  double  _textScale        = 1.0;

  String  get selectedLanguage => _selectedLanguage;
  bool    get voiceEnabled     => _voiceEnabled;
  bool    get offlineMode      => _offlineMode;
  String  get farmerName       => _farmerName;
  String  get farmerDistrict   => _farmerDistrict;
  double  get textScale        => _textScale;

  // ── Diagnosis step data ───────────────────────────────────────────────────
  String?       _selectedCrop;
  String?       _selectedState;
  String?       _selectedDistrict;
  DateTime?     _sowingDate;
  List<String>  _selectedSymptoms = [];
  double        _lat = 0.0;   // resolved when location is set
  double        _lon = 0.0;

  String?       get selectedCrop      => _selectedCrop;
  String?       get selectedState     => _selectedState;
  String?       get selectedDistrict  => _selectedDistrict;
  DateTime?     get sowingDate        => _sowingDate;
  List<String>  get selectedSymptoms  => List.unmodifiable(_selectedSymptoms);
  double        get lat               => _lat;
  double        get lon               => _lon;

  // ── Analysis result ───────────────────────────────────────────────────────
  DiagnosisStatus  _status = DiagnosisStatus.idle;
  AnalysisResult?  _currentResult;
  String?          _errorMessage;

  DiagnosisStatus  get status        => _status;
  AnalysisResult?  get currentResult => _currentResult;
  String?          get errorMessage  => _errorMessage;

  // ── History ───────────────────────────────────────────────────────────────
  List<AnalysisResult> get history => _storage.getHistory();
  AnalysisResult?      get lastAnalysis => _storage.getLastAnalysis();

  // ─────────────────────────────────────────────────────────────────────────
  // Initialise from storage (call once on app startup)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _selectedLanguage = await _storage.getLanguage() ?? 'hi';
    _voiceEnabled     = await _storage.getVoiceEnabled();
    _offlineMode      = await _storage.getOfflineMode();
    _farmerName       = await _storage.getFarmerName();
    _farmerDistrict   = await _storage.getFarmerDistrict();
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

  void setLocation(String state, String district, {double lat = 0.0, double lon = 0.0}) {
    _selectedState    = state;
    _selectedDistrict = district;
    _lat              = lat;
    _lon              = lon;
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
      _status       = DiagnosisStatus.error;
      _errorMessage = 'Please complete all steps before analysing.';
      notifyListeners();
      return;
    }

    _status = DiagnosisStatus.loading;
    notifyListeners();

    try {
      final result = await _service.analyze(
        crop:       _selectedCrop!,
        state:      _selectedState ?? '',
        district:   _selectedDistrict!,
        sowingDate: _sowingDate!,
        symptoms:   _selectedSymptoms,
        lat:        _lat,
        lon:        _lon,
        isOffline:  _offlineMode,
      );

      _currentResult = result;
      _status        = DiagnosisStatus.success;
      notifyListeners();
    } catch (e) {
      _status       = DiagnosisStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Save current result to history
  void saveCurrentToHistory() {
    if (_currentResult != null) {
      _storage.saveAnalysis(_currentResult!);
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
    _selectedCrop      = null;
    _selectedState     = null;
    _selectedDistrict  = null;
    _sowingDate        = null;
    _selectedSymptoms  = [];
    _lat               = 0.0;
    _lon               = 0.0;
    _status            = DiagnosisStatus.idle;
    _currentResult     = null;
    _errorMessage      = null;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VOICE ADDITIONS — added for voice interaction feature.
  // All existing logic above this line is untouched.
  // ══════════════════════════════════════════════════════════════════════════  // ── New voice state ───────────────────────────────────────────────────────

  /// True while TTS loop is running OR microphone is active.
  bool _isVoiceActive = false;

  /// True only during the STT + matching window.
  /// UI should dim and block taps while this is true.
  bool _isVoiceProcessing = false;

  bool get isVoiceActive      => _isVoiceActive;
  bool get isVoiceProcessing  => _isVoiceProcessing;

  // ── New voice methods ─────────────────────────────────────────────────────

  /// Starts the TTS question loop for the current diagnosis step.
  /// Does nothing if [voiceEnabled] is false.
  /// Safe to call multiple times — cancels any running loop first.
  Future<void> startQuestionLoop(String question) async {
    if (!_voiceEnabled) return;

    // Cancel any previously running loop before starting a new one
    await VoiceService.instance.cancelLoop();

    _isVoiceActive     = false;
    _isVoiceProcessing = false;
    notifyListeners();

    await VoiceService.instance.startLoop(
      question: question,
      enabled:  _voiceEnabled,
    );
  }

  /// Stops TTS, starts STT, runs [matcher] on the result.
  ///
  /// [matcher] receives the raw lowercase recognised string and must return
  /// the matched option key/name, or null if no match.
  ///
  /// [onMatch] is called with the matched value when a match is found.
  /// [onNoMatch] is called when no match — the question loop is restarted.
  /// [question] is the text re-spoken if no match is found.
  Future<void> listenForAnswer({
    required String question,
    required String? Function(String spoken) matcher,
    required void Function(String matched) onMatch,
    required VoidCallback onNoMatch,
  }) async {
    if (!_voiceEnabled) return;

    // Stop TTS loop before we start listening
    await VoiceService.instance.cancelLoop();

    _isVoiceActive     = true;
    _isVoiceProcessing = true;
    notifyListeners();

    // Listen once with a 6-second timeout
    final spoken = await VoiceService.instance.listenOnce(
      timeout: const Duration(seconds: 6),
    );

    if (spoken == null || spoken.isEmpty) {
      // Timeout or empty — restart loop quietly
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
      // No match — restart loop and inform caller
      await startQuestionLoop(question);
      onNoMatch();
    }
  }

  /// Applies a list of voice-detected symptom keys from SymptomVoiceProcessor.
  /// Replaces current selection — voice detection is treated as a fresh pick.
  /// Ignores any keys not in the valid set.
  void applyVoiceSymptoms(List<String> detectedKeys) {
    const validKeys = {
      'drought', 'waterlogging', 'nutrient', 'pest', 'fungal', 'heat'
    };
    final valid = detectedKeys.where(validKeys.contains).toList();
    if (valid.isEmpty) return;
    _selectedSymptoms = List.of(valid);
    notifyListeners();
  }

  /// Stops all voice activity (TTS + STT).
  /// Call this on screen dispose or when user manually navigates.
  Future<void> stopVoiceCompletely() async {
    await VoiceService.instance.stopAll();
    _isVoiceActive     = false;
    _isVoiceProcessing = false;
    notifyListeners();
  }
}
