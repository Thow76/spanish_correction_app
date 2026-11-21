import 'dart:convert';

import 'package:characters/characters.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/suggestion_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

/// One recorded call to the fake service.
class _Call {
  _Call(this.model, this.systemPrompt, this.userText, this.responseFormat);
  final String model;
  final String systemPrompt;
  final String userText;
  final Map<String, Object?>? responseFormat;
}

String _reply(List<Map<String, String>> items) => jsonEncode({'items': items});

Map<String, String> _item(
  String written,
  String suggestion,
  String category, [
  String reason = 'A reason.',
]) => {
  'written': written,
  'suggestion': suggestion,
  'category': category,
  'reason': reason,
};

/// A client whose two calls return [issuesReply] then [suggestionsReply].
(SuggestionClient, List<_Call>) _client(
  String issuesReply,
  String suggestionsReply,
) {
  final calls = <_Call>[];
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
          calls.add(_Call(model, systemPrompt, userText, responseFormat));
          return replies[calls.length - 1];
        },
  );
  return (client, calls);
}

/// The slice of [text] that [start]..[end] (graphemes) points at.
String _slice(String text, int? start, int? end) =>
    text.characters.getRange(start!, end!).toString();

void main() {
  group('parseSuggestionStepReply', () {
    test('reads the four parts of each item', () {
      final items = parseSuggestionStepReply(
        _reply([_item('cafe', 'café', 'Spelling', 'Needs the accent.')]),
      );
      expect(items, hasLength(1));
      expect(items.single.written, 'cafe');
      expect(items.single.suggestion, 'café');
      expect(items.single.category, 'Spelling');
      expect(items.single.reason, 'Needs the accent.');
    });

    test('tolerates Markdown fences and commentary', () {
      final items = parseSuggestionStepReply(
        '```json\n${_reply([_item('a', 'b', 'Grammar')])}\n```\nDone.',
      );
      expect(items, hasLength(1));
    });

    test('skips an item with a missing field', () {
      final items = parseSuggestionStepReply(
        '{"items": [{"written": "a", "suggestion": "b", "category": "Grammar"},'
        ' {"written": "c", "suggestion": "d", "category": "Grammar",'
        ' "reason": "r"}]}',
      );
      expect(items.map((i) => i.written), ['c']);
    });

    test('throws when there is no object or no items list', () {
      expect(() => parseSuggestionStepReply('nothing'), throwsFormatException);
      expect(
        () => parseSuggestionStepReply('{"corrected_text": "x"}'),
        throwsFormatException,
      );
    });
  });

  group('the two-step prompts', () {
    test('ask for the list of items only, not a rewritten text', () {
      for (final prompt in [
        twoStepIssuesPromptSpanish,
        twoStepSuggestionsPromptSpanish,
      ]) {
        expect(prompt, contains('one field, "items"'));
        expect(prompt, isNot(contains('corrected_text')));
      }
      for (final categories in [
        twoStepIssueCategories,
        twoStepSuggestionCategories,
      ]) {
        final schema =
            (twoStepResponseFormat(categories)['json_schema']!
                    as Map)['schema']!
                as Map;
        expect(schema['required'], ['items']);
        expect((schema['properties']! as Map).keys, ['items']);
      }
    });
  });

  group('suggestionCategoryFor', () {
    test('maps the four names onto today\'s categories until step 2.2', () {
      expect(suggestionCategoryFor('Spelling'), ErrorCategory.spelling);
      expect(suggestionCategoryFor('Grammar'), ErrorCategory.grammar);
      expect(suggestionCategoryFor('Word meaning'), ErrorCategory.wordChoice);
      expect(
        suggestionCategoryFor('Natural phrasing'),
        ErrorCategory.naturalPhrasing,
      );
      expect(suggestionCategoryFor('Tone'), isNull);
    });
  });

  group('wholeWordMatches', () {
    test('does not match inside a longer word', () {
      expect(wholeWordMatches('Compre cafe en una cafeteria', 'cafe'), [7]);
    });

    test('matches a span that starts with punctuation', () {
      expect(wholeWordMatches('Vi tráfico, y luego', ', y'), [10]);
    });
  });

  group('SuggestionClient.check', () {
    test(
      'calls Luna for Issues, then Sol on the text with Issues applied',
      () async {
        final (client, calls) = _client(
          _reply([_item('despues', 'después', 'Spelling')]),
          _reply([]),
        );

        await client.check('Voy despues.');

        expect(calls, hasLength(2));
        expect(calls[0].model, 'gpt-6-luna');
        expect(calls[0].systemPrompt, twoStepIssuesPromptSpanish);
        expect(calls[0].userText, 'Text to review:\nVoy despues.');
        expect(
          calls[0].responseFormat,
          twoStepResponseFormat(twoStepIssueCategories),
        );
        expect(calls[1].model, 'gpt-6-sol');
        expect(calls[1].systemPrompt, twoStepSuggestionsPromptSpanish);
        expect(calls[1].userText, 'Text to review:\nVoy después.');
        expect(
          calls[1].responseFormat,
          twoStepResponseFormat(twoStepSuggestionCategories),
        );
      },
    );

    test('the group is fixed by the step that found the point', () async {
      const text = 'Yo trabajo mucho y yo estudio en la librería pública.';
      final (client, _) = _client(
        _reply([
          _item('librería pública', 'biblioteca pública', 'Word Choice'),
        ]),
        _reply([_item('y yo estudio', 'y estudio', 'Natural phrasing')]),
      );

      final result = await client.check(text);

      expect(result.issues, hasLength(1));
      expect(result.issues.single.category, ErrorCategory.wordChoice);
      expect(result.suggestions, hasLength(1));
      expect(result.suggestions.single.category, ErrorCategory.naturalPhrasing);
      expect(result.groupOf(result.issues.single), SuggestionGroup.issue);
      expect(
        result.groupOf(result.suggestions.single),
        SuggestionGroup.suggestion,
      );
      expect(
        result.suggestedText,
        'Yo trabajo mucho y estudio en la biblioteca pública.',
      );
    });

    test('a category from the other step is left out', () async {
      final (client, _) = _client(
        _reply([_item('mucho', 'muchísimo', 'Natural phrasing')]),
        _reply([_item('Trabajo', 'Trabajó', 'Grammar')]),
      );

      final result = await client.check('Trabajo mucho.');

      expect(result.hasPoints, isFalse);
      expect(result.suggestedText, 'Trabajo mucho.');
    });

    test(
      'an item whose words are not found exactly once is left out',
      () async {
        final (client, _) = _client(
          _reply([
            _item('vi', 'veo', 'Grammar'),
            _item('no está aquí', 'x', 'Grammar'),
            _item('', 'x', 'Grammar'),
            _item('cafe', 'café', 'Spelling'),
          ]),
          _reply([]),
        );

        final result = await client.check(
          'Lo vi y lo vi en la cafeteria y cafe.',
        );

        expect(result.issues.map((i) => i.originalPhrase), ['cafe']);
        expect(result.suggestedText, 'Lo vi y lo vi en la cafeteria y café.');
      },
    );

    test('of two overlapping items, the first is kept', () async {
      final (client, _) = _client(
        _reply([
          _item('una decision', 'una decisión', 'Spelling'),
          _item('decision', 'decisión', 'Spelling'),
        ]),
        _reply([]),
      );

      final result = await client.check('Tomé una decision.');

      // The first item is kept, trimmed to the word that changes (2.2b);
      // the second then overlaps it and is dropped.
      expect(result.issues.single.originalPhrase, 'decision');
    });

    test('positions point at the right words in both texts', () async {
      const text = 'Compre cafe y yo lo bebí y yo comí.';
      final (client, _) = _client(
        _reply([
          _item('cafe', 'café', 'Spelling'),
          _item('Compre', 'Compré', 'Spelling'),
        ]),
        _reply([_item('y yo comí', 'y comí', 'Natural phrasing')]),
      );

      final result = await client.check(text);
      final response = result.toCorrectionResponse();

      expect(response.correctedText, 'Compré café y yo lo bebí y comí.');
      for (final CorrectionItem item in response.corrections) {
        expect(
          _slice(text, item.startIndex, item.endIndex),
          item.originalPhrase,
        );
        expect(
          _slice(
            response.correctedText,
            item.correctedStartIndex,
            item.correctedEndIndex,
          ),
          item.correctedPhrase,
        );
      }
      // Issues come first, in the order they appear in the text.
      expect(response.corrections.map((c) => c.originalPhrase), [
        'Compre',
        'cafe',
        'y yo comí',
      ]);
    });

    test(
      'a Suggestion that rewrites an Issue keeps no original position',
      () async {
        const text = 'Hizo un decision.';
        final (client, _) = _client(
          _reply([_item('decision', 'decisión', 'Spelling')]),
          _reply([
            _item('Hizo un decisión', 'Tomó una decisión', 'Natural phrasing'),
          ]),
        );

        final result = await client.check(text);

        expect(result.suggestedText, 'Tomó una decisión.');
        final issue = result.issues.single;
        expect(_slice(text, issue.startIndex, issue.endIndex), 'decision');
        expect(issue.correctedStartIndex, isNull);
        final suggestion = result.suggestions.single;
        expect(suggestion.startIndex, isNull);
        expect(
          _slice(
            result.suggestedText,
            suggestion.correctedStartIndex,
            suggestion.correctedEndIndex,
          ),
          'Tomó una decisión',
        );
      },
    );

    test('an Issue highlights only the words that change (2.2b)', () async {
      const text = 'Ayer yo fue al mercado. Estoy muy embarazada hoy.';
      final (client, _) = _client(
        _reply([
          _item('yo fue', 'yo fui', 'Grammar'),
          _item(
            'Estoy muy embarazada',
            'Estoy muy avergonzada',
            'Word Choice',
          ),
        ]),
        _reply([]),
      );

      final result = await client.check(text);

      expect(
        result.suggestedText,
        'Ayer yo fui al mercado. Estoy muy avergonzada hoy.',
      );
      final grammar = result.issues[0];
      expect(grammar.originalPhrase, 'fue');
      expect(grammar.correctedPhrase, 'fui');
      expect(grammar.startIndex, text.indexOf('fue'));
      expect(grammar.endIndex, text.indexOf('fue') + 3);
      final wordChoice = result.issues[1];
      expect(wordChoice.originalPhrase, 'embarazada');
      expect(wordChoice.correctedPhrase, 'avergonzada');
      expect(wordChoice.startIndex, text.indexOf('embarazada'));
    });

    test('a Natural phrasing point is never trimmed', () async {
      const text = 'Tengo que hacer una decisión.';
      final (client, _) = _client(
        _reply([]),
        _reply([
          _item('hacer una decisión', 'tomar una decisión', 'Natural phrasing'),
        ]),
      );

      final result = await client.check(text);

      expect(result.suggestions.single.originalPhrase, 'hacer una decisión');
      expect(result.suggestions.single.correctedPhrase, 'tomar una decisión');
    });

    test('words added or removed keep the quoted span', () async {
      const text = 'Fui mercado y vi muy muy bueno.';
      final (client, _) = _client(
        _reply([
          _item('Fui mercado', 'Fui al mercado', 'Grammar'),
          _item('muy muy bueno', 'muy bueno', 'Grammar'),
        ]),
        _reply([]),
      );

      final result = await client.check(text);

      expect(result.issues[0].originalPhrase, 'Fui mercado');
      expect(result.issues[1].originalPhrase, 'muy muy bueno');
      expect(result.suggestedText, 'Fui al mercado y vi muy bueno.');
    });

    test('nothing to report leaves the text as it was', () async {
      final (client, _) = _client(_reply([]), _reply([]));

      final result = await client.check('Hoy hace sol.');

      expect(result.hasPoints, isFalse);
      expect(result.suggestedText, 'Hoy hace sol.');
      expect(result.toCorrectionResponse().hasCorrections, isFalse);
    });

    test('an unreadable reply throws', () async {
      final (client, _) = _client('not json', _reply([]));

      expect(() => client.check('Hola.'), throwsFormatException);
    });
  });
}
