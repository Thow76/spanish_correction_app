import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';
import '../../corrections/application/correction_service.dart';
import '../../history/presentation/history_screen.dart';
import '../../saved/presentation/saved_screen.dart';
import '../../write/presentation/write_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.correctionService, super.key});

  final CorrectionService correctionService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      WriteScreen(correctionService: widget.correctionService),
      const HistoryScreen(),
      const SavedScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
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
}
