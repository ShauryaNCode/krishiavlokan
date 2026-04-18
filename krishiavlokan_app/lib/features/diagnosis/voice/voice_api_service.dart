import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';

class VoiceApiService {
  VoiceApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri get _transcribeUri =>
      Uri.parse('${AppConstants.backendBaseUrl}/voice/transcribe');
  Uri get _extractUri =>
      Uri.parse('${AppConstants.backendBaseUrl}/voice/extract');

  Future<String?> transcribeAudio(
    File audioFile, {
    String? sessionId,
    String? languageCode,
  }) async {
    if (!await audioFile.exists()) {
      return null;
    }

    final request = http.MultipartRequest('POST', _transcribeUri)
      ..headers['Accept'] = 'application/json';

    if (sessionId != null && sessionId.isNotEmpty) {
      request.fields['sessionId'] = sessionId;
    }
    if (languageCode != null && languageCode.isNotEmpty) {
      request.fields['languageCode'] = languageCode;
    }

    request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(milliseconds: AppConstants.receiveTimeoutMs));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final transcript = (payload['transcript'] as String? ?? '').trim();
      return transcript.isEmpty ? null : transcript;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> extractSymptoms(
    String transcript, {
    String? sessionId,
  }) async {
    final text = transcript.trim();
    if (text.isEmpty) {
      return const [];
    }

    final body = jsonEncode({
      'text': text,
      if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
    });

    try {
      final response = await _client
          .post(
            _extractUri,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(milliseconds: AppConstants.receiveTimeoutMs));

      if (response.statusCode != 200) {
        return const [];
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final symptoms = payload['symptoms'];
      if (symptoms is! List) {
        return const [];
      }

      return symptoms
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  void dispose() {
    _client.close();
  }
}
