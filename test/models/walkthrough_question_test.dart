import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/models/walkthrough_exceptions.dart';
import 'package:spanish_correction_app/core/models/walkthrough_question.dart';

void main() {
  Map<String, Object?> wellFormedJson() => {
    'english_stem': 'I am going',
    'correct_translation': 'voy',
    'distractors': ['va', 'vamos'],
    'chunk_position': 0,
  };

  test('well-formed JSON with two distractors parses cleanly', () {
    final question = WalkthroughQuestion.fromJson(wellFormedJson());

    expect(question.englishStem, 'I am going');
    expect(question.correctTranslation, 'voy');
    expect(question.distractors.first, 'va');
    expect(question.distractors.second, 'vamos');
    expect(question.chunkPosition, 0);
  });

  test('three-distractor input throws WalkthroughSchemaException', () {
    final json = wellFormedJson()
      ..['distractors'] = ['va', 'vamos', 'van'];

    expect(
      () => WalkthroughQuestion.fromJson(json),
      throwsA(isA<WalkthroughSchemaException>()),
    );
  });

  test('one-distractor input throws WalkthroughSchemaException', () {
    final json = wellFormedJson()..['distractors'] = ['va'];

    expect(
      () => WalkthroughQuestion.fromJson(json),
      throwsA(isA<WalkthroughSchemaException>()),
    );
  });

  test('non-list distractors throws WalkthroughSchemaException', () {
    final json = wellFormedJson()..['distractors'] = 'va';

    expect(
      () => WalkthroughQuestion.fromJson(json),
      throwsA(isA<WalkthroughSchemaException>()),
    );
  });

  test('round-trip: fromJson(toJson(q)) equals q', () {
    final question = WalkthroughQuestion.fromJson(wellFormedJson());

    final roundTripped = WalkthroughQuestion.fromJson(question.toJson());

    expect(roundTripped, question);
    expect(roundTripped.hashCode, question.hashCode);
  });
}
