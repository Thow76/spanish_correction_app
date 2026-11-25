import 'package:flutter/material.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_colors.dart';
import '../../corrections/application/submit_correction_use_case.dart';
import '../../saved/application/save_correction_use_case.dart';
import '../application/transcription_service.dart';
import 'write_screen.dart';

/// The Check a phrase page as a route of its own, opened from the icon on
/// Home (decisions B2 and B5; build step 3.1). It shows [WriteScreen]
/// unchanged under a back arrow, laid out as the old Write tab laid it out.
class CheckAPhrasePage extends StatelessWidget {
  const CheckAPhrasePage({
    required this.submitCorrectionUseCase,
    required this.saveCorrectionUseCase,
    required this.transcriptionService,
    required this.language,
    super.key,
  });

  final SubmitCorrectionUseCase submitCorrectionUseCase;
  final SaveCorrectionUseCase saveCorrectionUseCase;
  final TranscriptionService transcriptionService;
  final Language language;

  @override
  Widget build(BuildContext context) {
    // Read above the Scaffold, as the app shell does: here MediaQuery still
    // carries the real keyboard inset (the Scaffold zeroes it for its body),
    // and reading it rebuilds this page when the keyboard animates in or out.
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textSecondary),
      ),
      body: WriteScreen(
        submitCorrectionUseCase: submitCorrectionUseCase,
        saveCorrectionUseCase: saveCorrectionUseCase,
        transcriptionService: transcriptionService,
        language: language,
        keyboardVisible: keyboardVisible,
      ),
    );
  }
}
