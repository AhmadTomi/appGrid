import 'package:flutter/widgets.dart';
import 'app_grid_header_config.dart';
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

  /// Whether the column can be hidden. Defaults to true.
  ///
  /// When false, the column cannot be hidden via the header menu or the column chooser.
  final bool canHide;

  /// Whether this column can be merged with an adjacent [canCompact] column in compact mode.
  /// Defaults to true.
  final bool canCompact;

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

  /// Alignment for cell child widgets. Defaults to [Alignment.centerLeft].
  final Alignment cellAlignment;

  /// Alignment for column header child widgets. Defaults to [Alignment.center].
  final Alignment headerAlignment;

  /// Whether this column is a dedicated drag handle column for manual row reordering.
  final bool isRowDragHandle;

  /// Optional custom icon widget for row drag handle.
  final Widget? rowDragIcon;

  /// Optional custom icon widget when row drag handle is disabled (e.g. sorting active).
  final Widget? rowDragDisabledIcon;

  /// Optional custom icon widget for the column context/sort menu in unsorted state.
  final Widget? menuIcon;

  /// Optional custom icon widget displayed when this column is sorted in ascending order.
  final Widget? sortAscendingIcon;

  /// Optional custom icon widget displayed when this column is sorted in descending order.
  final Widget? sortDescendingIcon;

  /// Optional column-specific header configuration overriding grid-level defaults.
  final AppGridHeaderConfig? headerConfig;

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
    this.canHide = true,
    this.canCompact = true,
    this.comparator,
    this.valueGetter,
    this.footerBuilder,
    this.cellBuilder,
    this.headerBuilder,
    this.cellAlignment = Alignment.centerLeft,
    this.headerAlignment = Alignment.center,
    this.isRowDragHandle = false,
    this.rowDragIcon,
    this.rowDragDisabledIcon,
    this.menuIcon,
    this.sortAscendingIcon,
    this.sortDescendingIcon,
    this.headerConfig,
  }) : assert(minWidth >= 0, 'minWidth cannot be negative');

  /// Factory constructor creating a dedicated drag handle column for manual row reordering.
  ///
  /// Typically pinned to [GridColumnPin.left] with a compact fixed width, non-sortable,
  /// non-resizable, and cannot be hidden.
  factory GridColumn.rowDragHandle({
    String id = '__row_drag_handle__',
    String label = '',
    double width = 48.0,
    GridColumnPin pin = GridColumnPin.left,
    Widget? icon,
    Widget? disabledIcon,
    Alignment alignment = Alignment.center,
  }) {
    return GridColumn(
      id: id,
      label: label,
      initialWidth: width,
      minWidth: width,
      maxWidth: width,
      pin: pin,
      isSortable: false,
      isResizable: false,
      isReorderable: false,
      canHide: false,
      canCompact: false,
      isRowDragHandle: true,
      rowDragIcon: icon,
      rowDragDisabledIcon: disabledIcon,
      cellAlignment: alignment,
      headerAlignment: alignment,
    );
  }

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
    bool? canHide,
    bool? canCompact,
    int Function(dynamic a, dynamic b)? comparator,
    dynamic Function(dynamic rowData)? valueGetter,
    ColumnFooterBuilder? footerBuilder,
    ColumnCellBuilder<dynamic>? cellBuilder,
    ColumnHeaderBuilder? headerBuilder,
    Alignment? cellAlignment,
    Alignment? headerAlignment,
    Widget? menuIcon,
    Widget? sortAscendingIcon,
    Widget? sortDescendingIcon,
    AppGridHeaderConfig? headerConfig,
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
      canHide: canHide ?? this.canHide,
      canCompact: canCompact ?? this.canCompact,
      comparator: comparator ?? this.comparator,
      valueGetter: valueGetter ?? this.valueGetter,
      footerBuilder: footerBuilder ?? this.footerBuilder,
      cellBuilder: cellBuilder ?? this.cellBuilder,
      headerBuilder: headerBuilder ?? this.headerBuilder,
      cellAlignment: cellAlignment ?? this.cellAlignment,
      headerAlignment: headerAlignment ?? this.headerAlignment,
      isRowDragHandle: isRowDragHandle,
      rowDragIcon: rowDragIcon,
      rowDragDisabledIcon: rowDragDisabledIcon,
      menuIcon: menuIcon ?? this.menuIcon,
      sortAscendingIcon: sortAscendingIcon ?? this.sortAscendingIcon,
      sortDescendingIcon: sortDescendingIcon ?? this.sortDescendingIcon,
      headerConfig: headerConfig ?? this.headerConfig,
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
          isReorderable == other.isReorderable &&
          canHide == other.canHide &&
          canCompact == other.canCompact &&
          cellAlignment == other.cellAlignment &&
          headerAlignment == other.headerAlignment &&
          isRowDragHandle == other.isRowDragHandle &&
          headerConfig == other.headerConfig;

  @override
  int get hashCode =>
      id.hashCode ^
      label.hashCode ^
      pin.hashCode ^
      isVisible.hashCode ^
      isSortable.hashCode ^
      canHide.hashCode ^
      canCompact.hashCode ^
      cellAlignment.hashCode ^
      headerAlignment.hashCode ^
      isRowDragHandle.hashCode ^
      headerConfig.hashCode;

  @override
  String toString() =>
      'GridColumn(id: $id, label: $label, pin: $pin, isVisible: $isVisible, canHide: $canHide, canCompact: $canCompact, cellAlignment: $cellAlignment, headerAlignment: $headerAlignment, isRowDragHandle: $isRowDragHandle, headerConfig: $headerConfig)';
}
