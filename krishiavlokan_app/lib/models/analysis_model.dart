// lib/models/analysis_model.dart
// Updated to match the latest backend JSON shape.

// ─────────────────────────────────────────────────────────────────────────────
// Status helpers — new API sends internal keys directly (veryLow / low / etc.)
// ─────────────────────────────────────────────────────────────────────────────
String _statusEmoji(String status) => switch (status) {
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
  final String label;        // UI label e.g. "Early\n(Nov–Dec)"
  final String status;       // veryLow | low | normal | high | veryHigh
  final String emoji;

  // ── Raw API fields ─────────────────────────────────────────────────────────
  final String phase;           // "Early" | "Mid" | "Late"
  final String apiStatus;       // original API string (same as status in new API)
  final String idealStatus;     // expected status per crop rule
  final String metric;          // "rainfall / soil moisture"
  final double matchScore;      // 0.0–1.0
  final double rainfallMm;
  final double avgTempC;
  final double avgHumidityPct;
  final String source;          // "mock_fallback" | "open_meteo" etc.
  final String summary;         // human-readable summary sentence

  // Legacy fields — kept for backward compat, default 0
  final double rainfallDeviationPct;
  final double expectedRainfallMm;

  WeatherPhase({
    required this.label,
    required this.status,
    required this.emoji,
    required this.phase,
    required this.apiStatus,
    this.idealStatus            = '',
    this.metric                 = '',
    this.matchScore             = 0.0,
    required this.rainfallMm,
    required this.avgTempC,
    required this.avgHumidityPct,
    this.source                 = '',
    this.summary                = '',
    this.rainfallDeviationPct   = 0.0,
    this.expectedRainfallMm     = 0.0,
  });

  factory WeatherPhase.fromJson(Map<String, dynamic> json) {
    final rawStatus  = (json['status'] as String?) ?? 'normal';
    // New API sends internal keys directly; normalise to lowercase for safety
    final status     = rawStatus.toLowerCase().replaceAll(' ', '');
    // Map any legacy strings just in case
    final display    = _normaliseStatus(status);
    final phaseLabel = (json['phase'] as String?) ?? '';

    final start = (json['startDate'] as String?) ?? '';
    final end   = (json['endDate']   as String?) ?? '';
    final dateRange = (start.isNotEmpty && end.isNotEmpty)
        ? '${_shortDate(start)}–${_shortDate(end)}'
        : '';
    final label = dateRange.isNotEmpty
        ? '$phaseLabel\n($dateRange)'
        : phaseLabel;

    return WeatherPhase(
      label:                label,
      status:               display,
      emoji:                _statusEmoji(display),
      phase:                phaseLabel,
      apiStatus:            rawStatus,
      idealStatus:          (json['idealStatus']    as String?) ?? '',
      metric:               (json['metric']         as String?) ?? '',
      matchScore:           (json['matchScore']     as num?)?.toDouble() ?? 0.0,
      rainfallMm:           (json['rainfallMm']     as num?)?.toDouble() ?? 0.0,
      avgTempC:             (json['avgTempC']       as num?)?.toDouble() ?? 0.0,
      avgHumidityPct:       (json['avgHumidityPct'] as num?)?.toDouble() ?? 0.0,
      source:               (json['source']         as String?) ?? '',
      summary:              (json['summary']        as String?) ?? '',
      // Legacy fields
      rainfallDeviationPct: (json['rainfallDeviationPct'] as num?)?.toDouble() ?? 0.0,
      expectedRainfallMm:   (json['expectedRainfallMm']   as num?)?.toDouble() ?? 0.0,
    );
  }

  static String _normaliseStatus(String s) {
    if (s == 'verylow'  || s.contains('severe') && s.contains('low'))  return 'veryLow';
    if (s == 'veryhigh' || s.contains('severe') && s.contains('high')) return 'veryHigh';
    if (s == 'low'      || s.contains('moderate') && !s.contains('high')) return 'low';
    if (s == 'high'     || s.contains('high'))  return 'high';
    return 'normal';
  }

  static String _shortDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const m = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
      return "${m[dt.month-1]}'${dt.year.toString().substring(2)}";
    } catch (_) { return iso; }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RecommendationItem
