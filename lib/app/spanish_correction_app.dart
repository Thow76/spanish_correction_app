import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/enums/language.dart';
import '../core/services/walkthrough_service.dart';
import '../features/corrections/application/correction_repository_controller.dart';
import '../features/corrections/application/correction_service.dart';
import '../features/corrections/data/file_correction_repository.dart';
import '../features/corrections/data/open_ai_correction_service.dart';
import '../features/introduction/content/introduction_content.dart';
import '../features/introduction/data/record_voice_recorder.dart';
import '../features/introduction/data/url_launcher_link_opener.dart';
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
  const SpanishCorrectionApp({this.config, super.key});

  /// The key and model names. Null reads them from the build settings only.
  final AppConfig? config;

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

  /// Whether the introduction has been finished on this install (task 1.3).
  /// Once it has, it never shows again, including after a language switch.
  bool _introductionComplete = false;

  /// Whether "Stop for now" took the learner to the app this session. The
  /// introduction then waits for the next launch to resume.
  bool _introductionStoppedThisSession = false;

  @override
  void initState() {
    super.initState();

    final config = widget.config ?? AppConfig.fromEnvironment();
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
    final profile = await _profileRepository.getProfile();
    _introductionComplete = profile.introduction.isComplete;
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
        home: LanguageSelectionScreen(onLanguageSelected: _onLanguageSelected),
      );
    }

    if (_shouldShowIntroduction(selectedLanguage)) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Corrector de Espanol',
        theme: buildAppTheme(),
        home: IntroductionScreen(
          language: selectedLanguage,
          profileRepository: _profileRepository,
          transcriptionService: _transcriptionService,
          recorderFactory: RecordVoiceRecorder.new,
          linkOpener: const UrlLauncherLinkOpener(),
          onDone: (completed) => setState(() {
            if (completed) {
              _introductionComplete = true;
            } else {
              _introductionStoppedThisSession = true;
            }
          }),
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

  /// The introduction shows once per install, between the language choice
  /// and the app (task 1.3). It is skipped once it is complete, after "Stop
  /// for now" this session, and for a language with no introduction content
  /// yet (Portuguese in slice 1, decision F1).
  bool _shouldShowIntroduction(Language language) =>
      !_introductionComplete &&
      !_introductionStoppedThisSession &&
      IntroductionContent.hasContentFor(language);
}
