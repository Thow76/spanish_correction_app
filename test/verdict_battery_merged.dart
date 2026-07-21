// Merged verdict battery — measures the effect of the Stage 2/3 prompt
// edits (Edit A: "established" clarified as educated/written norm, not
// merely colloquial; Edit B: `dialectal` restricted to real
// confusion/offense risk, not ordinary regional preference; Edit C
// strengthened: mandatory acknowledgment of common-but-proscribed usage in
// Stage 3 feedback) against `stage2CategorizationSpanish`
// (lib/core/services/prompts/correction_prompt.dart).
//
// Two halves in one file, one report:
//
// - REUSED: `peninsular_norms_battery.dart`'s 21 cases, duplicated by value
//   verbatim (same reasoning that file gives for duplicating from
//   `stage2_categorization_harness.dart` — this file stays standalone and
//   disposable). Scored exactly as before: convergence only (do all 10 runs
//   agree with each other), no ground-truth catch rate. NOT rebuilt — text,
//   family, kind, and note are unchanged; only runsPerCase moves from 5 to
//   10 by running them through this file's shared harness instead.
//
// - NEW: 16 cases added this step — seeds probing constructions newly
//   relevant after Edit A/B (hodiernal preterite, "en la mañana", "entrar
//   a", a dative-clitic number-agreement trap, existential "haber"
//   pluralization, queísmo), four fixed-anchor controls that must not drift
//   as the prompt keeps changing, "se los dije" (new this step, decided
//   `error` this session), and three subcase-split families (leísmo by
//   animacy/gender/number, voseo, queísmo two-regime verbs) built as
//   matched pairs so the accepted-vs-nonstandard split is the only variable.
//   These score BOTH convergence AND a ground-truth catch rate
//   (acceptedVerdicts / expectedCategory), same as
//   stage2_categorization_harness.dart's `_ExpectedResult` pattern.
//
// One `_Case` type covers both halves: `acceptedVerdicts`/`expectedCategory`
// null means "convergence only, not scored" (the reused cases);
// non-null means "also score a catch rate" (the new cases). This is what
// lets a single aggregate/report function serve both without forking the
// file into two copies of the same machinery.
//
// Every seed's carrier sentence was written fresh for this file (Stage 2
// needs full-text context, not a bare phrase), but no additional
// phenomenon beyond Step 2's locked case list was invented — see the
// per-case notes below for the reasoning on cases whose expected verdict
// required interpretation (LEISMO-TRAP-1, SLD-1).
//
// No catalog files (`spanish_regional_variation_catalog.md` or similar)
// exist anywhere in this repo — checked `docs/` and the repo root before
// building this file. Proceeded with Step 2's locked list as the floor,
// per instruction.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/verdict_battery_merged.dart --exclude-tags live
//
// Run everything, including the live battery (costs real API calls — 37
// cases * 10 runs = 370 calls):
//   OPENAI_API_KEY=sk-... flutter test test/verdict_battery_merged.dart --timeout none
//
// Writes a report to docs/verdict_battery_merged.md (override with
// --dart-define=VERDICT_BATTERY_OUTPUT=...). Override run count per case
// with --dart-define=VERDICT_BATTERY_RUNS_PER_CASE=... (default 10).
// Override the model with --dart-define=VERDICT_BATTERY_MODEL=... (default
// 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerCase = int.fromEnvironment(
  'VERDICT_BATTERY_RUNS_PER_CASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'VERDICT_BATTERY_OUTPUT',
  defaultValue: 'docs/verdict_battery_merged.md',
);

const String verdictBatteryModel = String.fromEnvironment(
  'VERDICT_BATTERY_MODEL',
  defaultValue: 'gpt-5.5',
);

const int callDelayMs = int.fromEnvironment(
  'VERDICT_BATTERY_CALL_DELAY_MS',
  defaultValue: 750,
);

const Set<String> _validVerdicts = {'error', 'dialectal', 'not_an_error'};

/// Which section of the report a case belongs to. The first four values are
/// the reused peninsular-norms families; the rest are new this step.
enum _Section {
  paraDestination,
  cogerVocab,
  ordinaryVocab,
  softRegister,
  seeds,
  controls,
  newThisStep,
  leismoDirectObject,
  voseo,
  queismoTwoRegime,
}

String _sectionHeading(_Section section) => switch (section) {
  _Section.paraDestination => 'Reused: para + destination',
  _Section.cogerVocab => 'Reused: coger-type vocabulary',
  _Section.ordinaryVocab => 'Reused: ordinary regional vocabulary pairs',
  _Section.softRegister => 'Reused: soft-register / circumlocution (BP-001-style)',
  _Section.seeds => 'New: seeds',
  _Section.controls => 'New: controls (fixed anchors, must not drift)',
  _Section.newThisStep => 'New this step',
  _Section.leismoDirectObject => 'New: subcase split — leísmo by gender/number/animacy',
  _Section.voseo => 'New: subcase split — voseo',
  _Section.queismoTwoRegime => 'New: subcase split — queísmo two-regime verbs',
};

bool _isReusedSection(_Section section) => switch (section) {
  _Section.paraDestination ||
  _Section.cogerVocab ||
  _Section.ordinaryVocab ||
  _Section.softRegister => true,
  _ => false,
};

/// A reused case's role within its family — only meaningful for the four
/// reused sections; null for every new case. Drives the anchor/transfer/
/// negative rollup table, same metric as peninsular_norms_battery.dart.
enum _ReusedKind { anchor, transfer, negative }

String _kindLabel(_ReusedKind kind) => switch (kind) {
  _ReusedKind.anchor => 'Anchor',
  _ReusedKind.transfer => 'Transfer',
  _ReusedKind.negative => 'Negative',
};

/// One test case: a full text plus a single flagged phrase.
///
/// [acceptedVerdicts] null means "reused as-is, convergence-only" (the 21
/// peninsular cases — not rebuilt, not given a ground truth they didn't
/// already have). Non-null means "also score a catch rate against this
/// ground truth" (every new case this step). Same split for
/// [expectedCategory].
class _Case {
  const _Case({
    required this.id,
    required this.section,
    required this.text,
    required this.flaggedPhrase,
    required this.note,
    this.reusedKind,
    this.acceptedVerdicts,
    this.expectedCategory,
  });

  final String id;
  final _Section section;
  final String text;
  final String flaggedPhrase;
  final String note;
  final _ReusedKind? reusedKind;
  final Set<String>? acceptedVerdicts;
  final String? expectedCategory;
}

