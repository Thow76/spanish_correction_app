import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/network/network_status_service.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/application/correction_service.dart';
import '../../corrections/application/submit_correction_use_case.dart';
import '../../corrections/application/sync_queued_submissions_use_case.dart';
import '../../history/presentation/history_screen.dart';
import '../../saved/application/save_correction_use_case.dart';
import '../../saved/presentation/saved_screen.dart';
import '../../write/presentation/write_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.correctionService,
    required this.repositoryController,
    required this.networkStatusService,
    super.key,
  });

  final CorrectionService correctionService;
  final CorrectionRepositoryController repositoryController;
  final NetworkStatusService networkStatusService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  StreamSubscription<bool>? _connectionSubscription;
  bool _isSyncingQueue = false;

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
    final screens = [
      WriteScreen(
        submitCorrectionUseCase: submitCorrectionUseCase,
        saveCorrectionUseCase: saveCorrectionUseCase,
      ),
      HistoryScreen(
        repositoryController: widget.repositoryController,
        saveCorrectionUseCase: saveCorrectionUseCase,
      ),
      SavedScreen(repositoryController: widget.repositoryController),
    ];

    return Scaffold(
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
          ],
        ),
      ),
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
