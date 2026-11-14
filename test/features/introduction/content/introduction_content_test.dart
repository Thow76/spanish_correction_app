import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/introduction/content/interest.dart';
import 'package:spanish_correction_app/features/introduction/content/introduction_content.dart';
import 'package:spanish_correction_app/features/introduction/content/introduction_step_kind.dart';
import 'package:spanish_correction_app/features/introduction/content/recommendation_item.dart';

void main() {
  final interestIds = IntroductionContent.interests.map((i) => i.id).toSet();

  group('interests', () {
    test('about ten chips, each with a unique id and a label in all three '
        'languages', () {
      expect(IntroductionContent.interests.length, inInclusiveRange(8, 12));
      expect(interestIds.length, IntroductionContent.interests.length);
      for (final interest in IntroductionContent.interests) {
        expect(interest.id.trim(), isNotEmpty);
        expect(interest.english.trim(), isNotEmpty, reason: interest.id);
        expect(interest.spanish.trim(), isNotEmpty, reason: interest.id);
        expect(interest.portuguese.trim(), isNotEmpty, reason: interest.id);
      }
    });

    test('the chips are interests only: no everyday-life chips (A3)', () {
      expect(interestIds, isNot(contains('work')));
      expect(interestIds, isNot(contains('family')));
    });

    test('the learner picks one to five', () {
      expect(IntroductionContent.minimumChips, 1);
      expect(IntroductionContent.maximumChips, 5);
      expect(
        IntroductionContent.interests.length,
        greaterThanOrEqualTo(IntroductionContent.maximumChips),
      );
    });

    test('labelFor gives the label in the language being learnt', () {
      const interest = Interest(
        id: 'travel',
        english: 'Travel',
        spanish: 'Los viajes',
        portuguese: 'As viagens',
      );

      expect(interest.labelFor(Language.spanish), 'Los viajes');
      expect(interest.labelFor(Language.portuguese), 'As viagens');
    });

    test(
      'interestById finds a known id and returns null for an unknown one',
      () {
        expect(IntroductionContent.interestById('travel')?.english, 'Travel');
        expect(IntroductionContent.interestById('no-such-interest'), isNull);
      },
    );
  });

  group('step labels', () {
    test('there are three, in the order of Try it, each with a label', () {
      expect(IntroductionStepKind.values, [
        IntroductionStepKind.friendlyOpener,
        IntroductionStepKind.somethingYoureInto,
        IntroductionStepKind.recommendation,
      ]);
      for (final kind in IntroductionStepKind.values) {
        expect(kind.label.trim(), isNotEmpty, reason: kind.name);
      }
      expect(IntroductionStepKind.values.map((k) => k.label).toSet().length, 3);
    });
  });

  group('hints and end screen', () {
    test('the typing and speaking hints are short English lines', () {
      expect(IntroductionContent.typingHint.trim(), isNotEmpty);
      expect(IntroductionContent.speakingHint.trim(), isNotEmpty);
      expect(IntroductionContent.speakingHint, contains('microphone'));
    });

    test('has a closing line for Spanish and none for Portuguese', () {
      expect(IntroductionContent.endScreenLine.trim(), isNotEmpty);
      expect(
        IntroductionContent.endScreenLineFor(Language.spanish),
        IntroductionContent.endScreenLine,
      );
      expect(IntroductionContent.endScreenLineFor(Language.portuguese), isNull);
    });
  });

  group('friendly openers', () {
    test('a small shared set for Spanish, each with a unique id and text', () {
      final openers = IntroductionContent.friendlyOpenersFor(Language.spanish);

      expect(openers.length, inInclusiveRange(2, 6));
      expect(openers.map((o) => o.id).toSet().length, openers.length);
      for (final opener in openers) {
        expect(opener.text.trim(), isNotEmpty, reason: opener.id);
        expect(opener.text, endsWith('?'), reason: opener.id);
      }
    });

    test('the example from decision A3 is one of them', () {
      expect(
        IntroductionContent.friendlyOpenersFor(
          Language.spanish,
        ).map((o) => o.text),
        contains('¿Qué tal estás hoy?'),
      );
    });

    test('there are none for Portuguese in slice 1', () {
      expect(
        IntroductionContent.friendlyOpenersFor(Language.portuguese),
        isEmpty,
      );
    });

    test('friendlyOpenerById finds a known id', () {
      final first = IntroductionContent.friendlyOpeners.first;
      expect(IntroductionContent.friendlyOpenerById(first.id), first);
      expect(IntroductionContent.friendlyOpenerById('no-such-opener'), isNull);
    });
  });

  group('interest questions', () {
    test('every question has a unique id, text and a known interest', () {
      final ids = IntroductionContent.interestQuestions.map((q) => q.id);

      expect(ids.toSet().length, ids.length);
      for (final question in IntroductionContent.interestQuestions) {
        expect(question.text.trim(), isNotEmpty, reason: question.id);
        expect(
          interestIds,
          contains(question.interestId),
          reason: '${question.id} points at an interest that does not exist',
        );
      }
    });

    test('every interest has at least one Spanish question', () {
      for (final interest in IntroductionContent.interests) {
        expect(
          IntroductionContent.interestQuestionsForInterest(
            interest.id,
            Language.spanish,
          ),
          isNotEmpty,
          reason: interest.id,
        );
      }
    });

    test('there are none for Portuguese in slice 1', () {
      expect(
        IntroductionContent.interestQuestionsFor(Language.portuguese),
        isEmpty,
      );
    });

    test('interestQuestionById finds a known id', () {
      final first = IntroductionContent.interestQuestions.first;
      expect(IntroductionContent.interestQuestionById(first.id), first);
      expect(IntroductionContent.interestQuestionById('no-such-id'), isNull);
    });
  });

  group('recommendations', () {
    test('every item has a unique id, a title, a source, an https link and a '
        'known interest', () {
      final ids = IntroductionContent.recommendations.map((r) => r.id);

      expect(ids.toSet().length, ids.length);
      for (final item in IntroductionContent.recommendations) {
        expect(item.title.trim(), isNotEmpty, reason: item.id);
        expect(item.source.trim(), isNotEmpty, reason: item.id);
        expect(interestIds, contains(item.interestId), reason: item.id);
        final url = Uri.tryParse(item.url);
        expect(url?.scheme, 'https', reason: '${item.id}: ${item.url}');
        expect(url?.host, isNotEmpty, reason: '${item.id}: ${item.url}');
        final thumbnail = item.thumbnailUrl;
        if (thumbnail != null) {
          expect(
            Uri.tryParse(thumbnail)?.scheme,
            'https',
            reason: '${item.id}: $thumbnail',
          );
        }
      }
    });

    test('every interest has one Spanish recommendation', () {
      for (final interest in IntroductionContent.interests) {
        expect(
          IntroductionContent.recommendationsForInterest(
            interest.id,
            Language.spanish,
          ),
          hasLength(1),
          reason: interest.id,
        );
      }
    });

    test('the placeholders are articles and one other resource, no videos', () {
      final types = IntroductionContent.recommendations.map((r) => r.type);

      expect(types, contains(RecommendationType.article));
      expect(types, contains(RecommendationType.other));
    });

    test('there are none for Portuguese in slice 1', () {
      expect(
        IntroductionContent.recommendationsFor(Language.portuguese),
        isEmpty,
      );
    });

    test('recommendationById finds a known id', () {
      final first = IntroductionContent.recommendations.first;
      expect(IntroductionContent.recommendationById(first.id), first);
      expect(IntroductionContent.recommendationById('no-such-id'), isNull);
    });
  });

  group('Show me demos', () {
    test(
      'every interest has one Spanish demo with a question and an answer',
      () {
        final ids = IntroductionContent.demos.map((d) => d.id);
        expect(ids.toSet().length, ids.length);

        for (final interest in IntroductionContent.interests) {
          final demo = IntroductionContent.demoForInterest(
            interest.id,
            Language.spanish,
          );

          expect(demo, isNotNull, reason: interest.id);
          expect(demo!.question.trim(), isNotEmpty, reason: demo.id);
          expect(demo.sampleAnswer.trim(), isNotEmpty, reason: demo.id);
        }
        for (final demo in IntroductionContent.demos) {
          expect(interestIds, contains(demo.interestId), reason: demo.id);
        }
      },
    );

    test('each demo has a couple of points, each found exactly once in the '
        'answer, with a suggestion that differs and a reason', () {
      for (final demo in IntroductionContent.demos) {
        expect(demo.points.length, inInclusiveRange(2, 3), reason: demo.id);
        for (final point in demo.points) {
          final first = demo.sampleAnswer.indexOf(point.originalPhrase);
          final last = demo.sampleAnswer.lastIndexOf(point.originalPhrase);
          expect(
            first,
            greaterThanOrEqualTo(0),
            reason: '${demo.id}: "${point.originalPhrase}" not in answer',
          );
          expect(
            first,
            last,
            reason: '${demo.id}: "${point.originalPhrase}" appears twice',
          );
          expect(point.correctedPhrase.trim(), isNotEmpty, reason: demo.id);
          expect(
            point.correctedPhrase,
            isNot(point.originalPhrase),
            reason: demo.id,
          );
          expect(point.shortExplanation.trim(), isNotEmpty, reason: demo.id);
        }
      }
    });

    test('the reasons keep to the app\'s wording rule (C1)', () {
      final banned = RegExp(
        r'\b(wrong|error|incorrect|mistake)\b',
        caseSensitive: false,
      );
      for (final demo in IntroductionContent.demos) {
        for (final point in demo.points) {
          expect(
            banned.hasMatch(point.shortExplanation),
            isFalse,
            reason: '${demo.id}: "${point.shortExplanation}"',
          );
        }
      }
    });

    test(
      'toCorrectionResponse keeps every point, anchored, and applies them to '
      'the corrected text',
      () {
        for (final demo in IntroductionContent.demos) {
          final response = demo.toCorrectionResponse();

          expect(response.originalText, demo.sampleAnswer, reason: demo.id);
          expect(
            response.corrections.length,
            demo.points.length,
            reason: '${demo.id}: a point was dropped by the anchoring',
          );
          for (final item in response.corrections) {
            expect(item.startIndex, isNotNull, reason: demo.id);
            expect(item.endIndex, isNotNull, reason: demo.id);
            expect(item.correctedStartIndex, isNotNull, reason: demo.id);
            expect(item.correctedEndIndex, isNotNull, reason: demo.id);
            expect(
              demo.sampleAnswer.substring(item.startIndex!, item.endIndex!),
              item.originalPhrase,
              reason: demo.id,
            );
          }
          for (final point in demo.points) {
            expect(
              response.correctedText,
              contains(point.correctedPhrase),
              reason: '${demo.id}: "${point.correctedPhrase}"',
            );
            expect(
              response.correctedText,
              isNot(contains(point.originalPhrase)),
              reason: '${demo.id}: "${point.originalPhrase}" still there',
            );
          }
        }
      },
    );

    test('the travel demo reads as expected on the results screen', () {
      final demo = IntroductionContent.demoForInterest(
        'travel',
        Language.spanish,
      )!;
      final response = demo.toCorrectionResponse();

      expect(response.corrections.map((c) => c.category), [
        ErrorCategory.wordChoice,
        ErrorCategory.naturalLanguage,
      ]);
      expect(response.correctedText, contains('Estoy muy emocionado'));
      expect(response.correctedText, contains('tomar una decisión'));
    });

    test('there are none for Portuguese in slice 1', () {
      expect(IntroductionContent.demosFor(Language.portuguese), isEmpty);
      expect(
        IntroductionContent.demoForInterest('travel', Language.portuguese),
        isNull,
      );
    });
  });

  group('hasContentFor', () {
    test('Spanish has content and every interest is usable', () {
      expect(IntroductionContent.hasContentFor(Language.spanish), isTrue);
      for (final interest in IntroductionContent.interests) {
        expect(
          IntroductionContent.hasContentForInterest(
            interest.id,
            Language.spanish,
          ),
          isTrue,
          reason: interest.id,
        );
      }
    });

    test('Portuguese has none in slice 1', () {
      expect(IntroductionContent.hasContentFor(Language.portuguese), isFalse);
      expect(
        IntroductionContent.hasContentForInterest(
          'travel',
          Language.portuguese,
        ),
        isFalse,
      );
    });
  });

  group('pickForChips', () {
    test('one chip gives the question, recommendation and demo from it', () {
      final picks = IntroductionContent.pickForChips(
        chosenInterestIds: ['music'],
        language: Language.spanish,
      );

      expect(picks, isNotNull);
      expect(picks!.questionInterestId, 'music');
      expect(picks.recommendationInterestId, 'music');
      expect(picks.demoInterestId, 'music');
      expect(picks.interestQuestion.interestId, 'music');
      expect(picks.recommendation.interestId, 'music');
      expect(picks.demo.interestId, 'music');
    });

    test('more than one chip: the question from the first, the recommendation '
        'from the second, the demo on the first', () {
      final picks = IntroductionContent.pickForChips(
        chosenInterestIds: ['sport', 'travel', 'art'],
        language: Language.spanish,
      )!;

      expect(picks.questionInterestId, 'sport');
      expect(picks.recommendationInterestId, 'travel');
      expect(picks.demoInterestId, 'sport');
      expect(picks.recommendation.id, 'travel-recommendation-1');
    });

    test('ignores unknown and repeated ids', () {
      final picks = IntroductionContent.pickForChips(
        chosenInterestIds: ['no-such-interest', 'books', 'books', 'food'],
        language: Language.spanish,
      )!;

      expect(picks.questionInterestId, 'books');
      expect(picks.recommendationInterestId, 'food');
    });

    test('with nothing usable chosen, falls back to the list order', () {
      final picks = IntroductionContent.pickForChips(
        chosenInterestIds: const ['no-such-interest'],
        language: Language.spanish,
      )!;

      expect(picks.questionInterestId, IntroductionContent.interests[0].id);
      expect(
        picks.recommendationInterestId,
        IntroductionContent.interests[1].id,
      );
    });

    test('returns null for a language with no content', () {
      expect(
        IntroductionContent.pickForChips(
          chosenInterestIds: ['travel'],
          language: Language.portuguese,
        ),
        isNull,
      );
    });

    test('two picks from the same chips are equal', () {
      IntroductionPicks pick() => IntroductionContent.pickForChips(
        chosenInterestIds: ['travel', 'food'],
        language: Language.spanish,
      )!;

      expect(pick(), pick());
      expect(pick().hashCode, pick().hashCode);
    });
  });
}