const List<_Case> _cases = [
  // ── REUSED: para + destination (peninsular_norms_battery.dart, verbatim)
  _Case(
    id: 'PD-anchor',
    section: _Section.paraDestination,
    reusedKind: _ReusedKind.anchor,
    text:
        'Ayer fui al supermercado para comprar pan y después volví para casa '
        'para preparar la cena.',
    flaggedPhrase: 'volví para casa',
    note:
        'Same text as ES-1 in stage2_categorization_harness.dart, reused '
        'verbatim as the anchor for continuity with the already-measured '
        'baseline (30% verdict convergence live, per '
        'docs/stage2_categorization_harness.md).',
  ),
  _Case(
    id: 'PD-T1',
    section: _Section.paraDestination,
    reusedKind: _ReusedKind.transfer,
    text: 'Ya era tarde cuando vine para casa.',
    flaggedPhrase: 'vine para casa',
    note: 'Same "para + destination" construction, different verb.',
  ),
  _Case(
    id: 'PD-T2',
    section: _Section.paraDestination,
    reusedKind: _ReusedKind.transfer,
    text: 'Subió para la oficina en cuanto llegó.',
    flaggedPhrase: 'Subió para la oficina',
    note: 'Same construction, different destination and verb.',
  ),
  _Case(
    id: 'PD-T3',
    section: _Section.paraDestination,
    reusedKind: _ReusedKind.transfer,
    text: 'Al terminar el partido, regresamos para el pueblo.',
    flaggedPhrase: 'regresamos para el pueblo',
    note: 'Same construction, different destination and verb.',
  ),
  _Case(
    id: 'PD-neg',
    section: _Section.paraDestination,
    reusedKind: _ReusedKind.negative,
    text: 'Ya era tarde cuando volví a casa.',
    flaggedPhrase: 'volví a casa',
    note:
        'The accepted Peninsular form of the anchor construction (its own '
        'corrected_phrase). Must not be flagged at all.',
  ),

  // ── REUSED: coger-type vocabulary (verbatim) ────────────────────────────
  _Case(
    id: 'COG-anchor',
    section: _Section.cogerVocab,
    reusedKind: _ReusedKind.anchor,
    text: 'Voy a coger el autobús para ir al centro.',
    flaggedPhrase: 'coger el autobús',
    note:
        'Same text as the "coger" case in stage2_categorization_harness.dart '
        '— the canonical dialectal case (100% convergence live).',
  ),
  _Case(
    id: 'COG-T1',
    section: _Section.cogerVocab,
    reusedKind: _ReusedKind.transfer,
    text: 'Espera, voy a coger las llaves antes de salir.',
    flaggedPhrase: 'coger las llaves',
    note: 'Same coger-is-vulgar-in-parts-of-Latin-America split, different object.',
  ),
  _Case(
    id: 'COG-T2',
    section: _Section.cogerVocab,
    reusedKind: _ReusedKind.transfer,
    text: 'Vamos a coger un taxi para llegar antes.',
    flaggedPhrase: 'coger un taxi',
    note: 'Same split, different vehicle.',
  ),
  _Case(
    id: 'COG-T3',
    section: _Section.cogerVocab,
    reusedKind: _ReusedKind.transfer,
    text: 'Con esta lluvia vas a coger frío.',
    flaggedPhrase: 'coger frío',
    note: 'Same split, idiomatic non-transport use of "coger".',
  ),
  _Case(
    id: 'COG-neg',
    section: _Section.cogerVocab,
    reusedKind: _ReusedKind.negative,
    text: 'Vamos a tomar el autobús para ir al centro.',
    flaggedPhrase: 'tomar el autobús',
    note:
        'Mirrors PD-neg: reuses the pan-dialectal accepted form (the '
        'anchor\'s own corrected_phrase) rather than a same-verb-different-'
        'context "coger" sentence. In the varieties where "coger" is '
        'taboo, the stigma generally attaches to the verb itself, not to '
        'specific senses of it — so a "coger + [some other object]" '
        'negative (e.g. "coger un libro de la mesa") would not reliably '
        'test anything; it could just as easily read as another instance '
        'of the same split. "Tomar el autobús" is accepted everywhere, so '
        'a flag on it is an unambiguous overcorrection signal.',
  ),

  // ── REUSED: ordinary regional vocabulary pairs (verbatim) ───────────────
  _Case(
    id: 'VOC-anchor-ordenador',
    section: _Section.ordinaryVocab,
    reusedKind: _ReusedKind.anchor,
    text: 'Voy a usar el ordenador en la oficina.',
    flaggedPhrase: 'ordenador',
    note:
        'Same text as the "ordenador" case in '
        'stage2_categorization_harness.dart.',
  ),
  _Case(
    id: 'VOC-anchor-coche',
    section: _Section.ordinaryVocab,
    reusedKind: _ReusedKind.anchor,
    text: 'Aparqué el coche cerca de la oficina.',
    flaggedPhrase: 'coche',
    note: 'Same text as the "coche" case in stage2_categorization_harness.dart.',
  ),
  _Case(
    id: 'VOC-anchor-carro',
    section: _Section.ordinaryVocab,
    reusedKind: _ReusedKind.anchor,
    text: 'Lavé el carro el fin de semana.',
    flaggedPhrase: 'carro',
    note: 'Same text as the "carro" case in stage2_categorization_harness.dart.',
  ),
  _Case(
    id: 'VOC-T1-gafas',
    section: _Section.ordinaryVocab,
    reusedKind: _ReusedKind.transfer,
    text: 'No veo bien sin mis gafas.',
    flaggedPhrase: 'gafas',
    note: 'Same ordinary-regional-pair shape: gafas (Spain) / lentes (Latin America).',
  ),
  _Case(
    id: 'VOC-T2-movil',
    section: _Section.ordinaryVocab,
    reusedKind: _ReusedKind.transfer,
    text: 'Se me quedó el móvil en casa.',
    flaggedPhrase: 'móvil',
    note: 'móvil (Spain) / celular (Latin America).',
  ),
  _Case(
    id: 'VOC-T3-piso',
    section: _Section.ordinaryVocab,
    reusedKind: _ReusedKind.transfer,
    text: 'Alquilamos un piso cerca del centro.',
    flaggedPhrase: 'piso',
    note: 'piso (Spain) / apartamento (Latin America).',
  ),
  _Case(
    id: 'VOC-neg-libreria',
    section: _Section.ordinaryVocab,
    reusedKind: _ReusedKind.negative,
    text: 'Fui a la librería a devolver el libro que pedí prestado.',
    flaggedPhrase: 'librería',
    note:
        'Looks like a regional-pair candidate but is a genuine false-'
        'friend error in every variety — no established dialect uses '
        '"librería" to mean "library" (it means "bookstore" everywhere; '
        '"biblioteca" is library everywhere). Must come back as error, '
        'not dialectal/not_an_error.',
  ),

  // ── REUSED: soft-register / circumlocution (BP-001-style) (verbatim) ───
  _Case(
    id: 'SR-anchor',
    section: _Section.softRegister,
    reusedKind: _ReusedKind.anchor,
    text: 'En el gimnasio hay una máquina de correr nueva.',
    flaggedPhrase: 'máquina de correr',
    note:
        'The Portuguese prompt has a dedicated soft-register bullet '
        '(_ptSoftRegisterBullet) built around exactly this phrase '
        '("máquina de correr" -> "esteira"); stage2CategorizationSpanish '
        'has no Spanish equivalent bullet. This family tests whether the '
        'existing calque/Natural Language machinery catches the same kind '
        'of issue in Spanish ("máquina de correr" -> "cinta de correr") '
        'without one.',
  ),
  _Case(
    id: 'SR-T1',
    section: _Section.softRegister,
    reusedKind: _ReusedKind.transfer,
    text: 'Compramos una máquina de lavar la ropa.',
    flaggedPhrase: 'máquina de lavar la ropa',
    note: 'Same circumlocution-for-an-everyday-appliance shape, vs. "lavadora".',
  ),
  _Case(
    id: 'SR-T2',
    section: _Section.softRegister,
    reusedKind: _ReusedKind.transfer,
    text: 'Necesito un aparato para calentar la comida.',
    flaggedPhrase: 'aparato para calentar la comida',
    note: 'Same shape, vs. "microondas".',
  ),
  _Case(
    id: 'SR-neg',
    section: _Section.softRegister,
    reusedKind: _ReusedKind.negative,
    text: 'Puse el aire acondicionado porque hacía calor.',
    flaggedPhrase: 'aire acondicionado',
    note:
        '"Aire acondicionado" is itself the standard idiomatic phrase — '
        'there is no shorter single-word native term to prefer instead. '
        'Flagging it as an overly wordy circumlocution would be '
        'overcorrection.',
  ),

  // ── NEW: seeds ───────────────────────────────────────────────────────────
  _Case(
    id: 'HP-1',
    section: _Section.seeds,
    text: 'Hoy comí en casa de mis abuelos.',
    flaggedPhrase: 'Hoy comí',
    acceptedVerdicts: {'not_an_error', 'dialectal'},
    note:
        'Hodiernal preterite: simple past for a same-day action. Standard '
        'in Latin American and Canary Islands Spanish; Peninsular spoken '
        'norm generally prefers "he comido hoy" instead, but both are '
        'grammatical. A tense preference, not a confusion/offense risk — '
        'per Edit B, this is the kind of split that should land as '
        'not_an_error (or, if the model insists on flagging the regional '
        'split at all, dialectal) but never error.',
  ),
  _Case(
    id: 'TEMP-1',
    section: _Section.seeds,
    text: 'Voy a llamarte en la mañana.',
    flaggedPhrase: 'en la mañana',
    acceptedVerdicts: {'not_an_error'},
    note:
        '"en la mañana" (Latin America) vs. "por la mañana" (Spain) — a '
        'preposition-choice regional preference, one of Edit B\'s named '
        'examples of what must be not_an_error, not dialectal.',
  ),
  _Case(
    id: 'ENTRA-1',
    section: _Section.seeds,
    text: 'Ayer entramos al cine a las ocho.',
    flaggedPhrase: 'entramos al cine',
    acceptedVerdicts: {'not_an_error'},
    note:
        '"entrar a" vs. the traditionally prescribed "entrar en" — widely '
        'used and accepted across dialects, expected not_an_error per the '
        'locked case list.',
  ),
  _Case(
    id: 'LEISMO-TRAP-1',
    section: _Section.seeds,
    text: 'Ayer le dije a mis padres que llegaría tarde.',
    flaggedPhrase: 'le dije a mis padres',
    acceptedVerdicts: {'error'},
    expectedCategory: 'Grammar',
    note:
        'Interpretation note: "decir a alguien" takes an indirect-object '
        'clitic (le/les), and "mis padres" is plural, so the correct '
        'clitic is "les", not "le" — a plain number-agreement error under '
        'every norm, not a recognized dialectal leísmo split (leísmo/'
        'laísmo debates concern DIRECT-object clitics, e.g. "le vi" for '
        '"lo vi"; the indirect-object clitic here is not in dispute in '
        'any variety). This is a deliberate trap: the word "leísmo" in its '
        'label superficially resembles the accepted-vs-nonstandard split '
        'tested by the LEISMO-DO-* cases below, but the actual phenomenon '
        'is a hard agreement violation every established norm rejects — '
        'exactly the case Edit A\'s "established means the educated, '
        'written norm" clarification is meant to keep as error.',
  ),
  _Case(
    id: 'HABER-1',
    section: _Section.seeds,
    text: 'En la calle habían muchos coches aparcados.',
    flaggedPhrase: 'habían muchos coches',
    acceptedVerdicts: {'error'},
    expectedCategory: 'Grammar',
    note:
        'Existential "haber" pluralized to agree with its complement — '
        'proscribed by every established norm despite being extremely '
        'common in casual speech across all dialects. The canonical case '
        'for Stage 3\'s strengthened Edit C: common-but-proscribed, so the '
        'explanation MUST acknowledge how common it is while still '
        'marking it error.',
  ),
  _Case(
    id: 'QUEISMO-1',
    section: _Section.seeds,
    text: 'Me alegro que vinieras a la fiesta.',
    flaggedPhrase: 'Me alegro que vinieras',
    acceptedVerdicts: {'error'},
    expectedCategory: 'Grammar',
    note:
        '"Alegrarse" governs "de que"; omitting the required "de" '
        '(queísmo) is proscribed in every established variety, however '
        'common colloquially — expected error throughout, contrasted '
        'against QUEISMO-informar below where the governing verb '
        'genuinely takes bare "que".',
  ),

  // ── NEW: controls (fixed anchors, must not drift) ───────────────────────
  _Case(
    id: 'CTRL-para',
    section: _Section.controls,
    text: 'Cuando termino el trabajo, voy para casa en autobús.',
    flaggedPhrase: 'voy para casa',
    acceptedVerdicts: {'not_an_error'},
    note:
        'Same text as ES-2 in stage2_categorization_harness.dart, which '
        'accepted {dialectal, not_an_error} for this phrase pre-Edit-B. '
        'This control tightens the expectation to not_an_error only, per '
        'the locked case list — "voy para casa" carries no real confusion/'
        'offense risk (unlike coger), so after Edit B it should no longer '
        'plausibly land as dialectal.',
  ),
  _Case(
    id: 'CTRL-dequeismo',
    section: _Section.controls,
    text: 'Yo pienso de que deberíamos hablar con ella.',
    flaggedPhrase: 'pienso de que',
    acceptedVerdicts: {'error'},
    expectedCategory: 'Grammar',
    note:
        'Dequeísmo: inserting an unwanted "de" before "que" where the verb '
        'takes bare "que". Fixed anchor, must stay error.',
  ),
  _Case(
    id: 'CTRL-laismo',
    section: _Section.controls,
    text: 'Ayer la dije que viniera a la reunión.',
    flaggedPhrase: 'la dije que viniera',
    acceptedVerdicts: {'error'},
    expectedCategory: 'Grammar',
    note:
        'Laísmo: "la" used for an indirect-object clitic where "le" is '
        'required. Unlike masculine-singular direct-object leísmo (RAE-'
        'tolerated, see LEISMO-DO-accepted), laísmo is not accepted by any '
        'standard register in any variety. Must be error, never '
        'dialectal, per the locked case list.',
  ),
  _Case(
    id: 'CTRL-coger',
    section: _Section.controls,
    text: 'Voy a coger el autobús para ir al centro.',
    flaggedPhrase: 'coger el autobús',
    acceptedVerdicts: {'dialectal'},
    expectedCategory: 'Other',
    note:
        'Same text as COG-anchor above (reused), duplicated deliberately '
        'as an explicit ground-truth-scored control per the locked case '
        'list — COG-anchor is scored convergence-only, this entry adds a '
        'hard catch-rate check on the same phrase as the canonical '
        'real-confusion/offense dialectal case that must survive Edit B\'s '
        'tightened restraint line.',
  ),

  // ── NEW: this step ───────────────────────────────────────────────────────
  _Case(
    id: 'SLD-1',
    section: _Section.newThisStep,
    text: 'Mis padres querían saber el secreto y se los dije.',
    flaggedPhrase: 'se los dije',
    acceptedVerdicts: {'error'},
    expectedCategory: 'Grammar',
    note:
        '"El secreto" is singular, so the correct clitic is "se lo dije"; '
        '"se los" wrongly extends plural marking from the (plural) '
        'indirect-object referent onto the (singular) direct-object '
        'clitic — a widespread but proscribed clitic-agreement error. '
        'Decided error this session (per the task instruction); included '
        'here as a fixed ground truth for future runs.',
  ),

  // ── NEW: subcase split — leísmo by gender/number/animacy ────────────────
  _Case(
    id: 'LEISMO-DO-accepted',
    section: _Section.leismoDirectObject,
    text: 'Ayer vi a Juan en el parque y le saludé.',
    flaggedPhrase: 'le saludé',
    acceptedVerdicts: {'not_an_error', 'dialectal'},
    note:
        'Masculine-singular-animate direct-object leísmo ("le" for "lo") '
        'is RAE-tolerated — standard in much of Spain. Must not be error. '
        'Minimal pair with LEISMO-DO-nonstandard below: same sentence '
        'frame, only the referent\'s gender differs.',
  ),
  _Case(
    id: 'LEISMO-DO-nonstandard',
    section: _Section.leismoDirectObject,
    text: 'Ayer vi a Marta en el parque y le saludé.',
    flaggedPhrase: 'le saludé',
    acceptedVerdicts: {'error'},
    expectedCategory: 'Grammar',
    note:
        'Same frame as LEISMO-DO-accepted, feminine referent: "le" for a '
        'feminine direct object ("la saludé") is not the RAE-tolerated '
        'case — no established norm accepts feminine-object leísmo. This '
        'is the split the family exists to test: does the model draw the '
        'accepted/nonstandard line at animacy+gender+number, or does it '
        'treat "leísmo" as a single undifferentiated dialectal bucket?',
  ),

  // ── NEW: subcase split — voseo ───────────────────────────────────────────
  _Case(
    id: 'VOSEO-valid',
    section: _Section.voseo,
    text: 'Vos tenés razón en eso.',
    flaggedPhrase: 'Vos tenés',
    acceptedVerdicts: {'not_an_error'},
    note:
        'Standard Rioplatense voseo conjugation. A pronoun-system regional '
        'preference — per Edit B\'s named example, expected not_an_error.',
  ),
  _Case(
    id: 'VOSEO-hypercorrected',
    section: _Section.voseo,
    text: 'Vos comistes ayer bien tarde.',
    flaggedPhrase: 'Vos comistes',
    acceptedVerdicts: {'error'},
    expectedCategory: 'Grammar',
    note:
        '"Comistes" (with the extra -s) is a hypercorrected/nonstandard '
        'voseo preterite; the correct voseo form is "comiste". Wrong even '
        'within voseo-using varieties themselves — must be error, not '
        'excused as "just voseo".',
  ),

  // ── NEW: subcase split — queísmo two-regime verbs ───────────────────────
  _Case(
    id: 'QUEISMO-informar',
    section: _Section.queismoTwoRegime,
    text: 'Me informó que llegaría tarde.',
    flaggedPhrase: 'informó que',
    acceptedVerdicts: {'not_an_error'},
    note:
        '"Informar" genuinely takes bare "que" — contrast case against '
        'QUEISMO-1\'s "me alegro que" (which requires "de que"). Tests '
        'whether the model applies the de-que/que-alone distinction '
        'per-verb rather than pattern-matching on the surface "verb + que" '
        'shape.',
  ),
];

