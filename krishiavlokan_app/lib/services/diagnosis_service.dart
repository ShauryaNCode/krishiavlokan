// lib/services/diagnosis_service.dart
//
// Real HTTP integration with the CropSight backend.
// Sends farmer input + live coordinates → receives AI analysis JSON.
// Falls back to a safe error throw which DiagnosisProvider catches.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_model.dart';
import '../core/constants/app_constants.dart';

class DiagnosisService {
  /// POST to the backend analyze endpoint and return a parsed AnalysisResult.
  ///
  /// Throws a [DiagnosisException] on network error, timeout, or non-200 status.
  Future<AnalysisResult> analyze({
    required String       crop,
    required String       state,
    required String       district,
    required DateTime     sowingDate,
    required List<String> symptoms,
    required double       lat,
    required double       lon,
    bool isOffline = false,
  }) async {
    // Build request body matching backend contract exactly
    final body = jsonEncode({
      'crop':       crop,
      'state':      state,
      'district':   district,
      'sowingDate': _formatDate(sowingDate),  // "YYYY-MM-DD"
      'symptoms':   symptoms,
      'lat':        lat,
      'lon':        lon,
      'isOffline':  isOffline,
    });

    final uri = Uri.parse(AppConstants.analyzeEndpoint);

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept':       'application/json',
            },
            body: body,
          )
          .timeout(
            const Duration(milliseconds: AppConstants.receiveTimeoutMs),
            onTimeout: () => throw DiagnosisException(
              'Request timed out. Please check your connection.',
            ),
          );
    } on DiagnosisException {
      rethrow;
    } catch (e) {
      throw DiagnosisException('Network error: ${e.toString()}');
    }

    if (response.statusCode != 200) {
      throw DiagnosisException(
        'Server error (${response.statusCode}). Please try again.',
      );
    }

    // Parse the response JSON
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw DiagnosisException('Invalid response from server.');
    }

    return AnalysisResult.fromJson(
      json,
      state:             state,
      district:          district,
      originalSymptoms:  symptoms,
      isOffline:         isOffline,
    );
  }

  /// Formats DateTime as "YYYY-MM-DD" for the API.
  String _formatDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';
}

/// Thrown by DiagnosisService on any failure — network, timeout, or server error.
class DiagnosisException implements Exception {
  final String message;
  const DiagnosisException(this.message);

  @override
  String toString() => message;
}