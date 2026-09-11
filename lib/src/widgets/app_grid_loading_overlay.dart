import 'package:flutter/material.dart';

/// Production-ready loading overlay rendered over [AppGrid] during async data operations.
class AppGridLoadingOverlay extends StatelessWidget {
  /// Optional message displayed below the progress indicator.
  final String? message;

  /// Custom barrier background color. Defaults to semi-transparent surface adapting to brightness.
  final Color? barrierColor;

  /// Custom loading indicator widget. Defaults to [CircularProgressIndicator].
  final Widget? indicator;

  const AppGridLoadingOverlay({
    super.key,
    this.message,
    this.barrierColor,
    this.indicator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBarrier = isDark
        ? Colors.black.withAlpha(140)
        : Colors.white.withAlpha(170);

    return Container(
      color: barrierColor ?? defaultBarrier,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator ?? const CircularProgressIndicator(strokeWidth: 3.0),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