/// Lowercases and strips Spanish diacritics so span matching survives the
/// model correcting the accent itself. Duplicated by value from
/// stage2_categorization_harness.dart's `_normalizeForMatch` — this file
/// stays standalone.
String _normalizeForMatch(String text) {
  return text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàäâã]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöôõ]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('ç', 'c');
}

/// Case/diacritic-insensitive containment check in either direction.
/// Duplicated by value from stage2_categorization_harness.dart's
/// `_normalizedOverlap`.
bool _normalizedOverlap(String a, String b) {
  final normalizedA = _normalizeForMatch(a);
  final normalizedB = _normalizeForMatch(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) {
    return false;
  }
  return normalizedA.contains(normalizedB) || normalizedB.contains(normalizedA);
}

/// Builds the user-message content sent alongside `stage2CategorizationSpanish`:
/// the case's full text plus a JSON array containing its single flagged
/// phrase. Pure — no network.
String _buildUserContent({required String fullText, required String flaggedPhrase}) {
  return '''
Learner's text:
$fullText

Flagged phrases:
${jsonEncode([flaggedPhrase])}
''';
}

/// One flagged phrase's categorization, as returned by Stage 2.
class _CategorizationResult {
  const _CategorizationResult({
    required this.originalPhrase,
    required this.correctedPhrase,
    required this.occurrence,
    required this.category,
    required this.verdict,
  });

