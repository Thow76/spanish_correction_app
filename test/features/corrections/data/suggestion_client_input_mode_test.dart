import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/suggestion_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_input_mode.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

/// Build step 2.3: spoken text gets no Spelling items (decision C3).

String _reply(List<Map<String, String>> items) => jsonEncode({'items': items});

Map<String, String> _item(String written, String suggestion, String category) =>
    {
      'written': written,
      'suggestion': suggestion,
      'category': category,
      'reason': 'A reason.',
    };

/// A client whose two calls return [issuesReply] then [suggestionsReply],
/// recording the user message of each.
(SuggestionClient, List<String>) _client(
  String issuesReply,
  String suggestionsReply,
) {
  final userTexts = <String>[];
  final replies = [issuesReply, suggestionsReply];
  final client = SuggestionClient(
    call:
        ({
          required String model,
          required String systemPrompt,
          required String userText,
          String stageLabel = 'unspecified',
          Map<String, Object?>? responseFormat,
        }) async {
          userTexts.add(userText);
          return replies[userTexts.length - 1];
        },
  );
  return (client, userTexts);
}

void main() {
  group('issueCategoriesFor', () {
    test('typed text keeps every Issue category', () {
      expect(
        issueCategoriesFor(CorrectionInputMode.typed),
        twoStepIssueCategories,
      );
    });

    test('spoken text keeps every Issue category but Spelling', () {
      expect(issueCategoriesFor(CorrectionInputMode.spoken), [
        'Grammar',
        'Word Choice',
      ]);
    });
  });

  group('check with the input mode', () {
    const text = 'Donde esta el baño? Ayer yo fue al mercado.';
    final issuesReply = _reply([
      _item('Donde esta el baño?', '¿Dónde está el baño?', 'Spelling'),
      _item('yo fue', 'yo fui', 'Grammar'),
    ]);

    test('typed is the default and keeps the Spelling item', () async {
      final (client, userTexts) = _client(issuesReply, _reply(const []));

      final result = await client.check(text);

      expect(result.issues.map((i) => i.category), [
        ErrorCategory.spelling,
        ErrorCategory.grammar,
      ]);
      expect(
        result.suggestedText,
        '¿Dónde está el baño? Ayer yo fui al mercado.',
      );
      expect(
        userTexts.last,
        'Text to review:\n¿Dónde está el baño? Ayer yo fui al mercado.',
      );
    });

    test('spoken leaves the Spelling item out: not listed, not applied, and '
        'step 2 reads the text without it', () async {
      final (client, userTexts) = _client(issuesReply, _reply(const []));

      final result = await client.check(
        text,
        inputMode: CorrectionInputMode.spoken,
      );

      expect(result.issues, hasLength(1));
      expect(result.issues.single.category, ErrorCategory.grammar);
      expect(result.issues.single.originalPhrase, 'fue');
      expect(
        result.suggestedText,
        'Donde esta el baño? Ayer yo fui al mercado.',
      );
      expect(
        userTexts.last,
        'Text to review:\nDonde esta el baño? Ayer yo fui al mercado.',
      );
    });

    test('spoken still asks step 1 for every Issue category, so the prompt '
        'and the reply shape are unchanged', () async {
      Map<String, Object?>? firstFormat;
      final client = SuggestionClient(
        call:
            ({
              required String model,
              required String systemPrompt,
              required String userText,
              String stageLabel = 'unspecified',
              Map<String, Object?>? responseFormat,
            }) async {
              firstFormat ??= responseFormat;
              return _reply(const []);
            },
      );

      await client.check(text, inputMode: CorrectionInputMode.spoken);

      expect(firstFormat, twoStepResponseFormat(twoStepIssueCategories));
    });
  });
}