// ─────────────────────────────────────────────────────────────────────────────
class RecommendationItem {
  final String adviceKey;
  final String emoji;
  final String title;
  final String detail;
  final String priority;    // "High" | "Medium" | "Low"
  final String effortLevel; // "Easy" | "Hard"

  const RecommendationItem({
    required this.adviceKey,
    required this.emoji,
    required this.title,
    required this.detail,
    this.priority    = '',
    this.effortLevel = '',
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json, int index) {
    final title = (json['title'] as String?) ?? '';
    final detail = (json['detail'] as String?) ?? '';
    const emojis = ['🌱', '💧', '🔍', '🌾', '🧪', '📅', '🌿', '🤝'];
    return RecommendationItem(
      adviceKey:   _adviceKeyFromJson(json, title, detail, index),
      emoji:       emojis[index % emojis.length],
      title:       title,
      detail:      detail,
      priority:    (json['priority']     as String?) ?? '',
      effortLevel: (json['effort_level'] as String?) ?? '',
    );
  }

  static String _adviceKeyFromJson(
    Map<String, dynamic> json,
    String title,
    String detail,
    int index,
  ) {
    final rawKey = (json['advice_key'] as String?)?.trim() ?? '';
    if (rawKey.isNotEmpty) return rawKey;

    final source = (title.isNotEmpty ? title : detail).toLowerCase();
    final normalized = source.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final compact =
        normalized.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return compact.isNotEmpty ? compact : 'step_${index + 1}';
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
  final String causeKey;
  final String causeTitle;
  final double confidenceScore;
  final String explanation;
  final List<WeatherPhase>       weatherPhases;
  final List<RecommendationItem> recommendations;
  final bool     isLimitedAnalysis;
  final DateTime analyzedAt;
  bool           adviceTaken;
  final String?  weatherSource;
  final String?  modelMode;

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

  factory AnalysisResult.fromJson(
    Map<String, dynamic> json, {
    required String state,
    required String district,
    required List<String> originalSymptoms,
    bool isOffline = false,
  }) {
    final summary   = json['inputSummary'] as Map<String, dynamic>? ?? {};
    final crop      = (summary['crop'] as String?) ?? (json['crop'] as String?) ?? '';
    final sowingStr = (summary['sowingDate'] as String?) ?? '';
    DateTime sowingDate;
    try { sowingDate = DateTime.parse(sowingStr); }
    catch (_) { sowingDate = DateTime.now(); }

    final rawPhases = json['weatherPhases'] as List<dynamic>? ?? [];
    final phases = rawPhases
        .map((p) => WeatherPhase.fromJson(p as Map<String, dynamic>))
        .toList();

    final rawRecs = json['recommendations'] as List<dynamic>? ?? [];
    final recs = rawRecs.asMap().entries
        .map((e) => RecommendationItem.fromJson(e.value as Map<String, dynamic>, e.key))
        .toList();

    final model = json['modelDetails'] as Map<String, dynamic>? ?? {};

    return AnalysisResult(
      crop:             crop,
      state:            state,
      district:         district,
      sowingDate:       sowingDate,
      symptoms:         originalSymptoms,
      causeKey:         (json['causeKey']        as String?) ?? 'unknown',
      causeTitle:       (json['causeTitle']      as String?) ?? '',
      confidenceScore:  (json['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      explanation:      (json['explanation']     as String?) ?? '',
      weatherPhases:    phases,
      recommendations:  recs,
      isLimitedAnalysis: isOffline,
      weatherSource:    (model['weatherSource'] as String?),
      modelMode:        (model['mode']          as String?),
    );
  }

  String get season {
    final m = sowingDate.month;
    if (m >= 6 && m <= 9) return 'Kharif';
    if (m >= 10 || m <= 3) return 'Rabi';
    return 'Zaid';
  }

  String get seasonYear => '$season ${sowingDate.year}';
}