  final String originalPhrase;
  final String correctedPhrase;
  final int occurrence;
  final String? category;
  final String verdict;
}

/// Builds the raw JSON-able request body for one OpenAI chat completions
/// call. Duplicated by value from stage2_categorization_harness.dart's
/// `buildChatCompletionsBody`.
Map<String, Object?> _buildChatCompletionsBody({
  required String model,
  required String systemPrompt,
  required String userText,
}) {
  return {
    'model': model,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userText},
    ],
  };
}

/// Extracts the assistant's reply text from a decoded chat completions
/// response body. Duplicated by value from
/// stage2_categorization_harness.dart's `extractReplyText`.
String _extractReplyText(Map<String, Object?> decodedBody) {
  final choices = decodedBody['choices'];
  if (choices is! List || choices.isEmpty) {
    throw const FormatException('Chat completions response has no choices.');
  }

  final firstChoice = choices.first;
  if (firstChoice is! Map<String, Object?>) {
    throw const FormatException('Chat completions choice is not an object.');
  }

  final message = firstChoice['message'];
  if (message is! Map<String, Object?>) {
    throw const FormatException('Chat completions choice has no message.');
  }

  final content = message['content'];
  if (content is! String || content.trim().isEmpty) {
    throw const FormatException('Chat completions message has no content.');
  }

  return content.trim();
}

/// Parses a Stage 2 reply into [_CategorizationResult]s. Duplicated by
/// value from stage2_categorization_harness.dart's
/// `_parseCategorizationArray`, same tolerance for Markdown fences /
/// commentary.
List<_CategorizationResult> _parseCategorizationArray(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('[');
  final end = trimmed.lastIndexOf(']');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON array found in Stage 2 reply.');
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException('Stage 2 reply array did not decode to a List.');
  }

  return decoded.map((element) {
    if (element is! Map<String, Object?>) {
      throw FormatException(
        'Stage 2 reply array contained a non-object element: $element',
      );
    }

    final originalPhrase = element['original_phrase'];
    final correctedPhrase = element['corrected_phrase'];
    final occurrence = element['occurrence'];
    final category = element['category'];
    final verdict = element['verdict'];

    if (originalPhrase is! String || originalPhrase.isEmpty) {
      throw FormatException(
        'Stage 2 result missing/invalid original_phrase: $element',
      );
    }
    if (correctedPhrase is! String) {
      throw FormatException(
        'Stage 2 result missing/invalid corrected_phrase: $element',
      );
    }
    if (occurrence is! num || occurrence != occurrence.roundToDouble()) {
      throw FormatException('Stage 2 result missing/invalid occurrence: $element');
    }
    if (category != null && category is! String) {
      throw FormatException('Stage 2 result has a non-string category: $element');
    }
    if (verdict is! String || !_validVerdicts.contains(verdict)) {
      throw FormatException('Stage 2 result has an invalid verdict: $element');
    }

    return _CategorizationResult(
      originalPhrase: originalPhrase,
      correctedPhrase: correctedPhrase,
      occurrence: occurrence.round(),
      category: category as String?,
      verdict: verdict,
    );
  }).toList();
}

