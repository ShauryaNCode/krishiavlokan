// lib/providers/diagnosis_provider.dart
//
// Holds all state collected across the 4-step diagnosis flow.
// Also manages app-wide settings (offline mode, voice, language).

import 'package:flutter/material.dart';
import '../models/analysis_model.dart';
import '../services/diagnosis_service.dart';
import '../services/storage_service.dart';

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

  String?       get selectedCrop      => _selectedCrop;
  String?       get selectedState     => _selectedState;
  String?       get selectedDistrict  => _selectedDistrict;
  DateTime?     get sowingDate        => _sowingDate;
  List<String>  get selectedSymptoms  => List.unmodifiable(_selectedSymptoms);

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

  void setLocation(String state, String district) {
    _selectedState    = state;
    _selectedDistrict = district;
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
        isOffline:  _offlineMode,
      );

      _currentResult = result;
      _status        = DiagnosisStatus.success;
      notifyListeners();
    } catch (e) {
      _status       = DiagnosisStatus.error;
      _errorMessage = 'Analysis failed. Please try again.';
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
    _status            = DiagnosisStatus.idle;
    _currentResult     = null;
    _errorMessage      = null;
    notifyListeners();
  }
}
