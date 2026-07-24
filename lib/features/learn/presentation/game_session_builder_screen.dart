import 'package:flutter/material.dart';

import '../../../core/enums/language.dart';
import '../../../core/services/walkthrough_service.dart';
import '../../../core/text/sentence_splitter.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/category_square_chip.dart';
import '../../../shared/widgets/collapsible_category_section.dart';
import '../../../shared/widgets/empty_state_panel.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../../shared/widgets/saved_correction_summary_card.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/application/correction_service.dart';
import '../../corrections/domain/error_category.dart';
import '../../saved/domain/saved_correction.dart';
import '../../write/application/transcription_service.dart';
import '../domain/game_question.dart';
import 'prompt_translation_game_screen.dart';

/// One selectable saved correction, paired with the single sentence (from
/// `correctedSentence`) that actually contains its error — resolved once at
/// load time by [_resolveExpectedAnswer], not exploded into every sentence
/// the correction's full corrected text happens to contain.
class _CorrectionOption {
  _CorrectionOption({required this.correction, required this.expectedAnswer});

  final SavedCorrection correction;
  final String expectedAnswer;
}

/// Session-builder screen: lets the learner pick one or more categories, then
/// choose individual saved corrections to practice, instead of the game
/// auto-picking 10 random ones.
///
/// Nothing is preselected anywhere in this flow — with a large saved list,
/// starting from "everything checked" means deselecting hundreds of rows to
/// build a small session, so selection is opt-in throughout: no category's
/// corrections are shown until that category is picked, and no correction is
/// selected until it's tapped.
class GameSessionBuilderScreen extends StatefulWidget {
  const GameSessionBuilderScreen({
    required this.repositoryController,
    required this.transcriptionService,
    required this.correctionService,
    required this.walkthroughService,
    required this.language,
    super.key,
  });

  final CorrectionRepositoryController repositoryController;
  final TranscriptionService transcriptionService;
  final CorrectionService correctionService;
  final WalkthroughService walkthroughService;
  final Language language;

  @override
  State<GameSessionBuilderScreen> createState() =>
      _GameSessionBuilderScreenState();
}

class _GameSessionBuilderScreenState extends State<GameSessionBuilderScreen> {
  static const _maxSelections = 5;

  List<_CorrectionOption> _allOptions = const [];
  List<ErrorCategory> _availableCategories = const [];
  bool _isLoading = true;

  // Both start empty: no category's corrections are visible until a category
  // is picked, and picking a category never auto-checks anything inside it —
  // every selection is an explicit tap.
  final Set<ErrorCategory> _selectedCategories = {};
  final Set<String> _selectedIds = {};

  // Review mode: switching between category filters made it easy to lose
  // track of what had actually been picked across categories, so this shows
  // every selected correction in one list, independent of _selectedCategories,
  // to review (and trim) before starting. Turning a category chip or "Clear"
  // back on always exits review mode.
  bool _showingSelectedOnly = false;

  // Visible options are grouped under a collapsible header per category (as
  // in SavedScreen) rather than one flat list — picking several categories at
  // once otherwise mixes them together with nothing to tell them apart.
  final Set<ErrorCategory> _collapsedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  // Mirrors every other screen that reads repositoryController.savedCorrections
  // (SavedScreen, HistoryScreen, PromptTranslationGameScreen): the controller's
  // cache isn't guaranteed fresh for widget.language until setActiveLanguage
  // resolves, so this always awaits it rather than trusting a prior screen to
  // have already populated it.
  Future<void> _loadOptions() async {
    await widget.repositoryController.setActiveLanguage(widget.language);
    if (!mounted) {
      return;
    }

    final eligible = widget.repositoryController.savedCorrections
        .where((correction) => correction.promptPhrase.trim().isNotEmpty)
        .toList();

    final allOptions = [
      for (final correction in eligible)
        _CorrectionOption(
          correction: correction,
          expectedAnswer: _resolveExpectedAnswer(correction),
        ),
    ];
    final availableCategories = ErrorCategory.values
        .where((category) => eligible.any((c) => c.category == category))
        .toList();

    setState(() {
      _allOptions = allOptions;
      _availableCategories = availableCategories;
      _isLoading = false;
    });
  }

  String _str(String es, String pt) => switch (widget.language) {
    Language.spanish => es,
    Language.portuguese => pt,
  };

