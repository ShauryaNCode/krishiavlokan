// lib/services/diagnosis_service.dart
//
// Mock AI diagnosis service.
// Uses simple rule-based logic to simulate model inference.
// In production, replace with actual Vertex AI + Gemini API calls.

import 'dart:async';
import '../models/analysis_model.dart';

class DiagnosisService {
  /// Simulate network + model inference delay
  Future<AnalysisResult> analyze({
    required String crop,
    required String state,
    required String district,
    required DateTime sowingDate,
    required List<String> symptoms,
    bool isOffline = false,
  }) async {
    // Simulate processing time (2–3 seconds)
    await Future.delayed(const Duration(milliseconds: 2800));

    return _buildResult(
      crop: crop,
      state: state,
      district: district,
      sowingDate: sowingDate,
      symptoms: symptoms,
      isOffline: isOffline,
    );
  }

  AnalysisResult _buildResult({
    required String crop,
    required String state,
    required String district,
    required DateTime sowingDate,
    required List<String> symptoms,
    required bool isOffline,
  }) {
    // ── Rule-based cause determination ──────────────────────────────────────
    // Priority order: drought > waterlogging > pest > fungal > heat > nutrient
    String causeKey;
    if (symptoms.contains('drought')) {
      causeKey = 'drought';
    } else if (symptoms.contains('waterlogging')) {
      causeKey = 'waterlogging';
    } else if (symptoms.contains('pest')) {
      causeKey = 'pest';
    } else if (symptoms.contains('fungal')) {
      causeKey = 'fungal';
    } else if (symptoms.contains('heat')) {
      causeKey = 'heat';
    } else {
      causeKey = 'nutrient';
    }

    return AnalysisResult(
      crop: crop,
      state: state,
      district: district,
      sowingDate: sowingDate,
      symptoms: symptoms,
      causeKey: causeKey,
      causeTitle: _causeTitle(causeKey),
      explanation: _explanation(causeKey, crop, district),
      weatherPhases: _weatherPhases(causeKey),
      recommendations: _recommendations(causeKey, crop),
      isLimitedAnalysis: isOffline,
    );
  }

  // ── Cause title ────────────────────────────────────────────────────────────
  String _causeTitle(String key) => switch (key) {
        'drought'      => 'Sukha Takleef — Drought Stress',
        'waterlogging' => 'Paani Bhari — Waterlogging',
        'pest'         => 'Keeda Nuksan — Pest Damage',
        'fungal'       => 'Fungal Rog — Fungal Disease',
        'heat'         => 'Garmi Takleef — Heat Stress',
        _              => 'Poshan Kami — Nutrient Deficiency',
      };

  // ── Explanation text (Hindi + English mix for demo) ───────────────────────
  String _explanation(String key, String crop, String district) =>
      switch (key) {
        'drought' =>
          'Aapke $crop ki fasal ke shuruaati teen haftey mein $district mein '
              'bahut kam baarish hui. Isse fasal ka beejaarohan (germination) '
              'prabhavit hua aur paudhon ko paani nahi mila.',
        'waterlogging' =>
          '$district mein iss season mein zyada baarish ki wajah se khet mein '
              'paani jama ho gaya. $crop ki jaden (roots) sada ho gayi, '
              'jisse paudhon ko oxygen nahi mili.',
        'pest' =>
          '$crop ki fasal par keedo ka hamla hua. Patton par chhed aur ped '
              'ka rang peela hona, ye pest damage ke lakshan hain. '
              'Samay par davai na dene se nuksan badh gaya.',
        'fungal' =>
          'Zyada nami aur garam mausam ki wajah se $crop mein fungal rog '
              'fail gaya. Patton par kaale ya bhoore dabbe aur taaron par '
              'safed powder dikha jo fungus ki nishani hai.',
        'heat' =>
          '$district mein is season mein taapman (temperature) bahut zyada '
              'raha. $crop ki fasal ke phool girne lage aur patte jal gaye. '
              'Zyada garmi mein pooja ki zaroorat thi.',
        _ =>
          '$crop ki fasal mein nayatrogen, potassium ya zinc ki kami thi. '
              'Kheti se pehle mitti (soil) ki jaanch karni chahiye thi. '
              'Proper fertilizer ka upyog nahi hua iss season mein.',
      };

