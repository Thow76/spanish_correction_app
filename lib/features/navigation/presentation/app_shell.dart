import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/enums/language.dart';
import '../../../core/services/walkthrough_service.dart';
import '../../../shared/design/app_colors.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/application/correction_service.dart';
import '../../corrections/application/submit_correction_use_case.dart';
import '../../history/presentation/history_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../learn/presentation/learn_screen.dart';
import '../../profile/application/profile_repository.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../saved/application/save_correction_use_case.dart';
import '../../saved/presentation/saved_screen.dart';
import '../../write/application/transcription_service.dart';
import '../../write/presentation/check_a_phrase_page.dart';
import '../../write/presentation/write_screen.dart';
import '../application/new_items_marker.dart';

const _keySkipLanguageSelection = 'skip_language_selection';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.correctionService,
    required this.repositoryController,
    required this.transcriptionService,
    required this.walkthroughService,
    required this.newItemsMarker,
    required this.profileRepository,
    required this.language,
    required this.onChangeLanguage,
    super.key,
  });

  final CorrectionService correctionService;
  final CorrectionRepositoryController repositoryController;
  final TranscriptionService transcriptionService;
  final WalkthroughService walkthroughService;

  /// Decides when History and Saved show the dot for something new
  /// (task 1.4b).
  final NewItemsMarker newItemsMarker;

  /// Where the learner's interests are kept, for the profile screen
  /// (task 1.5).
  final ProfileRepository profileRepository;
  final Language language;
  final VoidCallback onChangeLanguage;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _skipLanguageSelection = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    widget.newItemsMarker.addListener(_onMarkerChanged);
    // Load History and Saved for this language, so the dot is right as soon
    // as the app opens, before either tab has been visited.
    widget.repositoryController.setActiveLanguage(widget.language);
    widget.newItemsMarker.setOpenTab(
      _markedTabAt(_selectedIndex),
      widget.language,
    );
  }

  @override
  void dispose() {
    widget.newItemsMarker.removeListener(_onMarkerChanged);
    super.dispose();
  }

  void _onMarkerChanged() {
    if (mounted) setState(() {});
  }

  /// Whether the first place in the bar is Home (decision B1; build step
  /// 3.1). Chats are Spanish only in the first build, and Portuguese keeps
  /// today's Write page in the bar (decision F1).
  bool get _hasHome => widget.language == Language.spanish;

  SubmitCorrectionUseCase get _submitCorrectionUseCase =>
      SubmitCorrectionUseCase(
        correctionService: widget.correctionService,
        repositoryController: widget.repositoryController,
      );

  SaveCorrectionUseCase get _saveCorrectionUseCase => SaveCorrectionUseCase(
    correctionService: widget.correctionService,
    repositoryController: widget.repositoryController,
  );

  /// The bottom bar's History tab is second and Saved third.
  static MarkedTab? _markedTabAt(int index) => switch (index) {
    1 => MarkedTab.history,
    2 => MarkedTab.saved,
    _ => null,
  };

  /// The tab's icon, with a small dot while it holds something new.
  Widget _iconWithDot(IconData icon, MarkedTab tab) {
    final hasNew = widget.newItemsMarker.hasNew(tab, widget.language);
    return Badge(
      key: ValueKey('new-items-dot-${tab.name}'),
      isLabelVisible: hasNew,
      smallSize: 8,
      backgroundColor: AppColors.coral,
      child: Icon(icon),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _skipLanguageSelection =
            prefs.getBool(_keySkipLanguageSelection) ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitCorrectionUseCase = _submitCorrectionUseCase;
    final saveCorrectionUseCase = _saveCorrectionUseCase;
    // Read above the Scaffold: here MediaQuery still carries the real keyboard
    // inset (the Scaffold zeroes it for its body), and reading it rebuilds this
    // widget when the keyboard animates in/out.
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final screens = [
      if (_hasHome)
        HomeScreen(onCheckAPhrase: _openCheckAPhrase)
      else
        WriteScreen(
          submitCorrectionUseCase: submitCorrectionUseCase,
          saveCorrectionUseCase: saveCorrectionUseCase,
          transcriptionService: widget.transcriptionService,
          language: widget.language,
          keyboardVisible: keyboardVisible,
        ),
      HistoryScreen(
        repositoryController: widget.repositoryController,
        saveCorrectionUseCase: saveCorrectionUseCase,
        language: widget.language,
      ),
      SavedScreen(
        repositoryController: widget.repositoryController,
        language: widget.language,
      ),
      LearnScreen(
        repositoryController: widget.repositoryController,
        transcriptionService: widget.transcriptionService,
        correctionService: widget.correctionService,
        walkthroughService: widget.walkthroughService,
        language: widget.language,
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            key: const ValueKey('open-profile'),
            tooltip: 'Your profile',
            icon: const Icon(
              Icons.person_outline,
              color: AppColors.textSecondary,
            ),
            onPressed: _openProfile,
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.cyan.withValues(alpha: 0.12),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? AppColors.cyan : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? AppColors.cyan : AppColors.textSecondary,
              size: 22,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
            widget.newItemsMarker.setOpenTab(
              _markedTabAt(index),
              widget.language,
            );
          },
          destinations: [
            if (_hasHome)
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              )
            else
              const NavigationDestination(
                icon: Icon(Icons.edit_outlined),
                selectedIcon: Icon(Icons.edit),
                label: 'Write',
              ),
            NavigationDestination(
              icon: _iconWithDot(Icons.history_outlined, MarkedTab.history),
              selectedIcon: _iconWithDot(Icons.history, MarkedTab.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: _iconWithDot(Icons.bookmark_border, MarkedTab.saved),
              selectedIcon: _iconWithDot(Icons.bookmark, MarkedTab.saved),
              label: 'Saved',
            ),
            const NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Learn',
            ),
          ],
        ),
      ),
    );
  }

  /// The Check a phrase icon on Home opens today's Write page as it is,
  /// as its own page with a back arrow (decisions B2 and B5).
  void _openCheckAPhrase() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckAPhrasePage(
          submitCorrectionUseCase: _submitCorrectionUseCase,
          saveCorrectionUseCase: _saveCorrectionUseCase,
          transcriptionService: widget.transcriptionService,
          language: widget.language,
        ),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileScreen(profileRepository: widget.profileRepository),
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text(
                      'Change language',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onChangeLanguage();
                    },
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Skip language selection on startup',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: _skipLanguageSelection,
                    activeThumbColor: AppColors.cyan,
                    activeTrackColor: AppColors.cyan.withValues(alpha: 0.4),
                    onChanged: (value) async {
                      setState(() => _skipLanguageSelection = value);
                      setSheetState(() {});
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool(_keySkipLanguageSelection, value);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