  /// Toggles [id]'s selection, enforcing the [_maxSelections] cap. Deselecting
  /// always works; selecting a new correction while already at the cap is a
  /// no-op with a SnackBar explaining why, rather than silently doing nothing.
  void _toggleSelection(BuildContext context, String id) {
    if (_selectedIds.contains(id)) {
      setState(() => _selectedIds.remove(id));
      return;
    }
    if (_selectedIds.length >= _maxSelections) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _str(
              'Solo puedes elegir $_maxSelections frases para esta sesión.',
              'Você só pode escolher $_maxSelections frases para esta sessão.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _selectedIds.add(id));
  }

  @override
  Widget build(BuildContext context) {
    final visibleOptions = _showingSelectedOnly
        ? _allOptions
              .where((option) => _selectedIds.contains(option.correction.id))
              .toList()
        : _allOptions
              .where(
                (option) => _selectedCategories.contains(option.correction.category),
              )
              .toList();
    final selectedCount = _selectedIds.length;
    final allVisibleSelected =
        visibleOptions.isNotEmpty &&
        visibleOptions.every(
          (option) => _selectedIds.contains(option.correction.id),
        );
    final groupedOptions = _groupByCategory(visibleOptions);

    EmptyStatePanel? emptyPanel;
    if (_showingSelectedOnly) {
      if (_selectedIds.isEmpty) {
        emptyPanel = EmptyStatePanel(
          icon: Icons.checklist_outlined,
          title: _str('Nada seleccionado todavía', 'Nada selecionado ainda'),
          message: _str(
            'Elige una categoría y toca las frases que quieras practicar.',
            'Escolha uma categoria e toque nas frases que quer praticar.',
          ),
        );
      }
    } else if (_selectedCategories.isEmpty) {
      emptyPanel = EmptyStatePanel(
        icon: Icons.category_outlined,
        title: _str('Elige una categoría', 'Escolha uma categoria'),
        message: _str(
          'Toca uno o más colores arriba para ver las frases guardadas.',
          'Toque em uma ou mais cores acima para ver as frases salvas.',
        ),
      );
    } else if (visibleOptions.isEmpty) {
      emptyPanel = EmptyStatePanel(
        icon: Icons.filter_alt_off_outlined,
        title: _str('Nada en esta categoría', 'Nada nesta categoria'),
        message: _str(
          'Elige otra categoría para ver más frases.',
          'Escolha outra categoria para ver mais frases.',
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                AppHeader(
                  title: _str('Elegir frases', 'Escolher frases'),
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  )
                else if (_allOptions.isEmpty)
                  EmptyStatePanel(
                    icon: Icons.translate,
                    title: _str('Nada para practicar', 'Nada para praticar'),
                    message: _str(
                      'Guarda algunas correcciones para empezar a practicar.',
                      'Salve algumas correções para começar a praticar.',
                    ),
                  )
                else ...[
                  _CategoryFilterBar(
                    categories: _availableCategories,
                    selected: _selectedCategories,
                    showingSelectedOnly: _showingSelectedOnly,
                    selectedLabel: _str('Seleccionadas', 'Selecionadas'),
                    onToggle: (category) => setState(() {
                      _showingSelectedOnly = false;
                      if (!_selectedCategories.remove(category)) {
                        _selectedCategories.add(category);
                      }
                    }),
                    onClear: () => setState(() {
                      _showingSelectedOnly = false;
                      _selectedCategories.clear();
                    }),
                    onToggleSelectedOnly: () => setState(() {
                      _showingSelectedOnly = !_showingSelectedOnly;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (emptyPanel != null)
                    emptyPanel
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _str(
                              '$selectedCount de $_maxSelections seleccionada(s)',
                              '$selectedCount de $_maxSelections selecionada(s)',
                            ),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.cyan,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () => setState(() {
                            if (allVisibleSelected) {
                              for (final option in visibleOptions) {
                                _selectedIds.remove(option.correction.id);
                              }
                            } else {
                              // Fill up to the cap rather than rejecting the
                              // whole bulk action — selects as many of the
                              // visible options as still fit.
                              for (final option in visibleOptions) {
                                if (_selectedIds.length >= _maxSelections) {
                                  break;
                                }
                                _selectedIds.add(option.correction.id);
                              }
                            }
                          }),
                          child: Text(
                            allVisibleSelected
                                ? _str('Deseleccionar todo', 'Desmarcar tudo')
                                : _str('Seleccionar todo', 'Selecionar tudo'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final entry in groupedOptions.entries)
                      CollapsibleCategorySection(
                        category: entry.key,
                        itemCount: entry.value.length,
                        isCollapsed: _collapsedCategories.contains(entry.key),
                        onToggle: () => setState(() {
                          if (!_collapsedCategories.remove(entry.key)) {
                            _collapsedCategories.add(entry.key);
                          }
                        }),
                        child: Column(
                          children: [
                            for (final option in entry.value) ...[
                              SavedCorrectionSummaryCard(
                                correction: option.correction,
                                selected: _selectedIds.contains(
                                  option.correction.id,
                                ),
                                onTap: () => _toggleSelection(
                                  context,
                                  option.correction.id,
                                ),
                                trailing: Text(
                                  '${_wordCount(option.expectedAnswer)} '
                                  '${_str('palabra(s)', 'palavra(s)')}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  PrimaryActionButton(
                    label: _str('Empezar sesión', 'Iniciar sessão'),
                    onPressed: selectedCount == 0 ? null : () => _start(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Groups [options] by category, in [ErrorCategory.values] order — the
  /// same fixed order `SavedScreen` groups by — so section order stays stable
  /// regardless of which categories happen to be visible.
  Map<ErrorCategory, List<_CorrectionOption>> _groupByCategory(
    List<_CorrectionOption> options,
  ) {
    final grouped = <ErrorCategory, List<_CorrectionOption>>{};
    for (final option in options) {
      grouped.putIfAbsent(option.correction.category, () => []).add(option);
    }
    return {
      for (final category in ErrorCategory.values)
        if (grouped.containsKey(category)) category: grouped[category]!,
    };
  }

  void _start(BuildContext context) {
    final questions = [
      for (final option in _allOptions)
        if (_selectedIds.contains(option.correction.id))
          GameQuestion(
            source: option.correction,
            promptPhrase: option.correction.promptPhrase.trim(),
            expectedAnswer: option.expectedAnswer,
          ),
    ];

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PromptTranslationGameScreen(
          repositoryController: widget.repositoryController,
          transcriptionService: widget.transcriptionService,
          correctionService: widget.correctionService,
          walkthroughService: widget.walkthroughService,
          language: widget.language,
          initialQuestions: questions,
        ),
      ),
    );
  }
}

/// Whitespace-delimited word count, used for the card's trailing badge — the
/// card's headline is just the short flagged phrase (e.g. "mercado"), so
/// without this a learner has no way to tell that selecting it actually means
/// translating a full sentence, not a single word.
int _wordCount(String text) =>
    text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

/// Resolves the single sentence within [correction.correctedSentence] that
/// actually contains its error, instead of exposing every sentence in what
/// may be a whole multi-sentence submission (the old behavior — one checkbox
/// row per sentence in the full corrected text — is what let a single saved
/// correction from a long paragraph explode into 8+ mostly-irrelevant rows).
///
/// Resolution order: the persisted `correctedStartIndex` (exact, when
/// present); a grapheme-safe substring search for `correctedPhrase` in
/// `correctedSentence` (older saves without a stored index); the first
/// sentence, or the raw trimmed text if the sentence splitter found nothing
/// at all. Never throws — worst case is a less precisely targeted, but still
/// valid, practice sentence.
String _resolveExpectedAnswer(SavedCorrection correction) {
  final sentences = splitIntoSentences(correction.correctedSentence);
  if (sentences.isEmpty) {
    return correction.correctedSentence.trim();
  }

  final anchor =
      correction.correctedStartIndex ??
      _graphemeIndexOf(correction.correctedSentence, correction.correctedPhrase);

  if (anchor != null) {
    final containing = sentences.firstWhere(
      (span) => anchor >= span.start && anchor < span.end,
      orElse: () => sentences.first,
    );
    return containing.text;
  }

  return sentences.first.text;
}

/// First grapheme-offset occurrence of [needle] in [haystack], or null when
/// [needle] is empty or not found. Grapheme-based (not code-unit-based) to
/// match [SentenceSpan]'s own offsets, mirroring the same case-sensitive
/// exact-match search `CorrectionItem`'s anchoring uses elsewhere.
int? _graphemeIndexOf(String haystack, String needle) {
  if (needle.isEmpty) {
    return null;
  }
  final haystackGraphemes = haystack.characters.toList();
  final needleGraphemes = needle.characters.toList();
  if (needleGraphemes.length > haystackGraphemes.length) {
    return null;
  }
  for (
    var start = 0;
    start <= haystackGraphemes.length - needleGraphemes.length;
    start++
  ) {
    var matched = true;
    for (var offset = 0; offset < needleGraphemes.length; offset++) {
      if (haystackGraphemes[start + offset] != needleGraphemes[offset]) {
        matched = false;
        break;
      }
    }
    if (matched) {
      return start;
    }
  }
  return null;
}

/// Filter row: [ClearFilterChip] ("Clear") + an [IconFilterChip] ([selectedLabel]
/// in its tooltip, "Seleccionadas"/"Selecionadas") that switches into review
/// mode, then a multi-select row of [CategorySquareChip]s — visually the same
/// family of chip as `SavedScreen`'s filter bar, but toggling a category chip
/// adds/removes it from a set instead of replacing a single current category,
/// so a session can be composed across categories.
///
/// Switching between category filters made it easy to lose track of what had
/// actually been selected across categories — the review-mode pill exists so
/// the whole cross-category selection can be seen (and trimmed) as one list
/// rather than only ever being visible one category at a time.
class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.showingSelectedOnly,
    required this.selectedLabel,
    required this.onToggle,
    required this.onClear,
    required this.onToggleSelectedOnly,
  });

  final List<ErrorCategory> categories;
  final Set<ErrorCategory> selected;
  final bool showingSelectedOnly;
  final String selectedLabel;
  final ValueChanged<ErrorCategory> onToggle;
  final VoidCallback onClear;
  final VoidCallback onToggleSelectedOnly;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 2,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ClearFilterChip(
              isSelected: selected.isEmpty && !showingSelectedOnly,
              onTap: onClear,
            );
          }
          if (index == 1) {
            return IconFilterChip(
              icon: Icons.checklist_outlined,
              label: selectedLabel,
              isSelected: showingSelectedOnly,
              onTap: onToggleSelectedOnly,
            );
          }
          final category = categories[index - 2];
          return CategorySquareChip(
            category: category,
            isSelected: selected.contains(category),
            onTap: () => onToggle(category),
          );
        },
      ),
    );
  }
}