  // ── Weather strip phases ──────────────────────────────────────────────────
  List<WeatherPhase> _weatherPhases(String key) => switch (key) {
        'drought' => const [
            WeatherPhase(label: 'Shuruaat\n(Early)',  status: 'veryLow', emoji: '🔴'),
            WeatherPhase(label: 'Beech\n(Mid)',        status: 'low',     emoji: '🟠'),
            WeatherPhase(label: 'Ant\n(Late)',         status: 'normal',  emoji: '🟢'),
          ],
        'waterlogging' => const [
            WeatherPhase(label: 'Shuruaat\n(Early)',  status: 'high',    emoji: '🔵'),
            WeatherPhase(label: 'Beech\n(Mid)',        status: 'veryHigh',emoji: '🔵'),
            WeatherPhase(label: 'Ant\n(Late)',         status: 'normal',  emoji: '🟢'),
          ],
        'heat' => const [
            WeatherPhase(label: 'Shuruaat\n(Early)',  status: 'normal',  emoji: '🟢'),
            WeatherPhase(label: 'Beech\n(Mid)',        status: 'high',    emoji: '🔴'),
            WeatherPhase(label: 'Ant\n(Late)',         status: 'veryHigh',emoji: '🔴'),
          ],
        _ => const [
            WeatherPhase(label: 'Shuruaat\n(Early)',  status: 'normal',  emoji: '🟢'),
            WeatherPhase(label: 'Beech\n(Mid)',        status: 'low',     emoji: '🟠'),
            WeatherPhase(label: 'Ant\n(Late)',         status: 'normal',  emoji: '🟢'),
          ],
      };

  // ── Recommendations ───────────────────────────────────────────────────────
  List<RecommendationItem> _recommendations(String key, String crop) =>
      switch (key) {
        'drought' => [
            const RecommendationItem(
              emoji: '🌱',
              title: 'Sukha-Sahansheel Kism Chuniye',
              detail: 'Choose drought-tolerant variety suitable for your district.',
            ),
            const RecommendationItem(
              emoji: '📅',
              title: 'Baayi Ka Samay Badliye',
              detail: 'Shift sowing date 2–3 weeks earlier to use residual moisture.',
            ),
            const RecommendationItem(
              emoji: '💧',
              title: 'Drip Sinchai Apnaiye',
              detail: 'Adopt drip or sprinkler irrigation to conserve water.',
            ),
          ],
        'waterlogging' => [
            const RecommendationItem(
              emoji: '🏗️',
              title: 'Raised Bed Banaiye',
              detail: 'Use raised-bed farming to prevent root waterlogging.',
            ),
            const RecommendationItem(
              emoji: '🌾',
              title: 'Drainage Sudhaaren',
              detail: 'Improve field drainage channels before next season.',
            ),
            const RecommendationItem(
              emoji: '🌱',
              title: 'Paani Sahansheel Kism',
              detail: 'Select a waterlogging-tolerant crop variety.',
            ),
          ],
        'pest' => [
            const RecommendationItem(
              emoji: '🔍',
              title: 'Niyamit Kheti Nirikshan',
              detail: 'Inspect crops weekly during early growth for pest signs.',
            ),
            const RecommendationItem(
              emoji: '🌿',
              title: 'Jaivik Keedanashak',
              detail: 'Use bio-pesticides like Neem oil as first line of defense.',
            ),
            const RecommendationItem(
              emoji: '🤝',
              title: 'KVK Se Salah',
              detail: 'Contact your nearest Krishi Vigyan Kendra for pest ID.',
            ),
          ],
        'fungal' => [
            const RecommendationItem(
              emoji: '💊',
              title: 'Beej Upchar Karo',
              detail: 'Treat seeds with fungicide before sowing next season.',
            ),
            const RecommendationItem(
              emoji: '🌬️',
              title: 'Hawa Ka Pravah Badhao',
              detail: 'Maintain proper plant spacing for air circulation.',
            ),
            const RecommendationItem(
              emoji: '🚫',
              title: 'Zyada Nami Se Bachao',
              detail: 'Avoid evening irrigation to reduce leaf wetness.',
            ),
          ],
        'heat' => [
            const RecommendationItem(
              emoji: '🌤️',
              title: 'Sahi Samay Par Baiye',
              detail: 'Sow before the peak heat months to avoid temperature stress.',
            ),
            const RecommendationItem(
              emoji: '💦',
              title: 'Shaam Ko Sinchai Karo',
              detail: 'Irrigate in the evening to cool soil and reduce heat stress.',
            ),
            const RecommendationItem(
              emoji: '🌿',
              title: 'Mulching Apnaiye',
              detail: 'Use crop residue as mulch to keep soil temperature low.',
            ),
          ],
        _ => [
            const RecommendationItem(
              emoji: '🧪',
              title: 'Mitti Jaanch Karaiye',
              detail: 'Get a soil health test done before the next season.',
            ),
            const RecommendationItem(
              emoji: '🌾',
              title: 'Balanced Fertilizer',
              detail: 'Apply NPK fertilizer as per soil test recommendations.',
            ),
            const RecommendationItem(
              emoji: '📋',
              title: 'Fasal Chakkar Apnaiye',
              detail: 'Rotate crops to restore soil nutrients naturally.',
            ),
          ],
      };
}
