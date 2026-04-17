// lib/models/analysis_model.dart
//
// Updated to match the real backend API response exactly.
// All fromJson factories parse the live JSON shape.
// Backward-compatible with mock data — emoji and display status
// are derived from API strings rather than stored separately.

/// Maps the API status string → internal display status key.
/// API sends: "Severe Anomaly" | "Moderate Anomaly" | "Normal" | "Mild Anomaly"
/// Internal keys drive color + label helpers in shared_widgets.dart.
String _apiStatusToDisplay(String apiStatus, double rainAnomaly) {
  final s = apiStatus.toLowerCase();
  if (s.contains('severe')) {
    return rainAnomaly >= 0 ? 'veryHigh' : 'veryLow';
  }
  if (s.contains('moderate')) {
    return rainAnomaly >= 0 ? 'high' : 'low';
  }
  if (s.contains('mild')) {
    return rainAnomaly >= 0 ? 'high' : 'low';
  }
  return 'normal';
}

/// Derives a display emoji from the internal status key.
String _statusEmoji(String displayStatus) => switch (displayStatus) {
      'veryLow'  => '🔴',
      'low'      => '🟠',
      'high'     => '🔵',
      'veryHigh' => '🔵',
      _          => '🟢',
    };

// ─────────────────────────────────────────────────────────────────────────────
// WeatherPhase
// ─────────────────────────────────────────────────────────────────────────────

class WeatherPhase {
  // ── Display fields (used by UI) ───────────────────────────────────────────
  final String label;          // e.g. "Early\n(Nov–Dec)"
  final String status;         // internal key: veryLow | low | normal | high | veryHigh
  final String emoji;          // 🔴 🟠 🟢 🔵

  // ── Raw API fields (available for debug / expanded UI) ────────────────────
  final String  phase;                 // "Early" | "Mid" | "Late"
  final String  apiStatus;            // original API string e.g. "Severe Anomaly"
  final double  rainfallMm;
  final double  expectedRainfallMm;
  final double  rainAnomaly;
  final double  rainfallDeviationPct;
  final double  avgTempC;
  final double  expectedTempC;
  final double  tempAnomaly;
  final double  temperatureDeviationPct;
  final double  avgHumidityPct;
  final double  expectedHumidityPct;
  final double  humidityAnomaly;
  final double  humidityDeviationPct;
  final double  isolationScore;
  final int     dataDays;
  final String  startDate;
  final String  endDate;

  WeatherPhase({
    required this.label,
    required this.status,
    required this.emoji,
    required this.phase,
    required this.apiStatus,
    required this.rainfallMm,
    required this.expectedRainfallMm,
    required this.rainAnomaly,
    required this.rainfallDeviationPct,
    required this.avgTempC,
    required this.expectedTempC,
    required this.tempAnomaly,
    required this.temperatureDeviationPct,
    required this.avgHumidityPct,
    required this.expectedHumidityPct,
    required this.humidityAnomaly,
    required this.humidityDeviationPct,
    required this.isolationScore,
    required this.dataDays,
    required this.startDate,
    required this.endDate,
  });

  /// Parse one element of the "weatherPhases" array from the API.
  factory WeatherPhase.fromJson(Map<String, dynamic> json) {
    final apiStatus   = (json['status'] as String?) ?? 'Normal';
    final rainAnomaly = (json['rainAnomaly'] as num?)?.toDouble() ?? 0.0;
    final display     = _apiStatusToDisplay(apiStatus, rainAnomaly);
    final phaseLabel  = (json['phase'] as String?) ?? '';

    // Build friendly date-range suffix for the label
    final start = (json['startDate'] as String?) ?? '';
    final end   = (json['endDate']   as String?) ?? '';
    final dateRange = (start.isNotEmpty && end.isNotEmpty)
        ? '${_shortDate(start)}–${_shortDate(end)}'
        : '';
    final label = dateRange.isNotEmpty
        ? '$phaseLabel\n($dateRange)'
        : phaseLabel;

    return WeatherPhase(
      label:                  label,
      status:                 display,
      emoji:                  _statusEmoji(display),
      phase:                  phaseLabel,
      apiStatus:              apiStatus,
      rainfallMm:             (json['rainfallMm'] as num?)?.toDouble() ?? 0.0,
      expectedRainfallMm:     (json['expectedRainfallMm'] as num?)?.toDouble() ?? 0.0,
      rainAnomaly:            rainAnomaly,
      rainfallDeviationPct:   (json['rainfallDeviationPct'] as num?)?.toDouble() ?? 0.0,
      avgTempC:               (json['avgTempC'] as num?)?.toDouble() ?? 0.0,
      expectedTempC:          (json['expectedTempC'] as num?)?.toDouble() ?? 0.0,
      tempAnomaly:            (json['tempAnomaly'] as num?)?.toDouble() ?? 0.0,
      temperatureDeviationPct:(json['temperatureDeviationPct'] as num?)?.toDouble() ?? 0.0,
      avgHumidityPct:         (json['avgHumidityPct'] as num?)?.toDouble() ?? 0.0,
      expectedHumidityPct:    (json['expectedHumidityPct'] as num?)?.toDouble() ?? 0.0,
      humidityAnomaly:        (json['humidityAnomaly'] as num?)?.toDouble() ?? 0.0,
      humidityDeviationPct:   (json['humidityDeviationPct'] as num?)?.toDouble() ?? 0.0,
      isolationScore:         (json['isolationScore'] as num?)?.toDouble() ?? 0.0,
      dataDays:               (json['dataDays'] as num?)?.toInt() ?? 0,
      startDate:              start,
      endDate:                end,
    );
  }

