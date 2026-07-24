import 'package:flutter/material.dart';

import '../../../core/enums/language.dart';
import '../../../core/services/walkthrough_service.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/application/correction_service.dart';
import '../../write/application/transcription_service.dart';
import 'game_session_builder_screen.dart';
import 'widgets/game_tile.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({
    required this.repositoryController,
    required this.transcriptionService,
    required this.correctionService,
    required this.walkthroughService,
    required this.language,
    super.key,
  });

  final CorrectionRepositoryController repositoryController;
  final TranscriptionService transcriptionService;
  final CorrectionService correctionService;
  final WalkthroughService walkthroughService;
  final Language language;

  @override
  Widget build(BuildContext context) {
    final soonLabel = switch (language) {
      Language.spanish => 'Próximamente',
      Language.portuguese => 'Em breve',
    };

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            children: [
              const AppHeader(title: 'Aprender'),
              const SizedBox(height: AppSpacing.xl),
              GameTile(
                title: switch (language) {
                  Language.spanish => 'Traducir frases',
                  Language.portuguese => 'Traduzir frases',
                },
                description: switch (language) {
                  Language.spanish =>
                    'Mira la frase en inglés y dila en español.',
                  Language.portuguese =>
                    'Veja a frase em inglês e diga em português.',
                },
                icon: Icons.translate,
                onTap: () => _openPromptedProductionGame(context),
              ),
              const SizedBox(height: AppSpacing.md),
              GameTile(
                title: switch (language) {
                  Language.spanish => 'Ordenar palabras',
                  Language.portuguese => 'Ordenar palavras',
                },
                description: soonLabel,
                icon: Icons.reorder,
                enabled: false,
                disabledLabel: soonLabel,
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.md),
              GameTile(
                title: switch (language) {
                  Language.spanish => 'Tarjetas',
                  Language.portuguese => 'Cartões',
                },
                description: soonLabel,
                icon: Icons.style,
                enabled: false,
                disabledLabel: soonLabel,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPromptedProductionGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GameSessionBuilderScreen(
          repositoryController: repositoryController,
          transcriptionService: transcriptionService,
          correctionService: correctionService,
          walkthroughService: walkthroughService,
          language: language,
        ),
      ),
    );
  }
}
