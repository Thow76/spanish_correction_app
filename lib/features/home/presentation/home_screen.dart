import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/empty_state_panel.dart';

/// Home: the first place in the bottom bar and what the app opens on
/// (decision B1; build step 3.1).
///
/// Under the header sits a band of labelled icons (B2). In this step it holds
/// Check a phrase only: Scrapbook and Goals are hidden until they are built
/// (F1). Under the band is the list of chats (B3), which stays empty until
/// steps 3.2 to 3.4 give it chats and a New chat control.
class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onCheckAPhrase, super.key});

  /// Opens the Check a phrase page, today's Write page as it is (B5).
  final VoidCallback onCheckAPhrase;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppHeader(title: 'Corregir'),
                const SizedBox(height: AppSpacing.sm),
                const _Line(),
                const SizedBox(height: AppSpacing.md),
                _IconBand(
                  items: [
                    _BandItem(
                      key: const ValueKey('home-check-a-phrase'),
                      icon: Icons.edit_outlined,
                      label: 'Check a phrase',
                      onTap: onCheckAPhrase,
                    ),
                    // Scrapbook and Goals take the other two slots once they
                    // are built (F1).
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const _Line(),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Chats',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Expanded(child: _EmptyChatList()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The divider between the header, the band and the chats, as drawn.
class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.textPrimary.withValues(alpha: 0.12),
    );
  }
}

/// Three equal slots across the band, so the icons keep their drawn places
/// while some are still hidden.
class _IconBand extends StatelessWidget {
  const _IconBand({required this.items});

  static const _slots = 3;

  final List<_BandItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _slots; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: i < items.length ? items[i] : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _BandItem extends StatelessWidget {
  const _BandItem({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.cyan, size: 22),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the chat area shows until there are chats (steps 3.2 to 3.4).
class _EmptyChatList extends StatelessWidget {
  const _EmptyChatList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: const [
        EmptyStatePanel(
          icon: Icons.chat_bubble_outline,
          title: 'No chats yet',
          message:
              'Your chats with your partner will appear here, newest first.',
        ),
      ],
    );
  }
}
