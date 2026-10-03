import 'package:flutter/material.dart';
import '../widgets/app_grid_scrollbar.dart';

/// Comprehensive styling configuration for [AppGrid].
///
/// Encapsulates row dimensions, row colors, header styling, footer styling,
/// grid dividers, scrollbars, text styles (header, row/cell, and context menu),
/// and header icons in a single immutable class with a fluent [copyWith] method.
///
/// PlutoGrid-style icons (context menu `≡`, rotated green sort icon for ascending,
/// and red sort icon for descending) are built-in by default.
class AppGridStyle {
  // --- Row & Cell Styling ---
  /// Height of standard grid rows in logical pixels. Defaults to 48.0.
  final double rowHeight;

  /// Optional text style for table body cells / rows. Defaults to 13pt regular if null.
  final TextStyle? rowTextStyle;

  /// Optional padding applied to table row cells.
  final EdgeInsetsGeometry? rowPadding;

  /// Background color applied to the selected row.
  final Color? selectedRowColor;

  /// Background color applied to even-indexed rows (0, 2, 4, ...).
  final Color? evenRowColor;

  /// Background color applied to odd-indexed rows (1, 3, 5, ...).
  final Color? oddRowColor;

  // --- Header Styling ---
  /// Height of the grid column header in logical pixels. Defaults to 48.0.
  final double headerHeight;

  /// Optional background color for header cells.
  final Color? headerBackgroundColor;

  /// Optional text style applied to column header labels. Defaults to 13pt bold if null.
  final TextStyle? headerTextStyle;

  /// Optional padding applied to column header labels / cells.
  final EdgeInsetsGeometry? headerPadding;

  // --- Menu Styling ---
  /// Default text style applied to column header context menu items. Defaults to 13pt regular.
  final TextStyle menuTextStyle;

  // --- Footer Styling ---
  /// Optional height of the grid footer in logical pixels.
  final double? footerHeight;

  /// Optional background color for the footer bar.
  final Color? footerBackgroundColor;

  /// Optional text style applied to column footer cells. Defaults to 12pt bold if null.
  final TextStyle? footerTextStyle;

  /// Optional padding applied to column footer cells.
  final EdgeInsetsGeometry? footerPadding;

  // --- Grid Lines & Borders ---
  /// Outer border color around the entire grid.
  final Color? borderColor;

  /// Divider color between table cells, rows, and headers.
  final Color? gridLineColor;

  /// Whether horizontal divider lines are rendered between rows. Defaults to true.
  final bool showHorizontalGridLines;

  /// Whether vertical divider lines are rendered between columns. Defaults to false.
  final bool showVerticalGridLines;

  /// Custom color for vertical grid dividers.
  final Color? verticalGridLineColor;

  // --- Scrollbar Styling ---
  /// Whether to render the horizontal scrollbar. Defaults to true.
  final bool showHorizontalScrollbar;

  /// Whether to render the vertical scrollbar. Defaults to true.
  final bool showVerticalScrollbar;

  /// Visibility behavior of both scrollbars (shorthand).
  final AppGridScrollbarVisibility? scrollbarVisibility;

  /// Specific visibility behavior of the vertical scrollbar.
  final AppGridScrollbarVisibility? verticalScrollbarVisibility;

  /// Specific visibility behavior of the horizontal scrollbar.
  final AppGridScrollbarVisibility? horizontalScrollbarVisibility;

  /// Thickness of horizontal and vertical scrollbars. Defaults to 10.0.
  final double scrollbarThickness;

  /// Custom color for the scrollbar thumb.
  final Color? scrollbarThumbColor;

  /// Custom color for the scrollbar track background.
  final Color? scrollbarTrackColor;

  // --- Icon Styling ---
  /// Optional custom widget for column context/sort menu in unsorted state.
  /// Defaults to PlutoGrid's `Icons.dehaze` ('≡').
  final Widget? columnMenuIcon;

  /// Optional custom widget displayed when a column is sorted in ascending order.
  /// Defaults to PlutoGrid's rotated green `Icons.sort`.
  final Widget? columnAscendingIcon;

  /// Optional custom widget displayed when a column is sorted in descending order.
  /// Defaults to PlutoGrid's red `Icons.sort`.
  final Widget? columnDescendingIcon;

