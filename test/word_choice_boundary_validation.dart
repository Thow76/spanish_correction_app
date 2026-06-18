// Word Choice vs. Natural Language boundary validation harness.
//
// MANUAL harness — makes live correction-API calls. Validates the sharpened
// one-word boundary (single word = Word Choice; phrase/construction = Natural
// Language) in both _correctionPromptSpanish and _correctionPromptPortuguese,
// with regression guards that Grammar and Spelling errors do not drift into
// Word Choice / Natural Language.
//
// Run:
//   OPENAI_API_KEY=sk-... flutter test test/word_choice_boundary_validation.dart --timeout none
//
// Writes a reviewable report to docs/word_choice_boundary_validation.md
// (override with --dart-define=WC_BOUNDARY_OUTPUT=...). Fails (not skips) when
// no API key is configured.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

const String outputPath = String.fromEnvironment(
  'WC_BOUNDARY_OUTPUT',
  defaultValue: 'docs/word_choice_boundary_validation.md',
);

class _Case {
  const _Case({
    required this.id,
    required this.language,
    required this.sentence,
    required this.targetToken,
    required this.expected,
    required this.note,
  });

  final String id;
  final Language language;

  /// The text submitted to the grader. Each is clean except for the one error
  /// under test (regression guards carry a single Grammar/Spelling error).
  final String sentence;

  /// A token identifying the error span, used to pick out the relevant
  /// correction from the grader's response.
  final String targetToken;

  /// The category the target correction must carry, or null for a
  /// register-prohibition guard where the target must NOT be flagged at all.
  final ErrorCategory? expected;
  final String note;
}

