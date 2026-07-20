import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_note.dart';

void main() {
  test('exposes the phrase and note it was constructed with', () {
    const note = CorrectionNote(
      phrase: 'coger el autobús',
      note: 'Standard in Spain; avoided in parts of Latin America.',
    );

    expect(note.phrase, 'coger el autobús');
    expect(
      note.note,
      'Standard in Spain; avoided in parts of Latin America.',
    );
  });
}
