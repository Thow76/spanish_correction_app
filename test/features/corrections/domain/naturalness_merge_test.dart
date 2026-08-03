import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_issue.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_merge.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_review.dart';

void main() {
  group('mergeNaturalnessReview', () {
    test('returns the first-pass text unchanged when there are no issues', () {
      final result = mergeNaturalnessReview(
        originalText: 'Necesito hacer una decision importante.',
        firstPassCorrectedText: 'Necesito hacer una decisión importante.',
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: false,
          issues: [],
        ),
      );

      expect(
        result.finalCorrectedText,
        'Necesito hacer una decisión importante.',
      );
      expect(result.appliedEdits, isEmpty);
      expect(result.skippedEdits, isEmpty);
      expect(result.originalText, 'Necesito hacer una decision importante.');
      expect(
        result.firstPassCorrectedText,
        'Necesito hacer una decisión importante.',
      );
    });

    test('applies a single unambiguous issue', () {
      const issue = NaturalnessIssue(
        span: 'hacer una decisión',
        naturalReplacement: 'tomar una decisión',
        explanation: 'Wrong collocation for "decisión".',
      );

      final result = mergeNaturalnessReview(
        originalText: 'Necesito hacer una decision importante.',
        firstPassCorrectedText: 'Necesito hacer una decisión importante.',
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue],
        ),
      );

      expect(
        result.finalCorrectedText,
        'Necesito tomar una decisión importante.',
      );
      expect(result.appliedEdits, hasLength(1));
      expect(result.appliedEdits.single.issue, same(issue));
      expect(result.skippedEdits, isEmpty);
    });

    test('applies multiple non-overlapping issues', () {
      const issue1 = NaturalnessIssue(
        span: 'hacer una decisión',
        naturalReplacement: 'tomar una decisión',
        explanation: 'Wrong collocation for "decisión".',
      );
      const issue2 = NaturalnessIssue(
        span: 'hacer un paseo',
        naturalReplacement: 'dar un paseo',
        explanation: 'Wrong collocation for "paseo".',
      );

      final result = mergeNaturalnessReview(
        originalText: 'placeholder',
        firstPassCorrectedText:
            'Voy a hacer una decisión y también voy a hacer un paseo.',
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue1, issue2],
        ),
      );

      expect(
        result.finalCorrectedText,
        'Voy a tomar una decisión y también voy a dar un paseo.',
      );
      expect(result.appliedEdits, hasLength(2));
      expect(result.skippedEdits, isEmpty);
    });

    test(
      'applies an exact single-occurrence naturalness fix on top of an '
      'unrelated first-pass grammar/spelling fix, and both appear in the '
      'final text (issue #33)',
      () {
        const issue = NaturalnessIssue(
          span: 'hizo una decisión',
          naturalReplacement: 'tomó una decisión',
          explanation:
              '"Hacer una decisión" is a calque; native speakers say '
              '"tomar una decisión".',
        );

        final result = mergeNaturalnessReview(
          // First pass already fixed "iso" -> "hizo", "desicion" ->
          // "decisión", and "tambien" -> "también" (grammar/spelling only)
          // before the naturalness pass ever ran — firstPassCorrectedText,
          // not originalText, is what the naturalness span is matched
          // against. "también" sits outside the naturalness span below, so
          // it survives untouched — unlike "hizo"/"decisión", which are
          // inside the span and get overwritten by naturalReplacement, so
          // they don't independently prove anything survived.
          originalText: 'Ayer ella iso una desicion importante y tambien '
              'fuimos a tomar un café.',
          firstPassCorrectedText:
              'Ayer ella hizo una decisión importante y también fuimos a '
              'tomar un café.',
          naturalnessReview: const NaturalnessReview(
            hasNaturalnessIssue: true,
            issues: [issue],
          ),
        );

        // The naturalness fix ("hizo una decisión" -> "tomó una decisión")
        // and the untouched, spatially separate first-pass fix ("tambien"
        // -> "también") both appear together in one final text.
        expect(
          result.finalCorrectedText,
          'Ayer ella tomó una decisión importante y también fuimos a tomar '
          'un café.',
        );
        expect(result.appliedEdits, hasLength(1));
        expect(result.appliedEdits.single.issue, same(issue));
        expect(result.skippedEdits, isEmpty);
      },
    );

    test(
      'skips a slash-separated multi-option replacement rather than '
      'splicing a menu of alternatives into the text (issue #108, the '
      '"beer" pattern)',
      () {
        const issue = NaturalnessIssue(
          span: '¿Puedo tener una cerveza?',
          naturalReplacement:
              '¿Me pones una cerveza? / ¿Me traes una cerveza? / ¿Me das '
              'una cerveza?',
          explanation: 'English-influenced "can I have" phrasing.',
        );

        final result = mergeNaturalnessReview(
          originalText: '¿Puedo tener una cerveza?',
          firstPassCorrectedText: '¿Puedo tener una cerveza?',
          naturalnessReview: const NaturalnessReview(
            hasNaturalnessIssue: true,
            issues: [issue],
          ),
        );

        expect(result.finalCorrectedText, '¿Puedo tener una cerveza?');
        expect(result.appliedEdits, isEmpty);
        expect(result.skippedEdits, hasLength(1));
        expect(result.skippedEdits.single.issue, same(issue));
        expect(
          result.skippedEdits.single.reason,
          NaturalnessMergeSkipReason.multiOptionReplacement,
        );
      },
    );

    test(
      'skips a slash-separated multi-option replacement rather than '
      'splicing a menu of alternatives into the text (issue #108, the '
      '"pasar un buen tiempo" pattern)',
      () {
        const issue = NaturalnessIssue(
          span: 'pasar un buen tiempo',
          naturalReplacement: 'pasarlo bien / pasar un buen rato',
          explanation: 'English-influenced "have a good time" phrasing.',
        );

        final result = mergeNaturalnessReview(
          originalText: 'Quiero pasar un buen tiempo.',
          firstPassCorrectedText: 'Quiero pasar un buen tiempo.',
          naturalnessReview: const NaturalnessReview(
            hasNaturalnessIssue: true,
            issues: [issue],
          ),
        );

        expect(result.finalCorrectedText, 'Quiero pasar un buen tiempo.');
        expect(result.appliedEdits, isEmpty);
        expect(result.skippedEdits, hasLength(1));
        expect(
          result.skippedEdits.single.reason,
          NaturalnessMergeSkipReason.multiOptionReplacement,
        );
      },
    );

    test(
      'does not mistake a bare slash with no surrounding spaces for a '
      'multi-option replacement (issue #108) — only " / " triggers the '
      'skip',
      () {
        const issue = NaturalnessIssue(
          span: 'y o',
          naturalReplacement: 'y/o',
          explanation:
              'Synthetic case: a legitimate single replacement that '
              'happens to contain an unspaced slash, e.g. "and/or".',
        );

        final result = mergeNaturalnessReview(
          originalText: 'Necesito pan y o leche.',
          firstPassCorrectedText: 'Necesito pan y o leche.',
          naturalnessReview: const NaturalnessReview(
            hasNaturalnessIssue: true,
            issues: [issue],
          ),
        );

        expect(result.finalCorrectedText, 'Necesito pan y/o leche.');
        expect(result.appliedEdits, hasLength(1));
        expect(result.skippedEdits, isEmpty);
      },
    );

    test('skips a span that does not occur in the first-pass text', () {
      const issue = NaturalnessIssue(
        span: 'no existe en el texto',
        naturalReplacement: 'reemplazo',
        explanation: 'Never actually present.',
      );

      final result = mergeNaturalnessReview(
        originalText: 'placeholder',
        firstPassCorrectedText: 'Todo está bien.',
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue],
        ),
      );

      expect(result.finalCorrectedText, 'Todo está bien.');
      expect(result.appliedEdits, isEmpty);
      expect(result.skippedEdits, hasLength(1));
      expect(result.skippedEdits.single.issue, same(issue));
      expect(
        result.skippedEdits.single.reason,
        NaturalnessMergeSkipReason.spanNotFound,
      );
    });

    test('skips a span that occurs more than once, without guessing', () {
      const issue = NaturalnessIssue(
        span: 'tráfico',
        naturalReplacement: 'tránsito',
        explanation: 'Anglicism.',
      );

      final result = mergeNaturalnessReview(
        originalText: 'placeholder',
        firstPassCorrectedText: 'Vi mucho tráfico y luego más tráfico.',
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue],
        ),
      );

      expect(
        result.finalCorrectedText,
        'Vi mucho tráfico y luego más tráfico.',
      );
      expect(result.appliedEdits, isEmpty);
      expect(result.skippedEdits, hasLength(1));
      expect(
        result.skippedEdits.single.reason,
        NaturalnessMergeSkipReason.ambiguousSpan,
      );
    });

    test(
      'applies the leftmost-starting issue and skips an overlapping one, '
      'regardless of which order they appear in the review',
      () {
        const issueLate = NaturalnessIssue(
          span: 'una decisión importante',
          naturalReplacement: 'una decisión clave',
          explanation: 'Overlaps the other candidate.',
        );
        const issueEarly = NaturalnessIssue(
          span: 'hacer una decisión',
          naturalReplacement: 'tomar una decisión',
          explanation: 'Wrong collocation for "decisión".',
        );

        final result = mergeNaturalnessReview(
          originalText: 'placeholder',
          // issueLate is listed FIRST in the review, but issueEarly starts
          // earlier in the text — leftmost-by-position must still win.
          firstPassCorrectedText: 'Voy a hacer una decisión importante hoy.',
          naturalnessReview: const NaturalnessReview(
            hasNaturalnessIssue: true,
            issues: [issueLate, issueEarly],
          ),
        );

        expect(
          result.finalCorrectedText,
          'Voy a tomar una decisión importante hoy.',
        );
        expect(result.appliedEdits, hasLength(1));
        expect(result.appliedEdits.single.issue, same(issueEarly));
        expect(result.skippedEdits, hasLength(1));
        expect(result.skippedEdits.single.issue, same(issueLate));
        expect(
          result.skippedEdits.single.reason,
          NaturalnessMergeSkipReason.overlapsAnotherEdit,
        );
      },
    );

    test(
      'skips both candidates when two spans start at the exact same '
      'position, since neither is a principled "leftmost" winner over '
      'the other (issue #34 review fix)',
      () {
        const issueShort = NaturalnessIssue(
          span: 'hacer una decisión',
          naturalReplacement: 'tomar una decisión',
          explanation: 'Wrong collocation for "decisión".',
        );
        const issueLong = NaturalnessIssue(
          span: 'hacer una decisión importante',
          naturalReplacement: 'tomar una decisión importante',
          explanation: 'Same collocation, wider span, same start.',
        );

        final result = mergeNaturalnessReview(
          originalText: 'placeholder',
          firstPassCorrectedText: 'Voy a hacer una decisión importante hoy.',
          naturalnessReview: const NaturalnessReview(
            hasNaturalnessIssue: true,
            issues: [issueShort, issueLong],
          ),
        );

        expect(
          result.finalCorrectedText,
          'Voy a hacer una decisión importante hoy.',
        );
        expect(result.appliedEdits, isEmpty);
        expect(result.skippedEdits, hasLength(2));
        expect(
          result.skippedEdits.map((edit) => edit.issue),
          [same(issueShort), same(issueLong)],
        );
        for (final skipped in result.skippedEdits) {
          expect(skipped.reason, NaturalnessMergeSkipReason.overlapsAnotherEdit);
        }
      },
    );

    test(
      'resolves a three-issue overlap chain: applies the two edits that '
      'don\'t overlap each other, and skips only the middle one that '
      'bridges both (issue #34)',
      () {
        // A = "hacer una decisión" (words 3-5), B = "una decisión
        // importante" (words 4-6, overlaps A), C = "importante hoy mismo"
        // (words 6-8, overlaps B but NOT A — A and C are adjacent, not
        // overlapping). B must not silently block C just because B itself
        // was skipped.
        const issueA = NaturalnessIssue(
          span: 'hacer una decisión',
          naturalReplacement: 'tomar una decisión',
          explanation: 'Wrong collocation for "decisión".',
        );
        const issueB = NaturalnessIssue(
          span: 'una decisión importante',
          naturalReplacement: 'una decisión crucial',
          explanation: 'Bridges A and C — must not be applied.',
        );
        const issueC = NaturalnessIssue(
          span: 'importante hoy mismo',
          naturalReplacement: 'clave desde mañana',
          explanation: 'Unrelated to A once B is out of the way.',
        );

        final result = mergeNaturalnessReview(
          originalText: 'placeholder',
          firstPassCorrectedText:
              'Voy a hacer una decisión importante hoy mismo.',
          naturalnessReview: const NaturalnessReview(
            hasNaturalnessIssue: true,
            issues: [issueA, issueB, issueC],
          ),
        );

        expect(
          result.finalCorrectedText,
          'Voy a tomar una decisión clave desde mañana.',
        );
        expect(result.appliedEdits, hasLength(2));
        expect(
          result.appliedEdits.map((edit) => edit.issue),
          [same(issueA), same(issueC)],
        );
        expect(result.skippedEdits, hasLength(1));
        expect(result.skippedEdits.single.issue, same(issueB));
        expect(
          result.skippedEdits.single.reason,
          NaturalnessMergeSkipReason.overlapsAnotherEdit,
        );
      },
    );

    test('preserves the review\'s issue order in skippedEdits even when '
        'reasons come from different resolution phases', () {
      const issueNotFound = NaturalnessIssue(
        span: 'nunca aparece',
        naturalReplacement: 'x',
        explanation: 'Not present at all.',
      );
      const issueLate = NaturalnessIssue(
        span: 'una decisión importante',
        naturalReplacement: 'una decisión clave',
        explanation: 'Overlaps the other candidate.',
      );
      const issueEarly = NaturalnessIssue(
        span: 'hacer una decisión',
        naturalReplacement: 'tomar una decisión',
        explanation: 'Wrong collocation for "decisión".',
      );

      final result = mergeNaturalnessReview(
        originalText: 'placeholder',
        firstPassCorrectedText: 'Voy a hacer una decisión importante hoy.',
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issueNotFound, issueLate, issueEarly],
        ),
      );

      expect(result.skippedEdits, hasLength(2));
      expect(result.skippedEdits[0].issue, same(issueNotFound));
      expect(result.skippedEdits[1].issue, same(issueLate));
    });

    test(
      'finalCorrectedText is firstPassCorrectedText with only the safe '
      'edit spliced in — the unsafe (ambiguous) edit never touches the '
      'base at all (issue #37: first-pass text is the foundation; '
      'naturalness only ever modifies it when safe)',
      () {
        const firstPassCorrectedText =
            'Voy a hacer una decisión importante hoy, y vi tráfico y luego '
            'más tráfico.';

        const safeIssue = NaturalnessIssue(
          span: 'hacer una decisión',
          naturalReplacement: 'tomar una decisión',
          explanation: 'Wrong collocation for "decisión".',
        );
        const unsafeIssue = NaturalnessIssue(
          span: 'tráfico',
          naturalReplacement: 'tránsito',
          explanation: 'Tráfico as traffic is an anglicism.',
        );

        final result = mergeNaturalnessReview(
          originalText: 'placeholder',
          firstPassCorrectedText: firstPassCorrectedText,
          naturalnessReview: const NaturalnessReview(
            hasNaturalnessIssue: true,
            issues: [safeIssue, unsafeIssue],
          ),
        );

        // The safe edit built on top of the first-pass base.
        expect(result.finalCorrectedText, contains('tomar una decisión'));
        // The unsafe (ambiguous) edit never touched the base — the exact
        // first-pass wording survives untouched at that location.
        expect(
          result.finalCorrectedText,
          contains('vi tráfico y luego más tráfico'),
        );
        expect(result.skippedEdits, hasLength(1));
        expect(result.skippedEdits.single.issue, same(unsafeIssue));
        expect(
          result.skippedEdits.single.reason,
          NaturalnessMergeSkipReason.ambiguousSpan,
        );
      },
    );
  });

  group(
    'guards removed after review — regression coverage (issue #111)',
    () {
      test(
        'still applies a full-sentence naturalness fix where the whole '
        'sentence genuinely is the idiom being corrected — '
        '"Te llamo para atrás." -> "Te devuelvo la llamada.", a real '
        'benchmark fixture (naturalness-llamar-para-atras)',
        () {
          const issue = NaturalnessIssue(
            span: 'Te llamo para atrás.',
            naturalReplacement: 'Te devuelvo la llamada.',
            explanation: 'English-influenced "llamar para atrás".',
          );

          final result = mergeNaturalnessReview(
            originalText: 'placeholder',
            firstPassCorrectedText: 'Te llamo para atrás.',
            naturalnessReview: const NaturalnessReview(
              hasNaturalnessIssue: true,
              issues: [issue],
            ),
          );

          // A first version of this guard rejected any span covering 80%+
          // of firstPassCorrectedText, meant to catch a full-sentence
          // rewrite of an already-fine sentence (e.g. "Vi mucho tráfico
          // ayer." -> "Había mucho tráfico ayer.", also span == 100% of
          // the text). Review caught that both the bad case and this
          // genuinely correct one are span == 100% of the text —
          // mechanically indistinguishable by span breadth alone, so no
          // threshold can separate them. The guard was removed rather
          // than tuned; this test guards against reintroducing it.
          expect(result.finalCorrectedText, 'Te devuelvo la llamada.');
          expect(result.appliedEdits, hasLength(1));
          expect(result.skippedEdits, isEmpty);
        },
      );

      test(
        'still applies a legitimately long phrase-level naturalness fix '
        'covering most of a longer sentence',
        () {
          const issue = NaturalnessIssue(
            span: 'corriendo tarde para la reunión',
            naturalReplacement: 'llegando tarde a la reunión',
            explanation: 'English-influenced phrasing.',
          );

          final result = mergeNaturalnessReview(
            originalText: 'placeholder',
            firstPassCorrectedText:
                'Le dije a mi jefe que estoy corriendo tarde para la '
                'reunión de mañana.',
            naturalnessReview: const NaturalnessReview(
              hasNaturalnessIssue: true,
              issues: [issue],
            ),
          );

          expect(
            result.finalCorrectedText,
            'Le dije a mi jefe que estoy llegando tarde a la reunión de '
            'mañana.',
          );
          expect(result.appliedEdits, hasLength(1));
          expect(result.skippedEdits, isEmpty);
        },
      );

      test(
        'still applies a noun replacement that was once blocked by a '
        'contentWordReplaced guard — "su parte" -> "su informe". That '
        'guard tried to infer a meaning-changing rewrite from word shape '
        'alone, with no semantic understanding of whether the '
        'replacement was actually wrong; it was removed as not a '
        'deterministically provable safety check, so this now applies '
        'like any other single naturalness edit. This is a real, live '
        'over-rewrite risk, but it belongs at the prompt-design/live-'
        'evaluation level, not merge-layer guessing.',
        () {
          const issue = NaturalnessIssue(
            span: 'su parte',
            naturalReplacement: 'su informe',
            explanation: '"Informe" reads as more concrete in context.',
          );

          final result = mergeNaturalnessReview(
            originalText: 'placeholder',
            firstPassCorrectedText: 'Era necesario que enviara su parte.',
            naturalnessReview: const NaturalnessReview(
              hasNaturalnessIssue: true,
              issues: [issue],
            ),
          );

          expect(
            result.finalCorrectedText,
            'Era necesario que enviara su informe.',
          );
          expect(result.appliedEdits, hasLength(1));
          expect(result.skippedEdits, isEmpty);
        },
      );
    },
  );

  group('word-boundary span matching (issue #111)', () {
    test(
      'skips (as spanNotFound) rather than matching mid-word and '
      'duplicating a word — the "Fui a la la tienda" article-duplication '
      'artifact observed live',
      () {
        const issue = NaturalnessIssue(
          span: 'a tienda',
          naturalReplacement: 'a la tienda',
          explanation:
              'Naturalness reviewed the pre-first-pass text, which was '
              'still missing the article here.',
        );

        final result = mergeNaturalnessReview(
          originalText: 'Fui a tienda después del trabajo.',
          // First pass already inserted "la" — the only remaining
          // occurrence of the character sequence "a tienda" is the
          // trailing "a" of "la" followed by " tienda", not a standalone
          // "a" word. Without word-boundary awareness this resolves as a
          // single "match" and duplicates the article: "la la tienda".
          firstPassCorrectedText: 'Fui a la tienda después del trabajo.',
          naturalnessReview: const NaturalnessReview(
            hasNaturalnessIssue: true,
            issues: [issue],
          ),
        );

        expect(
          result.finalCorrectedText,
          'Fui a la tienda después del trabajo.',
        );
        expect(result.appliedEdits, isEmpty);
        expect(result.skippedEdits, hasLength(1));
        expect(result.skippedEdits.single.issue, same(issue));
        expect(
          result.skippedEdits.single.reason,
          NaturalnessMergeSkipReason.spanNotFound,
        );
      },
    );

    test(
      'still finds and applies the one genuine word-boundary match even '
      'when a mid-word decoy of the same substring exists elsewhere in '
      'the text — proves the guard narrows to the real match rather than '
      'just rejecting whenever more than one raw substring hit exists',
      () {
        const issue = NaturalnessIssue(
          span: 'a tienda',
          naturalReplacement: 'a la tienda',
          explanation: 'Missing article before "tienda".',
        );

        final result = mergeNaturalnessReview(
          originalText: 'placeholder',
          // Two raw substring hits for "a tienda": the genuine one at
          // "Voy a tienda" (standalone "a", a real word boundary), and a
          // decoy inside "fui a la tienda" (the trailing "a" of "la").
          // Only the first is a real match once filtered.
          firstPassCorrectedText:
              'Voy a tienda mañana, y ya fui a la tienda ayer.',
          naturalnessReview: const NaturalnessReview(
            hasNaturalnessIssue: true,
            issues: [issue],
          ),
        );

        expect(
          result.finalCorrectedText,
          'Voy a la tienda mañana, y ya fui a la tienda ayer.',
        );
        expect(result.appliedEdits, hasLength(1));
        expect(result.skippedEdits, isEmpty);
      },
    );
  });
}
