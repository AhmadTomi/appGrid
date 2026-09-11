import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/grid_column.dart';
import '../models/row_index_info.dart';
import '../models/sort_criteria.dart';
import '../controllers/app_grid_controller.dart';
import '../column_layout/column_layout_manager.dart';
import '../rendering_engine/grid_builders.dart';
import '../rendering_engine/virtualized_grid_layout.dart';
import '../rendering_engine/app_grid_viewport.dart';
import '../keyboard_interaction/grid_keyboard_handler.dart';
import 'app_grid_header.dart';
import 'app_grid_footer.dart';

import '../models/data_fetch_mode.dart';
import 'app_grid_pagination_bar.dart';
import 'app_grid_loading_overlay.dart';
import 'app_grid_scrollbar.dart';

import 'dart:ui' show PointerDeviceKind;

/// Scroll behavior enabling mouse drag-scrolling and touch/stylus/trackpad interactions.
class AppGridScrollBehavior extends MaterialScrollBehavior {
  const AppGridScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    // AppGrid manages its own customized, interactive, and synchronized 2D scrollbars
    // (AppGridVerticalScrollbar and AppGridHorizontalScrollbar). Suppress the default
    // platform scrollbar to prevent ghosting or overlapping duplicate scrollbars.
    return child;
  }
}

/// High-performance virtualized 2D DataGrid engine widget.
class AppGrid<T> extends StatefulWidget {
  final AppGridController<T> controller;
  final double rowHeight;
  final double headerHeight;
  final double? footerHeight;
  final GridHeaderBuilder? headerBuilder;
  final GridFooterBuilder? footerBuilder;
  final ValueChanged<RowIndexInfo>? onRowSelected;
  final Color? selectedRowColor;

  /// Background color for odd rows (index 1, 3, 5, ...).
  ///
  /// Deprecated alias: [alternateRowColor] can also be used.
  final Color? oddRowColor;

  /// Whether the grid is in read-only mode.
  ///
  /// When true, rows cannot be selected (via pointer clicks or keyboard navigation)
  /// and no selected row highlighting will be rendered.
  final bool readOnly;

  /// Alternate row background color applied to odd rows (index 1, 3, 5, ...).
  ///
  /// For explicit even and odd row coloring, you can also use [evenRowColor] and [oddRowColor].
  final Color? alternateRowColor;

  /// Background color for even rows (index 0, 2, 4, ...).
  final Color? evenRowColor;
  final ScrollController? verticalScrollController;
  final ScrollController? horizontalScrollController;
  final FocusNode? focusNode;
  final bool autofocus;
  final double infiniteScrollThreshold;
  final bool autoStretch;

  /// Optional widget displayed when the table has 0 display rows.
  final Widget? emptyWidget;

  /// Whether to render the integrated [AppGridPaginationBar] automatically
  /// when [controller.fetchMode] is [DataFetchMode.pagination].
  final bool showPaginationBar;

  /// Optional callback invoked when page navigation occurs on the pagination bar.
  final void Function(int targetPage, int pageSize)? onPageChanged;

  /// Whether clicking and dragging anywhere on the grid body with a mouse or pointer
  /// smoothly scrolls both horizontally and vertically.
  final bool enableMouseDragScroll;

  /// Whether to display the interactive horizontal scrollbar at the bottom of the center pane.
  final bool showHorizontalScrollbar;

  /// Whether to display the interactive vertical scrollbar on the right edge.
  final bool showVerticalScrollbar;

  /// Visibility behavior of the vertical scrollbar.
  /// Options: [AppGridScrollbarVisibility.onHover] (default), [AppGridScrollbarVisibility.always], [AppGridScrollbarVisibility.hidden].
  final AppGridScrollbarVisibility? verticalScrollbarVisibility;

  /// Visibility behavior of the horizontal scrollbar.
  /// Options: [AppGridScrollbarVisibility.onHover] (default), [AppGridScrollbarVisibility.always], [AppGridScrollbarVisibility.hidden].
  final AppGridScrollbarVisibility? horizontalScrollbarVisibility;

  /// Convenient shorthand visibility behavior for both vertical and horizontal scrollbars.
  final AppGridScrollbarVisibility? scrollbarVisibility;

  /// Thickness of the horizontal and vertical scrollbars.
  final double scrollbarThickness;

