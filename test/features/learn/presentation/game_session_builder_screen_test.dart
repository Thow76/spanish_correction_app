import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/services/walkthrough_service.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository_controller.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/corrections/application/prompt_phrase_translation.dart';
import 'package:spanish_correction_app/features/corrections/application/retranslation_grade_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/history/domain/correction_submission.dart';
import 'package:spanish_correction_app/features/learn/presentation/game_session_builder_screen.dart';
import 'package:spanish_correction_app/features/learn/presentation/prompt_translation_game_screen.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';
import 'package:spanish_correction_app/features/write/application/transcription_service.dart';
import 'package:spanish_correction_app/core/models/walkthrough_activity.dart';
import 'package:spanish_correction_app/shared/widgets/saved_correction_summary_card.dart';

SavedExplanation _explanation() =>
    const SavedExplanation(whyItsWrong: 'why', inContext: 'context', alternatives: []);

SavedCorrection _buildSaved({
  required String id,
  required String promptPhrase,
  required String correctedSentence,
  String correctedPhrase = 'phrase',
  int? correctedStartIndex,
  ErrorCategory category = ErrorCategory.grammar,
}) {
  return SavedCorrection(
    id: id,
    category: category,
    shortExplanation: 'short',
    originalSentence: correctedSentence,
    explanation: _explanation(),
    savedAt: DateTime(2026, 1, 1),
    correctedPhrase: correctedPhrase,
    originalPhrase: 'y',
    correctedSentence: correctedSentence,
    promptPhrase: promptPhrase,
    language: Language.spanish,
    correctedStartIndex: correctedStartIndex,
  );
}

class _FakeCorrectionRepository implements CorrectionRepository {
  _FakeCorrectionRepository(this._saved);

  final List<SavedCorrection> _saved;

  @override
  Future<List<SavedCorrection>> getSavedCorrections({Language? language}) async =>
      _saved;

  @override
  Future<List<CorrectionSubmission>> getRecentSubmissions({Language? language}) async =>
      const [];

  @override
  Future<List<WalkthroughActivity>> getWalkthroughActivities({Language? language}) async =>
      const [];

  @override
  Future<void> addSubmission(CorrectionSubmission submission) async {}

  @override
  Future<void> removeSubmission(String id) async {}

  @override
  Future<void> addSavedCorrection(SavedCorrection correction) async {}

  @override
  Future<void> removeSavedCorrection(String id) async {}

  @override
  Future<void> addWalkthroughActivity(WalkthroughActivity activity) async {}

  @override
  Future<void> removeWalkthroughActivity(String sourcePhraseId) async {}

  @override
  Future<void> clear() async {}
}

class _UnusedTranscriptionService implements TranscriptionService {
  @override
  Future<String> transcribeAudio(String audioPath, Language language) async =>
      throw UnimplementedError();
}

class _UnusedCorrectionService implements CorrectionService {
  @override
  Future<CorrectionResponse> correctText(String text, Language language) async =>
      throw UnimplementedError();

  @override
  Future<String> generateLongExplanation(CorrectionItem correction, Language language) async =>
      throw UnimplementedError();

  @override
  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
    Language language,
  ) async => throw UnimplementedError();

  @override
  Future<PromptPhraseTranslation> generatePromptPhrase({
    required String correctedSentence,
    required String correctedPhrase,
    required Language language,
  }) async => throw UnimplementedError();

  @override
  Future<RetranslationGradeResponse> gradeRetranslation({
    required String attempt,
    required String expectedAnswer,
    required ErrorCategory targetCategory,
    required Language language,
  }) async => throw UnimplementedError();
}

class _UnusedWalkthroughService extends WalkthroughService {
  _UnusedWalkthroughService() : super(apiKey: 'test-key', model: 'test-model');
}

