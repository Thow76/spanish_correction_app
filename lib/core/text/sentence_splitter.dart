import 'package:characters/characters.dart';

/// One sentence extracted from a longer text, with its grapheme offsets into
/// the original [text] so callers can rebase other offsets (e.g. a saved
/// correction's `startIndex`/`endIndex`) onto this shorter span.
class SentenceSpan {
  const SentenceSpan({required this.text, required this.start, required this.end});

  /// The sentence text, including its trailing `.`/`!`/`?`.
  final String text;

  /// Grapheme-indexed start offset (inclusive) into the source text.
  final int start;

  /// Grapheme-indexed end offset (exclusive) into the source text.
  final int end;
}

const _terminators = {'.', '!', '?'};

/// Mechanically splits [text] into sentences on `.`, `!`, and `?`, with no
/// LLM call and no abbreviation-awareness — a rare mis-split (e.g. "Sr.
/// Pérez") is an acceptable trade for a deterministic, free split.
///
/// Leading `¿`/`¡` are kept with the sentence they open. Empty fragments
/// (consecutive terminators, leading/trailing whitespace-only runs) are
/// dropped. Offsets are grapheme-indexed to line up with the offsets already
/// stored on `SavedCorrection`.
List<SentenceSpan> splitIntoSentences(String text) {
  final graphemes = text.characters.toList();
  final spans = <SentenceSpan>[];

  var sentenceStart = 0;
  var i = 0;
  while (i < graphemes.length) {
    if (_terminators.contains(graphemes[i])) {
      // Absorb a run of terminators/closing quotes (e.g. "?!" or ".\"").
      var end = i + 1;
      while (end < graphemes.length && _terminators.contains(graphemes[end])) {
        end++;
      }
      _addTrimmed(spans, graphemes, sentenceStart, end);
      sentenceStart = end;
      i = end;
      continue;
    }
    i++;
  }
  _addTrimmed(spans, graphemes, sentenceStart, graphemes.length);

  return spans;
}

void _addTrimmed(
  List<SentenceSpan> spans,
  List<String> graphemes,
  int rawStart,
  int rawEnd,
) {
  var start = rawStart;
  var end = rawEnd;
  while (start < end && graphemes[start].trim().isEmpty) {
    start++;
  }
  while (end > start && graphemes[end - 1].trim().isEmpty) {
    end--;
  }
  if (start >= end) {
    return;
  }
  final text = graphemes.sublist(start, end).join();
  // Drop fragments with no letters/digits (e.g. a bare "..." left over after
  // trimming) — nothing translatable lives in a punctuation-only fragment.
  if (!_wordCharacter.hasMatch(text)) {
    return;
  }
  spans.add(SentenceSpan(text: text, start: start, end: end));
}

final _wordCharacter = RegExp(r'[\p{L}\p{N}]', unicode: true);