  /// Custom color for the scrollbar thumb.
  final Color? scrollbarThumbColor;

  /// Custom color for the scrollbar track background.
  final Color? scrollbarTrackColor;

  /// Optional background color for header cells.
  final Color? headerBackgroundColor;

  /// Optional outer border color for the entire table grid.
  final Color? borderColor;

  /// Optional grid line / divider color between cells, rows, and headers.
  final Color? gridLineColor;

  /// Whether to render horizontal grid lines / dividers between table rows.
  final bool showHorizontalGridLines;

  /// Whether to render vertical grid lines / dividers between table columns.
  final bool showVerticalGridLines;

  /// Optional custom color for vertical grid dividers between cells, headers, and footers.
  final Color? verticalGridLineColor;

  /// Whether the table is currently loading data asynchronously.
  ///
  /// When true, renders a loading overlay over the table body.
  /// If null, falls back to [controller.isLoading].
  final bool? isLoading;

  /// Custom loading overlay widget to render over the table when loading.
  ///
  /// Defaults to [AppGridLoadingOverlay].
  final Widget? loadingWidget;

  const AppGrid({
    super.key,
    required this.controller,
    this.rowHeight = 48.0,
    this.headerHeight = 48.0,
    this.footerHeight,
    this.headerBuilder,
    this.footerBuilder,
    this.onRowSelected,
    this.selectedRowColor,
    this.readOnly = false,
    this.alternateRowColor,
    this.evenRowColor,
    this.oddRowColor,
    this.headerBackgroundColor,
    this.borderColor,
    this.gridLineColor,
    this.showHorizontalGridLines = true,
    this.showVerticalGridLines = false,
    this.verticalGridLineColor,
    this.verticalScrollController,
    this.horizontalScrollController,
    this.focusNode,
    this.autofocus = true,
    this.infiniteScrollThreshold = 0.8,
    this.autoStretch = true,
    this.emptyWidget,
    this.isLoading,
    this.loadingWidget,
    this.showPaginationBar = false,
    this.onPageChanged,
    this.enableMouseDragScroll = true,
    this.showHorizontalScrollbar = true,
    this.showVerticalScrollbar = true,
    this.verticalScrollbarVisibility,
    this.horizontalScrollbarVisibility,
    this.scrollbarVisibility,
    this.scrollbarThickness = 10.0,
    this.scrollbarThumbColor,
    this.scrollbarTrackColor,
    this.physics,
  });

  /// Resolves the effective visibility behavior for the vertical scrollbar.
  AppGridScrollbarVisibility get effectiveVerticalScrollbarVisibility {
    if (verticalScrollbarVisibility != null) return verticalScrollbarVisibility!;
    if (scrollbarVisibility != null) return scrollbarVisibility!;
    if (!showVerticalScrollbar) return AppGridScrollbarVisibility.hidden;
    return AppGridScrollbarVisibility.onHover;
  }

  /// Resolves the effective visibility behavior for the horizontal scrollbar.
  AppGridScrollbarVisibility get effectiveHorizontalScrollbarVisibility {
    if (horizontalScrollbarVisibility != null) return horizontalScrollbarVisibility!;
    if (scrollbarVisibility != null) return scrollbarVisibility!;
    if (!showHorizontalScrollbar) return AppGridScrollbarVisibility.hidden;
    return AppGridScrollbarVisibility.onHover;
  }

  /// Optional scroll physics for the grid's vertical and horizontal viewports.
  final ScrollPhysics? physics;

  @override
  State<AppGrid<T>> createState() => _AppGridState<T>();
}

class _AppGridState<T> extends State<AppGrid<T>> {
  late final ColumnLayoutManager _layoutManager;
  late final ScrollController _verticalScrollController;
  late final ScrollController _horizontalScrollController;
  late final FocusNode _focusNode;
  final ValueNotifier<bool> _isGridHovered = ValueNotifier<bool>(false);
  bool _ownsVerticalController = false;
  bool _ownsHorizontalController = false;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    _layoutManager = ColumnLayoutManager(autoStretchEnabled: widget.autoStretch);
    _layoutManager.addListener(_onLayoutChanged);

    if (widget.verticalScrollController != null) {
      _verticalScrollController = widget.verticalScrollController!;
    } else {
      _verticalScrollController = ScrollController();
      _ownsVerticalController = true;
    }

