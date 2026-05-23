import 'package:flutter/material.dart';

import '../design/app_colors.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({required this.title, this.leading, super.key});

  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Sora',
                fontSize: 28,
                fontWeight: FontWeight.w600,
                height: 36 / 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