const List<_Case> _battery = [
  // ── Spanish ────────────────────────────────────────────────────────────────
  // Single-word false friend (the original Chunk 2 failing case).
  _Case(
    id: 'es-wc-falsefriend-realice',
    language: Language.spanish,
    sentence: 'Cuando llegué a casa, realicé que había olvidado las llaves.',
    targetToken: 'realicé',
    expected: ErrorCategory.wordChoice,
    note: 'Single-word false friend "realicé" (= I realised) -> Word Choice.',
  ),
  // A second, different single-word false friend (avoid weighting to one word).
  _Case(
    id: 'es-wc-falsefriend-atender',
    language: Language.spanish,
    sentence: 'Mañana tengo que atender una clase de historia en la universidad.',
    targetToken: 'atender',
    expected: ErrorCategory.wordChoice,
    note: 'Single-word false friend "atender" (= to attend) -> Word Choice.',
  ),
  // Phrase-level request-pattern calque; words are individually fine, but the
  // whole request restructures (no single-word fix). Article already correct.
  _Case(
    id: 'es-nl-phrase-buen-tiempo',
    language: Language.spanish,
    sentence: 'Tuvimos un buen tiempo en la fiesta de cumpleaños anoche.',
    // The grader anchors the calque restructure on the verb "Tuvimos"
    // ("Tuvimos un buen tiempo" -> "Lo pasamos bien"), so match there.
    targetToken: 'Tuvimos',
    expected: ErrorCategory.naturalLanguage,
    note: 'English calque "tener un buen tiempo" (= have a good time); a native '
        'restructures to "lo pasamos bien" -> Natural Language (phrase, no '
        'single-word fix).',
  ),
  // Request-pattern calque that GPT-4.1-mini did not flag at all; re-included to
  // see whether the new model surfaces it as Natural Language.
  _Case(
    id: 'es-nl-phrase-cerveza',
    language: Language.spanish,
    sentence: '¿Puedo tener una cerveza, por favor?',
    targetToken: 'tener',
    expected: ErrorCategory.naturalLanguage,
    note: 'English request calque "Puedo tener una cerveza" (= can I have a beer); '
        'native restructures the request ("¿Me pones/das una cerveza?") -> '
        'Natural Language. GPT-4.1-mini flagged nothing here.',
  ),
  // Register-prohibition guard: colloquial-but-correct word in a casual context
  // must NOT be flagged on formality grounds (expected == null -> no flag).
  _Case(
    id: 'es-register-guard-guay',
    language: Language.spanish,
    sentence: 'La fiesta de anoche estuvo muy guay, lo pasamos genial.',
    targetToken: 'guay',
    expected: null,
    note: 'Colloquial-but-correct "guay" (= cool) must NOT be flagged on register '
        'grounds.',
  ),
  // Regression guard: clear Grammar (verb conjugation).
  _Case(
    id: 'es-grammar-guard-conjugation',
    language: Language.spanish,
    sentence: 'Ayer yo va al mercado para comprar verduras frescas.',
    targetToken: 'va',
    expected: ErrorCategory.grammar,
    note: 'Wrong conjugation "yo va" (should be "fui") -> Grammar, NOT WC/NL.',
  ),
  // Regression guard: clear Spelling (missing tilde on ñ).
  _Case(
    id: 'es-spelling-guard-manana',
    language: Language.spanish,
    sentence: 'Voy a la playa con mis amigos manana por la tarde.',
    targetToken: 'manana',
    expected: ErrorCategory.spelling,
    note: 'Misspelling "manana" (should be "mañana") -> Spelling, NOT WC/NL.',
  ),

  // ── ES-001: English-calque flags (expect Natural Language) ──────────────────
  _Case(
    id: 'es-calque-cafe',
    language: Language.spanish,
    sentence: '¿Puedo tener un café, por favor?',
    targetToken: 'tener',
    expected: ErrorCategory.naturalLanguage,
    note: 'Request calque "puedo tener un café" -> "¿me pone un café?" -> NL.',
  ),
  _Case(
    id: 'es-calque-cita',
    language: Language.spanish,
    sentence: 'Necesito hacer una cita con el médico para la próxima semana.',
    targetToken: 'hacer una cita',
    expected: ErrorCategory.naturalLanguage,
    note: 'Calque "hacer una cita" -> "pedir cita" / "pedir hora" -> NL.',
  ),
  _Case(
    id: 'es-calque-para-atras',
    language: Language.spanish,
    sentence: 'Te voy a llamar para atrás esta tarde cuando llegue.',
    targetToken: 'para atrás',
    expected: ErrorCategory.naturalLanguage,
    note: 'Calque "llamar para atrás" -> "devolver la llamada" -> NL.',
  ),
  _Case(
    id: 'es-calque-cuidado',
    language: Language.spanish,
    sentence: 'Tienes que tomar mejor cuidado de tu salud.',
    targetToken: 'cuidado',
    expected: ErrorCategory.naturalLanguage,
    note: 'Calque "tomar cuidado de" -> "cuidar (mejor)" -> NL.',
  ),
  _Case(
    id: 'es-calque-tome-silla',
    language: Language.spanish,
    sentence: 'Cuando entré a la sala de espera, tomé silla cerca de la puerta.',
    targetToken: 'tomé silla',
    expected: ErrorCategory.naturalLanguage,
    note: 'Calque "tomé silla" -> "me senté" / "tomé asiento" -> NL.',
  ),

  // ── ES-001: false-positive guards (expect NO flag of the target) ────────────
  _Case(
    id: 'es-fp-me-sente',
    language: Language.spanish,
    sentence: 'Me senté cerca de la ventana para ver mejor el paisaje.',
    targetToken: 'senté',
    expected: null,
    note: 'Correct Spanish "me senté" must NOT be flagged.',
  ),
  _Case(
    id: 'es-fp-lo-pase-bien',
    language: Language.spanish,
    sentence: 'Lo pasé muy bien en la fiesta de anoche con mis amigos.',
    targetToken: 'pasé',
    expected: null,
    note: 'Correct Spanish "lo pasé bien" must NOT be flagged.',
  ),
  _Case(
    id: 'es-fp-pedi-cita',
    language: Language.spanish,
    sentence: 'Pedí cita con el médico para el lunes por la mañana.',
    targetToken: 'cita',
    expected: null,
    note: 'Correct Spanish "pedí cita" must NOT be flagged.',
  ),
  _Case(
    id: 'es-fp-final-del-dia-literal',
    language: Language.spanish,
    sentence: 'Volví a casa al final del día porque estaba muy cansado.',
    targetToken: 'al final del día',
    expected: null,
    note: 'Literal time-of-day "al final del día" must NOT be flagged on calque '
        'grounds.',
  ),

  // ── Portuguese (Brazilian) ──────────────────────────────────────────────────
  // Single-word false friend.
  _Case(
    id: 'pt-wc-falsefriend-realizei',
    language: Language.portuguese,
    sentence: 'Quando cheguei em casa, realizei que tinha esquecido as chaves.',
    targetToken: 'realizei',
    expected: ErrorCategory.wordChoice,
    note: 'Single-word false friend "realizei" (= I realised) -> Word Choice.',
  ),
  // Single-word anglicism (different surface pattern).
  _Case(
    id: 'pt-wc-anglicism-deletar',
    language: Language.portuguese,
    sentence: 'Preciso deletar esse arquivo antigo do meu computador hoje.',
    targetToken: 'deletar',
    expected: ErrorCategory.wordChoice,
    note: 'Single-word anglicism "deletar" (native: excluir/apagar) -> Word Choice.',
  ),
  // Phrase-level unidiomatic construction.
  _Case(
    id: 'pt-nl-phrase-fim-do-dia',
    language: Language.portuguese,
    sentence: 'No final do dia, o que realmente importa é a saúde da família.',
    targetToken: 'No final do dia',
    expected: ErrorCategory.naturalLanguage,
    note: 'Figurative calque phrase "no final do dia" (= at the end of the day) '
        '-> Natural Language.',
  ),
  // Register-prohibition guard: "legal" used to mean nice/good in a casual
  // context is correct and must NOT be flagged on register grounds (the
  // original failing case). expected == null -> no flag.
  _Case(
    id: 'pt-register-guard-legal',
    language: Language.portuguese,
    sentence: 'Achei o show de ontem muito legal, foi bem divertido.',
    targetToken: 'legal',
    expected: null,
    note: 'Colloquial-but-correct "legal" (= nice/cool) must NOT be flagged on '
        'register grounds.',
  ),
  // Regression guard: clear Grammar (verb conjugation).
  _Case(
    id: 'pt-grammar-guard-conjugation',
    language: Language.portuguese,
    sentence: 'Ontem eu vai ao mercado para comprar frutas e legumes.',
    targetToken: 'vai',
    expected: ErrorCategory.grammar,
    note: 'Wrong conjugation "eu vai" (should be "fui") -> Grammar, NOT WC/NL.',
  ),
  // Regression guard: clear Spelling (missing accents).
  _Case(
    id: 'pt-spelling-guard-proximo',
    language: Language.portuguese,
    sentence: 'Vou viajar para o Brasil no proximo mes com a minha familia.',
    targetToken: 'proximo',
    expected: ErrorCategory.spelling,
    note: 'Misspelling "proximo" (should be "próximo") -> Spelling, NOT WC/NL.',
  ),
];

