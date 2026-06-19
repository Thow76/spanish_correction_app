// THROWAWAY measurement harness — does NOT touch the production prompt/schema.
//
// Question it answers: if we asked the model to report, for each correction,
// the character positions of the corrected phrase IN ITS OWN corrected_text,
// would those positions actually be ACCURATE? This decides Option 2 (trust the
// model's corrected-text positions) vs Option 3 (the app must locate positions
// itself).
//
// It sends a MODIFIED copy of the correction request (a json_schema that ALSO
// requires corrected_start_index / corrected_end_index) to the committed model
// and, for every correction returned, slices the model's own corrected_text at
// the reported corrected indices and checks the slice equals corrected_phrase.
//
// Run:
//   OPENAI_API_KEY=sk-... flutter test test/corrected_index_reliability_probe.dart --timeout none
// (falls back to the committed AppConfig default key/model if env is unset)
//
// Writes a report to docs/corrected_index_reliability_probe.md
// (override with --dart-define=PROBE_OUTPUT=...).

import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';

const String outputPath = String.fromEnvironment(
  'PROBE_OUTPUT',
  defaultValue: 'docs/corrected_index_reliability_probe.md',
);

/// One sentence in the battery, tagged with the weak spot it stresses.
class _Case {
  const _Case({
    required this.id,
    required this.caseType,
    required this.sentence,
    required this.note,
  });

  final String id;
  final String caseType;
  final String sentence;
  final String note;
}

const List<_Case> _battery = [
  _Case(
    id: 'silent-edit-volvi',
    caseType: 'silent-edit / repeated-word',
    sentence:
        'Ayer fui al supermercado para comprar fruta y leche. Había mucha '
        'gente, pero encontré todo rápidamente. Después, pagué mis compras y '
        'volví para casa para preparar la cena.',
    note:
        'Bug 1 scenario: "para" appears 3x; the only error is "volví para casa" '
        '-> "volví a casa". The model may also tidy "para comprar" without '
        'itemising it.',
  ),
  _Case(
    id: 'repeated-word-banco',
    caseType: 'repeated-word',
    sentence:
        'Fui a el banco cerca de el parque para sacar dinero esta mañana.',
    note:
        'Repeated "el" / "a el" -> "al": positions must pick the RIGHT '
        'occurrence.',
  ),
  _Case(
    id: 'single-char-a',
    caseType: 'single-char',
    sentence: 'Cuando termino el trabajo, voy para casa en autobús.',
    note: 'Single-character corrected phrase "a" (para -> a). The hard case.',
  ),
  _Case(
    id: 'single-char-accent-ano',
    caseType: 'single-char / accented',
    sentence: 'Vivo en Espana desde hace tres anos y medio.',
    note:
        'Adds ñ to "Espana"->"España" and "anos"->"años": tests whether the '
        'model counts ñ as one user-perceived character the way the app does.',
  ),
  _Case(
    id: 'accented-habia',
    caseType: 'accented',
    sentence: 'Ayer habia mucho trafico en el centro de la ciudad.',
    note:
        'Accent restorations "habia"->"había", "trafico"->"tráfico": corrected '
        'phrases contain accented graphemes mid-string.',
  ),
  _Case(
    id: 'multi-correction-trip',
    caseType: 'multi-correction',
    sentence:
        'El año pasado yo va a Mexico con mi familia y nosotros comemos mucho '
        'comida tipico en muchos restaurantes.',
    note:
        '4+ errors (va->fui/iba, Mexico->México, mucho comida->mucha comida, '
        'tipico->típica): do positions stay accurate late in the string?',
  ),
];

/// Modified schema: production fields PLUS corrected-text positions.
const _probeSchema = <String, Object?>{
  'type': 'object',
  'additionalProperties': false,
  'required': ['original_text', 'corrected_text', 'corrections'],
  'properties': {
    'original_text': {'type': 'string'},
    'corrected_text': {'type': 'string'},
    'corrections': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': [
          'start_index',
          'end_index',
          'corrected_start_index',
          'corrected_end_index',
          'original_phrase',
          'corrected_phrase',
        ],
        'properties': {
          'start_index': {
            'type': 'integer',
            'description':
                'Zero-based inclusive index of original_phrase in original_text, '
                'in user-perceived characters.',
          },
          'end_index': {
            'type': 'integer',
            'description':
                'Zero-based exclusive index in original_text, in user-perceived '
                'characters.',
          },
          'corrected_start_index': {
            'type': 'integer',
            'description':
                'Zero-based inclusive index of corrected_phrase in the '
                'corrected_text string you return, in user-perceived characters.',
          },
          'corrected_end_index': {
            'type': 'integer',
            'description':
                'Zero-based exclusive index of corrected_phrase in the '
                'corrected_text string you return, in user-perceived characters.',
          },
          'original_phrase': {'type': 'string'},
          'corrected_phrase': {'type': 'string'},
        },
      },
    },
  },
};

