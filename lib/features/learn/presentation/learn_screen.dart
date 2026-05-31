import 'package:flutter/material.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/empty_state_panel.dart';
import '../../corrections/application/correction_repository_controller.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({
    required this.repositoryController,
    required this.language,
    super.key,
  });

  final CorrectionRepositoryController repositoryController;
  final Language language;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: Column(
              children: const [
                AppHeader(title: 'Aprender'),
                SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: Center(
                    child: EmptyStatePanel(
                      icon: Icons.school_outlined,
                      title: 'Coming soon',
                      message:
                          'Practice games will appear here. Save some corrections first to get started.',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
