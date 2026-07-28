// Tests for the shared verified-pricing helpers (see `model_pricing.dart`'s
// file header and spanish_correction_app#6).

import 'package:flutter_test/flutter_test.dart';

import 'model_pricing.dart';

void main() {
  group('verifiedPricingPerModel', () {
    test('contains verified OpenAI first-pass comparison model pricing', () {
      expect(
        verifiedPricingPerModel.keys,
        containsAll(['gpt-5.4', 'gpt-5.3-chat-latest', 'gpt-4.1']),
      );

      final gpt54 = verifiedPricingPerModel['gpt-5.4']!;
      expect(gpt54.modelId, 'gpt-5.4');
      expect(gpt54.inputPerMillionUsd, 2.50);
      expect(gpt54.outputPerMillionUsd, 15.00);
      expect(gpt54.currency, 'USD');
      expect(gpt54.pricingUnit, 'per 1M text tokens');
      expect(
        gpt54.source,
        'https://developers.openai.com/api/docs/models/gpt-5.4',
      );
      expect(gpt54.dateChecked, '2026-07-28');

      final gpt53Chat = verifiedPricingPerModel['gpt-5.3-chat-latest']!;
      expect(gpt53Chat.modelId, 'gpt-5.3-chat-latest');
      expect(gpt53Chat.inputPerMillionUsd, 1.75);
      expect(gpt53Chat.outputPerMillionUsd, 14.00);

      final gpt41 = verifiedPricingPerModel['gpt-4.1']!;
      expect(gpt41.modelId, 'gpt-4.1');
      expect(gpt41.inputPerMillionUsd, 2.00);
      expect(gpt41.outputPerMillionUsd, 8.00);
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
        model: 'gpt-4.1',
        inputTokens: 1000000,
        outputTokens: 1000000,
      );

      expect(estimate.isVerified, isTrue);
      expect(estimate.usd, closeTo(10.0, 1e-9));
      expect(estimate.display, r'$10.000000');
      expect(estimate.pricing?.modelId, 'gpt-4.1');
    });

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
      final section = pricingSection(['gpt-5.5', 'gpt-5.6-luna']);

      expect(section, contains('## Pricing'));
      expect(
        section,
        contains('No verified pricing is configured for any model'),
      );
      expect(
        section,
        contains(
          'Unknown cost because pricing is unavailable or unverified for: '
          '`gpt-5.5`, `gpt-5.6-luna`.',
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
      final section = pricingSection(['gpt-5.4', 'gpt-5.3', 'gpt-4.1']);

      expect(section, contains('Verified estimated costs use:'));
      expect(section, contains('`gpt-5.4`: input=2.5 USD'));
      expect(section, contains('`gpt-4.1`: input=2.0 USD'));
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
