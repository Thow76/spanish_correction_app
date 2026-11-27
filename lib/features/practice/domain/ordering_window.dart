/// The shuffled window of a Sentence ordering question (practice track,
/// step P.3).
///
/// Ported from `orderWindow_` in the Spanish Games sheet script
/// (`docs/games_port_source/test_review.gs.txt`, its item B29), with the
/// same rules. A sentence of [orderWindowSize] words or fewer is shuffled
/// whole. A longer one shuffles only a window of that many words around
/// the words that were corrected; the words before and after the window
/// stay on screen as fixed text.
///
/// Logic only. Step P.7 calls this when it builds an ordering question.
library;

/// A Sentence ordering question longer than this many words shuffles only
/// a window of this size.
const int orderWindowSize = 8;

/// The part of a long sentence that is shuffled, and the fixed text around
/// it.
class OrderWindow {
  const OrderWindow({
    required this.prompt,
    required this.answers,
    this.fixedStart,
    this.fixedEnd,
  });

  /// The window of the corrected sentence: the words to put in order.
  final String prompt;

  /// The accepted orders, each only the window: [prompt] first, then the
  /// window of every alternative sentence that was kept.
  final List<String> answers;

  /// The words shown, fixed, before the window; `null` when the window
  /// starts the sentence.
  final String? fixedStart;

  /// The words shown, fixed, after the window; `null` when the window ends
  /// the sentence.
  final String? fixedEnd;
}

/// Picks the shuffled window for a Sentence ordering question.
///
/// [prompt] is the corrected sentence, [answers] the accepted sentences
/// (the corrected one and any alternatives) and [original] the sentence as
/// the learner wrote it.
///
/// Returns `null` when the whole sentence is shuffled: it has
/// [orderWindowSize] words or fewer, there is no original, or nothing
/// changed between the two. Otherwise the window is [orderWindowSize]
/// words long with the changed words in its middle, moved as needed to
/// stay inside the sentence. If the changed words span more than the
/// window, the window is the first [orderWindowSize] words of that span.
/// An alternative answer that does not share the fixed start and end word
/// for word is dropped.
OrderWindow? orderWindow(
  String prompt,
  List<String> answers,
  String original,
) {
  final w = _words(prompt);
  if (w.length <= orderWindowSize) return null;
  final orig = _words(original);
  if (orig.isEmpty) return null;
  final changed = _changedWords(w, orig);
  final first = changed.indexOf(true);
  if (first < 0) return null;
  final last = changed.lastIndexOf(true);

  int start;
  final span = last - first + 1;
  if (span >= orderWindowSize) {
    start = first;
  } else {
    final spare = orderWindowSize - span;
    start = first - spare ~/ 2;
  }
  final latest = w.length - orderWindowSize;
  if (start > latest) start = latest;
  if (start < 0) start = 0;
  final end = start + orderWindowSize; // first word after the window

  final before = w.sublist(0, start);
  final after = w.sublist(end);
  String? middle(String sentence) {
    final s = _words(sentence);
    if (s.length <= before.length + after.length) return null;
    for (var k = 0; k < before.length; k++) {
      if (s[k] != before[k]) return null;
    }
    for (var k = 0; k < after.length; k++) {
      if (s[s.length - after.length + k] != after[k]) return null;
    }
    return s.sublist(before.length, s.length - after.length).join(' ');
  }

  final window = w.sublist(start, end).join(' ');
  final out = <String>[window];
  for (final answer in answers) {
    final m = middle(answer);
    if (m != null && !out.contains(m)) out.add(m);
  }
  return OrderWindow(
    prompt: window,
    answers: out,
    fixedStart: before.isEmpty ? null : before.join(' '),
    fixedEnd: after.isEmpty ? null : after.join(' '),
  );
}

/// The words of a sentence, split on white space.
List<String> _words(String sentence) =>
    sentence.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

/// A word compared without case or edge punctuation, accents kept.
String _wordKey(String word) =>
    word.toLowerCase().replaceAll(RegExp(r'^[¿¡"«(]+|[.,;:!?"»)]+$'), '');

/// For each word of [target], whether it is not part of the longest run of
/// words shared, in order, with [other]. The script carried its own copy
/// of this comparison (`changedWords_`); so does this file, so that step
/// P.3 does not depend on step P.4, which is built alongside it.
List<bool> _changedWords(List<String> target, List<String> other) {
  final a = target.map(_wordKey).toList();
  final b = other.map(_wordKey).toList();
  final table = List.generate(
    a.length + 1,
    (_) => List<int>.filled(b.length + 1, 0),
  );
  for (var i = a.length - 1; i >= 0; i--) {
    for (var j = b.length - 1; j >= 0; j--) {
      table[i][j] = a[i] == b[j]
          ? table[i + 1][j + 1] + 1
          : (table[i + 1][j] > table[i][j + 1]
                ? table[i + 1][j]
                : table[i][j + 1]);
    }
  }
  final kept = List<bool>.filled(a.length, false);
  var i = 0;
  var j = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      kept[i] = true;
      i++;
      j++;
    } else if (table[i + 1][j] >= table[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return [for (final k in kept) !k];
}
