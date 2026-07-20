import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_verdict.dart';

void main() {
  group('fromApiValue', () {
    test('matches each known verdict string', () {
      expect(
        StagedCorrectionVerdict.fromApiValue('error'),
        StagedCorrectionVerdict.error,
      );
      expect(
        StagedCorrectionVerdict.fromApiValue('dialectal'),
        StagedCorrectionVerdict.dialectal,
      );
      expect(
        StagedCorrectionVerdict.fromApiValue('not_an_error'),
        StagedCorrectionVerdict.notAnError,
      );
    });

    test('returns null for an unrecognized value', () {
      expect(StagedCorrectionVerdict.fromApiValue('maybe'), isNull);
      expect(StagedCorrectionVerdict.fromApiValue(''), isNull);
    });
  });
}
