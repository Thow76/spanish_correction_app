// Shared verified-pricing helpers for latency/token-usage/cost
// observability across this repo's harnesses.
//
// Issue: "Add correction API latency, token-usage, and verified pricing
// observability" (closes spanish_correction_app#6). Purpose: make sure a
// USD cost estimate shown in any report is either backed by pricing this
// repository's maintainers have personally verified against an explicit
// source — with that source, its pricing version/effective date, and the
// date it was checked recorded alongside the number — or shown as
// `unknown`. Token usage itself may always be recorded whenever the API
// returns it; only the USD conversion is gated on verification.
//
// Before this file, `model_comparison_harness.dart` and
// `pipeline_baseline_harness.dart` each carried their own copy of a
// "`_pricingPerModel`" table explicitly documented as "illustrative
// placeholders, not verified published pricing" and then displayed the
// resulting numbers in reports as precise-looking dollar figures (e.g.
// `$15.000000`) with no indication they were unverified. That is exactly
// what this file exists to prevent.
//
// [verifiedPricingPerModel] starts EMPTY and MUST stay empty until a
// maintainer personally opens the model provider's own published pricing
// page, confirms the number, and adds an entry with [VerifiedModelPricing
// .source] (the URL), [VerifiedModelPricing.pricingVersionOrEffectiveDate]
// (the version or effective date shown on that page), and
// [VerifiedModelPricing.dateChecked] (the day of that confirmation) all
// filled in. Do not add an entry from memory, a script's guess, a
// secondary/aggregator source, or a web-search summary — a model missing
// from this map yields `unknown` cost (see [CostEstimate.unknown]), which
// is correct and safe; a wrong entry silently produces a wrong yet
// confident-looking dollar figure.

/// One model's verified USD-per-million-token pricing, plus the metadata
/// required to treat a cost estimate derived from it as trustworthy.
class VerifiedModelPricing {
  const VerifiedModelPricing({
    required this.inputPerMillionUsd,
    required this.outputPerMillionUsd,
    required this.source,
    required this.pricingVersionOrEffectiveDate,
    required this.dateChecked,
  });

  final double inputPerMillionUsd;
  final double outputPerMillionUsd;

  /// Where this pricing was confirmed — e.g. a URL to the provider's own
  /// published pricing page. Required, never blank.
  final String source;

  /// The pricing version or effective date shown on [source] at the time
  /// it was checked, e.g. `'2026-07-01'` or `'v3'`. Required, never blank.
  final String pricingVersionOrEffectiveDate;

  /// The date a maintainer actually opened [source] and confirmed these
  /// numbers, e.g. `'2026-07-27'`. Required, never blank. This is
  /// deliberately distinct from [pricingVersionOrEffectiveDate]: a
  /// provider's price can stay unchanged for months while this date moves
  /// forward each time someone re-confirms it is still current.
  final String dateChecked;
}

/// Verified pricing, keyed by model id. See the file header — this MUST
/// stay empty until every entry has been personally confirmed against its
/// own [VerifiedModelPricing.source].
const Map<String, VerifiedModelPricing> verifiedPricingPerModel = {};

/// The result of [estimateCostUsd]: either a verified dollar estimate plus
/// the pricing metadata that justifies it, or an explicit "unknown" a
/// report can still show token usage next to.
class CostEstimate {
  const CostEstimate.unknown() : usd = null, pricing = null;

  const CostEstimate.verified(
    double this.usd,
    VerifiedModelPricing this.pricing,
  );

  /// The estimated cost in USD, or `null` if pricing for the model has not
  /// been verified.
  final double? usd;

  /// The verified pricing entry [usd] was computed from, or `null` when
  /// [usd] is `null`.
  final VerifiedModelPricing? pricing;

  bool get isVerified => usd != null;

  /// A report-ready rendering of [usd]: `unknown` when unverified, an
  /// explicit dollar amount otherwise. Never a precise-looking number for
  /// an unverified model.
  String get display =>
      usd == null ? 'unknown' : '\$${usd!.toStringAsFixed(6)}';

  /// A report-ready one-line provenance note for [pricing], or `null` when
  /// [isVerified] is `false` (nothing to attribute).
  String? get provenance {
    final entry = pricing;
    if (entry == null) {
      return null;
    }
    return 'source=${entry.source}, '
        'pricing version/effective date=${entry.pricingVersionOrEffectiveDate}, '
        'checked=${entry.dateChecked}';
  }
}

/// Estimates USD cost for one call's [inputTokens]/[outputTokens] under
/// [model]. Returns [CostEstimate.unknown] unless [model] has a verified
/// entry in [pricingTable] (defaults to [verifiedPricingPerModel]) — never
/// a computed-but-unverified number. [pricingTable] is overridable only so
/// tests can exercise the "verified" path without adding a real entry to
/// [verifiedPricingPerModel].
CostEstimate estimateCostUsd({
  required String model,
  required int inputTokens,
  required int outputTokens,
  Map<String, VerifiedModelPricing> pricingTable = verifiedPricingPerModel,
}) {
  final pricing = pricingTable[model];
  if (pricing == null) {
    return const CostEstimate.unknown();
  }
  final usd =
      (inputTokens / 1000000) * pricing.inputPerMillionUsd +
      (outputTokens / 1000000) * pricing.outputPerMillionUsd;
  return CostEstimate.verified(usd, pricing);
}

/// A markdown-ready "Pricing" section for any report that shows a USD
/// estimate for one or more of [models]: one bullet per model with
/// verified pricing (source/version/date), or an explicit note that no
/// model in [models] has verified pricing configured — so every cost in
/// the report is `unknown` by design, not by omission. [pricingTable] is
/// overridable only so tests can exercise the "verified" rendering path
/// without adding a real entry to [verifiedPricingPerModel].
String pricingSection(
  Iterable<String> models, {
  Map<String, VerifiedModelPricing> pricingTable = verifiedPricingPerModel,
}) {
  final verifiedLines = <String>[];
  for (final model in models) {
    final pricing = pricingTable[model];
    if (pricing == null) {
      continue;
    }
    verifiedLines.add(
      '- `$model`: source=${pricing.source}, '
      'pricing version/effective date=${pricing.pricingVersionOrEffectiveDate}, '
      'checked=${pricing.dateChecked}',
    );
  }

  final body = verifiedLines.isEmpty
      ? 'No verified pricing is configured for any model in this report. '
            'Every cost estimate below shows as `unknown` by design — see '
            '`test/shared/model_pricing.dart` to add a verified entry once '
            'a maintainer has verified pricing for that model against its '
            'provider-published pricing page.'
      : verifiedLines.join('\n');

  return '## Pricing\n\n$body\n';
}