/// Finds the result in [results] whose `originalPhrase` overlaps
/// [flaggedPhrase], or null if Stage 2 didn't return a matching object.
_CategorizationResult? _matchResultFor(
  List<_CategorizationResult> results,
  String flaggedPhrase,
) {
  for (final result in results) {
    if (_normalizedOverlap(flaggedPhrase, result.originalPhrase)) {
      return result;
    }
  }
  return null;
}

/// One run's outcome for one case.
class _RunRecord {
  const _RunRecord({required this.caseId, required this.runIndex, this.result, this.error});

  final String caseId;
  final int runIndex;
  final _CategorizationResult? result;
  final Object? error;

  bool get isError => error != null;
}

_RunRecord _buildRunRecord({
  required _Case testCase,
  required int runIndex,
  required List<_CategorizationResult> results,
}) {
  return _RunRecord(
    caseId: testCase.id,
    runIndex: runIndex,
    result: _matchResultFor(results, testCase.flaggedPhrase),
  );
}

_RunRecord _errorRunRecord({
  required _Case testCase,
  required int runIndex,
  required Object error,
}) {
  return _RunRecord(caseId: testCase.id, runIndex: runIndex, error: error);
}

String _distKey(String? value) => value ?? '(none)';

/// Aggregated results for one case across all its non-error runs.
///
/// [verdictCaughtCount] / [categoryCaughtCount] are null when the case has
/// no [_Case.acceptedVerdicts] / [_Case.expectedCategory] — i.e. for the 21
/// reused cases, which are scored convergence-only, exactly as they were in
/// peninsular_norms_battery.dart.
class _Aggregate {
  const _Aggregate({
    required this.caseId,
    required this.totalRuns,
    required this.errorRuns,
    required this.okRunCount,
    required this.verdictDistribution,
    required this.categoryDistribution,
    required this.verdictConvergencePct,
    required this.categoryConvergencePct,
    required this.verdictCaughtCount,
    required this.categoryCaughtCount,
  });

  final String caseId;
  final int totalRuns;
  final int errorRuns;
  final int okRunCount;
  final Map<String, int> verdictDistribution;
  final Map<String, int> categoryDistribution;
  final double verdictConvergencePct;
  final double categoryConvergencePct;
  final int? verdictCaughtCount;
  final int? categoryCaughtCount;
}

int _maxCount(Map<String, int> distribution) {
  if (distribution.isEmpty) {
    return 0;
  }
  return distribution.values.reduce((a, b) => a > b ? a : b);
}

double _convergencePct(Map<String, int> distribution, int total) {
  if (total == 0 || distribution.isEmpty) {
    return 0.0;
  }
  return _maxCount(distribution) / total * 100;
}

_Aggregate _aggregateCase(_Case testCase, List<_RunRecord> records) {
  final okRecords = records.where((r) => !r.isError).toList();
  final errorCount = records.length - okRecords.length;

  final verdictDist = <String, int>{};
  final categoryDist = <String, int>{};
  int? verdictCaught = testCase.acceptedVerdicts != null ? 0 : null;
  int? categoryCaught = testCase.expectedCategory != null ? 0 : null;

  for (final record in okRecords) {
    final verdictKey = record.result == null ? '(missing)' : record.result!.verdict;
    verdictDist[verdictKey] = (verdictDist[verdictKey] ?? 0) + 1;

    final categoryKey =
        record.result == null ? '(missing)' : _distKey(record.result!.category);
    categoryDist[categoryKey] = (categoryDist[categoryKey] ?? 0) + 1;

    if (testCase.acceptedVerdicts != null &&
        record.result != null &&
        testCase.acceptedVerdicts!.contains(record.result!.verdict)) {
      verdictCaught = (verdictCaught ?? 0) + 1;
    }
    if (testCase.expectedCategory != null &&
        record.result != null &&
        record.result!.category == testCase.expectedCategory) {
      categoryCaught = (categoryCaught ?? 0) + 1;
    }
  }

  return _Aggregate(
    caseId: testCase.id,
    totalRuns: records.length,
    errorRuns: errorCount,
    okRunCount: okRecords.length,
    verdictDistribution: verdictDist,
    categoryDistribution: categoryDist,
    verdictConvergencePct: _convergencePct(verdictDist, okRecords.length),
    categoryConvergencePct: _convergencePct(categoryDist, okRecords.length),
    verdictCaughtCount: verdictCaught,
    categoryCaughtCount: categoryCaught,
  );
}

String _percentLabel(int count, int total) {
  if (total == 0) {
    return '0.0% (0/0)';
  }
  final pct = (count / total * 100).toStringAsFixed(1);
  return '$pct% ($count/$total)';
}

String _describeDistribution(Map<String, int> counts) {
  if (counts.isEmpty) {
    return '(none)';
  }
  final entries = counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((e) => '${e.key}: ${e.value}').join(', ');
}

String _describeError(Object error) => error.toString();

String _describeRun(_RunRecord record) {
  final prefix = 'Run ${record.runIndex}';
  if (record.isError) {
    return '- $prefix: ERROR — ${_describeError(record.error!)}';
  }
  final result = record.result;
  if (result == null) {
    return '- $prefix: (no matching result returned)';
  }
  return '- $prefix: verdict=${result.verdict}, category=${_distKey(result.category)}, '
      'occurrence=${result.occurrence}';
}

/// One reused family's anchor/transfer/negative convergence rollup — same
/// metric as peninsular_norms_battery.dart's `_FamilyRollup`.
class _FamilyRollup {
  const _FamilyRollup({
    required this.section,
    required this.anchorPct,
    required this.transferPct,
    required this.negativePct,
  });

  final _Section section;
  final double anchorPct;
  final double transferPct;
  final double negativePct;

  double get gap => anchorPct - transferPct;
}

double _average(Iterable<double> values) {
  final list = values.toList();
  if (list.isEmpty) {
    return 0.0;
  }
  return list.reduce((a, b) => a + b) / list.length;
}

_FamilyRollup _rollupFamily(
  _Section section,
  List<_Case> cases,
  Map<String, _Aggregate> aggregatesById,
) {
  double pctFor(_ReusedKind kind) => _average(
    cases
        .where((c) => c.section == section && c.reusedKind == kind)
        .map((c) => aggregatesById[c.id]!.verdictConvergencePct),
  );

  return _FamilyRollup(
    section: section,
    anchorPct: pctFor(_ReusedKind.anchor),
    transferPct: pctFor(_ReusedKind.transfer),
    negativePct: pctFor(_ReusedKind.negative),
  );
}