    if (widget.horizontalScrollController != null) {
      _horizontalScrollController = widget.horizontalScrollController!;
    } else {
      _horizontalScrollController = ScrollController();
      _ownsHorizontalController = true;
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode(debugLabel: 'AppGridFocusNode');
      _ownsFocusNode = true;
    }
    _focusNode.addListener(_onFocusChanged);

    if (widget.onRowSelected != null) {
      widget.controller.onRowSelected = widget.onRowSelected;
    }

    if ((widget.readOnly || widget.controller.isReadOnly) &&
        widget.controller.selectedOriginalIndex != null) {
      widget.controller.clearSelection();
    }

    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AppGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onRowSelected != null) {
      widget.controller.onRowSelected = widget.onRowSelected;
    }
    if (widget.readOnly != oldWidget.readOnly && widget.readOnly) {
      if (widget.controller.selectedOriginalIndex != null) {
        widget.controller.clearSelection();
      }
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      if (_ownsFocusNode) {
        _focusNode.removeListener(_onFocusChanged);
        _focusNode.dispose();
        _ownsFocusNode = false;
      }
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
      } else {
        _focusNode = FocusNode(debugLabel: 'AppGridFocusNode');
        _ownsFocusNode = true;
      }
      _focusNode.addListener(_onFocusChanged);
    }
    if (oldWidget.autoStretch != widget.autoStretch) {
      _layoutManager.autoStretchEnabled = widget.autoStretch;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocusChanged);
    _layoutManager.removeListener(_onLayoutChanged);
    _layoutManager.dispose();
    _isGridHovered.dispose();

    if (_ownsVerticalController) {
      _verticalScrollController.dispose();
    }
    if (_ownsHorizontalController) {
      _horizontalScrollController.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onLayoutChanged() {
    setState(() {});
  }

  SortCriteria? _lastSortCriteria;

  void _onControllerChanged() {
    if (_lastSortCriteria != widget.controller.sortCriteria) {
      _lastSortCriteria = widget.controller.sortCriteria;
      if (_verticalScrollController.hasClients) {
        _verticalScrollController.jumpTo(0.0);
      }
    }
    setState(() {});
  }

  void _handleAutoFit(GridColumn column) {
    // Measure longest text representation across current data
    double maxTextLength = column.label.length.toDouble();
    final rowCount = widget.controller.displayRowCount;
    final sampleCount = math.min(rowCount, 200); // Check first 200 rows for speed

    for (var r = 0; r < sampleCount; r++) {
      final rowData = widget.controller.getRowByDisplayIndex(r);
      final val = column.valueGetter != null ? column.valueGetter!(rowData) : '';
      final strLen = val?.toString().length.toDouble() ?? 0.0;
      if (strLen > maxTextLength) {
        maxTextLength = strLen;
      }
    }

    // Estimate width at ~9px per character + padding
    final estimatedWidth = math.max(column.minWidth, maxTextLength * 9.5 + 32.0);
    _layoutManager.autoFitColumn(column: column, contentWidth: estimatedWidth);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;

        const double borderWidth = 1.0;
        final double innerWidth = math.max(0.0, totalWidth - (borderWidth * 2));

        final hasFooter = widget.footerBuilder != null ||
            widget.footerHeight != null ||
            widget.controller.visibleColumns.any((c) => c.footerBuilder != null);
        final footerH = hasFooter ? (widget.footerHeight ?? 40.0) : 0.0;
        final hasPagination = widget.showPaginationBar &&
            widget.controller.fetchMode == DataFetchMode.pagination;
        final paginationH = hasPagination ? 52.0 : 0.0;
        final viewportHeight = math.max(0.0, totalHeight - widget.headerHeight - footerH - paginationH);

        final computedLayout = _layoutManager.computeLayout(
          visibleColumns: widget.controller.visibleColumns,
          availableViewportWidth: innerWidth,
        );

        final double leftWidth = computedLayout.leftPane.totalWidth;
        final double rightWidth = computedLayout.rightPane.totalWidth;
        final double centerWidth = math.max(0.0, innerWidth - leftWidth - rightWidth);
        final bool effectiveReadOnly = widget.readOnly || widget.controller.isReadOnly;

        return ScrollConfiguration(
          behavior: const AppGridScrollBehavior(),
          child: GridKeyboardHandler<T>(
            controller: widget.controller,
            verticalScrollController: _verticalScrollController,
            viewportHeight: viewportHeight,
            rowHeight: widget.rowHeight,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            readOnly: effectiveReadOnly,
            child: ClipRect(
              child: Material(
                type: MaterialType.transparency,
                clipBehavior: Clip.hardEdge,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.borderColor ??
                          (_focusNode.hasFocus
                              ? Theme.of(context).colorScheme.primary.withAlpha(120)
                              : Theme.of(context).dividerColor.withAlpha(60)),
                      width: 1.0,
                    ),
                  ),
                  child: MouseRegion(
                    onEnter: (_) => _isGridHovered.value = true,
                    onExit: (_) => _isGridHovered.value = false,
                    child: Column(
                      children: [
                        // 1. Header Bar
                        SizedBox(
                          height: widget.headerHeight,
                          width: innerWidth,
                          child: _buildHeader(
                            totalWidth: innerWidth,
                            leftWidth: leftWidth,
                            centerWidth: centerWidth,
                            rightWidth: rightWidth,
                            layout: computedLayout,
                          ),
                        ),

                        // 2. Body Viewport or Empty State with Loading Overlay
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final effectiveIsLoading = widget.isLoading ?? widget.controller.isLoading;
                              final isEmpty = widget.controller.displayRowCount == 0;

                              Widget bodyContent;
                              if (isEmpty && !effectiveIsLoading && widget.emptyWidget != null) {
                                bodyContent = widget.emptyWidget!;
                              } else {
                                bodyContent = AppGridViewport<T>(
                                  controller: widget.controller,
                                  layoutManager: _layoutManager,
                                  computedLayout: computedLayout,
                                  verticalScrollController: _verticalScrollController,
                                  horizontalScrollController: _horizontalScrollController,
                                  rowHeight: widget.rowHeight,
                                  headerHeight: widget.headerHeight,
                                  footerHeight: widget.footerHeight,
                                  selectedRowColor: widget.selectedRowColor,
                                  readOnly: effectiveReadOnly,
                                  alternateRowColor: widget.alternateRowColor,
                                  evenRowColor: widget.evenRowColor,
                                  oddRowColor: widget.oddRowColor,
                                  gridLineColor: widget.gridLineColor,
                                  showHorizontalGridLines: widget.showHorizontalGridLines,
                                  showVerticalGridLines: widget.showVerticalGridLines,
                                  verticalGridLineColor: widget.verticalGridLineColor,
                                  infiniteScrollThreshold: widget.infiniteScrollThreshold,
                                  enableMouseDragScroll: widget.enableMouseDragScroll,
                                  showHorizontalScrollbar: widget.showHorizontalScrollbar,
                                  showVerticalScrollbar: widget.showVerticalScrollbar,
                                  horizontalScrollbarVisibility: widget.effectiveHorizontalScrollbarVisibility,
                                  verticalScrollbarVisibility: widget.effectiveVerticalScrollbarVisibility,
                                  isParentHovered: _isGridHovered,
                                  scrollbarThickness: widget.scrollbarThickness,
                                  scrollbarThumbColor: widget.scrollbarThumbColor,
                                  scrollbarTrackColor: widget.scrollbarTrackColor,
                                  physics: widget.physics,
                                );
                              }

                              if (!effectiveIsLoading) {
                                return bodyContent;
                              }

                              return Stack(
                                children: [
                                  Positioned.fill(child: bodyContent),
                                  Positioned.fill(
                                    child: widget.loadingWidget ?? const AppGridLoadingOverlay(),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // 3. Footer Bar (Optional)
                        if (hasFooter)
                          SizedBox(
                            height: footerH,
                            width: innerWidth,
                            child: _buildFooter(
                              totalWidth: innerWidth,
                              leftWidth: leftWidth,
                              centerWidth: centerWidth,
                              rightWidth: rightWidth,
                              layout: computedLayout,
                              footerHeight: footerH,
                            ),
                          ),

                        // 4. Built-in Pagination Bar (Optional)
                        if (widget.showPaginationBar &&
                            widget.controller.fetchMode == DataFetchMode.pagination)
                          AppGridPaginationBar<T>(
                            controller: widget.controller,
                            onPageChanged: widget.onPageChanged,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required double totalWidth,
    required double leftWidth,
    required double centerWidth,
    required double rightWidth,
    required ComputedGridLayout layout,
  }) {
    return ClipRect(
      child: Stack(
        children: [
          // Center Scrollable Header (Horizontally Virtualized)
          if (centerWidth > 0 && layout.centerPane.columns.isNotEmpty)
            Positioned(
              left: leftWidth,
              width: centerWidth,
              top: 0,
              bottom: 0,
              child: ClipRect(
                child: Material(
                  type: MaterialType.transparency,
                  clipBehavior: Clip.hardEdge,
                  child: AnimatedBuilder(
                    animation: _horizontalScrollController,
                    builder: (context, _) {
                      final hScroll = _horizontalScrollController.hasClients &&
                              _horizontalScrollController.positions.isNotEmpty
                          ? _horizontalScrollController.positions.first.pixels
                          : 0.0;
                      final centerColRange = VirtualizedGridLayout.computeColumnRange(
                        scrollOffset: hScroll,
                        viewportWidth: centerWidth,
                        columns: layout.centerPane.columns,
                        widths: layout.centerPane.widths,
                        offsets: layout.centerPane.offsets,
                      );
                      final visibleCols = centerColRange.count > 0
                          ? layout.centerPane.columns.sublist(
                              centerColRange.startIndex,
                              centerColRange.endIndex + 1,
                            )
                          : <GridColumn>[];
                      if (visibleCols.isEmpty) return const SizedBox.shrink();

                      final firstOffset = layout.centerPane.offsets[visibleCols.first.id] ?? 0.0;

                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            left: firstOffset - hScroll,
                            top: 0,
                            bottom: 0,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final col in visibleCols)
                                  AppGridHeaderCell<T>(
                                    controller: widget.controller,
                                    layoutManager: _layoutManager,
                                    column: col,
                                    width: layout.centerPane.widths[col.id]!,
                                    height: widget.headerHeight,
                                    customHeaderBuilder: widget.headerBuilder,
                                    onAutoFit: _handleAutoFit,
                                    headerBackgroundColor: widget.headerBackgroundColor,
                                    gridLineColor: widget.gridLineColor,
                                    verticalGridLineColor: widget.verticalGridLineColor,
                                    showHorizontalGridLines: widget.showHorizontalGridLines,
                                    showVerticalGridLines: widget.showVerticalGridLines,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

          // Left Pinned Header (Stays static)
          if (leftWidth > 0 && layout.leftPane.columns.isNotEmpty)
            Positioned(
              left: 0,
              width: leftWidth,
              top: 0,
              bottom: 0,
              child: ClipRect(
                child: Material(
                  type: MaterialType.transparency,
                  clipBehavior: Clip.hardEdge,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final col in layout.leftPane.columns)
                        AppGridHeaderCell<T>(
                          controller: widget.controller,
                          layoutManager: _layoutManager,
                          column: col,
                          width: layout.leftPane.widths[col.id]!,
                          height: widget.headerHeight,
                          customHeaderBuilder: widget.headerBuilder,
                          onAutoFit: _handleAutoFit,
                          headerBackgroundColor: widget.headerBackgroundColor,
                          gridLineColor: widget.gridLineColor,
                          verticalGridLineColor: widget.verticalGridLineColor,
                          showHorizontalGridLines: widget.showHorizontalGridLines,
                          showVerticalGridLines: widget.showVerticalGridLines,
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Right Pinned Header (Stays static)
          if (rightWidth > 0 && layout.rightPane.columns.isNotEmpty)
            Positioned(
              right: 0,
              width: rightWidth,
              top: 0,
              bottom: 0,
              child: ClipRect(
                child: Material(
                  type: MaterialType.transparency,
                  clipBehavior: Clip.hardEdge,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final col in layout.rightPane.columns)
                        AppGridHeaderCell<T>(
                          controller: widget.controller,
                          layoutManager: _layoutManager,
                          column: col,
                          width: layout.rightPane.widths[col.id]!,
                          height: widget.headerHeight,
                          customHeaderBuilder: widget.headerBuilder,
                          onAutoFit: _handleAutoFit,
                          headerBackgroundColor: widget.headerBackgroundColor,
                          gridLineColor: widget.gridLineColor,
                          verticalGridLineColor: widget.verticalGridLineColor,
                          showHorizontalGridLines: widget.showHorizontalGridLines,
                          showVerticalGridLines: widget.showVerticalGridLines,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter({
    required double totalWidth,
    required double leftWidth,
    required double centerWidth,
    required double rightWidth,
    required ComputedGridLayout layout,
    required double footerHeight,
  }) {
    final visibleData = widget.controller.data;

    return ClipRect(
      child: Stack(
        children: [
          // Center Scrollable Footer (Horizontally Virtualized)
          if (centerWidth > 0 && layout.centerPane.columns.isNotEmpty)
            Positioned(
              left: leftWidth,
              width: centerWidth,
              top: 0,
              bottom: 0,
              child: ClipRect(
                child: Material(
                  type: MaterialType.transparency,
                  clipBehavior: Clip.hardEdge,
                  child: AnimatedBuilder(
                    animation: _horizontalScrollController,
                    builder: (context, _) {
                      final hScroll = _horizontalScrollController.hasClients &&
                              _horizontalScrollController.positions.isNotEmpty
                          ? _horizontalScrollController.positions.first.pixels
                          : 0.0;
                      final centerColRange = VirtualizedGridLayout.computeColumnRange(
                        scrollOffset: hScroll,
                        viewportWidth: centerWidth,
                        columns: layout.centerPane.columns,
                        widths: layout.centerPane.widths,
                        offsets: layout.centerPane.offsets,
                      );
                      final visibleCols = centerColRange.count > 0
                          ? layout.centerPane.columns.sublist(
                              centerColRange.startIndex,
                              centerColRange.endIndex + 1,
                            )
                          : <GridColumn>[];
                      if (visibleCols.isEmpty) return const SizedBox.shrink();

                      final firstOffset = layout.centerPane.offsets[visibleCols.first.id] ?? 0.0;

                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            left: firstOffset - hScroll,
                            top: 0,
                            bottom: 0,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final col in visibleCols)
                                  AppGridFooterCell(
                                    column: col,
                                    width: layout.centerPane.widths[col.id]!,
                                    height: footerHeight,
                                    currentVisibleData: visibleData,
                                    customFooterBuilder: widget.footerBuilder,
                                    verticalGridLineColor: widget.verticalGridLineColor,
                                    gridLineColor: widget.gridLineColor,
                                    showHorizontalGridLines: widget.showHorizontalGridLines,
                                    showVerticalGridLines: widget.showVerticalGridLines,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

          // Left Pinned Footer
          if (leftWidth > 0 && layout.leftPane.columns.isNotEmpty)
            Positioned(
              left: 0,
              width: leftWidth,
              top: 0,
              bottom: 0,
              child: ClipRect(
                child: Material(
                  type: MaterialType.transparency,
                  clipBehavior: Clip.hardEdge,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final col in layout.leftPane.columns)
                        AppGridFooterCell(
                          column: col,
                          width: layout.leftPane.widths[col.id]!,
                          height: footerHeight,
                          currentVisibleData: visibleData,
                          customFooterBuilder: widget.footerBuilder,
                          verticalGridLineColor: widget.verticalGridLineColor,
                          gridLineColor: widget.gridLineColor,
                          showHorizontalGridLines: widget.showHorizontalGridLines,
                          showVerticalGridLines: widget.showVerticalGridLines,
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Right Pinned Footer
          if (rightWidth > 0 && layout.rightPane.columns.isNotEmpty)
            Positioned(
              right: 0,
              width: rightWidth,
              top: 0,
              bottom: 0,
              child: ClipRect(
                child: Material(
                  type: MaterialType.transparency,
                  clipBehavior: Clip.hardEdge,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final col in layout.rightPane.columns)
                        AppGridFooterCell(
                          column: col,
                          width: layout.rightPane.widths[col.id]!,
                          height: footerHeight,
                          currentVisibleData: visibleData,
                          customFooterBuilder: widget.footerBuilder,
                          verticalGridLineColor: widget.verticalGridLineColor,
                          gridLineColor: widget.gridLineColor,
                          showHorizontalGridLines: widget.showHorizontalGridLines,
                          showVerticalGridLines: widget.showVerticalGridLines,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
