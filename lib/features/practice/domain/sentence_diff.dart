/// A plain word-by-word comparison of two sentences, used to find which
/// words changed between what the learner wrote and what was suggested
/// (practice track, step P.4).
///
/// Moved out of the Spanish Games app's `SentenceText` helper
/// (`docs/games_port_source/sentence_text.dart.txt`) as plain functions
/// with no widget code, behaviour unchanged. Step P.7 uses [sentenceDiff]
/// to find "the change" every question is built around.
///
/// Words are compared without case or the punctuation on their edges, so
/// "Hola," and "hola" count as the same word. Accents are kept, so "esta"
/// and "está" are different words. Nothing here is language-specific.
library;

/// One word of a sentence, and whether it differs from the other sentence.
typedef DiffWord = ({String word, bool changed});

/// The words of [sentence], split on white space. Punctuation stays
/// attached to its word.
List<String> sentenceWords(String sentence) =>
    sentence.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

/// [word] as it is compared: lower case, without opening punctuation
/// (¿ ¡ " « () at its start or closing punctuation (. , ; : ! ? " » )) at
/// its end. Accents are kept.
String wordKey(String word) =>
    word.toLowerCase().replaceAll(RegExp(r'^[¿¡"«(]+|[.,;:!?"»)]+$'), '');

/// The words of [target], each marked `changed` if it is not part of the
/// longest run of words shared, in order, with [other] (case and edge
/// punctuation ignored, accents kept).
///
/// To see what was taken out of the learner's sentence, pass the sentence
/// as written as [target] and the suggested one as [other]; to see what
/// was put in, pass them the other way round.
List<DiffWord> sentenceDiff(String target, String other) {
  final a = sentenceWords(target);
  final b = sentenceWords(other);
  final ka = a.map(wordKey).toList();
  final kb = b.map(wordKey).toList();
  // Longest common subsequence table.
  final table = List.generate(
    a.length + 1,
    (_) => List<int>.filled(b.length + 1, 0),
  );
  for (var i = a.length - 1; i >= 0; i--) {
    for (var j = b.length - 1; j >= 0; j--) {
      table[i][j] = ka[i] == kb[j]
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
    if (ka[i] == kb[j]) {
      kept[i] = true;
      i++;
      j++;
    } else if (table[i + 1][j] >= table[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return [for (var k = 0; k < a.length; k++) (word: a[k], changed: !kept[k])];
}

/// The words that changed in [target] compared with [other]. Each run of
/// neighbouring changed words comes first ("me llamo"), then each word of
/// a longer run on its own ("me", "llamo"), without repeats (case and edge
/// punctuation ignored). Empty when nothing changed.
List<String> changedRuns(String target, String other) {
  final diff = sentenceDiff(target, other);
  final runs = <List<String>>[];
  var current = <String>[];
  for (final w in diff) {
    if (w.changed) {
      current.add(w.word);
    } else if (current.isNotEmpty) {
      runs.add(current);
      current = <String>[];
    }
  }
  if (current.isNotEmpty) runs.add(current);

  final seen = <String>{};
  final out = <String>[];
  void add(List<String> words) {
    final text = words.join(' ');
    final key = words.map(wordKey).join(' ');
    if (key.trim().isEmpty || !seen.add(key)) return;
    out.add(text);
  }

  for (final run in runs) {
    add(run);
  }
  for (final run in runs) {
    if (run.length < 2) continue;
    for (final word in run) {
      add([word]);
    }
  }
  return out;
}
