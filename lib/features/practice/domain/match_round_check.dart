/// The check on a Matching round made from the rule bank (practice track,
/// step P.3).
///
/// Ported from `checkMatchRound_` in the Spanish Games sheet script
/// (`docs/games_port_source/test_review.gs.txt`, its item B28), with the
/// same rules in the same order. A rule (for example "verbs that take en")
/// has slots; each slot lists the starts it accepts ("pensar", "confiar")
/// and may fix the one answer that goes with them ("en"). A round is a
/// list of pairs, start and answer, and it passes only when it fills every
/// slot exactly once.
///
/// Logic only: the rules themselves are kept in the practice database
/// (step P.5).
library;

/// A start or an answer as it is compared: spaces trimmed and collapsed,
/// case ignored, accents kept (as the games' answer checking).
String ruleKey(String? text) =>
    (text ?? '').trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// One slot of a rule.
class MatchSlot {
  /// [starts] and [fixed] may be given as written; they are compared with
  /// [ruleKey].
  MatchSlot({
    required this.slot,
    this.needs = '',
    required List<String> starts,
    String? fixed,
  }) : starts = List.unmodifiable(
         starts.map(ruleKey).where((s) => s.isNotEmpty),
       ),
       fixed = ruleKey(fixed);

  /// The slot's name or number, used in messages.
  final String slot;

  /// What the slot needs, in words (for the person reading the rule).
  final String needs;

  /// The approved starts for this slot, as keys.
  final List<String> starts;

  /// The one answer every start in this slot must be matched with, as a
  /// key; empty when the answer is free.
  final String fixed;
}

/// One rule of the rule bank.
class MatchRule {
  const MatchRule({this.name = '', required this.slots});

  final String name;
  final List<MatchSlot> slots;
}

/// Checks a Matching round against its rule. [pairs] is a list of
/// `[start, answer]` pairs and [rules] the rule bank by rule id.
///
/// Returns `null` when the round is fine, else why it fails, which is the
/// first of these that applies:
/// - the rule is not in the rule bank;
/// - the round has no pairs;
/// - a pair is not two non-empty parts;
/// - a start is in no slot's list;
/// - two pairs use the same slot;
/// - an answer is not the slot's fixed answer;
/// - two answers are the same;
/// - a slot has no pair.
String? checkMatchRound(
  String ruleId,
  List<List<String>> pairs,
  Map<String, MatchRule> rules,
) {
  final rule = rules[ruleId];
  if (rule == null) return 'rule "$ruleId" is not in the rule bank';
  if (pairs.isEmpty) return 'it has no pairs';
  final used = <int>{};
  final answers = <String>{};
  for (var i = 0; i < pairs.length; i++) {
    final p = pairs[i];
    if (p.length != 2 || ruleKey(p[0]).isEmpty || ruleKey(p[1]).isEmpty) {
      return 'pair ${i + 1} is not "start = answer"';
    }
    final start = ruleKey(p[0]);
    final answer = ruleKey(p[1]);
    final slots = [
      for (var s = 0; s < rule.slots.length; s++)
        if (rule.slots[s].starts.contains(start)) s,
    ];
    if (slots.isEmpty) {
      return '"${p[0]}" is not an approved start for $ruleId';
    }
    final free = slots.where((s) => !used.contains(s));
    if (free.isEmpty) {
      return 'two pairs use slot ${rule.slots[slots.first].slot} ("${p[0]}")';
    }
    final slot = rule.slots[free.first];
    used.add(free.first);
    if (slot.fixed.isNotEmpty && answer != slot.fixed) {
      return '"${p[0]}" should be matched with "${slot.fixed}", '
          'not "${p[1]}"';
    }
    if (!answers.add(answer)) return 'the answer "${p[1]}" appears twice';
  }
  final missing = [
    for (var s = 0; s < rule.slots.length; s++)
      if (!used.contains(s)) rule.slots[s].slot,
  ];
  if (missing.isNotEmpty) return 'no pair for slot ${missing.join(', ')}';
  return null;
}