Future<void> pumpBuilder(
  WidgetTester tester, {
  required List<SavedCorrection> savedCorrections,
}) async {
  final controller = CorrectionRepositoryController(
    _FakeCorrectionRepository(savedCorrections),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: GameSessionBuilderScreen(
        repositoryController: controller,
        transcriptionService: _UnusedTranscriptionService(),
        correctionService: _UnusedCorrectionService(),
        walkthroughService: _UnusedWalkthroughService(),
        language: Language.spanish,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The filter bar (Clear + Seleccionadas + category squares) is a horizontal
/// `ListView`, which only builds items near the visible viewport — a chip a
/// few categories in (e.g. Spelling, once Clear/Seleccionadas/Grammar have
/// already taken up width) may not exist in the tree at all until scrolled
/// into view, exactly as a real user would swipe the row to reach it.
Future<void> tapFilterChip(WidgetTester tester, Finder chip) async {
  await tester.dragUntilVisible(
    chip,
    find.byWidgetPredicate(
      (widget) => widget is ListView && widget.scrollDirection == Axis.horizontal,
    ),
    const Offset(-60, 0),
  );
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

void main() {
  group('GameSessionBuilderScreen', () {
    testWidgets('shows the empty state when there are no saved corrections', (
      tester,
    ) async {
      await pumpBuilder(tester, savedCorrections: const []);

      expect(find.text('Nada para practicar'), findsOneWidget);
      expect(find.text('Empezar sesión'), findsNothing);
    });

    testWidgets(
      'no cards are shown until a category is picked, and nothing is preselected',
      (tester) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'A trip to the market',
              correctedSentence: 'Fui al mercado.',
              correctedPhrase: 'mercado',
            ),
          ],
        );

        expect(find.text('Elige una categoría'), findsOneWidget);
        expect(find.byType(SavedCorrectionSummaryCard), findsNothing);
        expect(find.text('0 de 5 seleccionada(s)'), findsNothing);

        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();

        expect(find.byType(SavedCorrectionSummaryCard), findsOneWidget);
        expect(find.text('0 de 5 seleccionada(s)'), findsOneWidget);
      },
    );

    testWidgets(
      'a card shows just the phrase, not the full corrected sentence',
      (tester) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'A trip to the market',
              correctedSentence: 'Fui al mercado. Compré pan.',
              correctedPhrase: 'mercado',
            ),
          ],
        );
        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();

        expect(find.text('mercado'), findsOneWidget);
        expect(find.text('Fui al mercado.'), findsNothing);
        expect(find.text('Compré pan.'), findsNothing);
      },
    );

    testWidgets('tapping a card toggles its selection and the counter', (
      tester,
    ) async {
      await pumpBuilder(
        tester,
        savedCorrections: [
          _buildSaved(
            id: 'sc-1',
            promptPhrase: 'A trip to the market',
            correctedSentence: 'Fui al mercado.',
            correctedPhrase: 'mercado',
          ),
        ],
      );
      await tester.tap(find.byTooltip('Grammar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('mercado'));
      await tester.pumpAndSettle();
      expect(find.text('1 de 5 seleccionada(s)'), findsOneWidget);

      await tester.tap(find.text('mercado'));
      await tester.pumpAndSettle();
      expect(find.text('0 de 5 seleccionada(s)'), findsOneWidget);
    });

    testWidgets(
      'a card shows the word count of the practice sentence, not the '
      'short phrase headline',
      (tester) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'A trip to the market',
              // The practice sentence (expectedAnswer) resolves to this
              // whole 6-word sentence, even though the card's headline is
              // just the 1-word phrase "mercado".
              correctedSentence: 'Fui al mercado el sábado pasado.',
              correctedPhrase: 'mercado',
              correctedStartIndex: 7,
            ),
          ],
        );
        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();

        expect(find.text('mercado'), findsOneWidget);
        expect(find.text('6 palabra(s)'), findsOneWidget);
      },
    );

    testWidgets(
      'multiple categories can be picked at once, and hiding a category '
      'does not clear its selection',
      (tester) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'Grammar one',
              correctedSentence: 'Fui al mercado.',
              correctedPhrase: 'mercado',
              category: ErrorCategory.grammar,
            ),
            _buildSaved(
              id: 'sc-2',
              promptPhrase: 'Spelling one',
              correctedSentence: 'Comí una manzana.',
              correctedPhrase: 'manzana',
              category: ErrorCategory.spelling,
            ),
          ],
        );

        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();
        await tapFilterChip(tester, find.byTooltip('Spelling'));

        expect(find.text('mercado'), findsOneWidget);
        expect(find.text('manzana'), findsOneWidget);

        await tester.tap(find.text('mercado'));
        await tester.tap(find.text('manzana'));
        await tester.pumpAndSettle();
        expect(find.text('2 de 5 seleccionada(s)'), findsOneWidget);

        // Turn off the Spelling category chip.
        await tester.tap(find.byTooltip('Spelling'));
        await tester.pumpAndSettle();

        expect(find.text('mercado'), findsOneWidget);
        expect(find.text('manzana'), findsNothing);
        // Both remain selected under the hood — only visibility changed.
        expect(find.text('2 de 5 seleccionada(s)'), findsOneWidget);
      },
    );

    testWidgets(
      'cards are grouped under a collapsible header per category, with a count',
      (tester) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'Grammar one',
              correctedSentence: 'Fui al mercado.',
              correctedPhrase: 'mercado',
              category: ErrorCategory.grammar,
            ),
            _buildSaved(
              id: 'sc-2',
              promptPhrase: 'Grammar two',
              correctedSentence: 'Comí pan.',
              correctedPhrase: 'pan',
              category: ErrorCategory.grammar,
            ),
            _buildSaved(
              id: 'sc-3',
              promptPhrase: 'Spelling one',
              correctedSentence: 'Comí una manzana.',
              correctedPhrase: 'manzana',
              category: ErrorCategory.spelling,
            ),
          ],
        );

        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();
        await tapFilterChip(tester, find.byTooltip('Spelling'));

        // One section header per category, each labeled with its own count.
        expect(find.text('Grammar'), findsOneWidget);
        expect(find.text('Spelling'), findsOneWidget);
        expect(find.text('2'), findsOneWidget); // Grammar's count
        expect(find.text('1'), findsOneWidget); // Spelling's count
        expect(find.text('mercado'), findsOneWidget);
        expect(find.text('pan'), findsOneWidget);
        expect(find.text('manzana'), findsOneWidget);
      },
    );

    testWidgets(
      'collapsing one category section hides only its own cards',
      (tester) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'Grammar one',
              correctedSentence: 'Fui al mercado.',
              correctedPhrase: 'mercado',
              category: ErrorCategory.grammar,
            ),
            _buildSaved(
              id: 'sc-2',
              promptPhrase: 'Spelling one',
              correctedSentence: 'Comí una manzana.',
              correctedPhrase: 'manzana',
              category: ErrorCategory.spelling,
            ),
          ],
        );

        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();
        await tapFilterChip(tester, find.byTooltip('Spelling'));

        expect(find.text('mercado').hitTestable(), findsOneWidget);
        expect(find.text('manzana').hitTestable(), findsOneWidget);

        // Collapse the Grammar section by tapping its header. AnimatedCrossFade
        // keeps the collapsed child mounted (so find.text still matches it) but
        // shrinks it to zero size, so hitTestable() is the right check here.
        await tester.tap(find.text('Grammar'));
        await tester.pumpAndSettle();

        expect(find.text('mercado').hitTestable(), findsNothing);
        // Spelling's section is untouched by collapsing Grammar's.
        expect(find.text('manzana').hitTestable(), findsOneWidget);

        // Expanding it again brings the card back.
        await tester.tap(find.text('Grammar'));
        await tester.pumpAndSettle();

        expect(find.text('mercado').hitTestable(), findsOneWidget);
        expect(find.text('manzana').hitTestable(), findsOneWidget);
      },
    );

    testWidgets('Clear deselects every category and hides all cards', (
      tester,
    ) async {
      await pumpBuilder(
        tester,
        savedCorrections: [
          _buildSaved(
            id: 'sc-1',
            promptPhrase: 'A trip to the market',
            correctedSentence: 'Fui al mercado.',
            correctedPhrase: 'mercado',
          ),
        ],
      );
      await tester.tap(find.byTooltip('Grammar'));
      await tester.pumpAndSettle();
      expect(find.byType(SavedCorrectionSummaryCard), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.byType(SavedCorrectionSummaryCard), findsNothing);
      expect(find.text('Elige una categoría'), findsOneWidget);
    });

    testWidgets('Seleccionar todo selects every visible card at once', (
      tester,
    ) async {
      await pumpBuilder(
        tester,
        savedCorrections: [
          _buildSaved(
            id: 'sc-1',
            promptPhrase: 'One',
            correctedSentence: 'Fui al mercado.',
            correctedPhrase: 'mercado',
          ),
          _buildSaved(
            id: 'sc-2',
            promptPhrase: 'Two',
            correctedSentence: 'Comí una manzana.',
            correctedPhrase: 'manzana',
          ),
        ],
      );
      await tester.tap(find.byTooltip('Grammar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seleccionar todo'));
      await tester.pumpAndSettle();

      expect(find.text('2 de 5 seleccionada(s)'), findsOneWidget);
      expect(find.text('Deseleccionar todo'), findsOneWidget);

      await tester.tap(find.text('Deseleccionar todo'));
      await tester.pumpAndSettle();

      expect(find.text('0 de 5 seleccionada(s)'), findsOneWidget);
    });

    group('selection cap (max 5)', () {
      List<SavedCorrection> sevenGrammarCorrections() => [
        for (var i = 1; i <= 7; i++)
          _buildSaved(
            id: 'sc-$i',
            promptPhrase: 'Correction $i',
            correctedSentence: 'Frase número $i.',
            correctedPhrase: 'p$i',
          ),
      ];

      // With 7 cards plus the header/filter bar/counter row, the default
      // 800x600 test surface requires scrolling — a tall surface instead
      // keeps every card on-screen at once, since these tests care about the
      // cap logic, not scrolling behavior.
      void useTallSurface(WidgetTester tester) {
        tester.view.physicalSize = const Size(400, 3000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
      }

      testWidgets(
        'selecting a 6th phrase is blocked and shows a message',
        (tester) async {
          useTallSurface(tester);
          await pumpBuilder(
            tester,
            savedCorrections: sevenGrammarCorrections(),
          );
          await tester.tap(find.byTooltip('Grammar'));
          await tester.pumpAndSettle();

          for (var i = 1; i <= 5; i++) {
            await tester.tap(find.text('p$i'));
            await tester.pumpAndSettle();
          }
          expect(find.text('5 de 5 seleccionada(s)'), findsOneWidget);

          await tester.tap(find.text('p6'));
          await tester.pumpAndSettle();

          // Still capped at 5 — the 6th tap was rejected, not added.
          expect(find.text('5 de 5 seleccionada(s)'), findsOneWidget);
          final card6 = tester.widget<SavedCorrectionSummaryCard>(
            find.ancestor(
              of: find.text('p6'),
              matching: find.byType(SavedCorrectionSummaryCard),
            ),
          );
          expect(card6.selected, isFalse);
          expect(
            find.textContaining('Solo puedes elegir 5 frases'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'Seleccionar todo fills only up to the cap when more than 5 are visible',
        (tester) async {
          useTallSurface(tester);
          await pumpBuilder(
            tester,
            savedCorrections: sevenGrammarCorrections(),
          );
          await tester.tap(find.byTooltip('Grammar'));
          await tester.pumpAndSettle();

          await tester.tap(find.text('Seleccionar todo'));
          await tester.pumpAndSettle();

          expect(find.text('5 de 5 seleccionada(s)'), findsOneWidget);
          final card7 = tester.widget<SavedCorrectionSummaryCard>(
            find.ancestor(
              of: find.text('p7'),
              matching: find.byType(SavedCorrectionSummaryCard),
            ),
          );
          expect(card7.selected, isFalse);
        },
      );

      testWidgets(
        'deselecting still works normally while at the cap',
        (tester) async {
          useTallSurface(tester);
          await pumpBuilder(
            tester,
            savedCorrections: sevenGrammarCorrections(),
          );
          await tester.tap(find.byTooltip('Grammar'));
          await tester.pumpAndSettle();
          for (var i = 1; i <= 5; i++) {
            await tester.tap(find.text('p$i'));
            await tester.pumpAndSettle();
          }

          await tester.tap(find.text('p1'));
          await tester.pumpAndSettle();

          expect(find.text('4 de 5 seleccionada(s)'), findsOneWidget);

          // With room again, a new one can be selected.
          await tester.tap(find.text('p6'));
          await tester.pumpAndSettle();

          expect(find.text('5 de 5 seleccionada(s)'), findsOneWidget);
        },
      );
    });

    testWidgets('Start session is disabled when nothing is selected', (
      tester,
    ) async {
      await pumpBuilder(
        tester,
        savedCorrections: [
          _buildSaved(
            id: 'sc-1',
            promptPhrase: 'A trip to the market',
            correctedSentence: 'Fui al mercado.',
            correctedPhrase: 'mercado',
          ),
        ],
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'Start session resolves the sentence containing the error via '
      'correctedStartIndex, not the whole multi-sentence submission',
      (tester) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'A trip to the market',
              correctedSentence:
                  'Fui al mercado. Compré pan y luego volví a casa.',
              correctedPhrase: 'mercado',
              correctedStartIndex: 7,
            ),
          ],
        );
        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('mercado'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Empezar sesión'));
        await tester.pumpAndSettle();

        final gameScreen = tester.widget<PromptTranslationGameScreen>(
          find.byType(PromptTranslationGameScreen),
        );
        expect(gameScreen.initialQuestions, hasLength(1));
        expect(
          gameScreen.initialQuestions.single.expectedAnswer,
          'Fui al mercado.',
        );
      },
    );

    testWidgets(
      'falls back to a substring search for correctedPhrase when '
      'correctedStartIndex is absent (older saves)',
      (tester) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'A trip to the market',
              correctedSentence:
                  'Fui al mercado. Compré pan y luego volví a casa.',
              correctedPhrase: 'mercado',
            ),
          ],
        );
        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('mercado'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Empezar sesión'));
        await tester.pumpAndSettle();

        final gameScreen = tester.widget<PromptTranslationGameScreen>(
          find.byType(PromptTranslationGameScreen),
        );
        expect(
          gameScreen.initialQuestions.single.expectedAnswer,
          'Fui al mercado.',
        );
      },
    );

    testWidgets(
      'falls back to the first sentence when neither an index nor a '
      'locatable phrase is available',
      (tester) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'A trip to the market',
              correctedSentence: 'Fui al mercado. Compré pan.',
              correctedPhrase: '',
            ),
          ],
        );
        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();
        // The card's phrase text is empty, so select it via its card widget
        // directly rather than by text.
        await tester.tap(find.byType(SavedCorrectionSummaryCard));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Empezar sesión'));
        await tester.pumpAndSettle();

        final gameScreen = tester.widget<PromptTranslationGameScreen>(
          find.byType(PromptTranslationGameScreen),
        );
        expect(
          gameScreen.initialQuestions.single.expectedAnswer,
          'Fui al mercado.',
        );
      },
    );

    group('phrase-only toggle', () {
      testWidgets(
        'defaults to on: Start session uses the resolved single sentence',
        (tester) async {
          await pumpBuilder(
            tester,
            savedCorrections: [
              _buildSaved(
                id: 'sc-1',
                promptPhrase: 'A trip to the market',
                correctedSentence:
                    'Fui al mercado. Compré pan y luego volví a casa.',
                correctedPhrase: 'mercado',
                correctedStartIndex: 7,
              ),
            ],
          );

          final toggle = tester.widget<SwitchListTile>(
            find.byType(SwitchListTile),
          );
          expect(toggle.value, isTrue);

          await tester.tap(find.byTooltip('Grammar'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('mercado'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Empezar sesión'));
          await tester.pumpAndSettle();

          final gameScreen = tester.widget<PromptTranslationGameScreen>(
            find.byType(PromptTranslationGameScreen),
          );
          expect(
            gameScreen.initialQuestions.single.expectedAnswer,
            'Fui al mercado.',
          );
        },
      );

      testWidgets(
        'turning it off uses the whole saved correctedSentence instead of '
        'just the resolved sentence',
        (tester) async {
          await pumpBuilder(
            tester,
            savedCorrections: [
              _buildSaved(
                id: 'sc-1',
                promptPhrase: 'A trip to the market',
                correctedSentence:
                    'Fui al mercado. Compré pan y luego volví a casa.',
                correctedPhrase: 'mercado',
                correctedStartIndex: 7,
              ),
            ],
          );

          await tester.tap(find.byType(SwitchListTile));
          await tester.pumpAndSettle();

          await tester.tap(find.byTooltip('Grammar'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('mercado'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Empezar sesión'));
          await tester.pumpAndSettle();

          final gameScreen = tester.widget<PromptTranslationGameScreen>(
            find.byType(PromptTranslationGameScreen),
          );
          expect(
            gameScreen.initialQuestions.single.expectedAnswer,
            'Fui al mercado. Compré pan y luego volví a casa.',
          );
        },
      );

      testWidgets(
        'the word-count badge reflects the current toggle state',
        (tester) async {
          await pumpBuilder(
            tester,
            savedCorrections: [
              _buildSaved(
                id: 'sc-1',
                promptPhrase: 'A trip to the market',
                correctedSentence:
                    'Fui al mercado. Compré pan y luego volví a casa.',
                correctedPhrase: 'mercado',
                correctedStartIndex: 7,
              ),
            ],
          );
          await tester.tap(find.byTooltip('Grammar'));
          await tester.pumpAndSettle();

          // Phrase only (on): "Fui al mercado." — 3 words.
          expect(find.text('3 palabra(s)'), findsOneWidget);

          await tester.tap(find.byType(SwitchListTile));
          await tester.pumpAndSettle();

          // Full text: "Fui al mercado. Compré pan y luego volví a casa." — 10 words.
          expect(find.text('10 palabra(s)'), findsOneWidget);
        },
      );

      testWidgets(
        'flipping the switch after selecting still applies at session start',
        (tester) async {
          await pumpBuilder(
            tester,
            savedCorrections: [
              _buildSaved(
                id: 'sc-1',
                promptPhrase: 'A trip to the market',
                correctedSentence:
                    'Fui al mercado. Compré pan y luego volví a casa.',
                correctedPhrase: 'mercado',
                correctedStartIndex: 7,
              ),
            ],
          );

          await tester.tap(find.byTooltip('Grammar'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('mercado'));
          await tester.pumpAndSettle();

          // Select first (phrase-only on), then flip the switch off — the
          // final toggle state at session-start time should win.
          await tester.tap(find.byType(SwitchListTile));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Empezar sesión'));
          await tester.pumpAndSettle();

          final gameScreen = tester.widget<PromptTranslationGameScreen>(
            find.byType(PromptTranslationGameScreen),
          );
          expect(
            gameScreen.initialQuestions.single.expectedAnswer,
            'Fui al mercado. Compré pan y luego volví a casa.',
          );
        },
      );
    });

    group('review mode ("Seleccionadas")', () {
      testWidgets(
        'shows every selected correction across categories in one list, '
        'and lets you deselect from it',
        (tester) async {
          await pumpBuilder(
            tester,
            savedCorrections: [
              _buildSaved(
                id: 'sc-1',
                promptPhrase: 'One',
                correctedSentence: 'Fui al mercado.',
                correctedPhrase: 'mercado',
                category: ErrorCategory.grammar,
              ),
              _buildSaved(
                id: 'sc-2',
                promptPhrase: 'Two',
                correctedSentence: 'Comí una manzana.',
                correctedPhrase: 'manzana',
                category: ErrorCategory.spelling,
              ),
            ],
          );

          // Select one correction from each of two different categories.
          await tester.tap(find.byTooltip('Grammar'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('mercado'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Grammar')); // back out of Grammar
          await tester.pumpAndSettle();
          await tapFilterChip(tester, find.byTooltip('Spelling'));
          await tester.tap(find.text('manzana'));
          await tester.pumpAndSettle();

          // Neither category chip alone shows both — Spelling is the only
          // one currently on.
          expect(find.text('mercado'), findsNothing);
          expect(find.text('manzana'), findsOneWidget);

          await tester.tap(find.byTooltip('Seleccionadas'));
          await tester.pumpAndSettle();

          // Review mode shows both, regardless of category filter state.
          expect(find.text('mercado'), findsOneWidget);
          expect(find.text('manzana'), findsOneWidget);
          expect(find.text('2 de 5 seleccionada(s)'), findsOneWidget);

          // Deselecting from the review list works like any other card.
          await tester.tap(find.text('mercado'));
          await tester.pumpAndSettle();

          expect(find.text('mercado'), findsNothing);
          expect(find.text('manzana'), findsOneWidget);
          expect(find.text('1 de 5 seleccionada(s)'), findsOneWidget);
        },
      );

      testWidgets('shows a prompt when nothing has been selected yet', (
        tester,
      ) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'A trip to the market',
              correctedSentence: 'Fui al mercado.',
              correctedPhrase: 'mercado',
            ),
          ],
        );

        // "Seleccionadas" is reachable even before any category is picked.
        await tester.tap(find.byTooltip('Seleccionadas'));
        await tester.pumpAndSettle();

        expect(find.text('Nada seleccionado todavía'), findsOneWidget);
      });

      testWidgets('tapping a category chip exits review mode', (
        tester,
      ) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'Selected, grammar',
              correctedSentence: 'Fui al mercado.',
              correctedPhrase: 'mercado',
              category: ErrorCategory.grammar,
            ),
            _buildSaved(
              id: 'sc-2',
              promptPhrase: 'Unselected, grammar',
              correctedSentence: 'Comí pan.',
              correctedPhrase: 'pan',
              category: ErrorCategory.grammar,
            ),
          ],
        );

        // Select "mercado", then back out of the Grammar filter entirely
        // (_selectedCategories is empty going into review mode) so the only
        // thing that could be showing "pan" afterwards is exiting review mode
        // back into Grammar's normal (not review-only) view.
        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('mercado'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Seleccionadas'));
        await tester.pumpAndSettle();
        expect(find.text('mercado'), findsOneWidget);
        expect(find.text('pan'), findsNothing);

        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();

        // Back in Grammar's normal view: both the selected and unselected
        // correction show, proving review mode (selected-only) is off.
        expect(find.text('mercado'), findsOneWidget);
        expect(find.text('pan'), findsOneWidget);
      });

      testWidgets('tapping Clear exits review mode too', (tester) async {
        await pumpBuilder(
          tester,
          savedCorrections: [
            _buildSaved(
              id: 'sc-1',
              promptPhrase: 'A trip to the market',
              correctedSentence: 'Fui al mercado.',
              correctedPhrase: 'mercado',
            ),
          ],
        );

        await tester.tap(find.byTooltip('Grammar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('mercado'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Seleccionadas'));
        await tester.pumpAndSettle();
        expect(find.text('mercado'), findsOneWidget);

        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        expect(find.text('Elige una categoría'), findsOneWidget);
        // Selection itself is untouched by Clear — only the filter/view resets.
        expect(find.text('1 de 5 seleccionada(s)'), findsNothing);
      });
    });
  });
}