/// Builds the full markdown report: header, one section per `_Section`
/// (each case's metadata, verdict/category distributions with convergence
/// — plus a catch rate wherever the case specifies ground truth — and
/// run-by-run detail), then the reused-family convergence rollup table,
/// then a new-cases catch-rate summary table.
///
/// Pure — takes already-collected [recordsByCaseId] rather than making any
/// calls itself, so it's golden-testable against synthetic data.
String _buildReport({
  required String model,
  required int runsPerCase,
  required DateTime generatedAt,
  required List<_Case> cases,
  required Map<String, List<_RunRecord>> recordsByCaseId,
  String? commit,
}) {
  final aggregatesById = {
    for (final testCase in cases)
      testCase.id: _aggregateCase(testCase, recordsByCaseId[testCase.id] ?? const []),
  };

  final report = StringBuffer()
    ..writeln('# Merged Verdict Battery')
    ..writeln()
    ..writeln('Model: `$model`  ');
  if (commit != null) {
    report.writeln('Commit: `$commit`  ');
  }
  report
    ..writeln('Generated: ${generatedAt.toIso8601String()}  ')
    ..writeln('Runs per case: $runsPerCase')
    ..writeln();

  for (final section in _Section.values) {
    final sectionCases = cases.where((c) => c.section == section).toList();
    if (sectionCases.isEmpty) {
      continue;
    }

    report
      ..writeln('## ${_sectionHeading(section)}')
      ..writeln();

    for (final testCase in sectionCases) {
      final aggregate = aggregatesById[testCase.id]!;
      final records = recordsByCaseId[testCase.id] ?? const <_RunRecord>[];

      final kindSuffix =
          testCase.reusedKind != null ? ' (${_kindLabel(testCase.reusedKind!)})' : '';

      final verdictScoreSuffix = testCase.acceptedVerdicts == null
          ? ''
          : ' (accepted: ${(testCase.acceptedVerdicts!.toList()..sort()).join('/')}) '
                '-> caught ${_percentLabel(aggregate.verdictCaughtCount!, aggregate.okRunCount)}';

      final categoryScoreSuffix = testCase.expectedCategory == null
          ? ''
          : ' (expected ${testCase.expectedCategory}) '
                '-> caught ${_percentLabel(aggregate.categoryCaughtCount!, aggregate.okRunCount)}';

      report
        ..writeln('### ${testCase.id}$kindSuffix')
        ..writeln()
        ..writeln('- Text: `${testCase.text}`')
        ..writeln('- Flagged phrase: "${testCase.flaggedPhrase}"')
        ..writeln('- Note: ${testCase.note}')
        ..writeln()
        ..writeln('#### Summary (${aggregate.totalRuns} runs, ${aggregate.errorRuns} error(s))')
        ..writeln()
        ..writeln(
          '- Verdict distribution: ${_describeDistribution(aggregate.verdictDistribution)} '
          '-> convergence ${_percentLabel(_maxCount(aggregate.verdictDistribution), aggregate.okRunCount)}'
          '$verdictScoreSuffix',
        )
        ..writeln(
          '- Category distribution: ${_describeDistribution(aggregate.categoryDistribution)} '
          '-> convergence ${_percentLabel(_maxCount(aggregate.categoryDistribution), aggregate.okRunCount)}'
          '$categoryScoreSuffix',
        )
        ..writeln()
        ..writeln('#### Run detail')
        ..writeln();

      for (final record in records) {
        report.writeln(_describeRun(record));
      }
      report.writeln();
    }
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Reused-family convergence rollup')
    ..writeln()
    ..writeln(
      '| Construction family | Anchor convergence (verdict) | '
      'Transfer convergence (avg) | Negative convergence | Anchor→Transfer gap |',
    )
    ..writeln('| --- | --- | --- | --- | --- |');

  for (final section in _Section.values) {
    if (!_isReusedSection(section)) {
      continue;
    }
    final sectionCases = cases.where((c) => c.section == section).toList();
    if (sectionCases.isEmpty) {
      continue;
    }
    final rollup = _rollupFamily(section, sectionCases, aggregatesById);
    report.writeln(
      '| ${_sectionHeading(section)} | ${rollup.anchorPct.toStringAsFixed(1)}% | '
      '${rollup.transferPct.toStringAsFixed(1)}% | '
      '${rollup.negativePct.toStringAsFixed(1)}% | '
      '${rollup.gap.toStringAsFixed(1)} pts |',
    );
  }

  report
    ..writeln()
    ..writeln('## New-case catch-rate summary')
    ..writeln()
    ..writeln('| Case | Accepted verdicts | Verdict catch rate | Category catch rate |')
    ..writeln('| --- | --- | --- | --- |');

  for (final section in _Section.values) {
    if (_isReusedSection(section)) {
      continue;
    }
    for (final testCase in cases.where((c) => c.section == section)) {
      final aggregate = aggregatesById[testCase.id]!;
      final acceptedLabel = testCase.acceptedVerdicts == null
          ? '(not scored)'
          : (testCase.acceptedVerdicts!.toList()..sort()).join('/');
      final verdictRate = testCase.acceptedVerdicts == null
          ? 'n/a'
          : _percentLabel(aggregate.verdictCaughtCount!, aggregate.okRunCount);
      final categoryRate = testCase.expectedCategory == null
          ? 'n/a'
          : _percentLabel(aggregate.categoryCaughtCount!, aggregate.okRunCount);
      report.writeln('| ${testCase.id} | $acceptedLabel | $verdictRate | $categoryRate |');
    }
  }

  return report.toString();
}

String _gitHead() {
  try {
    final result = Process.runSync('git', ['rev-parse', 'HEAD']);
    return (result.stdout as String).trim();
  } catch (_) {
    return 'unknown';
  }
}

Future<List<_CategorizationResult>> _callStage2Categorization({
  required HttpClient httpClient,
  required String apiKey,
  required String model,
  required String fullText,
  required String flaggedPhrase,
}) async {
  final request = await httpClient
      .postUrl(Uri.https('api.openai.com', '/v1/chat/completions'))
      .timeout(const Duration(seconds: 10));

  request.headers
    ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
    ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);

  request.add(
    utf8.encode(
      jsonEncode(
        _buildChatCompletionsBody(
          model: model,
          systemPrompt: stage2CategorizationSpanish,
          userText: _buildUserContent(fullText: fullText, flaggedPhrase: flaggedPhrase),
        ),
      ),
    ),
  );

  final response = await request.close().timeout(const Duration(seconds: 30));
  final body = await utf8.decodeStream(response);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Chat completions call failed with HTTP ${response.statusCode}: $body');
  }

  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Chat completions response root is not an object.');
  }

  return _parseCategorizationArray(_extractReplyText(decoded));
}

