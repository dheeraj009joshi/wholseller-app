import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';

class TrustIndicator extends StatelessWidget {
  final IconData icon;
  final String text;

  const TrustIndicator({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTheme.bodySmall,
        ),
      ],
    );
  }
}
