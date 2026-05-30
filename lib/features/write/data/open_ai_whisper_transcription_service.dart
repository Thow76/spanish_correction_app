import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../../core/enums/language.dart';
import '../../../core/services/prompt_builder.dart';
import '../application/transcription_service.dart';
import '../application/transcription_service_exception.dart';

class OpenAiWhisperTranscriptionService implements TranscriptionService {
  OpenAiWhisperTranscriptionService({
    required String apiKey,
    HttpClient? httpClient,
  }) : _apiKey = apiKey.trim(),
       _httpClient = httpClient ?? HttpClient();

  final String _apiKey;
  final HttpClient _httpClient;

  @override
  Future<String> transcribeAudio(String audioPath, Language language) async {
    _ensureConfigured();

    final audioFile = File(audioPath);
    if (!await audioFile.exists()) {
      throw const TranscriptionServiceException(
        TranscriptionFailureReason.apiFailure,
        'Recorded audio file does not exist.',
      );
    }

    final boundary = 'language-correction-${Random().nextInt(1 << 32)}';

    try {
      final request = await _httpClient
          .postUrl(Uri.https('api.openai.com', '/v1/audio/transcriptions'))
          .timeout(const Duration(seconds: 10));

      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey')
        ..set(
          HttpHeaders.contentTypeHeader,
          'multipart/form-data; boundary=$boundary',
        );

      _writeTextField(request, boundary, 'model', 'whisper-1');
      _writeTextField(
        request,
        boundary,
        'language',
        PromptBuilder.whisperLanguageCode(language),
      );
      _writeTextField(request, boundary, 'response_format', 'json');
      _writeTextField(
        request,
        boundary,
        'prompt',
        'Hola, ¿cómo estás? Me llamo María. El niño jugó rápidamente en el jardín. Sí, también está aquí.',
      );
      await _writeFileField(
        request,
        boundary,
        'file',
        audioFile,
        contentType: 'audio/wav',
      );
      request.write('--$boundary--\r\n');

      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      final body = await utf8.decodeStream(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw TranscriptionServiceException(
          TranscriptionFailureReason.apiFailure,
          'OpenAI transcription failed with HTTP ${response.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException(
          'OpenAI transcription root is not an object.',
        );
      }

      final text = decoded['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw const FormatException('OpenAI transcription text is empty.');
      }

      return text.trim();
    } on SocketException catch (error) {
      throw TranscriptionServiceException(
        TranscriptionFailureReason.networkUnavailable,
        'No internet available: $error',
      );
    } on TimeoutException catch (error) {
      throw TranscriptionServiceException(
        TranscriptionFailureReason.apiFailure,
        'OpenAI transcription timed out: $error',
      );
    } on FormatException catch (error) {
      throw TranscriptionServiceException(
        TranscriptionFailureReason.invalidResponse,
        'OpenAI returned an invalid transcription response: $error',
      );
    }
  }

  void _ensureConfigured() {
    if (_apiKey.isEmpty) {
      throw const TranscriptionServiceException(
        TranscriptionFailureReason.missingConfiguration,
        'Missing OPENAI_API_KEY.',
      );
    }
  }

  void _writeTextField(
    HttpClientRequest request,
    String boundary,
    String name,
    String value,
  ) {
    request.add(utf8.encode('--$boundary\r\n'));
    request.add(
      utf8.encode('Content-Disposition: form-data; name="$name"\r\n\r\n'),
    );
    request.add(utf8.encode('$value\r\n'));
  }

  Future<void> _writeFileField(
    HttpClientRequest request,
    String boundary,
    String name,
    File file, {
    required String contentType,
  }) async {
    request.write('--$boundary\r\n');
    request.write(
      'Content-Disposition: form-data; name="$name"; filename="recording.wav"\r\n',
    );
    request.write('Content-Type: $contentType\r\n\r\n');
    await request.addStream(file.openRead());
    request.write('\r\n');
  }
}
