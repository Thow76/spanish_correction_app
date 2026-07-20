import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/enums/language.dart';
import '../core/services/walkthrough_service.dart';
import '../features/corrections/application/correction_repository_controller.dart';
import '../features/corrections/application/correction_service.dart';
import '../features/corrections/data/file_correction_repository.dart';
import '../features/corrections/data/gemini_correction_service.dart';
import '../features/corrections/data/open_ai_correction_service.dart';
import '../features/language_selection/language_selection_screen.dart';
import '../features/navigation/presentation/app_shell.dart';
import '../features/write/application/transcription_service.dart';
import '../features/write/data/open_ai_whisper_transcription_service.dart';
import '../shared/design/app_colors.dart';
import '../shared/network/connectivity_network_status_service.dart';
import '../shared/network/network_status_service.dart';
import 'app_config.dart';
import 'app_theme.dart';

const _keySkipLanguageSelection = 'skip_language_selection';
const _keyLastSelectedLanguage = 'last_selected_language';

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
  late final WalkthroughService _walkthroughService;
  Language? _selectedLanguage;
  bool _isInitialising = true;

  @override
  void initState() {
    super.initState();

    final config = AppConfig.fromEnvironment();
    _correctionService = buildCorrectionService(config);
    _transcriptionService = OpenAiWhisperTranscriptionService(
      apiKey: config.openAiApiKey,
    );
    _walkthroughService = WalkthroughService(
      apiKey: config.openAiApiKey,
      model: config.openAiWalkthroughModel,
    );
    _repositoryController = CorrectionRepositoryController(
      FileCorrectionRepository(),
    );
    _networkStatusService = ConnectivityNetworkStatusService();

    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final skip = prefs.getBool(_keySkipLanguageSelection) ?? false;
    if (skip) {
      final langCode = prefs.getString(_keyLastSelectedLanguage);
      if (langCode != null) {
        _selectedLanguage = Language.fromJson(langCode);
      }
    }
    if (mounted) {
      setState(() => _isInitialising = false);
    }
  }

  Future<void> _onLanguageSelected(Language lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSelectedLanguage, lang.toJson());
    if (mounted) {
      setState(() => _selectedLanguage = lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialising) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const Scaffold(backgroundColor: AppColors.background),
      );
    }

    final selectedLanguage = _selectedLanguage;

    if (selectedLanguage == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Corrector de Espanol',
        theme: buildAppTheme(),
        home: LanguageSelectionScreen(
          onLanguageSelected: _onLanguageSelected,
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Corrector de Espanol',
      theme: buildAppTheme(),
      home: AppShell(
        correctionService: _correctionService,
        repositoryController: _repositoryController,
        networkStatusService: _networkStatusService,
        transcriptionService: _transcriptionService,
        walkthroughService: _walkthroughService,
        language: selectedLanguage,
        onChangeLanguage: () => setState(() => _selectedLanguage = null),
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
      useStagedSpanishPipeline: config.useStagedSpanishPipeline,
    ),
  };
}
