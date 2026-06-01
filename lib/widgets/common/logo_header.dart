import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LogoHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool lightMode;
  const LogoHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      this.lightMode = false});

  @override
  Widget build(BuildContext context) {
    final color = lightMode ? Colors.white : AppColors.primary;
    return Column(
      children: [
        Icon(Icons.landscape_rounded, color: color, size: 56),
        const SizedBox(height: 12),
        Text(title,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(subtitle,
            style:
                TextStyle(fontSize: 14, color: color.withValues(alpha: 0.8))),
      ],
    );
  }
}
