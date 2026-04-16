// lib/services/storage_service.dart
//
// Mock storage service. In production, replace with Hive / Firestore.

import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_model.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  // In-memory history store (survives app session)
  final List<AnalysisResult> _history = [];

  // ── SharedPreferences Wrappers ─────────────────────────────────────────────

  Future<void> saveLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kLanguageKey, code);
  }

  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.kLanguageKey);
  }

  Future<void> saveFarmerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kFarmerName, name);
  }

  Future<String> getFarmerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.kFarmerName) ?? '';
  }

  Future<void> saveFarmerDistrict(String district) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.kFarmerDistrict, district);
  }

  Future<String> getFarmerDistrict() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.kFarmerDistrict) ?? '';
  }

  Future<void> saveVoiceEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.kVoiceEnabled, val);
  }

  Future<bool> getVoiceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.kVoiceEnabled) ?? true;
  }

  Future<void> saveOfflineMode(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.kOfflineMode, val);
  }

  Future<bool> getOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.kOfflineMode) ?? false;
  }

  // ── History ────────────────────────────────────────────────────────────────

  void saveAnalysis(AnalysisResult result) {
    _history.insert(0, result);
  }

  List<AnalysisResult> getHistory() => List.unmodifiable(_history);

  AnalysisResult? getLastAnalysis() =>
      _history.isEmpty ? null : _history.first;
}
