import 'package:flutter/material.dart';

import '../../../../shared/design/app_spacing.dart';
import '../../../../shared/widgets/category_pill.dart';
import '../../../../shared/widgets/collapsible_section.dart';
import '../../../../shared/widgets/highlighted_sentence.dart';
import '../../../../shared/widgets/primary_action_button.dart';
import '../../../../shared/widgets/text_body.dart';
import '../../../saved/domain/saved_correction.dart';

/// The "Ver respuesta" answer screen (Figma 599:1887 / 626:1216): a read-only
/// recap of the saved correction the learner just practised — no LLM call, all
/// fields sourced from [correction].
///
/// It shows the category pill, the wrong phrase in the category colour, a short
/// intro paragraph, and two collapsible sections (the original sentence with the
/// wrong phrase underlined, and the longer "why it's wrong" explanation). A
/// single forward button advances; its label is [onForward]'s caller's choice of
/// "next vs finish" via [isLastQuestion], so the same screen serves both Figma
/// frames.
class AnswerView extends StatefulWidget {
  const AnswerView({
    required this.correction,
    required this.isLastQuestion,
    required this.onForward,
    required this.str,
    super.key,
  });

  final SavedCorrection correction;

  /// Whether the practised question is the last in the session. Drives the
  /// forward button label ("Terminar" vs "Siguiente pregunta"); the caller
  /// computes it from its own (pre- or post-record) session state.
  final bool isLastQuestion;

  /// Advance action. The caller wires the correct behaviour per entry point
  /// (record-then-advance from the reveal screen, advance-only from the
  /// walkthrough result), so this widget stays presentation-only.
  final VoidCallback onForward;
  final String Function(String es, String pt) str;

  @override
  State<AnswerView> createState() => _AnswerViewState();
}

class _AnswerViewState extends State<AnswerView> {
  bool _sentenceCollapsed = false;
  bool _whyCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final correction = widget.correction;
    final str = widget.str;
    final categoryColor = correction.category.color;

    // Intro paragraph: prefer the in-context explanation; fall back to the short
    // explanation when no in-context text was saved (older records).
    final intro = correction.explanation.inContext.trim().isNotEmpty
        ? correction.explanation.inContext
        : correction.shortExplanation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryPill(label: correction.category.label, color: categoryColor),
        const SizedBox(height: AppSpacing.lg),
        Text(
          correction.originalPhrase,
          style: TextStyle(
            color: categoryColor,
            fontFamily: 'Sora',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 32 / 24,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextBody(text: intro),
        const SizedBox(height: AppSpacing.xl),
        CollapsibleSection(
          key: const Key('answer-sentence-section'),
          title: str('Frase original', 'Frase original'),
          isCollapsed: _sentenceCollapsed,
          onToggle: () =>
              setState(() => _sentenceCollapsed = !_sentenceCollapsed),
          child: HighlightedSentence(
            sentence: correction.originalSentence,
            item: correction.toCorrectionItem(),
            color: categoryColor,
            decoration: TextDecoration.underline,
            // Anchor on the persisted original range; for old records with no
            // saved range the shared helper falls back to substring matching.
            rangeSelector: (item) => (item.startIndex, item.endIndex),
            phraseSelector: (item) => item.originalPhrase,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        CollapsibleSection(
          key: const Key('answer-why-section'),
          title: str('Por qué está mal', 'Por que está errado'),
          isCollapsed: _whyCollapsed,
          onToggle: () => setState(() => _whyCollapsed = !_whyCollapsed),
          child: TextBody(text: correction.explanation.whyItsWrong),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryActionButton(
          key: const Key('answer-forward'),
          label: widget.isLastQuestion
              ? str('Terminar', 'Terminar')
              : str('Siguiente pregunta', 'Próxima pergunta'),
          onPressed: widget.onForward,
        ),
      ],
    );
  }
}
