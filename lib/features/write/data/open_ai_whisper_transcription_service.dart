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

    // Every recorder in the app writes mono WAV at 16 kHz, 16 bits: 32,000
    // bytes a second after a 44-byte header. Under about half a second there
    // are no words to hear, and Whisper tends to invent a line instead.
    if (await audioFile.length() < minimumAudioBytes) {
      throw const TranscriptionServiceException(
        TranscriptionFailureReason.nothingHeard,
        'The recording is too short to hold any words.',
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

      if (isSilenceHallucination(text)) {
        throw TranscriptionServiceException(
          TranscriptionFailureReason.nothingHeard,
          'Whisper returned a line it invents for silence: $text',
        );
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

  /// About half a second of mono 16 kHz 16-bit WAV, plus its header.
  static const int minimumAudioBytes = 44 + 16000;

  /// Lines Whisper is known to invent when it hears silence or noise, learnt
  /// from the subtitled videos it was trained on (for example "Subtítulos
  /// realizados por la comunidad de Amara.org"). Matched without regard to
  /// case or accents.
  static const List<String> _inventedLineFragments = [
    'amara.org',
    'subtitulos realizados por',
    'subtitulos por la comunidad',
    'subtitulado por la comunidad',
    'legendas pela comunidade',
  ];

  /// Short lines that are invented when they are the whole transcription.
  static const List<String> _inventedWholeLines = [
    'gracias por ver el video',
    'gracias por ver',
    'suscribete',
    'subtitulos',
    'obrigado por assistir',
  ];

  /// Whether [text] is one of Whisper's invented lines rather than speech.
  static bool isSilenceHallucination(String text) {
    final plain = _plain(text);
    if (plain.isEmpty) {
      return true;
    }
    if (_inventedLineFragments.any(plain.contains)) {
      return true;
    }
    final bare = plain.replaceAll(RegExp(r'[^a-z0-9 ]'), '').trim();
    return _inventedWholeLines.contains(bare);
  }

  static String _plain(String text) {
    const accented = 'áàâäãéèêëíìîïóòôöõúùûüñç';
    const plain = 'aaaaaeeeeiiiiooooouuuunc';
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().trim().runes) {
      final char = String.fromCharCode(rune);
      final index = accented.indexOf(char);
      buffer.write(index >= 0 ? plain[index] : char);
    }
    return buffer.toString();
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
