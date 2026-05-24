import 'package:flutter/material.dart';

import '../features/corrections/application/correction_repository_controller.dart';
import '../features/corrections/application/correction_service.dart';
import '../features/corrections/data/file_correction_repository.dart';
import '../features/corrections/data/gemini_correction_service.dart';
import '../features/corrections/data/open_ai_correction_service.dart';
import '../features/navigation/presentation/app_shell.dart';
import '../features/write/application/transcription_service.dart';
import '../features/write/data/open_ai_whisper_transcription_service.dart';
import '../shared/network/connectivity_network_status_service.dart';
import '../shared/network/network_status_service.dart';
import 'app_config.dart';
import 'app_theme.dart';

class SpanishCorrectionApp extends StatefulWidget {
  const SpanishCorrectionApp({super.key});

  @override
  State<SpanishCorrectionApp> createState() => _SpanishCorrectionAppState();
}

class _SpanishCorrectionAppState extends State<SpanishCorrectionApp> {
  late final CorrectionService _correctionService;
  late final CorrectionRepositoryController _repositoryController;
  late final NetworkStatusService _networkStatusService;
  late final TranscriptionService _transcriptionService;

  @override
  void initState() {
    super.initState();

    final config = AppConfig.fromEnvironment();
    _correctionService = buildCorrectionService(config);
    _transcriptionService = OpenAiWhisperTranscriptionService(
      apiKey: config.openAiApiKey,
    );
    _repositoryController = CorrectionRepositoryController(
      FileCorrectionRepository(),
    );
    _networkStatusService = ConnectivityNetworkStatusService();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Corrector de Espanol',
      theme: buildAppTheme(),
      home: AppShell(
        correctionService: _correctionService,
        repositoryController: _repositoryController,
        networkStatusService: _networkStatusService,
        transcriptionService: _transcriptionService,
      ),
    );
  }
}

CorrectionService buildCorrectionService(AppConfig config) {
  return switch (config.correctionProvider) {
    CorrectionProvider.gemini => GeminiCorrectionService(
      apiKey: config.geminiApiKey,
      model: config.geminiModel,
    ),
    CorrectionProvider.openAi => OpenAiCorrectionService(
      apiKey: config.openAiApiKey,
      model: config.openAiCorrectionModel,
    ),
  };
}