const _probeSystemPrompt = '''
You are a Spanish correction engine.

Return only valid JSON matching the provided schema:
- original_text: the submitted text copied exactly.
- corrected_text: a polished corrected version of the whole text.
- corrections: one entry per change.

For EACH correction return TWO index pairs, both zero-based and measured in
user-perceived characters (an accented letter, ñ, or inverted punctuation each
count as ONE character):

1. start_index / end_index: locate original_phrase inside original_text
   (inclusive start, exclusive end). original_phrase must equal that slice.
2. corrected_start_index / corrected_end_index: locate corrected_phrase inside
   the corrected_text string you yourself return (inclusive start, exclusive
   end). The slice of corrected_text from corrected_start_index to
   corrected_end_index MUST equal corrected_phrase exactly, character for
   character.

Before responding, verify both slices match by counting characters in the
strings you return. If corrected_phrase is empty (a deletion) set
corrected_start_index == corrected_end_index at the deletion point.
Do not include Markdown, code fences, or any keys outside the schema.
''';

void main() {
  test('corrected-text index self-report reliability', () async {
    final config = AppConfig.fromEnvironment();
    final apiKey = _readEnv('OPENAI_API_KEY', config.openAiApiKey);
    final model = _readEnv('OPENAI_CORRECTION_MODEL', config.openAiCorrectionModel);

    if (apiKey.isEmpty) {
      fail('Set OPENAI_API_KEY (or an AppConfig default) to run this probe.');
    }

    final report = StringBuffer()
      ..writeln('# Corrected-text index self-report reliability')
      ..writeln()
      ..writeln('Model: `$model`  ')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln(
        'Question: are the model\'s self-reported corrected_text positions '
        'accurate (slice == corrected_phrase)?',
      )
      ..writeln()
      ..writeln(
        '| case type | sentence id | corrected_phrase | reported '
        '[cs,ce) | slice at that index | match? | offset |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- | --- |');

    final details = StringBuffer();
    var totalCorr = 0;
    var totalPass = 0;
    final byType = <String, List<bool>>{};

    for (final c in _battery) {
      Map<String, Object?> json;
      try {
        json = await _correctWithCorrectedIndices(
          apiKey: apiKey,
          model: model,
          sentence: c.sentence,
        );
      } catch (error) {
        report.writeln(
          '| ${c.caseType} | ${c.id} | — | — | (API error) | ❌ | — |',
        );
        details
          ..writeln('### ${c.id} — API error')
          ..writeln()
          ..writeln('- $error')
          ..writeln();
        // ignore: avoid_print
        print('[ERR ] ${c.id}: $error');
        continue;
      }

      final correctedText = (json['corrected_text'] as String?) ?? '';
      final correctedGraphemes = correctedText.characters.toList();
      final corrections = (json['corrections'] as List?) ?? const [];

      details
        ..writeln('### ${c.id}  (${c.caseType})')
        ..writeln()
        ..writeln('- Sentence: `${c.sentence}`')
        ..writeln('- Note: ${c.note}')
        ..writeln('- corrected_text: `$correctedText`')
        ..writeln();

      for (final raw in corrections) {
        if (raw is! Map) continue;
        final correctedPhrase = (raw['corrected_phrase'] as String?) ?? '';
        final cs = _asInt(raw['corrected_start_index']);
        final ce = _asInt(raw['corrected_end_index']);
        totalCorr++;
        byType.putIfAbsent(c.caseType, () => <bool>[]);

        final slice = _graphemeSlice(correctedGraphemes, cs, ce);
        final match = slice == correctedPhrase;

        // If it didn't match, measure how far off the reported start is from
        // the nearest true occurrence of corrected_phrase in corrected_text.
        String offset = '0';
        if (!match) {
          offset = _nearestOffset(
            correctedGraphemes,
            correctedPhrase,
            cs ?? 0,
          );
        }

        if (match) totalPass++;
        byType[c.caseType]!.add(match);

        report.writeln(
          '| ${c.caseType} | ${c.id} | `$correctedPhrase` | '
          '[$cs,$ce) | `$slice` | ${match ? '✅' : '❌'} | $offset |',
        );
        details.writeln(
          '  - `$correctedPhrase` -> reported [$cs,$ce), slice `$slice` '
          '${match ? 'OK' : 'MISALIGNED ($offset)'}',
        );
        // ignore: avoid_print
        print(
          '[${match ? 'ok ' : 'FAIL'}] ${c.id}: "$correctedPhrase" '
          '[$cs,$ce) -> "$slice"${match ? '' : ' off=$offset'}',
        );
      }
      details.writeln();
    }

    final overall = totalCorr == 0
        ? 0
        : (100 * totalPass / totalCorr).round();

    report
      ..writeln()
      ..writeln('## Accuracy')
      ..writeln()
      ..writeln('Overall: $totalPass / $totalCorr correct ($overall%)')
      ..writeln()
      ..writeln('| case type | correct / total |')
      ..writeln('| --- | --- |');
    byType.forEach((type, results) {
      final pass = results.where((r) => r).length;
      report.writeln('| $type | $pass / ${results.length} |');
    });
    report
      ..writeln()
      ..writeln('---')
      ..writeln()
      ..write(details.toString());

    File(outputPath).writeAsStringSync(report.toString());
    // ignore: avoid_print
    print('Wrote $outputPath — $totalPass/$totalCorr ($overall%) accurate');
  }, timeout: const Timeout(Duration(minutes: 15)));
}

