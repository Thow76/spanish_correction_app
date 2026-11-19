import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../introduction/content/interest.dart';
import '../../introduction/content/introduction_content.dart';
import '../application/profile_repository.dart';
import '../domain/learner_profile.dart';

/// The profile screen (task 1.5, decision A2).
///
/// Opened from the person icon beside settings. It lists the learner's
/// interests in English, in the order chosen, with a button to remove each,
/// and below them the interests not yet chosen, with a button to add each.
/// Every change is saved straight away, so it is kept after a relaunch.
///
/// The same limits as the introduction's chips apply: at least one interest
/// and at most five ([IntroductionContent.minimumChips] and
/// [IntroductionContent.maximumChips]).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.profileRepository, super.key});

  final ProfileRepository profileRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  LearnerProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await widget.profileRepository.getProfile();
    if (mounted) {
      setState(() => _profile = profile);
    }
  }

  /// The chosen interests that have a label to show, in the order chosen.
  /// An id with no matching interest is kept in the file but not shown.
  List<Interest> _chosen(LearnerProfile profile) => [
    for (final id in profile.interestIds)
      ...IntroductionContent.interests.where((interest) => interest.id == id),
  ];

  List<Interest> _notChosen(LearnerProfile profile) => [
    for (final interest in IntroductionContent.interests)
      if (!profile.hasInterest(interest.id)) interest,
  ];

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _remove(Interest interest) async {
    final profile = _profile;
    if (profile == null) return;
    if (_chosen(profile).length <= IntroductionContent.minimumChips) {
      _showMessage('Keep at least one interest.');
      return;
    }
    final updated = await widget.profileRepository.updateProfile(
      (stored) => stored.withInterestRemoved(interest.id),
    );
    if (mounted) setState(() => _profile = updated);
  }

  Future<void> _add(Interest interest) async {
    final profile = _profile;
    if (profile == null) return;
    if (_chosen(profile).length >= IntroductionContent.maximumChips) {
      _showMessage('You can have up to five. Remove one first.');
      return;
    }
    final updated = await widget.profileRepository.updateProfile(
      (stored) => stored.withInterestAdded(interest.id),
    );
    if (mounted) setState(() => _profile = updated);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Your profile'),
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(profile),
    );
  }

  Widget _buildBody(LearnerProfile profile) {
    final chosen = _chosen(profile);
    final notChosen = _notChosen(profile);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const _SectionHeading('Your interests'),
        Text(
          '${chosen.length} of ${IntroductionContent.maximumChips} chosen',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (chosen.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'No interests chosen yet. Add one below.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ),
        for (final interest in chosen)
          _InterestRow(
            key: ValueKey('chosen-${interest.id}'),
            label: interest.english,
            icon: Icons.remove_circle_outline,
            iconColor: AppColors.coral,
            tooltip: 'Remove ${interest.english}',
            onPressed: () => _remove(interest),
          ),
        const SizedBox(height: AppSpacing.lg),
        if (notChosen.isNotEmpty) ...[
          const _SectionHeading('Add an interest'),
          const SizedBox(height: AppSpacing.sm),
          for (final interest in notChosen)
            _InterestRow(
              key: ValueKey('not-chosen-${interest.id}'),
              label: interest.english,
              icon: Icons.add_circle_outline,
              iconColor: AppColors.cyan,
              tooltip: 'Add ${interest.english}',
              onPressed: () => _add(interest),
            ),
        ],
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InterestRow extends StatelessWidget {
  const _InterestRow({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: Icon(icon, color: iconColor),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
