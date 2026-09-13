import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/grid_column.dart';
import '../models/compact_column_group.dart';
import 'auto_stretch_calculator.dart';

/// Layout computation result for pinned and unpinned column sections.
class ComputedPaneLayout {
  final List<GridColumn> columns;
  final List<CompactColumnGroup> groups;
  final Map<String, double> widths;
  final Map<String, double> offsets;
  final double totalWidth;

  const ComputedPaneLayout({
    required this.columns,
    this.groups = const [],
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

  /// Cached active computed column widths from the last layout pass.
  Map<String, double> _lastComputedWidths = {};

  /// Whether auto-stretch is enabled when no manual resizes exist.
  bool autoStretchEnabled;

  /// Whether the table layout is currently rendered in compact mode.
  bool compactMode;

  ColumnLayoutManager({
    AutoStretchCalculator stretchCalculator = const AutoStretchCalculator(),
    this.autoStretchEnabled = true,
    this.compactMode = false,
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
    if (_userResizedWidths.isEmpty && _lastComputedWidths.isNotEmpty) {
      _userResizedWidths.addAll(_lastComputedWidths);
    }

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

  /// Updates runtime width for an entire column group (synchronizing both columns in a pair).
  void resizeColumnGroup({
    required CompactColumnGroup group,
    required double newWidth,
  }) {
    if (_userResizedWidths.isEmpty && _lastComputedWidths.isNotEmpty) {
      _userResizedWidths.addAll(_lastComputedWidths);
    }

    double clamped = newWidth;
    if (clamped < group.minWidth) {
      clamped = group.minWidth;
    }
    if (group.maxWidth != null && clamped > group.maxWidth!) {
      clamped = group.maxWidth!;
    }

    for (final col in group.columns) {
      _userResizedWidths[col.id] = clamped;
    }
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

  /// Sets group width to auto-fit content length across both columns in the group.
  void autoFitColumnGroup({
    required CompactColumnGroup group,
    required double contentWidth,
    double horizontalPadding = 32.0,
  }) {
    final double targetWidth = contentWidth + horizontalPadding;
    resizeColumnGroup(group: group, newWidth: targetWidth);
  }

  /// Clears in-memory resizing overrides.
  void resetWidths() {
    _userResizedWidths.clear();
    _lastComputedWidths.clear();
    notifyListeners();
  }

  /// Computes full grid layout for active [visibleColumns] given [availableViewportWidth].
  ComputedGridLayout computeLayout({
    required List<GridColumn> visibleColumns,
    required double availableViewportWidth,
    bool? compactMode,
  }) {
    final isCompact = compactMode ?? this.compactMode;

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

    final leftGroups = CompactColumnGroup.buildGroups(columns: leftCols, compactMode: isCompact);
    final centerGroups = CompactColumnGroup.buildGroups(columns: centerCols, compactMode: isCompact);
    final rightGroups = CompactColumnGroup.buildGroups(columns: rightCols, compactMode: isCompact);

    final allGroups = [...leftGroups, ...centerGroups, ...rightGroups];

    final representativeColumns = allGroups.map((g) {
      return GridColumn(
        id: g.id,
        label: g.topColumn.label,
        initialWidth: g.initialWidth,
        minWidth: g.minWidth,
        maxWidth: g.maxWidth,
        pin: g.pin,
      );
    }).toList();

    final groupUserResizedWidths = <String, double>{};
    for (final g in allGroups) {
      double? groupResized;
      for (final col in g.columns) {
        final r = _userResizedWidths[col.id];
        if (r != null) {
          groupResized = (groupResized == null) ? r : math.max(groupResized, r);
        }
      }
      if (groupResized != null) {
        groupUserResizedWidths[g.id] = groupResized;
      }
    }

    final calculatedGroupWidths = _stretchCalculator.calculateWidths(
      columns: representativeColumns,
      availableViewportWidth: availableViewportWidth,
      userResizedWidths: groupUserResizedWidths,
      disableAutoStretch: !autoStretchEnabled,
    );

    final Map<String, double> allWidths = {};
    for (final g in allGroups) {
      final w = calculatedGroupWidths[g.id] ?? g.initialWidth;
      for (final col in g.columns) {
        allWidths[col.id] = w;
      }
    }
    _lastComputedWidths = allWidths;

    final leftPane = _computePane(leftCols, leftGroups, allWidths);
    final centerPane = _computePane(centerCols, centerGroups, allWidths);
    final rightPane = _computePane(rightCols, rightGroups, allWidths);

    final totalGridWidth = leftPane.totalWidth + centerPane.totalWidth + rightPane.totalWidth;

    return ComputedGridLayout(
      leftPane: leftPane,
      centerPane: centerPane,
      rightPane: rightPane,
      allWidths: allWidths,
      totalGridWidth: totalGridWidth,
    );
  }

  ComputedPaneLayout _computePane(
    List<GridColumn> cols,
    List<CompactColumnGroup> groups,
    Map<String, double> allWidths,
  ) {
    final Map<String, double> widths = {};
    final Map<String, double> offsets = {};
    double currentOffset = 0.0;

    for (final group in groups) {
      final w = allWidths[group.topColumn.id] ?? group.initialWidth;
      for (final col in group.columns) {
        widths[col.id] = w;
        offsets[col.id] = currentOffset;
      }
      currentOffset += w;
    }

    return ComputedPaneLayout(
      columns: cols,
      groups: groups,
      widths: widths,
      offsets: offsets,
      totalWidth: currentOffset,
    );
  }
}