  /// Custom color for header icons (defaults to subtle grey [Colors.black26] in light mode).
  final Color? iconColor;

  /// Size of header icons in logical pixels. Defaults to 16.0.
  final double iconSize;

  /// Whether to display a push-pin icon when a column is pinned in unsorted state.
  /// Defaults to false.
  final bool showPinIcon;

  const AppGridStyle({
    this.rowHeight = 48.0,
    this.rowTextStyle,
    this.rowPadding,
    this.selectedRowColor,
    this.evenRowColor,
    this.oddRowColor,
    this.headerHeight = 48.0,
    this.headerBackgroundColor,
    this.headerTextStyle,
    this.headerPadding,
    this.menuTextStyle =
        const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
    this.footerHeight,
    this.footerBackgroundColor,
    this.footerTextStyle,
    this.footerPadding,
    this.borderColor,
    this.gridLineColor,
    this.showHorizontalGridLines = true,
    this.showVerticalGridLines = false,
    this.verticalGridLineColor,
    this.showHorizontalScrollbar = true,
    this.showVerticalScrollbar = true,
    this.scrollbarVisibility,
    this.verticalScrollbarVisibility,
    this.horizontalScrollbarVisibility,
    this.scrollbarThickness = 10.0,
    this.scrollbarThumbColor,
    this.scrollbarTrackColor,
    this.columnMenuIcon,
    this.columnAscendingIcon,
    this.columnDescendingIcon,
    this.iconColor,
    this.iconSize = 16.0,
    this.showPinIcon = false,
  });