/// Direct call to /v1/responses with the MODIFIED schema. Returns the parsed
/// correction JSON object (NOT routed through fromAnchoredJson, so the
/// corrected_* fields survive).
Future<Map<String, Object?>> _correctWithCorrectedIndices({
  required String apiKey,
  required String model,
  required String sentence,
}) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20);
  try {
    final request = await client.postUrl(
      Uri.https('api.openai.com', '/v1/responses'),
    );
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer ${apiKey.trim()}')
      ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);
    request.add(
      utf8.encode(
        jsonEncode({
          'model': model.trim(),
          'input': [
            {'role': 'system', 'content': _probeSystemPrompt},
            {'role': 'user', 'content': 'Review this Spanish text:\n\n$sentence'},
          ],
          'text': {
            'format': {
              'type': 'json_schema',
              'name': 'corrected_index_probe',
              'strict': true,
              'schema': _probeSchema,
            },
          },
        }),
      ),
    );

    final response = await request.close().timeout(
      const Duration(minutes: 3),
    );
    final body = await utf8.decodeStream(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('HTTP ${response.statusCode}: $body');
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('response root not an object');
    }
    final text = _extractOutputText(decoded);
    final obj = jsonDecode(_extractJsonObject(text));
    if (obj is! Map<String, Object?>) {
      throw const FormatException('correction root not an object');
    }
    return obj;
  } finally {
    client.close(force: true);
  }
}

String _graphemeSlice(List<String> graphemes, int? start, int? end) {
  if (start == null || end == null) return '<null>';
  if (start < 0 || end > graphemes.length || end < start) {
    return '<out-of-range $start..$end of ${graphemes.length}>';
  }
  return graphemes.sublist(start, end).join();
}

/// Reports the signed grapheme distance from [reportedStart] to the nearest
/// true occurrence of [phrase] in [graphemes], or "(not found)".
String _nearestOffset(List<String> graphemes, String phrase, int reportedStart) {
  if (phrase.isEmpty) return 'empty-phrase';
  final needle = phrase.characters.toList();
  final occurrences = <int>[];
  for (var i = 0; i + needle.length <= graphemes.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      if (graphemes[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) occurrences.add(i);
  }
  if (occurrences.isEmpty) return '(phrase absent from corrected_text)';
  var best = occurrences.first;
  for (final o in occurrences) {
    if ((o - reportedStart).abs() < (best - reportedStart).abs()) best = o;
  }
  final delta = reportedStart - best;
  final occ = occurrences.length > 1 ? ' (${occurrences.length} occ)' : '';
  return '${delta >= 0 ? '+' : ''}$delta chars$occ';
}

int? _asInt(Object? v) => v is int ? v : (v is num ? v.toInt() : null);

String _extractJsonObject(String text) {
  final trimmed = text.trim();
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) return trimmed;
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('no JSON object found');
  }
  return trimmed.substring(start, end + 1);
}

String _extractOutputText(Map<String, Object?> decoded) {
  final outputText = decoded['output_text'];
  if (outputText is String && outputText.trim().isNotEmpty) {
    return outputText.trim();
  }
  final output = decoded['output'];
  if (output is! List) throw const FormatException('no output');
  final buffer = StringBuffer();
  for (final item in output) {
    if (item is! Map<String, Object?>) continue;
    final content = item['content'];
    if (content is! List) continue;
    for (final part in content) {
      if (part is! Map<String, Object?>) continue;
      final t = part['text'];
      if (t is String) buffer.write(t);
    }
  }
  final t = buffer.toString().trim();
  if (t.isEmpty) throw const FormatException('no output text');
  return t;
}

String _readEnv(String key, String fallback) {
  final v = Platform.environment[key]?.trim();
  return v == null || v.isEmpty ? fallback : v;
}
