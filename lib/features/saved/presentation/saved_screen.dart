import 'package:flutter/material.dart';

import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/empty_state_panel.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            children: const [
              AppHeader(title: 'Saved'),
              SizedBox(height: AppSpacing.xl),
              EmptyStatePanel(
                icon: Icons.bookmark_border,
                title: 'No saved corrections',
                message:
                    'Saved explanations will be grouped by category and date once long explanations are generated.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