void main() {
  test('word choice vs natural language boundary validation', () async {
    final config = AppConfig.fromEnvironment();
    final apiKey = _readEnvironment(
      'OPENAI_API_KEY',
      defaultValue: config.openAiApiKey,
    );
    final model = _readEnvironment(
      'OPENAI_CORRECTION_MODEL',
      defaultValue: config.openAiCorrectionModel,
    );

    if (apiKey.isEmpty) {
      fail(
        'Set OPENAI_API_KEY (or a default in AppConfig) to run the Word Choice '
        'boundary validation harness.',
      );
    }

    final service = OpenAiCorrectionService(apiKey: apiKey, model: model);

    final report = StringBuffer()
      ..writeln('# Word Choice vs. Natural Language Boundary Validation')
      ..writeln()
      ..writeln('Model: `$model`  ')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('| id | sentence | target | expected | actual | result |')
      ..writeln('| --- | --- | --- | --- | --- | --- |');

    var passes = 0;
    var fails = 0;
    var errors = 0;
    final details = StringBuffer();

    for (final testCase in _battery) {
      List<CorrectionItem> corrections;
      try {
        final response = await service.correctText(
          testCase.sentence,
          testCase.language,
        );
        corrections = response.corrections;
      } catch (error) {
        errors++;
        report.writeln(
          '| ${testCase.id} | ${testCase.sentence} | ${testCase.targetToken} '
          '| ${testCase.expected?.label ?? '(no flag)'} | (grader error) | ❌ |',
        );
        details
          ..writeln('### ${testCase.id} — grader error')
          ..writeln()
          ..writeln('- Error: $error')
          ..writeln();
        // ignore: avoid_print
        print('[ERR ] ${testCase.id}: $error');
        continue;
      }

      final target = _matchTarget(corrections, testCase.targetToken);
      final actual = target?.category;
      final actualLabel = actual?.label ?? '(not flagged)';
      // For register-prohibition guards (expected == null) pass means the
      // target was NOT flagged; otherwise the flagged category must match.
      final pass = testCase.expected == null
          ? target == null
          : actual == testCase.expected;
      final expectedLabel = testCase.expected?.label ?? '(no flag)';
      if (pass) {
        passes++;
      } else {
        fails++;
      }

      report.writeln(
        '| ${testCase.id} | ${testCase.sentence} | ${testCase.targetToken} '
        '| $expectedLabel | $actualLabel | ${pass ? '✅' : '❌'} |',
      );

      details
        ..writeln('### ${testCase.id}  ${pass ? '✅' : '❌'}')
        ..writeln()
        ..writeln('- Language: ${testCase.language.name}')
        ..writeln('- Sentence: `${testCase.sentence}`')
        ..writeln('- Target: `${testCase.targetToken}`')
        ..writeln(
          '- Expected: **$expectedLabel** · '
          'Actual: **$actualLabel**',
        )
        ..writeln('- All corrections: ${_describe(corrections)}')
        ..writeln('- Note: ${testCase.note}')
        ..writeln();

      // ignore: avoid_print
      print(
        '[${pass ? 'ok ' : 'FAIL'}] ${testCase.id}: '
        'expected=$expectedLabel actual=$actualLabel',
      );
    }

    report
      ..writeln()
      ..writeln(
        'Cases: ${_battery.length} · Pass: $passes · Fail: $fails · '
        'Grader errors: $errors',
      )
      ..writeln()
      ..writeln('---')
      ..writeln()
      ..write(details.toString());

    File(outputPath).writeAsStringSync(report.toString());
    // ignore: avoid_print
    print('Wrote $outputPath (pass $passes / fail $fails / err $errors)');
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Picks the correction whose original phrase best matches [targetToken],
/// ignoring pure punctuation insertions. Accent- and case-insensitive.
CorrectionItem? _matchTarget(
  List<CorrectionItem> corrections,
  String targetToken,
) {
  final needle = _fold(targetToken);
  CorrectionItem? best;
  for (final correction in corrections) {
    final original = correction.originalPhrase;
    if (original.trim().isEmpty) {
      continue; // skip punctuation/whitespace insertions
    }
    final hay = _fold(original);
    if (hay.contains(needle) || needle.contains(hay)) {
      best ??= correction;
    }
  }
  return best;
}

String _fold(String value) {
  final lower = value.toLowerCase().trim();
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index == -1 ? char : to[index]);
  }
  return buffer.toString();
}

String _describe(List<CorrectionItem> corrections) {
  if (corrections.isEmpty) {
    return '(none)';
  }
  return corrections
      .map(
        (c) =>
            '${c.category.label}:"${c.originalPhrase}"->"${c.correctedPhrase}"',
      )
      .join('; ');
}

String _readEnvironment(String key, {String defaultValue = ''}) {
  final value = Platform.environment[key]?.trim();
  return value == null || value.isEmpty ? defaultValue : value;
}
