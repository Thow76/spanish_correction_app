import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Thrown when [OpenAiChatCompletionsClient.complete] cannot produce a reply
/// — a network failure, a non-2xx HTTP status, or a response shape that
/// doesn't match what `/v1/chat/completions` is expected to return.
class ChatCompletionsException implements Exception {
  const ChatCompletionsException(this.message);

  final String message;

  @override
  String toString() => 'ChatCompletionsException: $message';
}

/// Calls OpenAI's `/v1/chat/completions` endpoint with a system/user message
/// pair and returns the assistant's raw reply text.
///
/// This is the shared transport primitive the staged correction pipeline's
/// four prompt calls (Stage 1, Stage 1B, Stage 2, Stage 3) are built on —
/// each stage harness in `test/` already validated this exact request shape
/// and extraction logic independently; this class is that logic made real
/// and reusable instead of copied by value a fifth time. It knows nothing
/// about any stage's prompt content or response shape — parsing a stage's
/// reply into its own structured result is each stage's own concern, not
/// this class's.
///
/// Deliberately not part of the `CorrectionService` interface and not
/// wired into `correctText()` or any live route — the staged pipeline this
/// supports is assembled and tested independently before any such wiring.
class OpenAiChatCompletionsClient {
  OpenAiChatCompletionsClient({required String apiKey, HttpClient? httpClient})
    : _apiKey = apiKey.trim(),
      _httpClient = httpClient ?? HttpClient();

  final String _apiKey;
  final HttpClient _httpClient;

  Future<String> complete({
    required String model,
    required String systemPrompt,
    required String userText,
  }) async {
    try {
      final request = await _httpClient
          .postUrl(Uri.https('api.openai.com', '/v1/chat/completions'))
          .timeout(const Duration(seconds: 10));

      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey')
        ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);

      request.add(
        utf8.encode(
          jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userText},
            ],
          }),
        ),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await utf8.decodeStream(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ChatCompletionsException(
          'Chat completions call failed with HTTP ${response.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException(
          'Chat completions response root is not an object.',
        );
      }

      return _extractReplyText(decoded);
    } on SocketException catch (error) {
      throw ChatCompletionsException('No internet available: $error');
    } on TimeoutException catch (error) {
      throw ChatCompletionsException('Chat completions call timed out: $error');
    } on FormatException catch (error) {
      throw ChatCompletionsException(
        'Chat completions returned an invalid response: $error',
      );
    }
  }

  /// Extracts `choices[0].message.content`, trimmed — the assistant's reply
  /// text from a decoded `/v1/chat/completions` response body.
  static String _extractReplyText(Map<String, Object?> decodedBody) {
    final choices = decodedBody['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('Chat completions response has no choices.');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map<String, Object?>) {
      throw const FormatException('Chat completions choice is not an object.');
    }

    final message = firstChoice['message'];
    if (message is! Map<String, Object?>) {
      throw const FormatException('Chat completions choice has no message.');
    }

    final content = message['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const FormatException('Chat completions message has no content.');
    }

    return content.trim();
  }
}
