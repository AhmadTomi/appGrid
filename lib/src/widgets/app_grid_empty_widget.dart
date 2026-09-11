import 'package:flutter/material.dart';

/// Pre-built placeholder widget rendered when the table has zero records.
class AppGridEmptyWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const AppGridEmptyWidget({
    super.key,
    this.message = 'No data available',
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurface.withAlpha(80),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