  /// Shortens "2025-11-01" → "Nov'25"
  static String _shortDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return "${months[dt.month - 1]}'${dt.year.toString().substring(2)}";
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationItem
// ─────────────────────────────────────────────────────────────────────────────

class RecommendationItem {
  final String emoji;  // derived from index — API doesn't send emoji
  final String title;
  final String detail;

  const RecommendationItem({
    required this.emoji,
    required this.title,
    required this.detail,
  });

  /// Parse one element of the "recommendations" array from the API.
  /// [index] is used to pick a rotating emoji since API sends none.
  factory RecommendationItem.fromJson(Map<String, dynamic> json, int index) {
    const emojis = ['🌱', '💧', '🔍', '🌾', '🧪', '📅', '🌿', '🤝'];
    return RecommendationItem(
      emoji:  emojis[index % emojis.length],
      title:  (json['title']  as String?) ?? '',
      detail: (json['detail'] as String?) ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AnalysisResult
// ─────────────────────────────────────────────────────────────────────────────

class AnalysisResult {
  final String crop;
  final String state;
  final String district;
  final DateTime sowingDate;
  final List<String> symptoms;

  // ── Diagnosis fields ───────────────────────────────────────────────────────
  final String causeKey;        // e.g. "waterlogging"
  final String causeTitle;      // e.g. "Waterlogging Stress"
  final double confidenceScore; // 0.0 – 1.0
  final String explanation;

  final List<WeatherPhase>      weatherPhases;
  final List<RecommendationItem> recommendations;

  // ── Meta ───────────────────────────────────────────────────────────────────
  final bool     isLimitedAnalysis;
  final DateTime analyzedAt;
  bool           adviceTaken;

  // ── Raw model details (optional, for debug/display) ───────────────────────
  final String? weatherSource;
  final String? modelMode;

  AnalysisResult({
    required this.crop,
    required this.state,
    required this.district,
    required this.sowingDate,
    required this.symptoms,
    required this.causeKey,
    required this.causeTitle,
    required this.confidenceScore,
    required this.explanation,
    required this.weatherPhases,
    required this.recommendations,
    this.isLimitedAnalysis = false,
    DateTime? analyzedAt,
    this.adviceTaken     = false,
    this.weatherSource,
    this.modelMode,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  // ── fromJson — parses the live backend response ────────────────────────────
  factory AnalysisResult.fromJson(
    Map<String, dynamic> json, {
    // These come from the provider since the API echoes them in inputSummary
    required String state,
    required String district,
    required List<String> originalSymptoms,
    bool isOffline = false,
  }) {
    // inputSummary carries crop + sowingDate echoed back by backend
    final summary = json['inputSummary'] as Map<String, dynamic>? ?? {};
    final crop    = (summary['crop'] as String?) ??
                    (json['crop']    as String?) ?? '';
    final sowingStr = (summary['sowingDate'] as String?) ?? '';
    DateTime sowingDate;
    try {
      sowingDate = DateTime.parse(sowingStr);
    } catch (_) {
      sowingDate = DateTime.now();
    }

    // Weather phases
    final rawPhases = json['weatherPhases'] as List<dynamic>? ?? [];
    final phases = rawPhases
        .map((p) => WeatherPhase.fromJson(p as Map<String, dynamic>))
        .toList();

    // Recommendations
    final rawRecs = json['recommendations'] as List<dynamic>? ?? [];
    final recs = rawRecs.asMap().entries
        .map((e) =>
            RecommendationItem.fromJson(e.value as Map<String, dynamic>, e.key))
        .toList();

    // Model details
    final model = json['modelDetails'] as Map<String, dynamic>? ?? {};

    return AnalysisResult(
      crop:             crop,
      state:            state,
      district:         district,
      sowingDate:       sowingDate,
      symptoms:         originalSymptoms,
      causeKey:         (json['causeKey']    as String?) ?? 'unknown',
      causeTitle:       (json['causeTitle']  as String?) ?? '',
      confidenceScore:  (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      explanation:      (json['explanation'] as String?) ?? '',
      weatherPhases:    phases,
      recommendations:  recs,
      isLimitedAnalysis: isOffline,
      weatherSource:    (model['weatherSource'] as String?),
      modelMode:        (model['mode']          as String?),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get season {
    final m = sowingDate.month;
    if (m >= 6 && m <= 9) return 'Kharif';
    if (m >= 10 || m <= 3) return 'Rabi';
    return 'Zaid';
  }

  String get seasonYear => '$season ${sowingDate.year}';
}