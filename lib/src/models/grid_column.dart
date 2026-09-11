import 'package:flutter/widgets.dart';
import 'row_index_info.dart';
import 'sort_criteria.dart';

/// Position where a column can be pinned/frozen.
enum GridColumnPin {
  none,
  left,
  right;

  bool get isPinned => this != GridColumnPin.none;
}

/// Custom cell builder signature for a specific column in [AppGrid].
typedef ColumnCellBuilder<T> = Widget Function(
  BuildContext context,
  T rowData,
  RowIndexInfo indexInfo,
);

/// Custom header builder signature for a specific column in [AppGrid].
typedef ColumnHeaderBuilder = Widget Function(
  BuildContext context,
  SortDirection sortDirection,
  VoidCallback onSortToggle,
);

/// Custom footer builder signature encapsulated within a specific [GridColumn].
typedef ColumnFooterBuilder = Widget Function(
  BuildContext context,
  List<dynamic> currentVisibleData,
);

/// Configuration and schema definition for an [AppGrid] column.
class GridColumn {
  /// Unique identifier for this column.
  final String id;

  /// Display title / label in the column header.
  final String label;

  /// Initial width of the column in logical pixels before auto-stretch or user resize.
  final double initialWidth;

  /// Minimum width below which the column cannot be resized or shrunk.
  final double minWidth;

  /// Optional maximum width cap for user resizing.
  final double? maxWidth;

  /// Pinning status: [GridColumnPin.none], [GridColumnPin.left], or [GridColumnPin.right].
  final GridColumnPin pin;

  /// Whether the column is visible in the viewport.
  final bool isVisible;

  /// Whether sorting is enabled for this column.
  final bool isSortable;

  /// Whether the user can drag-resize the column.
  final bool isResizable;

  /// Whether the user can drag-and-drop to reorder this column.
  final bool isReorderable;

  /// Optional comparator function for sorting rows by this column.
  final int Function(dynamic a, dynamic b)? comparator;

  /// Optional accessor for reading the column's raw value from row data.
  final dynamic Function(dynamic rowData)? valueGetter;

  /// Column-level modular footer builder. Takes precedence over global grid footerBuilder.
  final ColumnFooterBuilder? footerBuilder;

  /// Column-level modular cell builder for this specific column.
  final ColumnCellBuilder<dynamic>? cellBuilder;

  /// Column-level modular header builder for this specific column.
  final ColumnHeaderBuilder? headerBuilder;

  const GridColumn({
    required this.id,
    required this.label,
    this.initialWidth = 120.0,
    this.minWidth = 60.0,
    this.maxWidth,
    this.pin = GridColumnPin.none,
    this.isVisible = true,
    this.isSortable = true,
    this.isResizable = true,
    this.isReorderable = true,
    this.comparator,
    this.valueGetter,
    this.footerBuilder,
    this.cellBuilder,
    this.headerBuilder,
  }) : assert(minWidth >= 0, 'minWidth cannot be negative');

  bool get isFrozen => pin != GridColumnPin.none;

  GridColumn copyWith({
    String? id,
    String? label,
    double? initialWidth,
    double? minWidth,
    double? maxWidth,
    GridColumnPin? pin,
    bool? isVisible,
    bool? isSortable,
    bool? isResizable,
    bool? isReorderable,
    int Function(dynamic a, dynamic b)? comparator,
    dynamic Function(dynamic rowData)? valueGetter,
    ColumnFooterBuilder? footerBuilder,
    ColumnCellBuilder<dynamic>? cellBuilder,
    ColumnHeaderBuilder? headerBuilder,
  }) {
    return GridColumn(
      id: id ?? this.id,
      label: label ?? this.label,
      initialWidth: initialWidth ?? this.initialWidth,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      pin: pin ?? this.pin,
      isVisible: isVisible ?? this.isVisible,
      isSortable: isSortable ?? this.isSortable,
      isResizable: isResizable ?? this.isResizable,
      isReorderable: isReorderable ?? this.isReorderable,
      comparator: comparator ?? this.comparator,
      valueGetter: valueGetter ?? this.valueGetter,
      footerBuilder: footerBuilder ?? this.footerBuilder,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      headerBuilder: headerBuilder ?? this.headerBuilder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridColumn &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          pin == other.pin &&
          isVisible == other.isVisible &&
          isSortable == other.isSortable &&
          isResizable == other.isResizable &&
          isReorderable == other.isReorderable;

  @override
  int get hashCode =>
      id.hashCode ^
      label.hashCode ^
      pin.hashCode ^
      isVisible.hashCode ^
      isSortable.hashCode;

  @override
  String toString() =>
      'GridColumn(id: $id, label: $label, pin: $pin, isVisible: $isVisible)';
}
