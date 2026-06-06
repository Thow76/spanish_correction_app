import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/network/network_status_service.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/application/correction_service.dart';
import '../../corrections/application/submit_correction_use_case.dart';
import '../../corrections/application/sync_queued_submissions_use_case.dart';
import '../../history/presentation/history_screen.dart';
import '../../learn/presentation/learn_screen.dart';
import '../../saved/application/save_correction_use_case.dart';
import '../../saved/presentation/saved_screen.dart';
import '../../write/application/transcription_service.dart';
import '../../write/presentation/write_screen.dart';

const _keySkipLanguageSelection = 'skip_language_selection';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.correctionService,
    required this.repositoryController,
    required this.networkStatusService,
    required this.transcriptionService,
    required this.language,
    required this.onChangeLanguage,
    super.key,
  });

  final CorrectionService correctionService;
  final CorrectionRepositoryController repositoryController;
  final NetworkStatusService networkStatusService;
  final TranscriptionService transcriptionService;
  final Language language;
  final VoidCallback onChangeLanguage;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isSyncingQueue = false;
  bool _skipLanguageSelection = false;

  @override
  void initState() {
    super.initState();
    widget.repositoryController.loadQueuedSubmissions();
    _connectionSubscription = widget.networkStatusService.connectionChanges
        .listen((hasConnection) {
          if (hasConnection) {
            _syncQueuedSubmissions();
          }
        });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncQueuedSubmissions();
    });
    _loadSettings();
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
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitCorrectionUseCase = SubmitCorrectionUseCase(
      correctionService: widget.correctionService,
      repositoryController: widget.repositoryController,
      networkStatusService: widget.networkStatusService,
    );
    final saveCorrectionUseCase = SaveCorrectionUseCase(
      correctionService: widget.correctionService,
      repositoryController: widget.repositoryController,
    );
    // Read above the Scaffold: here MediaQuery still carries the real keyboard
    // inset (the Scaffold zeroes it for its body), and reading it rebuilds this
    // widget when the keyboard animates in/out.
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final screens = [
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
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.edit_outlined),
              selectedIcon: Icon(Icons.edit),
              label: 'Write',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Saved',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Learn',
            ),
          ],
        ),
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

  Future<void> _syncQueuedSubmissions() async {
    if (_isSyncingQueue) {
      return;
    }

    _isSyncingQueue = true;
    try {
      final syncedCount = await SyncQueuedSubmissionsUseCase(
        correctionService: widget.correctionService,
        repositoryController: widget.repositoryController,
      )();

      if (!mounted || syncedCount == 0) {
        return;
      }

      final label = syncedCount == 1 ? 'submission' : 'submissions';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced $syncedCount queued $label')),
      );
    } catch (_) {
      // Sync will be retried the next time connectivity changes or the app restarts.
    } finally {
      _isSyncingQueue = false;
    }
  }
}
