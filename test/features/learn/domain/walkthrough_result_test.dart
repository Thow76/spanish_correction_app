import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/learn/domain/walkthrough_result.dart';

void main() {
  WalkthroughResult result(int correct, int total) =>
      WalkthroughResult(correctCount: correct, totalCount: total);

  group('percentage rounding', () {
    test('2/3 rounds to 67', () {
      expect(result(2, 3).percentage, 67);
    });

    test('1/3 rounds to 33', () {
      expect(result(1, 3).percentage, 33);
    });

    test('3/3 is 100', () {
      expect(result(3, 3).percentage, 100);
    });

    test('4/5 is 80', () {
      expect(result(4, 5).percentage, 80);
    });
  });

  group('tier boundaries', () {
    test('100% is success', () {
      expect(result(3, 3).tier, WalkthroughTier.success);
      expect(result(5, 5).tier, WalkthroughTier.success);
    });

    test('exactly 50% is satisfactory', () {
      expect(result(2, 4).percentage, 50);
      expect(result(2, 4).tier, WalkthroughTier.satisfactory);
    });

    test('99% is satisfactory (not success)', () {
      expect(result(99, 100).percentage, 99);
      expect(result(99, 100).tier, WalkthroughTier.satisfactory);
    });

    test('below 50% is poor', () {
      expect(result(1, 3).tier, WalkthroughTier.poor); // 33%
      expect(result(2, 5).tier, WalkthroughTier.poor); // 40%
    });

    test('0% is poor', () {
      expect(result(0, 5).percentage, 0);
      expect(result(0, 5).tier, WalkthroughTier.poor);
    });
  });

  group('zero-guard', () {
    test('0/0 yields 0% and poor without throwing', () {
      final r = result(0, 0);
      expect(r.percentage, 0);
      expect(r.tier, WalkthroughTier.poor);
    });
  });
}
