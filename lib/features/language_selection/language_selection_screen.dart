import 'package:flutter/material.dart';

import '../../core/enums/language.dart';
import '../../shared/design/app_colors.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({required this.onLanguageSelected, super.key});

  final void Function(Language language) onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FlagButton(
              imagePath: 'assets/images/flag_es.png',
              onTap: () => onLanguageSelected(Language.spanish),
            ),
            const SizedBox(width: 16),
            _FlagButton(
              imagePath: 'assets/images/flag_pt.png',
              onTap: () => onLanguageSelected(Language.portuguese),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagButton extends StatefulWidget {
  const _FlagButton({required this.imagePath, required this.onTap});

  final String imagePath;
  final VoidCallback onTap;

  @override
  State<_FlagButton> createState() => _FlagButtonState();
}

class _FlagButtonState extends State<_FlagButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            widget.imagePath,
            width: 108,
            height: 72,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