  /// Creates a copy of this style with the given fields replaced with new values.
  AppGridStyle copyWith({
    double? rowHeight,
    TextStyle? rowTextStyle,
    EdgeInsetsGeometry? rowPadding,
    Color? selectedRowColor,
    Color? evenRowColor,
    Color? oddRowColor,
    double? headerHeight,
    Color? headerBackgroundColor,
    TextStyle? headerTextStyle,
    EdgeInsetsGeometry? headerPadding,
    TextStyle? menuTextStyle,
    double? footerHeight,
    Color? footerBackgroundColor,
    TextStyle? footerTextStyle,
    EdgeInsetsGeometry? footerPadding,
    Color? borderColor,
    Color? gridLineColor,
    bool? showHorizontalGridLines,
    bool? showVerticalGridLines,
    Color? verticalGridLineColor,
    bool? showHorizontalScrollbar,
    bool? showVerticalScrollbar,
    AppGridScrollbarVisibility? scrollbarVisibility,
    AppGridScrollbarVisibility? verticalScrollbarVisibility,
    AppGridScrollbarVisibility? horizontalScrollbarVisibility,
    double? scrollbarThickness,
    Color? scrollbarThumbColor,
    Color? scrollbarTrackColor,
    Widget? columnMenuIcon,
    Widget? columnAscendingIcon,
    Widget? columnDescendingIcon,
    Color? iconColor,
    double? iconSize,
    bool? showPinIcon,
  }) {
    return AppGridStyle(
      rowHeight: rowHeight ?? this.rowHeight,
      rowTextStyle: rowTextStyle ?? this.rowTextStyle,
      rowPadding: rowPadding ?? this.rowPadding,
      selectedRowColor: selectedRowColor ?? this.selectedRowColor,
      evenRowColor: evenRowColor ?? this.evenRowColor,
      oddRowColor: oddRowColor ?? this.oddRowColor,
      headerHeight: headerHeight ?? this.headerHeight,
      headerBackgroundColor:
          headerBackgroundColor ?? this.headerBackgroundColor,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      headerPadding: headerPadding ?? this.headerPadding,
      menuTextStyle: menuTextStyle ?? this.menuTextStyle,
      footerHeight: footerHeight ?? this.footerHeight,
      footerBackgroundColor:
          footerBackgroundColor ?? this.footerBackgroundColor,
      footerTextStyle: footerTextStyle ?? this.footerTextStyle,
      footerPadding: footerPadding ?? this.footerPadding,
      borderColor: borderColor ?? this.borderColor,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      showHorizontalGridLines:
          showHorizontalGridLines ?? this.showHorizontalGridLines,
      showVerticalGridLines:
          showVerticalGridLines ?? this.showVerticalGridLines,
      verticalGridLineColor:
          verticalGridLineColor ?? this.verticalGridLineColor,
      showHorizontalScrollbar:
          showHorizontalScrollbar ?? this.showHorizontalScrollbar,
      showVerticalScrollbar:
          showVerticalScrollbar ?? this.showVerticalScrollbar,
      scrollbarVisibility: scrollbarVisibility ?? this.scrollbarVisibility,
      verticalScrollbarVisibility:
          verticalScrollbarVisibility ?? this.verticalScrollbarVisibility,
      horizontalScrollbarVisibility:
          horizontalScrollbarVisibility ?? this.horizontalScrollbarVisibility,
      scrollbarThickness: scrollbarThickness ?? this.scrollbarThickness,
      scrollbarThumbColor: scrollbarThumbColor ?? this.scrollbarThumbColor,
      scrollbarTrackColor: scrollbarTrackColor ?? this.scrollbarTrackColor,
      columnMenuIcon: columnMenuIcon ?? this.columnMenuIcon,
      columnAscendingIcon: columnAscendingIcon ?? this.columnAscendingIcon,
      columnDescendingIcon: columnDescendingIcon ?? this.columnDescendingIcon,
      iconColor: iconColor ?? this.iconColor,
      iconSize: iconSize ?? this.iconSize,
      showPinIcon: showPinIcon ?? this.showPinIcon,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppGridStyle &&
          runtimeType == other.runtimeType &&
          rowHeight == other.rowHeight &&
          rowTextStyle == other.rowTextStyle &&
          rowPadding == other.rowPadding &&
          selectedRowColor == other.selectedRowColor &&
          evenRowColor == other.evenRowColor &&
          oddRowColor == other.oddRowColor &&
          headerHeight == other.headerHeight &&
          headerBackgroundColor == other.headerBackgroundColor &&
          headerTextStyle == other.headerTextStyle &&
          headerPadding == other.headerPadding &&
          menuTextStyle == other.menuTextStyle &&
          footerHeight == other.footerHeight &&
          footerBackgroundColor == other.footerBackgroundColor &&
          footerTextStyle == other.footerTextStyle &&
          footerPadding == other.footerPadding &&
          borderColor == other.borderColor &&
          gridLineColor == other.gridLineColor &&
          showHorizontalGridLines == other.showHorizontalGridLines &&
          showVerticalGridLines == other.showVerticalGridLines &&
          verticalGridLineColor == other.verticalGridLineColor &&
          showHorizontalScrollbar == other.showHorizontalScrollbar &&
          showVerticalScrollbar == other.showVerticalScrollbar &&
          scrollbarVisibility == other.scrollbarVisibility &&
          verticalScrollbarVisibility == other.verticalScrollbarVisibility &&
          horizontalScrollbarVisibility ==
              other.horizontalScrollbarVisibility &&
          scrollbarThickness == other.scrollbarThickness &&
          scrollbarThumbColor == other.scrollbarThumbColor &&
          scrollbarTrackColor == other.scrollbarTrackColor &&
          columnMenuIcon == other.columnMenuIcon &&
          columnAscendingIcon == other.columnAscendingIcon &&
          columnDescendingIcon == other.columnDescendingIcon &&
          iconColor == other.iconColor &&
          iconSize == other.iconSize &&
          showPinIcon == other.showPinIcon;

  @override
  int get hashCode =>
      Object.hashAll([
        rowHeight,
        rowTextStyle,
        rowPadding,
        selectedRowColor,
        evenRowColor,
        oddRowColor,
        headerHeight,
        headerBackgroundColor,
        headerTextStyle,
        headerPadding,
        menuTextStyle,
        footerHeight,
        footerBackgroundColor,
        footerTextStyle,
        footerPadding,
        borderColor,
        gridLineColor,
        showHorizontalGridLines,
        showVerticalGridLines,
        verticalGridLineColor,
        showHorizontalScrollbar,
        showVerticalScrollbar,
        scrollbarVisibility,
        verticalScrollbarVisibility,
        horizontalScrollbarVisibility,
      ]) ^
      Object.hash(
        scrollbarThickness,
        scrollbarThumbColor,
        scrollbarTrackColor,
        columnMenuIcon,
        columnAscendingIcon,
        columnDescendingIcon,
        iconColor,
        iconSize,
        showPinIcon,
      );
}
