// Tests for the shared verified-pricing helpers (see `model_pricing.dart`'s
// file header and spanish_correction_app#6).

import 'package:flutter_test/flutter_test.dart';

import 'model_pricing.dart';

void main() {
  group('verifiedPricingPerModel', () {
    test('starts empty — no placeholder pricing is baked in', () {
      expect(
        verifiedPricingPerModel,
        isEmpty,
        reason:
            'Entries must only be added once a maintainer has personally '
            "verified a model's price against its provider-published "
            'pricing page. See the file header for the process.',
      );
    });
  });

  group('estimateCostUsd', () {
    test('returns unknown for a model with no verified pricing', () {
      final estimate = estimateCostUsd(
        model: 'gpt-5.5',
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
        inputPerMillionUsd: 1.0,
        outputPerMillionUsd: 2.0,
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
        'source=https://example.com/pricing, '
        'pricing version/effective date=2026-01-01, '
        'checked=2026-01-02',
      );
    });
  });

  group('estimateCostUsd with an overridden pricingTable', () {
    test('computes cost when the override has a matching entry', () {
      const pricing = VerifiedModelPricing(
        inputPerMillionUsd: 3.0,
        outputPerMillionUsd: 12.0,
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
      final section = pricingSection(['gpt-5.5', 'gpt-5.6-luna']);

      expect(section, contains('## Pricing'));
      expect(
        section,
        contains('No verified pricing is configured for any model'),
      );
    });

    test('lists provenance for models with an overridden verified entry', () {
      const pricing = VerifiedModelPricing(
        inputPerMillionUsd: 3.0,
        outputPerMillionUsd: 12.0,
        source: 'https://example.com/pricing',
        pricingVersionOrEffectiveDate: '2026-01-01',
        dateChecked: '2026-01-02',
      );
      final section = pricingSection(
        ['gpt-5.5', 'gpt-5.6-luna'],
        pricingTable: const {'gpt-5.5': pricing},
      );

      expect(section, contains('## Pricing'));
      expect(
        section,
        contains(
          '- `gpt-5.5`: source=https://example.com/pricing, '
          'pricing version/effective date=2026-01-01, checked=2026-01-02',
        ),
      );
      expect(section, isNot(contains('gpt-5.6-luna')));
    });
  });
}
