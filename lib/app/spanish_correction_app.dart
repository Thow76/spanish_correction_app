import 'package:flutter/material.dart';

import '../features/corrections/data/gemini_correction_service.dart';
import '../features/navigation/presentation/app_shell.dart';
import 'app_config.dart';
import 'app_theme.dart';

class SpanishCorrectionApp extends StatelessWidget {
  const SpanishCorrectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.fromEnvironment();
    final correctionService = GeminiCorrectionService(
      apiKey: config.geminiApiKey,
      model: config.geminiModel,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Corrector de Espanol',
      theme: buildAppTheme(),
      home: AppShell(correctionService: correctionService),
    );
  }
}
