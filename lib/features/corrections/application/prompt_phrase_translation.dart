/// Result of translating a saved correction's sentence into English for the
/// "Traducir frases" prompt card.
///
/// [highlightStartIndex]/[highlightEndIndex] are grapheme offsets into [text]
/// marking the span corresponding to the correction's flagged phrase, when
/// the model identified one and the app verified it's an actual substring of
/// [text] — see [OpenAiCorrectionService.generatePromptPhrase]. Null when no
/// such span was identified or verified; callers render [text] with no
/// highlight in that case, never an error.
class PromptPhraseTranslation {
  const PromptPhraseTranslation({
    required this.text,
    this.highlightStartIndex,
    this.highlightEndIndex,
  });

  final String text;
  final int? highlightStartIndex;
  final int? highlightEndIndex;
}
