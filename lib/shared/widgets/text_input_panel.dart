import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/app_colors.dart';

class TextInputPanel extends StatelessWidget {
  const TextInputPanel({
    required this.controller,
    required this.characterLimit,
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final int characterLimit;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        inputFormatters: [LengthLimitingTextInputFormatter(characterLimit)],
        onChanged: onChanged,
        cursorColor: AppColors.cyan,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          height: 24 / 15,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
