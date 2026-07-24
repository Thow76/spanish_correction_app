import '../enums/language.dart';

/// Mechanically splits a single sentence into 2-5 phrase-level chunks, no LLM
/// call. A closed set of function words (articles, prepositions, contractions,
/// proclitic pronouns) always binds forward to the next token, chained when
/// consecutive (e.g. Spanish "a la" binds through to the noun after "la").
/// This mirrors the walkthrough prompt's own decomposition rules — keep an
/// article with its noun, a preposition with its object, a contraction atomic
/// — by construction, since a bound function word is never its own chunk to
/// begin with.
///
/// This is a heuristic, not real parsing: it has no notion of verb phrases,
/// direct objects, or demonstratives, so it will sometimes produce a more
/// fragmented (word-level) split than a phrase-aware model would. What it
/// guarantees instead: the chunks are contiguous, non-overlapping, and their
/// concatenation trivially reproduces the sentence — there is no
/// "reconstruction" to get wrong and nothing to validate or retry.
List<String> chunkSentence(String sentence, Language language) {
  final stripped = sentence.trim().replaceAll(RegExp(r'[.?!¡¿"“”]+$'), '').trim();
  final words = stripped
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return const [];
  }

  final units = _buildBindingUnits(words, _bindsForward(language));
  return _capAt(units, 5);
}

/// Pass 1: greedily absorb each function word into the unit it starts, along
/// with everything up to (and including) the next non-function word. A run of
/// consecutive function words chains into a single unit.
List<String> _buildBindingUnits(List<String> words, Set<String> bindsForward) {
  final units = <String>[];
  final buffer = StringBuffer();

  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    if (buffer.isNotEmpty) {
      buffer.write(' ');
    }
    buffer.write(word);

    final isFunctionWord = bindsForward.contains(word.toLowerCase());
    final isLastWord = i == words.length - 1;
    if (!isFunctionWord || isLastWord) {
      units.add(buffer.toString());
      buffer.clear();
    }
  }

  return units;
}

/// Pass 2: while there are more than [maxChunks] units, repeatedly merge
/// whichever adjacent pair has the smallest combined word count, keeping
/// chunk sizes as balanced as the merges allow.
List<String> _capAt(List<String> units, int maxChunks) {
  final result = [...units];
  while (result.length > maxChunks) {
    var mergeIndex = 0;
    var smallestCombined = _wordCount(result[0]) + _wordCount(result[1]);
    for (var i = 1; i < result.length - 1; i++) {
      final combined = _wordCount(result[i]) + _wordCount(result[i + 1]);
      if (combined < smallestCombined) {
        smallestCombined = combined;
        mergeIndex = i;
      }
    }
    result[mergeIndex] = '${result[mergeIndex]} ${result[mergeIndex + 1]}';
    result.removeAt(mergeIndex + 1);
  }
  return result;
}

int _wordCount(String unit) => unit.split(' ').length;

Set<String> _bindsForward(Language language) => switch (language) {
  Language.spanish => _spanishBindsForward,
  Language.portuguese => _portugueseBindsForward,
};

const _spanishBindsForward = {
  // Contractions (atomic, and bind forward like the article they contain).
  'al', 'del',
  // Definite/indefinite articles.
  'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
  // Simple prepositions.
  'a', 'de', 'en', 'con', 'por', 'para', 'sin', 'sobre', 'entre', 'hacia',
  'hasta', 'desde', 'según', 'durante', 'contra', 'tras',
  // Proclitic object/reflexive pronouns (preverbal position).
  'me', 'te', 'se', 'lo', 'le', 'les', 'nos', 'os',
};

const _portugueseBindsForward = {
  // Contractions named explicitly in the walkthrough decomposition rules,
  // plus their plural/feminine forms.
  'no', 'na', 'nos', 'nas', 'do', 'da', 'dos', 'das', 'à', 'ao', 'às', 'aos',
  'pelo', 'pela', 'pelos', 'pelas', 'num', 'numa', 'nuns', 'numas',
  // Definite/indefinite articles.
  'o', 'a', 'os', 'as', 'um', 'uma', 'uns', 'umas',
  // Simple prepositions.
  'de', 'em', 'para', 'por', 'com', 'sem', 'sobre', 'entre', 'desde', 'até',
  'contra', 'segundo', 'durante',
  // Proclitic object/reflexive pronouns (preverbal position).
  'me', 'te', 'se', 'lhe', 'lhes', 'vos',
};
