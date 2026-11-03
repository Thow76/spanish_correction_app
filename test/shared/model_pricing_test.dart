// Tests for the shared verified-pricing helpers (see `model_pricing.dart`'s
// file header and spanish_correction_app#6).

import 'package:flutter_test/flutter_test.dart';

import 'model_pricing.dart';

const Map<String, ({double input, double output, String source})>
scopedFirstPassModelPricing = {
  'gpt-5.5': (
    input: 5.00,
    output: 30.00,
    source: 'https://developers.openai.com/api/docs/models/gpt-5.5',
  ),
  'gpt-5.3-chat-latest': (
    input: 1.75,
    output: 14.00,
    source: 'https://developers.openai.com/api/docs/models/gpt-5.3-chat-latest',
  ),
  'gpt-5.2': (
    input: 1.75,
    output: 14.00,
    source: 'https://developers.openai.com/api/docs/models/gpt-5.2',
  ),
  'gpt-5.1': (
    input: 1.25,
    output: 10.00,
    source: 'https://developers.openai.com/api/docs/models/gpt-5.1',
  ),
  'gpt-5': (
    input: 1.25,
    output: 10.00,
    source: 'https://developers.openai.com/api/docs/models/gpt-5',
  ),
  'gpt-5-mini': (
    input: 0.25,
    output: 2.00,
    source: 'https://developers.openai.com/api/docs/models/gpt-5-mini',
  ),
  'gpt-4.1': (
    input: 2.00,
    output: 8.00,
    source: 'https://developers.openai.com/api/docs/models/gpt-4.1',
  ),
  'gpt-4.1-mini': (
    input: 0.40,
    output: 1.60,
    source: 'https://developers.openai.com/api/docs/models/gpt-4.1-mini',
  ),
  'gpt-4o': (
    input: 2.50,
    output: 10.00,
    source: 'https://developers.openai.com/api/docs/models/gpt-4o',
  ),
  'gpt-4o-mini': (
    input: 0.15,
    output: 0.60,
    source: 'https://developers.openai.com/api/docs/models/gpt-4o-mini',
  ),
};

