import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../application/voice_recorder.dart';

/// Records with the `record` package, in the same format as the Check a
/// phrase page (mono WAV at 16 kHz, which the transcription service takes).
class RecordVoiceRecorder implements VoiceRecorder {
  RecordVoiceRecorder() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    final temporaryDirectory = await getTemporaryDirectory();
    final audioPath =
        '${temporaryDirectory.path}/introduction-recording-'
        '${DateTime.now().microsecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        numChannels: 1,
        sampleRate: 16000,
      ),
      path: audioPath,
    );
  }

  @override
  Future<String?> stop() => _recorder.stop();

  @override
  Future<void> dispose() => _recorder.dispose();
}
