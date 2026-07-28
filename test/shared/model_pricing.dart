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
// [verifiedPricingPerModel] MUST only contain entries whose model id and
// price have been confirmed by a maintainer against the model provider's own
// published pricing page. Each entry records the exact model id, token prices,
// currency, pricing unit, source URL, pricing version/effective date if the
// source publishes one, and date checked. Do not add an entry from memory, a
// script's guess, a secondary/aggregator source, or a web-search summary — a
// model missing from this map yields `unknown` cost (see
// [CostEstimate.unknown]), which is correct and safe; a wrong entry silently
// produces a wrong yet confident-looking dollar figure.

/// One model's verified USD-per-million-token pricing, plus the metadata
/// required to treat a cost estimate derived from it as trustworthy.
class VerifiedModelPricing {
  const VerifiedModelPricing({
    required this.modelId,
    required this.inputPerMillionUsd,
    required this.outputPerMillionUsd,
    required this.currency,
    required this.pricingUnit,
    required this.source,
    required this.pricingVersionOrEffectiveDate,
    required this.dateChecked,
  });

  /// Exact API model id this entry applies to. This must match the key used
  /// in [verifiedPricingPerModel].
  final String modelId;

  final double inputPerMillionUsd;
  final double outputPerMillionUsd;

  /// Currency used by [inputPerMillionUsd] and [outputPerMillionUsd].
  final String currency;

  /// Provider-published unit for these prices, e.g. `per 1M text tokens`.
  final String pricingUnit;

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

/// Verified pricing, keyed by exact API model id.
const Map<String, VerifiedModelPricing> verifiedPricingPerModel = {
  'gpt-5.4': VerifiedModelPricing(
    modelId: 'gpt-5.4',
    inputPerMillionUsd: 2.50,
    outputPerMillionUsd: 15.00,
    currency: 'USD',
    pricingUnit: 'per 1M text tokens',
    source: 'https://developers.openai.com/api/docs/models/gpt-5.4',
    pricingVersionOrEffectiveDate:
        'OpenAI model page standard text-token pricing; no separate '
        'pricing effective date shown',
    dateChecked: '2026-07-28',
  ),
  'gpt-5.3-chat-latest': VerifiedModelPricing(
    modelId: 'gpt-5.3-chat-latest',
    inputPerMillionUsd: 1.75,
    outputPerMillionUsd: 14.00,
    currency: 'USD',
    pricingUnit: 'per 1M text tokens',
    source: 'https://developers.openai.com/api/docs/models/gpt-5.3-chat-latest',
    pricingVersionOrEffectiveDate:
        'OpenAI model page standard text-token pricing; no separate '
        'pricing effective date shown',
    dateChecked: '2026-07-28',
  ),
  'gpt-4.1': VerifiedModelPricing(
    modelId: 'gpt-4.1',
    inputPerMillionUsd: 2.00,
    outputPerMillionUsd: 8.00,
    currency: 'USD',
    pricingUnit: 'per 1M text tokens',
    source: 'https://developers.openai.com/api/docs/models/gpt-4.1',
    pricingVersionOrEffectiveDate:
        'OpenAI model page standard text-token pricing; no separate '
        'pricing effective date shown',
    dateChecked: '2026-07-28',
  ),
};

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
    return 'model=${entry.modelId}, '
        'input=${entry.inputPerMillionUsd} ${entry.currency}, '
        'output=${entry.outputPerMillionUsd} ${entry.currency}, '
        'unit=${entry.pricingUnit}, '
        'source=${entry.source}, '
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
  final unknownModels = <String>[];
  for (final model in models) {
    final pricing = pricingTable[model];
    if (pricing == null) {
      unknownModels.add(model);
      continue;
    }
    verifiedLines.add(
      '- `$model`: input=${pricing.inputPerMillionUsd} ${pricing.currency}, '
      'output=${pricing.outputPerMillionUsd} ${pricing.currency}, '
      'unit=${pricing.pricingUnit}, source=${pricing.source}, '
      'pricing version/effective date=${pricing.pricingVersionOrEffectiveDate}, '
      'checked=${pricing.dateChecked}',
    );
  }

  final bodyLines = <String>[];
  if (verifiedLines.isEmpty) {
    bodyLines.add(
      'No verified pricing is configured for any model in this report. '
      'Every cost estimate below shows as `unknown` by design — see '
      '`test/shared/model_pricing.dart` to add a verified entry once '
      'a maintainer has verified pricing for that model against its '
      'provider-published pricing page.',
    );
  } else {
    bodyLines
      ..add('Verified estimated costs use:')
      ..addAll(verifiedLines);
  }

  if (unknownModels.isNotEmpty) {
    bodyLines
      ..add('')
      ..add(
        'Unknown cost because pricing is unavailable or unverified for: '
        '${unknownModels.map((model) => '`$model`').join(', ')}.',
      );
  }

  return '## Pricing\n\n${bodyLines.join('\n')}\n';
}
