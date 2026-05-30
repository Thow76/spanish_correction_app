import '../../../core/enums/language.dart';

abstract interface class TranscriptionService {
  Future<String> transcribeAudio(String audioPath, Language language);
}