void main() {
  group('verifiedPricingPerModel', () {
    test('contains verified OpenAI first-pass comparison model pricing', () {
      expect(
        verifiedPricingPerModel.keys,
        containsAll(scopedFirstPassModelPricing.keys),
      );

      for (final expected in scopedFirstPassModelPricing.entries) {
        final actual = verifiedPricingPerModel[expected.key]!;
        expect(actual.modelId, expected.key);
        expect(actual.inputPerMillionUsd, expected.value.input);
        expect(actual.outputPerMillionUsd, expected.value.output);
        expect(actual.currency, 'USD');
        expect(actual.pricingUnit, 'per 1M text tokens');
        expect(actual.source, expected.value.source);
        expect(actual.dateChecked, '2026-07-28');
        expect(
          actual.pricingVersionOrEffectiveDate,
          contains('OpenAI model page standard text-token pricing'),
        );
      }
    });

    test('does not invent a plain gpt-5.3 price', () {
      expect(verifiedPricingPerModel, isNot(contains('gpt-5.3')));
    });

    test('keys match the exact model ids in their pricing entries', () {
      for (final entry in verifiedPricingPerModel.entries) {
        expect(entry.value.modelId, entry.key);
        expect(entry.value.source, startsWith('https://'));
        expect(entry.value.pricingVersionOrEffectiveDate.trim(), isNotEmpty);
        expect(entry.value.dateChecked.trim(), isNotEmpty);
      }
    });
  });

  group('estimateCostUsd', () {
    test('returns a verified estimate for a model with verified pricing', () {
      final estimate = estimateCostUsd(
        model: 'gpt-5.5',
        inputTokens: 1000000,
        outputTokens: 1000000,
      );

      expect(estimate.isVerified, isTrue);
      expect(estimate.usd, closeTo(35.0, 1e-9));
      expect(estimate.display, r'$35.000000');
      expect(estimate.pricing?.modelId, 'gpt-5.5');
    });

    test('returns unknown for a model with no verified pricing', () {
      final estimate = estimateCostUsd(
        model: 'gpt-5.3',
        inputTokens: 1000000,
        outputTokens: 1000000,
      );

      expect(estimate.isVerified, isFalse);
      expect(estimate.usd, isNull);
      expect(estimate.pricing, isNull);
      expect(estimate.display, 'unknown');
      expect(estimate.provenance, isNull);
    });

    test('returns unknown for any unrecognized model id', () {
      final estimate = estimateCostUsd(
        model: 'not-a-real-model',
        inputTokens: 100,
        outputTokens: 100,
      );

      expect(estimate.isVerified, isFalse);
      expect(estimate.display, 'unknown');
    });
  });

  group('CostEstimate.verified', () {
    test('computes cost and exposes pricing provenance', () {
      const pricing = VerifiedModelPricing(
        modelId: 'test-model',
        inputPerMillionUsd: 1.0,
        outputPerMillionUsd: 2.0,
        currency: 'USD',
        pricingUnit: 'per 1M text tokens',
        source: 'https://example.com/pricing',
        pricingVersionOrEffectiveDate: '2026-01-01',
        dateChecked: '2026-01-02',
      );
      const estimate = CostEstimate.verified(3.5, pricing);

      expect(estimate.isVerified, isTrue);
      expect(estimate.usd, 3.5);
      expect(estimate.display, r'$3.500000');
      expect(
        estimate.provenance,
        'model=test-model, input=1.0 USD, output=2.0 USD, '
        'unit=per 1M text tokens, source=https://example.com/pricing, '
        'pricing version/effective date=2026-01-01, '
        'checked=2026-01-02',
      );
    });
  });

  group('estimateCostUsd with an overridden pricingTable', () {
    test('computes cost when the override has a matching entry', () {
      const pricing = VerifiedModelPricing(
        modelId: 'test-model',
        inputPerMillionUsd: 3.0,
        outputPerMillionUsd: 12.0,
        currency: 'USD',
        pricingUnit: 'per 1M text tokens',
        source: 'https://example.com/pricing',
        pricingVersionOrEffectiveDate: '2026-01-01',
        dateChecked: '2026-01-02',
      );
      final estimate = estimateCostUsd(
        model: 'test-model',
        inputTokens: 1000000,
        outputTokens: 1000000,
        pricingTable: const {'test-model': pricing},
      );

      expect(estimate.isVerified, isTrue);
      expect(estimate.usd, closeTo(15.0, 1e-9));
      expect(estimate.pricing, pricing);
    });
  });

  group('pricingSection', () {
    test('notes that no verified pricing is configured when none matches', () {
      final section = pricingSection(['gpt-5.6-sol', 'gpt-5.6-luna']);

      expect(section, contains('## Pricing'));
      expect(
        section,
        contains('No verified pricing is configured for any model'),
      );
      expect(
        section,
        contains(
          'Unknown cost because pricing is unavailable or unverified for: '
          '`gpt-5.6-sol`, `gpt-5.6-luna`.',
        ),
      );
    });

    test('lists provenance for models with an overridden verified entry', () {
      const pricing = VerifiedModelPricing(
        modelId: 'gpt-5.5',
        inputPerMillionUsd: 3.0,
        outputPerMillionUsd: 12.0,
        currency: 'USD',
        pricingUnit: 'per 1M text tokens',
        source: 'https://example.com/pricing',
        pricingVersionOrEffectiveDate: '2026-01-01',
        dateChecked: '2026-01-02',
      );
      final section = pricingSection(
        ['gpt-5.5', 'gpt-5.6-luna'],
        pricingTable: const {'gpt-5.5': pricing},
      );

      expect(section, contains('## Pricing'));
      expect(section, contains('Verified estimated costs use:'));
      expect(
        section,
        contains(
          '- `gpt-5.5`: input=3.0 USD, output=12.0 USD, '
          'unit=per 1M text tokens, source=https://example.com/pricing, '
          'pricing version/effective date=2026-01-01, checked=2026-01-02',
        ),
      );
      expect(
        section,
        contains(
          'Unknown cost because pricing is unavailable or unverified for: '
          '`gpt-5.6-luna`.',
        ),
      );
    });

    test('renders real verified pricing and unknown fallback together', () {
      final section = pricingSection(['gpt-5.5', 'gpt-5.3', 'gpt-4.1-mini']);

      expect(section, contains('Verified estimated costs use:'));
      expect(section, contains('`gpt-5.5`: input=5.0 USD'));
      expect(section, contains('`gpt-4.1-mini`: input=0.4 USD'));
      expect(
        section,
        contains(
          'Unknown cost because pricing is unavailable or unverified for: '
          '`gpt-5.3`.',
        ),
      );
    });
  });
}
