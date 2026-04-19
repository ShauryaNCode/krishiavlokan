// lib/services/history_api_service.dart
//
// Handles all network calls to the backend history endpoints:
//   POST /history/{userId}   — save one diagnosis result
//   GET  /history/{userId}   — fetch all saved results for this device
//
// Both calls are fire-and-forget safe — errors are caught and surfaced as
// typed exceptions so the UI can decide whether to show them.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/analysis_model.dart';

class HistoryApiService {
  HistoryApiService._();
  static final HistoryApiService instance = HistoryApiService._();

  static const _timeout =
      Duration(milliseconds: AppConstants.receiveTimeoutMs);

  // ── POST /history/{userId} ─────────────────────────────────────────────────

  /// Saves [result] to Firestore via the backend.
  /// Throws [HistoryApiException] on failure.
  Future<void> saveResult({
    required String userId,
    required AnalysisResult result,
  }) async {
    final uri = Uri.parse('${AppConstants.historyEndpoint}/$userId');

    // Build the payload that matches what the backend history_service expects.
    // The backend stores whatever dict it receives, so we mirror the structure
    // the diagnosis endpoint already returns (request + response wrapper).
    final payload = _buildPayload(result);

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            _timeout,
            onTimeout: () => throw const HistoryApiException('Save timed out.'),
          );
    } on HistoryApiException {
      rethrow;
    } catch (e) {
      throw HistoryApiException('Network error: $e');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw HistoryApiException(
          'Save failed (${response.statusCode}).');
    }
  }

  // ── GET /history/{userId} ──────────────────────────────────────────────────

  /// Fetches all history entries for [userId] from the backend.
  /// Returns a list of [AnalysisResult] parsed from the Firestore documents.
  /// Throws [HistoryApiException] on failure.
  Future<List<AnalysisResult>> fetchHistory({
    required String userId,
  }) async {
    final uri = Uri.parse('${AppConstants.historyEndpoint}/$userId');

    http.Response response;
    try {
      response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(
            _timeout,
            onTimeout: () =>
                throw const HistoryApiException('Fetch timed out.'),
          );
    } on HistoryApiException {
      rethrow;
    } catch (e) {
      throw HistoryApiException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw HistoryApiException(
          'Fetch failed (${response.statusCode}).');
    }

    final List<dynamic> raw;
    try {
      raw = jsonDecode(response.body) as List<dynamic>;
    } catch (_) {
      throw const HistoryApiException('Invalid response from server.');
    }

    // Parse each Firestore document into an AnalysisResult.
    // Documents have the shape:  { id, created_at, request: {...}, response: {...} }
    final results = <AnalysisResult>[];
    for (final item in raw) {
      try {
        final parsed = _parseHistoryItem(item as Map<String, dynamic>);
        if (parsed != null) results.add(parsed);
      } catch (_) {
        // Skip malformed entries — don't let one bad record crash the list
        continue;
      }
    }

    return results;
  }

  // ── Payload builder ────────────────────────────────────────────────────────
  //
  // Mirrors the exact JSON structure the backend already produces so that
  // stored documents are consistent whether saved by the backend after
  // diagnosis or saved manually by the Flutter client.

  Map<String, dynamic> _buildPayload(AnalysisResult r) {
    return {
      'request': {
        'crop':       r.crop,
        'state':      r.state,
        'district':   r.district,
        'sowingDate': _fmtDate(r.sowingDate),
        'symptoms':   r.symptoms,
        'lat':        0.0, // coordinates not stored on AnalysisResult directly
        'lon':        0.0, // (they're used during analysis, not persisted)
      },
      'response': {
        'causeKey':        r.causeKey,
        'causeTitle':      r.causeTitle,
        'confidenceScore': r.confidenceScore,
        'explanation':     r.explanation,
        'weatherPhases':   r.weatherPhases.map(_phaseToJson).toList(),
        'recommendations': r.recommendations.map(_recToJson).toList(),
        'inputSummary': {
          'crop':       r.crop,
          'state':      r.state,
          'district':   r.district,
          'sowingDate': _fmtDate(r.sowingDate),
          'season':     r.season.toLowerCase(),
          'normalizedSymptoms': r.symptoms,
        },
      },
    };
  }

  Map<String, dynamic> _phaseToJson(WeatherPhase p) => {
        'phase':          p.phase,
        'status':         p.status,
        'rainfallMm':     p.rainfallMm,
        'avgTempC':       p.avgTempC,
        'avgHumidityPct': p.avgHumidityPct,
        'matchScore':     p.matchScore,
        'idealStatus':    p.idealStatus,
        'metric':         p.metric,
        'source':         p.source,
        'summary':        p.summary,
      };

  Map<String, dynamic> _recToJson(RecommendationItem r) => {
        'title':        r.title,
        'detail':       r.detail,
        'priority':     r.priority,
        'effort_level': r.effortLevel,
      };

  String _fmtDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  // ── History item parser ────────────────────────────────────────────────────
  //
  // Each Firestore document returned by GET /history/{userId} looks like:
  //   { "id": "abc123", "created_at": "...", "request": {...}, "response": {...} }

  AnalysisResult? _parseHistoryItem(Map<String, dynamic> item) {
    final req  = item['request']  as Map<String, dynamic>? ?? {};
    final resp = item['response'] as Map<String, dynamic>? ?? {};
    if (resp.isEmpty) return null;

    // Merge into the shape AnalysisResult.fromJson expects
    final merged = Map<String, dynamic>.from(resp);
    merged['inputSummary'] = {
      ...( resp['inputSummary'] as Map<String, dynamic>? ?? {} ),
      'crop':       req['crop']       ?? resp['inputSummary']?['crop'] ?? '',
      'state':      req['state']      ?? '',
      'district':   req['district']   ?? '',
      'sowingDate': req['sowingDate'] ?? '',
    };

    // Parse analyzedAt from created_at if available
    DateTime? analyzedAt;
    final createdAt = item['created_at'];
    if (createdAt is String) {
      analyzedAt = DateTime.tryParse(createdAt);
    }

    final result = AnalysisResult.fromJson(
      merged,
      state:            req['state']    as String? ?? '',
      district:         req['district'] as String? ?? '',
      originalSymptoms: List<String>.from(req['symptoms'] as List? ?? []),
    );

    // Inject the Firestore document id and timestamp
    return AnalysisResult(
      crop:             result.crop,
      state:            result.state,
      district:         result.district,
      sowingDate:       result.sowingDate,
      symptoms:         result.symptoms,
      causeKey:         result.causeKey,
      causeTitle:       result.causeTitle,
      confidenceScore:  result.confidenceScore,
      explanation:      result.explanation,
      weatherPhases:    result.weatherPhases,
      recommendations:  result.recommendations,
      isLimitedAnalysis: result.isLimitedAnalysis,
      analyzedAt:       analyzedAt ?? result.analyzedAt,
      weatherSource:    result.weatherSource,
      modelMode:        result.modelMode,
    );
  }
}

/// Thrown on any history API failure.
class HistoryApiException implements Exception {
  final String message;
  const HistoryApiException(this.message);
  @override
  String toString() => message;
}