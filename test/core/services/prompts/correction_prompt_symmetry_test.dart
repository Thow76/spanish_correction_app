import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Structural symmetry check for the Spanish/Portuguese correction-prompt
// sections in lib/core/services/prompts/correction_prompt.dart.
//
// This source-scrapes the file at test time instead of hand-maintaining a
// parallel list of section names, so it can't silently drift from the code:
// any new `_es*`/`_pt*` section constant is picked up automatically. Any
// asymmetry between the two languages' section names must be either
// resolved or added to the allowlist below with an honest status -- this is
// the test that would have caught the missing Portuguese calque-restraint
// guardrail (and BP-001, in reverse) automatically had it existed earlier.

/// Documents a *known* asymmetry and why it's currently allowed to exist.
/// `status` is not a rubber stamp -- an entry can be allowlisted and still
/// describe an open problem (see `CalqueRestraint` below).
class _AllowedAsymmetry {
  const _AllowedAsymmetry(this.status, this.note);
  final String status;
  final String note;
}

const Map<String, _AllowedAsymmetry> _esOnlyAllowlist = {
  'CalqueRestraint': _AllowedAsymmetry(
    'NOT YET RESOLVED',
    'No PT counterpart. Suspected cause of ES-2 in-app false positives '
        '(Spanish flags "termino el trabajo" style corrections that the '
        'bare prompt never produces). Open item, not accepted as '
        'correct-by-design.',
  ),
};

const Map<String, _AllowedAsymmetry> _ptOnlyAllowlist = {
  'SoftRegisterBullet': _AllowedAsymmetry(
    'RESOLVED / correct-by-design',
    'No ES counterpart. This is BP-001, correctly PT-only by original '
        'design -- Spanish has no equivalent soft-register gap identified.',
  ),
  'NaturalnessWhitelist': _AllowedAsymmetry(
    'NOT INDEPENDENTLY VERIFIED',
    'No ES counterpart. Believed PT-specific (gerund / "a gente" / "ter" '
        'existential ambiguity has no Spanish equivalent) but not '
        'independently verified against Spanish -- flagged for a '
        'follow-up check rather than assumed safe.',
  ),
  'EuropeanVocabGuardrail': _AllowedAsymmetry(
    'BELIEVED CORRECT-BY-DESIGN / NOT INDEPENDENTLY VERIFIED',
    'No ES counterpart. Spanish has no European/Latin-American '
        'vocabulary distinction analogous to European/Brazilian '
        'Portuguese, so this guardrail is expected to be structurally '
        'inapplicable -- but no test cases confirm Peninsular-Spanish '
        'vocabulary leakage is actually a non-issue for the Spanish prompt.',
  ),
  'SpellingNorms': _AllowedAsymmetry(
    'RESOLVED / correct-by-design',
    'No ES counterpart. Spanish orthography does not vary between Spain '
        'and Latin America the way Portuguese orthography varies between '
        'Portugal and Brazil, so this section is structurally '
        'inapplicable to the Spanish prompt.',
  ),
  'LiteralConstructions': _AllowedAsymmetry(
    'NOT A CONTENT GAP -- extraction-order artifact',
    'No ES counterpart by name, but the equivalent content exists: '
        'Spanish bundles its overly-literal-construction examples inside '
        '_esCalqueExamples as one contiguous block. Portuguese\'s '
        'equivalent content is split into _ptCalqueExamples and '
        '_ptLiteralConstructions only because BP-001\'s soft-register '
        'bullet (_ptSoftRegisterBullet) sits between them in the original '
        'prompt text and had to stay in its original position.',
  ),
};

void main() {
  test(
    'Spanish and Portuguese correction-prompt sections have no undocumented '
    'asymmetry',
    () {
      final source = File(
        'lib/core/services/prompts/correction_prompt.dart',
      ).readAsStringSync();

      // Anchored to actual const/final declarations (not doc-comment
      // mentions) so comments naming the missing counterpart don't pollute
      // the extracted section-name sets.
      final declaredNamePattern = RegExp(
        r'^(?:const|final) String (_es[A-Z]\w*|_pt[A-Z]\w*)',
        multiLine: true,
      );

      final esNames = <String>{};
      final ptNames = <String>{};
      for (final match in declaredNamePattern.allMatches(source)) {
        final name = match.group(1)!;
        if (name.startsWith('_es')) {
          esNames.add(name.substring(3));
        } else {
          ptNames.add(name.substring(3));
        }
      }

      expect(esNames, isNotEmpty);
      expect(ptNames, isNotEmpty);

      final esOnly = esNames.difference(ptNames);
      final ptOnly = ptNames.difference(esNames);

      final undocumentedEsOnly = esOnly.difference(
        _esOnlyAllowlist.keys.toSet(),
      );
      final undocumentedPtOnly = ptOnly.difference(
        _ptOnlyAllowlist.keys.toSet(),
      );

      expect(
        undocumentedEsOnly,
        isEmpty,
        reason:
            'Spanish-only correction-prompt section(s) found with no '
            'allowlist entry explaining the asymmetry: $undocumentedEsOnly. '
            'Add an honest _AllowedAsymmetry entry (status + note) rather '
            'than silently accepting or failing.',
      );
      expect(
        undocumentedPtOnly,
        isEmpty,
        reason:
            'Portuguese-only correction-prompt section(s) found with no '
            'allowlist entry explaining the asymmetry: $undocumentedPtOnly. '
            'Add an honest _AllowedAsymmetry entry (status + note) rather '
            'than silently accepting or failing.',
      );

      // Catch the inverse too: an allowlist entry for an asymmetry that no
      // longer exists (e.g. someone added the missing counterpart) should be
      // removed rather than left stale and misleading.
      final staleEsEntries = _esOnlyAllowlist.keys.toSet().difference(esOnly);
      final stalePtEntries = _ptOnlyAllowlist.keys.toSet().difference(ptOnly);
      expect(
        staleEsEntries,
        isEmpty,
        reason:
            'Allowlist entries for Spanish-only sections that are no '
            'longer asymmetric (a Portuguese counterpart now exists): '
            '$staleEsEntries. Remove the stale allowlist entry.',
      );
      expect(
        stalePtEntries,
        isEmpty,
        reason:
            'Allowlist entries for Portuguese-only sections that are no '
            'longer asymmetric (a Spanish counterpart now exists): '
            '$stalePtEntries. Remove the stale allowlist entry.',
      );
    },
  );
}
