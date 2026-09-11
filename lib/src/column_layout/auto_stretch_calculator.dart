import '../models/grid_column.dart';

/// Computes effective column widths implementing auto-stretch when total
/// column minimum width is less than available viewport width (REQ-COL-05 & AC-06).
///
/// Rules:
/// 1. Auto-stretch ONLY activates when the sum of [minWidth] across all visible columns
///    is strictly less than [availableViewportWidth].
/// 2. If the sum of [minWidth] exceeds or equals [availableViewportWidth], auto-stretch is
///    inhibited and columns retain their natural base widths, enabling horizontal scrolling.
/// 3. Auto-stretch is automatically DISABLED whenever the user manually resizes any column
///    ([userResizedWidths] is non-empty) or when [disableAutoStretch] is set.
class AutoStretchCalculator {
  const AutoStretchCalculator();

  /// Calculates effective widths for [columns] given [availableViewportWidth]
  /// and any temporary in-memory [userResizedWidths].
  ///
  /// In accordance with REQ-STATE-03, width values are strictly calculated
  /// dynamically at layout time and are never read from persistence storage.
  Map<String, double> calculateWidths({
    required List<GridColumn> columns,
    required double availableViewportWidth,
    Map<String, double> userResizedWidths = const {},
    bool disableAutoStretch = false,
  }) {
    if (columns.isEmpty) return {};

    final Map<String, double> baseWidths = {};
    double totalBaseWidth = 0.0;
    double totalMinWidth = 0.0;

    for (final col in columns) {
      final overrideWidth = userResizedWidths[col.id];
      double width = overrideWidth ?? col.initialWidth;
      // Clamp to minWidth
      if (width < col.minWidth) {
        width = col.minWidth;
      }
      if (col.maxWidth != null && width > col.maxWidth!) {
        width = col.maxWidth!;
      }
      baseWidths[col.id] = width;
      totalBaseWidth += width;
      totalMinWidth += col.minWidth;
    }

    // Rule 3: Auto-stretch is DISABLED when user has manually resized any column
    // or when explicitly disabled.
    final bool hasManualResize = userResizedWidths.isNotEmpty;
    if (disableAutoStretch || hasManualResize) {
      return baseWidths;
    }

    // Rule 2: If total minimum width exceeds or equals the screen width,
    // auto-stretch is disabled to allow natural horizontal scroll.
    if (totalMinWidth >= availableViewportWidth || availableViewportWidth <= 0) {
      return baseWidths;
    }

    // Rule 1: Auto-stretch when total minWidth is lower than screen width.
    // If total base width is also less than available viewport width,
    // stretch proportionally to fill 100% of the available viewport width.
    if (totalBaseWidth < availableViewportWidth && totalBaseWidth > 0) {
      final double remainingSpace = availableViewportWidth - totalBaseWidth;
      final Map<String, double> stretchedWidths = {};

      double accumulated = 0.0;
      for (var i = 0; i < columns.length; i++) {
        final col = columns[i];
        final base = baseWidths[col.id]!;
        if (i == columns.length - 1) {
          // Last column absorbs rounding delta to guarantee exact fill
          final lastWidth = availableViewportWidth - accumulated;
          stretchedWidths[col.id] = lastWidth > col.minWidth ? lastWidth : col.minWidth;
        } else {
          final extra = remainingSpace * (base / totalBaseWidth);
          final finalWidth = base + extra;
          stretchedWidths[col.id] = finalWidth;
          accumulated += finalWidth;
        }
      }
      return stretchedWidths;
    }

    // If totalBaseWidth >= availableViewportWidth but totalMinWidth < availableViewportWidth:
    // Scale down from base width towards minWidth so it fits the screen without overflow.
    if (totalBaseWidth >= availableViewportWidth && totalMinWidth < availableViewportWidth) {
      final double shrinkableSpace = totalBaseWidth - totalMinWidth;
      if (shrinkableSpace > 0) {
        final double excess = totalBaseWidth - availableViewportWidth;
        final Map<String, double> fittedWidths = {};
        double accumulated = 0.0;

        for (var i = 0; i < columns.length; i++) {
          final col = columns[i];
          final base = baseWidths[col.id]!;
          if (i == columns.length - 1) {
            final lastWidth = availableViewportWidth - accumulated;
            fittedWidths[col.id] = lastWidth > col.minWidth ? lastWidth : col.minWidth;
          } else {
            final colShrinkable = base - col.minWidth;
            final colReduction = excess * (colShrinkable / shrinkableSpace);
            final finalWidth = base - colReduction;
            fittedWidths[col.id] = finalWidth;
            accumulated += finalWidth;
          }
        }
        return fittedWidths;
      }
    }

    return baseWidths;
  }
}
