import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/enums/language.dart';
import '../core/services/walkthrough_service.dart';
import '../features/corrections/application/correction_repository_controller.dart';
import '../features/corrections/application/correction_service.dart';
import '../features/corrections/data/file_correction_repository.dart';
import '../features/corrections/data/open_ai_correction_service.dart';
import '../features/introduction/application/introduction_controller.dart';
import '../features/introduction/presentation/introduction_screen.dart';
import '../features/language_selection/language_selection_screen.dart';
import '../features/navigation/presentation/app_shell.dart';
import '../features/profile/application/profile_repository.dart';
import '../features/profile/data/file_profile_repository.dart';
import '../features/write/application/transcription_service.dart';
import '../features/write/data/open_ai_whisper_transcription_service.dart';
import '../shared/design/app_colors.dart';
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
  late final TranscriptionService _transcriptionService;
  late final WalkthroughService _walkthroughService;
  late final ProfileRepository _profileRepository;
  Language? _selectedLanguage;
  bool _isInitialising = true;

  /// Whether the introduction (decision A1) is on screen. It runs once per
  /// install, between the language choice and the app, and is skipped when
  /// the profile file says it is complete, including after a language
  /// switch (decision A2).
  bool _showIntroduction = false;

  /// Once the learner leaves the introduction in this launch, by "Stop for
  /// now" or from its end screen, it stays away until the next launch; an
  /// unfinished introduction resumes where it stopped then.
  bool _introductionLeftThisLaunch = false;

  @override
  void initState() {
    super.initState();

    final config = AppConfig.fromEnvironment();
    _correctionService = OpenAiCorrectionService(
      apiKey: config.openAiApiKey,
      model: config.openAiCorrectionModel,
    );
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
    _profileRepository = FileProfileRepository();

    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final skip = prefs.getBool(_keySkipLanguageSelection) ?? false;
    if (skip) {
      final langCode = prefs.getString(_keyLastSelectedLanguage);
      if (langCode != null) {
        final lang = Language.fromJson(langCode);
        _selectedLanguage = lang;
        _showIntroduction = await _introductionNeeded(lang);
      }
    }
    if (mounted) {
      setState(() => _isInitialising = false);
    }
  }

  Future<void> _onLanguageSelected(Language lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSelectedLanguage, lang.toJson());
    final showIntroduction = await _introductionNeeded(lang);
    if (mounted) {
      setState(() {
        _selectedLanguage = lang;
        _showIntroduction = showIntroduction;
      });
    }
  }

  Future<bool> _introductionNeeded(Language lang) async {
    if (_introductionLeftThisLaunch) {
      return false;
    }
    final profile = await _profileRepository.getProfile();
    return IntroductionController.isNeeded(profile, lang);
  }

  void _onIntroductionLeft() {
    setState(() {
      _showIntroduction = false;
      _introductionLeftThisLaunch = true;
    });
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
        home: LanguageSelectionScreen(onLanguageSelected: _onLanguageSelected),
      );
    }

    if (_showIntroduction) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Corrector de Espanol',
        theme: buildAppTheme(),
        home: IntroductionScreen(
          language: selectedLanguage,
          profileRepository: _profileRepository,
          transcriptionService: _transcriptionService,
          onLeave: _onIntroductionLeft,
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
        transcriptionService: _transcriptionService,
        walkthroughService: _walkthroughService,
        language: selectedLanguage,
        onChangeLanguage: () => setState(() => _selectedLanguage = null),
      ),
    );
  }
}
