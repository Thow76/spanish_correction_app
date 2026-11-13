import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records one spoken answer to a file for the transcription service.
///
/// A small face over the `record` package so the introduction screen can be
/// tested without a real microphone. [start] begins a recording; [stop] ends
/// it and returns the path of the audio file, or null if nothing was
/// recorded.
abstract interface class AnswerRecorder {
  Future<bool> hasPermission();

  Future<void> start();

  Future<String?> stop();

  Future<void> dispose();
}

/// Records with the phone's microphone, in the same format as the Check a
/// phrase page (16 kHz mono WAV in the temporary folder).
class MicrophoneAnswerRecorder implements AnswerRecorder {
  MicrophoneAnswerRecorder();

  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  Future<bool> hasPermission() => _audioRecorder.hasPermission();

  @override
  Future<void> start() async {
    final temporaryDirectory = await getTemporaryDirectory();
    final audioPath =
        '${temporaryDirectory.path}/introduction-recording-'
        '${DateTime.now().microsecondsSinceEpoch}.wav';
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        numChannels: 1,
        sampleRate: 16000,
      ),
      path: audioPath,
    );
  }

  @override
  Future<String?> stop() => _audioRecorder.stop();

  @override
  Future<void> dispose() => _audioRecorder.dispose();
}
