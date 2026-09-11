import 'package:flutter/foundation.dart';
import '../models/grid_column.dart';
import 'auto_stretch_calculator.dart';

/// Layout computation result for pinned and unpinned column sections.
class ComputedPaneLayout {
  final List<GridColumn> columns;
  final Map<String, double> widths;
  final Map<String, double> offsets;
  final double totalWidth;

  const ComputedPaneLayout({
    required this.columns,
    required this.widths,
    required this.offsets,
    required this.totalWidth,
  });
}

/// Overall computed grid layout partitioning columns into Left Pinned, Center Scrollable,
/// and Right Pinned panes with auto-stretch calculation.
class ComputedGridLayout {
  final ComputedPaneLayout leftPane;
  final ComputedPaneLayout centerPane;
  final ComputedPaneLayout rightPane;
  final Map<String, double> allWidths;
  final double totalGridWidth;

  const ComputedGridLayout({
    required this.leftPane,
    required this.centerPane,
    required this.rightPane,
    required this.allWidths,
    required this.totalGridWidth,
  });
}

/// Manages interactive column resizing, auto-fit content sizing, and layout partitioning.
///
/// NOTE: In strict accordance with REQ-STATE-03, resized widths are strictly runtime in-memory
/// and NEVER persisted.
class ColumnLayoutManager extends ChangeNotifier {
  final AutoStretchCalculator _stretchCalculator;

  /// In-memory runtime column widths overridden by user drag-resize or auto-fit.
  final Map<String, double> _userResizedWidths = {};

  /// Whether auto-stretch is enabled when no manual resizes exist.
  bool autoStretchEnabled;

  ColumnLayoutManager({
    AutoStretchCalculator stretchCalculator = const AutoStretchCalculator(),
    this.autoStretchEnabled = true,
  }) : _stretchCalculator = stretchCalculator;

  /// Whether the user has manually resized any column in this session.
  bool get hasManualResize => _userResizedWidths.isNotEmpty;

  /// Retrieves runtime resized width for a column, if any.
  double? getUserResizedWidth(String columnId) => _userResizedWidths[columnId];

  /// Updates runtime width for a column during drag-resizing.
  void resizeColumn({
    required GridColumn column,
    required double newWidth,
  }) {
    double clamped = newWidth;
    if (clamped < column.minWidth) {
      clamped = column.minWidth;
    }
    if (column.maxWidth != null && clamped > column.maxWidth!) {
      clamped = column.maxWidth!;
    }

    _userResizedWidths[column.id] = clamped;
    notifyListeners();
  }

  /// Sets column width to auto-fit content length.
  void autoFitColumn({
    required GridColumn column,
    required double contentWidth,
    double horizontalPadding = 32.0,
  }) {
    final double targetWidth = contentWidth + horizontalPadding;
    resizeColumn(column: column, newWidth: targetWidth);
  }

  /// Clears in-memory resizing overrides.
  void resetWidths() {
    _userResizedWidths.clear();
    notifyListeners();
  }

  /// Computes full grid layout for active [visibleColumns] given [availableViewportWidth].
  ComputedGridLayout computeLayout({
    required List<GridColumn> visibleColumns,
    required double availableViewportWidth,
  }) {
    final allWidths = _stretchCalculator.calculateWidths(
      columns: visibleColumns,
      availableViewportWidth: availableViewportWidth,
      userResizedWidths: _userResizedWidths,
      disableAutoStretch: !autoStretchEnabled,
    );

    final leftCols = <GridColumn>[];
    final centerCols = <GridColumn>[];
    final rightCols = <GridColumn>[];

    for (final col in visibleColumns) {
      switch (col.pin) {
        case GridColumnPin.left:
          leftCols.add(col);
          break;
        case GridColumnPin.right:
          rightCols.add(col);
          break;
        case GridColumnPin.none:
          centerCols.add(col);
          break;
      }
    }

    final leftPane = _computePane(leftCols, allWidths);
    final centerPane = _computePane(centerCols, allWidths);
    final rightPane = _computePane(rightCols, allWidths);

    final totalGridWidth = leftPane.totalWidth + centerPane.totalWidth + rightPane.totalWidth;

    return ComputedGridLayout(
      leftPane: leftPane,
      centerPane: centerPane,
      rightPane: rightPane,
      allWidths: allWidths,
      totalGridWidth: totalGridWidth,
    );
  }

  ComputedPaneLayout _computePane(List<GridColumn> cols, Map<String, double> allWidths) {
    final Map<String, double> widths = {};
    final Map<String, double> offsets = {};
    double currentOffset = 0.0;

    for (final col in cols) {
      final w = allWidths[col.id] ?? col.initialWidth;
      widths[col.id] = w;
      offsets[col.id] = currentOffset;
      currentOffset += w;
    }

    return ComputedPaneLayout(
      columns: cols,
      widths: widths,
      offsets: offsets,
      totalWidth: currentOffset,
    );
  }
}
