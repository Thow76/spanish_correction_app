import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../data/partner_settings_store.dart';
import '../domain/partner_settings.dart';

/// Asks the learner for a time of day, starting from [initial]. Null when
/// the learner cancels. A parameter so tests can answer without the clock
/// dialog.
typedef GreetingTimePicker =
    Future<GreetingTime?> Function(BuildContext context, GreetingTime initial);

/// The partner settings (decision B4, part 1; build step 5.1).
///
/// Opened from "Partner greetings" in the settings sheet. One switch turns
/// the partner's greetings on or off; under it the learner sets up to two
/// times of day. Every change is saved straight away.
class PartnerSettingsScreen extends StatefulWidget {
  const PartnerSettingsScreen({
    this.store = const PartnerSettingsStore(),
    this.pickTime = _pickWithClockDialog,
    super.key,
  });

  final PartnerSettingsStore store;
  final GreetingTimePicker pickTime;

  @override
  State<PartnerSettingsScreen> createState() => _PartnerSettingsScreenState();
}

Future<GreetingTime?> _pickWithClockDialog(
  BuildContext context,
  GreetingTime initial,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    helpText: 'Greeting time',
  );
  return picked == null ? null : GreetingTime(picked.hour, picked.minute);
}

class _PartnerSettingsScreenState extends State<PartnerSettingsScreen> {
  PartnerSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await widget.store.load();
    if (mounted) {
      setState(() => _settings = settings);
    }
  }

  Future<void> _apply(PartnerSettings next) async {
    setState(() => _settings = next);
    await widget.store.save(next);
  }

  Future<void> _changeTime(int index) async {
    final settings = _settings!;
    final picked = await widget.pickTime(context, settings.times[index]);
    if (picked != null && mounted) {
      await _apply(_settings!.withTimeChanged(index, picked));
    }
  }

  Future<void> _addTime() async {
    final picked = await widget.pickTime(context, _settings!.suggestedNewTime);
    if (picked != null && mounted) {
      await _apply(_settings!.withTimeAdded(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Partner greetings'),
      ),
      body: settings == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                SwitchListTile(
                  key: const ValueKey('partner-greetings-switch'),
                  title: const Text(
                    'Partner greetings',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    settings.greetingsOn
                        ? 'Your partner says hello at the times below.'
                        : 'Your partner waits for you to start a chat.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  value: settings.greetingsOn,
                  activeThumbColor: AppColors.cyan,
                  activeTrackColor: AppColors.cyan.withValues(alpha: 0.4),
                  onChanged: (on) => _apply(settings.withGreetingsOn(on)),
                ),
                if (settings.greetingsOn) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xs,
                    ),
                    child: Text(
                      'Greeting times (up to two a day)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (var i = 0; i < settings.times.length; i++)
                    ListTile(
                      key: ValueKey('greeting-time-$i'),
                      leading: const Icon(
                        Icons.schedule,
                        color: AppColors.cyan,
                      ),
                      title: Text(
                        settings.times[i].toLabel(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => _changeTime(i),
                      trailing: settings.times.length > 1
                          ? IconButton(
                              key: ValueKey('remove-greeting-time-$i'),
                              tooltip: 'Remove this time',
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () => _apply(
                                settings.withTimeRemoved(settings.times[i]),
                              ),
                            )
                          : null,
                    ),
                  if (settings.canAddTime)
                    ListTile(
                      key: const ValueKey('add-greeting-time'),
                      leading: const Icon(Icons.add, color: AppColors.cyan),
                      title: const Text(
                        'Add a second time',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: _addTime,
                    ),
                ],
              ],
            ),
    );
  }
}
