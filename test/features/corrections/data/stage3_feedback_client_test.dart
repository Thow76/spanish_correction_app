import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/data/stage3_feedback_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_candidate.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_verdict.dart';

void main() {
  const errorItem = CorrectionItem(
    originalPhrase: 'trafico',
    correctedPhrase: 'tráfico',
    category: ErrorCategory.spelling,
    shortExplanation: '',
    startIndex: 9,
    endIndex: 16,
  );

  StagedCorrectionCandidate dialectalCandidate({String? category = 'Other'}) {
    return StagedCorrectionCandidate(
      originalPhrase: 'coger el autobús',
      correctedPhrase: 'coger el autobús',
      occurrence: 1,
      category: category,
      verdict: StagedCorrectionVerdict.dialectal,
      startIndex: 20,
      endIndex: 37,
    );
  }

  group('buildStage3UserContent', () {
    test('includes one entry per error item and dialectal candidate', () {
      final content = buildStage3UserContent(
        errorItems: [errorItem],
        dialectalCandidates: [dialectalCandidate()],
      );
      final decoded = jsonDecode(content) as List;

      expect(decoded, hasLength(2));
      expect(decoded[0], {
        'start_index': 9,
        'original_phrase': 'trafico',
        'corrected_phrase': 'tráfico',
        'category': 'Spelling',
        'verdict': 'error',
      });
      expect(decoded[1], {
        'start_index': 20,
        'original_phrase': 'coger el autobús',
        'corrected_phrase': 'coger el autobús',
        'category': 'Other',
        'verdict': 'dialectal',
      });
    });

    test('defaults a null dialectal category to Other', () {
      final content = buildStage3UserContent(
        errorItems: const [],
        dialectalCandidates: [dialectalCandidate(category: null)],
      );
      final decoded = jsonDecode(content) as List;

      expect(decoded.single['category'], 'Other');
    });

    test('encodes an empty combined list as []', () {
      final content = buildStage3UserContent(
        errorItems: const [],
        dialectalCandidates: const [],
      );

      expect(content, '[]');
    });
  });

  group('parseStage3ExplanationArray', () {
    test('parses a populated array', () {
      final results = parseStage3ExplanationArray(
        '[{"start_index": 9, "short_explanation": "Missing accent."}]',
      );

      expect(results, hasLength(1));
      expect(results.single.startIndex, 9);
      expect(results.single.shortExplanation, 'Missing accent.');
    });

    test('parses an empty array', () {
      expect(parseStage3ExplanationArray('[]'), isEmpty);
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      final results = parseStage3ExplanationArray(
        '```json\n[{"start_index": 0, "short_explanation": "x"}]\n```',
      );
      expect(results, hasLength(1));
    });

    test('throws when no array is present', () {
      expect(
        () => parseStage3ExplanationArray('No explanations.'),
        throwsFormatException,
      );
    });

    test('throws when start_index is missing or invalid', () {
      expect(
        () => parseStage3ExplanationArray(
          '[{"short_explanation": "x"}]',
        ),
        throwsFormatException,
      );
      expect(
        () => parseStage3ExplanationArray(
          '[{"start_index": "nine", "short_explanation": "x"}]',
        ),
        throwsFormatException,
      );
    });

    test('throws when short_explanation is missing or empty', () {
      expect(
        () => parseStage3ExplanationArray('[{"start_index": 0}]'),
        throwsFormatException,
      );
      expect(
        () => parseStage3ExplanationArray(
          '[{"start_index": 0, "short_explanation": "   "}]',
        ),
        throwsFormatException,
      );
    });
  });

  group('joinStage3Explanations', () {
    test('fills in the real shortExplanation for a matched error item', () {
      final result = joinStage3Explanations(
        errorItems: [errorItem],
        dialectalCandidates: const [],
        explanations: const [
          Stage3ExplanationResult(
            startIndex: 9,
            shortExplanation: 'Haber is spelled with b — wait, tráfico takes an accent.',
          ),
        ],
      );

      expect(result.errorItems, hasLength(1));
      final item = result.errorItems.single;
      expect(
        item.shortExplanation,
        'Haber is spelled with b — wait, tráfico takes an accent.',
      );
      // Every other field carried over unchanged.
      expect(item.originalPhrase, errorItem.originalPhrase);
      expect(item.correctedPhrase, errorItem.correctedPhrase);
      expect(item.category, errorItem.category);
      expect(item.startIndex, errorItem.startIndex);
      expect(item.endIndex, errorItem.endIndex);
    });

    test('builds a CorrectionNote for a matched dialectal candidate', () {
      final result = joinStage3Explanations(
        errorItems: const [],
        dialectalCandidates: [dialectalCandidate()],
        explanations: const [
          Stage3ExplanationResult(
            startIndex: 20,
            shortExplanation: 'Standard in Spain; vulgar in parts of Latin America.',
          ),
        ],
      );

      expect(result.notes, hasLength(1));
      expect(result.notes.single.phrase, 'coger el autobús');
      expect(
        result.notes.single.note,
        'Standard in Spain; vulgar in parts of Latin America.',
      );
    });

    test('drops an error item Stage 3 returned no explanation for', () {
      final result = joinStage3Explanations(
        errorItems: [errorItem],
        dialectalCandidates: const [],
        explanations: const [],
      );

      expect(result.errorItems, isEmpty);
    });

    test('drops a dialectal candidate Stage 3 returned no explanation for', () {
      final result = joinStage3Explanations(
        errorItems: const [],
        dialectalCandidates: [dialectalCandidate()],
        explanations: const [],
      );

      expect(result.notes, isEmpty);
    });

    test(
      'joins each item to its own explanation by start_index, even when '
      'Stage 3 returns fewer explanations than requested',
      () {
        const secondErrorItem = CorrectionItem(
          originalPhrase: 'haver',
          correctedPhrase: 'haber',
          category: ErrorCategory.spelling,
          shortExplanation: '',
          startIndex: 40,
          endIndex: 45,
        );

        final result = joinStage3Explanations(
          errorItems: [errorItem, secondErrorItem],
          dialectalCandidates: [dialectalCandidate()],
          explanations: const [
            // Only the first error item and the dialectal candidate get an
            // explanation — secondErrorItem's start_index (40) is absent.
            Stage3ExplanationResult(startIndex: 9, shortExplanation: 'Missing accent.'),
            Stage3ExplanationResult(startIndex: 20, shortExplanation: 'Regional split.'),
          ],
        );

        expect(result.errorItems, hasLength(1));
        expect(result.errorItems.single.originalPhrase, 'trafico');
        expect(result.notes, hasLength(1));
      },
    );
  });

  group('callStage3Feedback', () {
    test('sends the Stage 3 system prompt and the built user content, and '
        'parses the reply', () async {
      final client = _CapturingHttpClient(
        _feedbackEnvelope(
          '[{"start_index": 9, "short_explanation": "Missing accent."}]',
        ),
      );

      final result = await callStage3Feedback(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: client,
        ),
        model: 'gpt-5.5',
        errorItems: [errorItem],
        dialectalCandidates: const [],
      );

      expect(result, hasLength(1));
      expect(result.single.startIndex, 9);
      expect(result.single.shortExplanation, 'Missing accent.');

      final sent = jsonDecode(client.lastRequest!.bodyAsString) as Map;
      final messages = sent['messages'] as List;
      expect(messages[0], {
        'role': 'system',
        'content': stage3FeedbackSpanish,
      });
      expect(
        messages[1]['content'],
        buildStage3UserContent(errorItems: [errorItem], dialectalCandidates: const []),
      );
    });
  });
}

/// Wraps [replyContent] (the JSON-array-shaped Stage 3 reply text) in a
/// minimal `/v1/chat/completions` response envelope.
String _feedbackEnvelope(String replyContent) => jsonEncode({
  'choices': [
    {
      'message': {'role': 'assistant', 'content': replyContent},
    },
  ],
});

// ── Minimal dart:io HttpClient fake that captures the outgoing request body
// — same hand-rolled approach as the other stage client tests.

class _CapturingHttpClient implements HttpClient {
  _CapturingHttpClient(this._replyBody);

  final String _replyBody;
  _CapturingRequest? lastRequest;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    final request = _CapturingRequest(replyBody: _replyBody);
    lastRequest = request;
    return request;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _CapturingRequest implements HttpClientRequest {
  _CapturingRequest({required this.replyBody});

  final String replyBody;
  final BytesBuilder _bytes = BytesBuilder();

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) => _bytes.add(data);

  String get bodyAsString => utf8.decode(_bytes.toBytes());

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse(responseBody: replyBody);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse({required String responseBody}) : _body = responseBody;

  final String _body;

  @override
  final int statusCode = 200;

  late final Stream<List<int>> _inner = Stream.fromIterable([
    utf8.encode(_body),
  ]);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _inner.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}
