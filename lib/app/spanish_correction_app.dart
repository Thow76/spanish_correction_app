import 'package:flutter/material.dart';

import '../features/corrections/application/correction_repository_controller.dart';
import '../features/corrections/application/correction_service.dart';
import '../features/corrections/data/file_correction_repository.dart';
import '../features/corrections/data/gemini_correction_service.dart';
import '../features/navigation/presentation/app_shell.dart';
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

  @override
  void initState() {
    super.initState();

    final config = AppConfig.fromEnvironment();
    _correctionService = GeminiCorrectionService(
      apiKey: config.geminiApiKey,
      model: config.geminiModel,
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
      ),
    );
  }
}
