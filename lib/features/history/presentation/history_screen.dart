import 'package:flutter/material.dart';

import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/empty_state_panel.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            children: const [
              AppHeader(title: 'History'),
              SizedBox(height: AppSpacing.xl),
              EmptyStatePanel(
                icon: Icons.history,
                title: 'No reviewed text yet',
                message:
                    'Recent submissions will appear here after the Gemini correction flow is connected.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
