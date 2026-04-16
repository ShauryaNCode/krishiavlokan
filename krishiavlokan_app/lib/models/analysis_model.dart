// lib/models/analysis_model.dart

/// Represents a single phase of the weather strip
class WeatherPhase {
  final String label;
  final String status; // 'normal' | 'low' | 'high' | 'veryLow' | 'veryHigh'
  final String emoji;

  const WeatherPhase({
    required this.label,
    required this.status,
    required this.emoji,
  });
}

/// Full analysis result returned by the diagnosis service
class AnalysisResult {
  final String crop;
  final String state;
  final String district;
  final DateTime sowingDate;
  final List<String> symptoms;
  final String causeKey;
  final String causeTitle;
  final String explanation;
  final List<WeatherPhase> weatherPhases;
  final List<RecommendationItem> recommendations;
  final bool isLimitedAnalysis; // true when offline/cached
  final DateTime analyzedAt;
  bool adviceTaken;

  AnalysisResult({
    required this.crop,
    required this.state,
    required this.district,
    required this.sowingDate,
    required this.symptoms,
    required this.causeKey,
    required this.causeTitle,
    required this.explanation,
    required this.weatherPhases,
    required this.recommendations,
    this.isLimitedAnalysis = false,
    DateTime? analyzedAt,
    this.adviceTaken = false,
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  /// Returns the season label based on the sowing month
  String get season {
    final m = sowingDate.month;
    if (m >= 6 && m <= 9) return 'Kharif';
    if (m >= 10 || m <= 3) return 'Rabi';
    return 'Zaid';
  }

  String get seasonYear => '${season} ${sowingDate.year}';
}

/// A single recommendation card
class RecommendationItem {
  final String emoji;
  final String title;
  final String detail;

  const RecommendationItem({
    required this.emoji,
    required this.title,
    required this.detail,
  });
}