void main() {
  test('merged verdict battery case fixtures are well-formed', () {
    expect(
      _cases.length,
      37,
      reason:
          '21 reused (para 5 + coger 5 + ordinaryVocab 7 + softRegister 4) + '
          '16 new (seeds 6 + controls 4 + newThisStep 1 + leismoDO 2 + voseo 2 '
          '+ queismoTwoRegime 1).',
    );

    final ids = _cases.map((c) => c.id).toSet();
    expect(ids.length, _cases.length, reason: 'Case ids must be unique.');

    for (final testCase in _cases) {
      expect(testCase.text.trim(), isNotEmpty, reason: testCase.id);
      expect(
        testCase.text.contains(testCase.flaggedPhrase),
        isTrue,
        reason:
            '${testCase.id}: flagged phrase "${testCase.flaggedPhrase}" not '
            'found in case text.',
      );
      if (testCase.acceptedVerdicts != null) {
        expect(
          testCase.acceptedVerdicts!.isNotEmpty,
          isTrue,
          reason: '${testCase.id}: acceptedVerdicts must be non-empty when specified.',
        );
        expect(
          testCase.acceptedVerdicts!.difference(_validVerdicts),
          isEmpty,
          reason: '${testCase.id}: unknown verdict in acceptedVerdicts.',
        );
      }
      // Every reused case (has a reusedKind) is convergence-only, matching
      // peninsular_norms_battery.dart — not rebuilt with new ground truth.
      if (testCase.reusedKind != null) {
        expect(
          testCase.acceptedVerdicts,
          isNull,
          reason: '${testCase.id}: reused cases must stay convergence-only.',
        );
      }
    }

    final countsBySection = <_Section, int>{};
    for (final testCase in _cases) {
      countsBySection[testCase.section] = (countsBySection[testCase.section] ?? 0) + 1;
    }
    expect(countsBySection[_Section.paraDestination], 5);
    expect(countsBySection[_Section.cogerVocab], 5);
    expect(countsBySection[_Section.ordinaryVocab], 7);
    expect(countsBySection[_Section.softRegister], 4);
    expect(countsBySection[_Section.seeds], 6);
    expect(countsBySection[_Section.controls], 4);
    expect(countsBySection[_Section.newThisStep], 1);
    expect(countsBySection[_Section.leismoDirectObject], 2);
    expect(countsBySection[_Section.voseo], 2);
    expect(countsBySection[_Section.queismoTwoRegime], 1);

    // Every locked-list expected verdict, checked explicitly.
    Set<String>? acceptedFor(String id) =>
        _cases.firstWhere((c) => c.id == id).acceptedVerdicts;
    expect(acceptedFor('HP-1'), {'not_an_error', 'dialectal'});
    expect(acceptedFor('TEMP-1'), {'not_an_error'});
    expect(acceptedFor('ENTRA-1'), {'not_an_error'});
    expect(acceptedFor('LEISMO-TRAP-1'), {'error'});
    expect(acceptedFor('HABER-1'), {'error'});
    expect(acceptedFor('QUEISMO-1'), {'error'});
    expect(acceptedFor('CTRL-para'), {'not_an_error'});
    expect(acceptedFor('CTRL-dequeismo'), {'error'});
    expect(acceptedFor('CTRL-laismo'), {'error'});
    expect(acceptedFor('CTRL-coger'), {'dialectal'});
    expect(acceptedFor('SLD-1'), {'error'});
    expect(acceptedFor('LEISMO-DO-accepted'), {'not_an_error', 'dialectal'});
    expect(acceptedFor('LEISMO-DO-nonstandard'), {'error'});
    expect(acceptedFor('VOSEO-valid'), {'not_an_error'});
    expect(acceptedFor('VOSEO-hypercorrected'), {'error'});
    expect(acceptedFor('QUEISMO-informar'), {'not_an_error'});
  });

  group('_parseCategorizationArray', () {
    test('parses a populated array', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "coger el autobús", "corrected_phrase": '
        '"tomar el autobús", "occurrence": 1, "category": "Other", '
        '"verdict": "dialectal"}]',
      );

      expect(results, hasLength(1));
      expect(results.single.verdict, 'dialectal');
      expect(results.single.category, 'Other');
    });

    test('parses a null category for not_an_error', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "gafas", "corrected_phrase": "gafas", '
        '"occurrence": 1, "category": null, "verdict": "not_an_error"}]',
      );
      expect(results.single.category, isNull);
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      final results = _parseCategorizationArray(
        '```json\n[{"original_phrase": "librería", "corrected_phrase": '
        '"biblioteca", "occurrence": 1, "category": "Word Choice", '
        '"verdict": "error"}]\n```',
      );
      expect(results, hasLength(1));
    });

    test('throws on an unrecognized verdict', () {
      expect(
        () => _parseCategorizationArray(
          '[{"original_phrase": "x", "corrected_phrase": "y", '
          '"occurrence": 1, "category": "Other", "verdict": "maybe"}]',
        ),
        throwsFormatException,
      );
    });
  });

  group('_aggregateCase', () {
    test('convergence-only case (no acceptedVerdicts) leaves caught counts null', () {
      final testCase = _cases.firstWhere((c) => c.id == 'COG-anchor');
      final records = [
        _buildRunRecord(
          testCase: testCase,
          runIndex: 1,
          results: const [
            _CategorizationResult(
              originalPhrase: 'coger el autobús',
              correctedPhrase: 'tomar el autobús',
              occurrence: 1,
              category: 'Other',
              verdict: 'dialectal',
            ),
          ],
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);
      expect(aggregate.verdictConvergencePct, 100.0);
      expect(aggregate.verdictCaughtCount, isNull);
      expect(aggregate.categoryCaughtCount, isNull);
    });

    test('scored case (acceptedVerdicts + expectedCategory) computes a catch rate', () {
      final testCase = _cases.firstWhere((c) => c.id == 'HABER-1');
      final records = [
        _buildRunRecord(
          testCase: testCase,
          runIndex: 1,
          results: const [
            _CategorizationResult(
              originalPhrase: 'habían muchos coches',
              correctedPhrase: 'había muchos coches',
              occurrence: 1,
              category: 'Grammar',
              verdict: 'error',
            ),
          ],
        ),
        _buildRunRecord(
          testCase: testCase,
          runIndex: 2,
          results: const [
            _CategorizationResult(
              originalPhrase: 'habían muchos coches',
              correctedPhrase: 'había muchos coches',
              occurrence: 1,
              category: 'Other',
              verdict: 'dialectal',
            ),
          ],
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);
      expect(aggregate.verdictCaughtCount, 1);
      expect(aggregate.categoryCaughtCount, 1);
      expect(aggregate.okRunCount, 2);
    });

    test('errored runs are excluded from convergence and catch-rate denominators', () {
      final testCase = _cases.firstWhere((c) => c.id == 'SLD-1');
      final records = [
        _buildRunRecord(
          testCase: testCase,
          runIndex: 1,
          results: const [
            _CategorizationResult(
              originalPhrase: 'se los dije',
              correctedPhrase: 'se lo dije',
              occurrence: 1,
              category: 'Grammar',
              verdict: 'error',
            ),
          ],
        ),
        _errorRunRecord(testCase: testCase, runIndex: 2, error: StateError('boom')),
      ];

      final aggregate = _aggregateCase(testCase, records);
      expect(aggregate.okRunCount, 1);
      expect(aggregate.verdictCaughtCount, 1);
    });
  });

  test(
    '_buildReport matches the captured golden format '
    '(header, reused convergence-only case, new scored case, both rollup tables)',
    () {
      const synthCases = [
        _Case(
          id: 'SYN-REUSED-anchor',
          section: _Section.paraDestination,
          reusedKind: _ReusedKind.anchor,
          text: 'Volví para casa ayer.',
          flaggedPhrase: 'Volví para casa',
          note: 'synthetic reused anchor',
        ),
        _Case(
          id: 'SYN-REUSED-T1',
          section: _Section.paraDestination,
          reusedKind: _ReusedKind.transfer,
          text: 'Vine para casa tarde.',
          flaggedPhrase: 'Vine para casa',
          note: 'synthetic reused transfer',
        ),
        _Case(
          id: 'SYN-NEW-1',
          section: _Section.seeds,
          text: 'Hoy comí temprano.',
          flaggedPhrase: 'Hoy comí',
          acceptedVerdicts: {'not_an_error', 'dialectal'},
          note: 'synthetic new scored case',
        ),
      ];

      final recordsByCaseId = {
        'SYN-REUSED-anchor': [
          _buildRunRecord(
            testCase: synthCases[0],
            runIndex: 1,
            results: const [
              _CategorizationResult(
                originalPhrase: 'Volví para casa',
                correctedPhrase: 'Volví a casa',
                occurrence: 1,
                category: 'Grammar',
                verdict: 'error',
              ),
            ],
          ),
          _buildRunRecord(
            testCase: synthCases[0],
            runIndex: 2,
            results: const [
              _CategorizationResult(
                originalPhrase: 'Volví para casa',
                correctedPhrase: 'Volví a casa',
                occurrence: 1,
                category: 'Other',
                verdict: 'error',
              ),
            ],
          ),
        ],
        'SYN-REUSED-T1': [
          _buildRunRecord(
            testCase: synthCases[1],
            runIndex: 1,
            results: const [
              _CategorizationResult(
                originalPhrase: 'Vine para casa',
                correctedPhrase: 'Vine a casa',
                occurrence: 1,
                category: 'Natural Language',
                verdict: 'error',
              ),
            ],
          ),
          _buildRunRecord(
            testCase: synthCases[1],
            runIndex: 2,
            results: const [
              _CategorizationResult(
                originalPhrase: 'Vine para casa',
                correctedPhrase: 'Vine para casa',
                occurrence: 1,
                category: null,
                verdict: 'not_an_error',
              ),
            ],
          ),
        ],
        'SYN-NEW-1': [
          _buildRunRecord(
            testCase: synthCases[2],
            runIndex: 1,
            results: const [
              _CategorizationResult(
                originalPhrase: 'Hoy comí',
                correctedPhrase: 'Hoy comí',
                occurrence: 1,
                category: null,
                verdict: 'not_an_error',
              ),
            ],
          ),
          _buildRunRecord(
            testCase: synthCases[2],
            runIndex: 2,
            results: const [
              _CategorizationResult(
                originalPhrase: 'Hoy comí',
                correctedPhrase: 'Hoy comí',
                occurrence: 1,
                category: 'Other',
                verdict: 'dialectal',
              ),
            ],
          ),
        ],
      };

      final report = _buildReport(
        model: 'test-model',
        runsPerCase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        cases: synthCases,
        recordsByCaseId: recordsByCaseId,
        commit: 'abc1234',
      );

      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'merged verdict battery (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the merged verdict battery. This '
          'script does NOT fall back to any hardcoded/default key — no '
          'AppConfig involved, by design (see the file header).',
        );
      }

      final httpClient = HttpClient();
      final recordsByCaseId = <String, List<_RunRecord>>{};

      try {
        for (final testCase in _cases) {
          final records = <_RunRecord>[];
          // ignore: avoid_print
          print('=== ${testCase.id} ===');

          for (var run = 1; run <= runsPerCase; run++) {
            _RunRecord record;
            try {
              final results = await _callStage2Categorization(
                httpClient: httpClient,
                apiKey: apiKey,
                model: verdictBatteryModel,
                fullText: testCase.text,
                flaggedPhrase: testCase.flaggedPhrase,
              );
              record = _buildRunRecord(testCase: testCase, runIndex: run, results: results);
            } catch (error) {
              record = _errorRunRecord(testCase: testCase, runIndex: run, error: error);
            }
            records.add(record);
            // ignore: avoid_print
            print(_describeRun(record));
            await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
          }

          recordsByCaseId[testCase.id] = records;
        }
      } finally {
        httpClient.close();
      }

      final report = _buildReport(
        model: verdictBatteryModel,
        runsPerCase: runsPerCase,
        generatedAt: DateTime.now(),
        cases: _cases,
        recordsByCaseId: recordsByCaseId,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath');
    },
    timeout: const Timeout(Duration(minutes: 60)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Merged Verdict Battery\n\nModel: `test-model`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per case: 2\n\n## Reused: para + destination\n\n### SYN-REUSED-anchor (Anchor)\n\n- Text: `Volví para casa ayer.`\n- Flagged phrase: \"Volví para casa\"\n- Note: synthetic reused anchor\n\n#### Summary (2 runs, 0 error(s))\n\n- Verdict distribution: error: 2 -> convergence 100.0% (2/2)\n- Category distribution: Grammar: 1, Other: 1 -> convergence 50.0% (1/2)\n\n#### Run detail\n\n- Run 1: verdict=error, category=Grammar, occurrence=1\n- Run 2: verdict=error, category=Other, occurrence=1\n\n### SYN-REUSED-T1 (Transfer)\n\n- Text: `Vine para casa tarde.`\n- Flagged phrase: \"Vine para casa\"\n- Note: synthetic reused transfer\n\n#### Summary (2 runs, 0 error(s))\n\n- Verdict distribution: error: 1, not_an_error: 1 -> convergence 50.0% (1/2)\n- Category distribution: (none): 1, Natural Language: 1 -> convergence 50.0% (1/2)\n\n#### Run detail\n\n- Run 1: verdict=error, category=Natural Language, occurrence=1\n- Run 2: verdict=not_an_error, category=(none), occurrence=1\n\n## New: seeds\n\n### SYN-NEW-1\n\n- Text: `Hoy comí temprano.`\n- Flagged phrase: \"Hoy comí\"\n- Note: synthetic new scored case\n\n#### Summary (2 runs, 0 error(s))\n\n- Verdict distribution: dialectal: 1, not_an_error: 1 -> convergence 50.0% (1/2) (accepted: dialectal/not_an_error) -> caught 100.0% (2/2)\n- Category distribution: (none): 1, Other: 1 -> convergence 50.0% (1/2)\n\n#### Run detail\n\n- Run 1: verdict=not_an_error, category=(none), occurrence=1\n- Run 2: verdict=dialectal, category=Other, occurrence=1\n\n---\n\n## Reused-family convergence rollup\n\n| Construction family | Anchor convergence (verdict) | Transfer convergence (avg) | Negative convergence | Anchor→Transfer gap |\n| --- | --- | --- | --- | --- |\n| Reused: para + destination | 100.0% | 50.0% | 0.0% | 50.0 pts |\n\n## New-case catch-rate summary\n\n| Case | Accepted verdicts | Verdict catch rate | Category catch rate |\n| --- | --- | --- | --- |\n| SYN-NEW-1 | dialectal/not_an_error | 100.0% (2/2) | n/a |\n"';
