import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/write/application/transcription_service_exception.dart';
import 'package:spanish_correction_app/features/write/data/open_ai_whisper_transcription_service.dart';

void main() {
  group('lines Whisper invents for silence', () {
    test(
      'the Amara.org subtitle credit is caught, with or without accents',
      () {
        expect(
          OpenAiWhisperTranscriptionService.isSilenceHallucination(
            'Subtítulos realizados por la comunidad de Amara.org',
          ),
          isTrue,
        );
        expect(
          OpenAiWhisperTranscriptionService.isSilenceHallucination(
            'subtitulos por la comunidad de amara.org',
          ),
          isTrue,
        );
      },
    );

    test('short invented lines are caught only as the whole text', () {
      expect(
        OpenAiWhisperTranscriptionService.isSilenceHallucination(
          '¡Gracias por ver el video!',
        ),
        isTrue,
      );
      expect(
        OpenAiWhisperTranscriptionService.isSilenceHallucination(
          'Gracias por ver la película conmigo ayer.',
        ),
        isFalse,
      );
    });

    test('ordinary speech is kept', () {
      expect(
        OpenAiWhisperTranscriptionService.isSilenceHallucination(
          'Me gusta mucho el jazz y voy a conciertos.',
        ),
        isFalse,
      );
    });
  });

  test(
    'a recording too short to hold words is refused before sending',
    () async {
      final directory = await Directory.systemTemp.createTemp('whisper_test_');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/short.wav');
      await file.writeAsBytes(List.filled(2000, 0));

      final service = OpenAiWhisperTranscriptionService(apiKey: 'test-key');
      await expectLater(
        service.transcribeAudio(file.path, Language.spanish),
        throwsA(
          isA<TranscriptionServiceException>().having(
            (error) => error.reason,
            'reason',
            TranscriptionFailureReason.nothingHeard,
          ),
        ),
      );
    },
  );
}
