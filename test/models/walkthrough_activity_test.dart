import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/models/walkthrough_activity.dart';
import 'package:spanish_correction_app/core/models/walkthrough_exceptions.dart';
import 'package:spanish_correction_app/core/models/walkthrough_state.dart';

void main() {
  Map<String, Object?> questionJson(int chunkPosition) => {
    'english_stem': 'I am going',
    'correct_translation': 'voy',
    'distractors': ['va', 'vamos'],
    'chunk_position': chunkPosition,
  };

  Map<String, Object?> wellFormedJson({
    List<Object?>? answers,
    Object? completedAt,
    Object? language = 'portuguese',
  }) => {
    'source_phrase_id': 'phrase-1',
    'target_sentence': 'voy a la tienda',
    'language': language,
    'questions': [questionJson(0), questionJson(1)],
    'answers': answers ?? <Object?>[null, null],
    'completed_at': completedAt,
  };

  test('well-formed JSON parses with questions and answers populated', () {
    final activity = WalkthroughActivity.fromJson(
      wellFormedJson(answers: ['voy', null]),
    );

    expect(activity.sourcePhraseId, 'phrase-1');
    expect(activity.targetSentence, 'voy a la tienda');
    expect(activity.language, Language.portuguese);
    expect(activity.questions, hasLength(2));
    expect(activity.questions[0].englishStem, 'I am going');
    expect(activity.questions[1].chunkPosition, 1);
    expect(activity.answers, ['voy', null]);
    expect(activity.completedAt, isNull);
  });

  test('state is notStarted when all answers null and completedAt null', () {
    final activity = WalkthroughActivity.fromJson(wellFormedJson());

    expect(activity.state, WalkthroughState.notStarted);
  });

  test('state is inProgress when at least one answer is non-null', () {
    final activity = WalkthroughActivity.fromJson(
      wellFormedJson(answers: [null, 'tienda']),
    );

    expect(activity.state, WalkthroughState.inProgress);
  });

  test('state is completed when completedAt is set', () {
    final activity = WalkthroughActivity.fromJson(
      wellFormedJson(completedAt: '2026-06-16T10:00:00.000Z'),
    );

    expect(activity.state, WalkthroughState.completed);
  });

  test('copyWith updates answers without mutating the original', () {
    final original = WalkthroughActivity.fromJson(wellFormedJson());

    final updated = original.copyWith(answers: ['voy', 'a']);

    expect(updated.answers, ['voy', 'a']);
    expect(original.answers, [null, null]);
    expect(updated.state, WalkthroughState.inProgress);
    expect(original.state, WalkthroughState.notStarted);
  });

  test('round-trip: fromJson(toJson(a)) equals a', () {
    final activity = WalkthroughActivity.fromJson(
      wellFormedJson(
        answers: ['voy', null],
        completedAt: '2026-06-16T10:00:00.000Z',
      ),
    );

    final roundTripped = WalkthroughActivity.fromJson(activity.toJson());

    expect(roundTripped, activity);
    expect(roundTripped.hashCode, activity.hashCode);
  });

  test('non-list questions throws WalkthroughSchemaException', () {
    final json = wellFormedJson()..['questions'] = 'not a list';

    expect(
      () => WalkthroughActivity.fromJson(json),
      throwsA(isA<WalkthroughSchemaException>()),
    );
  });

  test('non-list answers throws WalkthroughSchemaException', () {
    final json = wellFormedJson()..['answers'] = 'not a list';

    expect(
      () => WalkthroughActivity.fromJson(json),
      throwsA(isA<WalkthroughSchemaException>()),
    );
  });

  test('missing language throws WalkthroughSchemaException', () {
    final json = wellFormedJson()..remove('language');

    expect(
      () => WalkthroughActivity.fromJson(json),
      throwsA(isA<WalkthroughSchemaException>()),
    );
  });

  test('invalid language throws WalkthroughSchemaException', () {
    final json = wellFormedJson(language: 'klingon');

    expect(
      () => WalkthroughActivity.fromJson(json),
      throwsA(isA<WalkthroughSchemaException>()),
    );
  });
}
