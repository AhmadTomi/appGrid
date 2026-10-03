import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/app_grid_header_config.dart';
import '../models/grid_column.dart';
import '../models/compact_column_group.dart';
import '../models/row_index_info.dart';
import '../models/sort_criteria.dart';
import '../models/app_grid_style.dart';
import '../controllers/app_grid_controller.dart';
import '../column_layout/column_layout_manager.dart';
import '../rendering_engine/grid_builders.dart';
import '../rendering_engine/virtualized_grid_layout.dart';
import '../rendering_engine/app_grid_viewport.dart';
import '../keyboard_interaction/grid_keyboard_handler.dart';
import 'app_grid_header.dart';
import 'app_grid_footer.dart';
import 'app_grid_column_dialog.dart';

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
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    // AppGrid manages its own customized, interactive, and synchronized 2D scrollbars
    // (AppGridVerticalScrollbar and AppGridHorizontalScrollbar). Suppress the default
    // platform scrollbar to prevent ghosting or overlapping duplicate scrollbars.
    return child;
  }
}

/// High-performance virtualized 2D DataGrid engine widget.
class AppGrid<T> extends StatefulWidget {
  final AppGridController<T> controller;

  /// Optional declarative dataset.
  ///
  /// When provided, updates to [data] across widget rebuilds will automatically
  /// be reconciled and rendered via [AppGridController.updateData] using virtualized diffing.
  final List<T>? data;

  /// Optional custom equality predicate for comparing rows during auto-diff reconciliation.
  final bool Function(T a, T b)? rowEquality;

  /// Comprehensive styling configuration for [AppGrid].
  ///
  /// Encapsulates row heights, colors, header styling, footer styling,
  /// grid dividers, scrollbars, and header icons in a single immutable object.
  final AppGridStyle style;

  /// Header configuration controlling sorting, menu, resizing, reordering, and icons.
  final AppGridHeaderConfig headerConfig;

  final GridHeaderBuilder? headerBuilder;
  final GridFooterBuilder? footerBuilder;
  final ValueChanged<RowIndexInfo>? onRowSelected;

  /// Optional callback invoked when a row is clicked/tapped.
  final ValueChanged<RowIndexInfo>? onRowTap;

  /// Optional callback invoked when a row is double-clicked/double-tapped.
  ///
  /// Note: Even when [onRowDoubleTap] is provided, single-click selection
  /// triggers immediately on pointer down without any delay or gesture conflict.
  final ValueChanged<RowIndexInfo>? onRowDoubleTap;

  /// Whether the grid is in read-only mode.
  ///
  /// When true, rows cannot be selected (via pointer clicks or keyboard navigation)
  /// and no selected row highlighting will be rendered.
  final bool readOnly;

  final ScrollController? verticalScrollController;
  final ScrollController? horizontalScrollController;
  final FocusNode? focusNode;
  final bool autofocus;
  final double infiniteScrollThreshold;
  final bool autoStretch;

  /// Whether the table is rendered in compact mode with 2 values (top and bottom) per merged cell/header.
  final bool compactMode;

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

  /// Whether the table is currently loading data asynchronously.
  ///
  /// When true, renders a loading overlay over the table body.
  /// If null, falls back to [controller.isLoading].
  final bool? isLoading;

  /// Custom loading overlay widget to render over the table when loading.
  ///
  /// Defaults to [AppGridLoadingOverlay].
  final Widget? loadingWidget;

  /// Whether manual drag-and-drop row reordering is enabled. Defaults to false.
  ///
  /// Requires that column sorting is not actively applied. When true, rows can accept
  /// drops from [AppGridRowDragHandle] widgets.
  final bool enableRowReorder;

  /// Optional callback triggered when a row is manually moved from [oldIndex] to [newIndex].
  final void Function(int oldIndex, int newIndex)? onRowReorder;

  /// Optional scroll physics for the grid's vertical and horizontal viewports.
  final ScrollPhysics? physics;

  /// Optional clock provider (defaults to [DateTime.now]).
  final DateTime Function()? clock;

  const AppGrid({
    super.key,
    required this.controller,
    this.data,
    this.rowEquality,
    this.style = const AppGridStyle(),
    this.headerConfig = const AppGridHeaderConfig(),
    this.headerBuilder,
    this.footerBuilder,
    this.onRowSelected,
    this.onRowTap,
    this.onRowDoubleTap,
    this.readOnly = false,
    this.verticalScrollController,
    this.horizontalScrollController,
    this.focusNode,
    this.autofocus = true,
    this.infiniteScrollThreshold = 0.8,
    this.autoStretch = true,
    this.compactMode = false,
    this.emptyWidget,
    this.isLoading,
    this.loadingWidget,
    this.showPaginationBar = false,
    this.onPageChanged,
    this.enableMouseDragScroll = true,
    this.physics,
    this.clock,
    this.enableRowReorder = false,
    this.onRowReorder,
  });

  /// Row height in logical pixels.
  double get rowHeight => style.rowHeight;

  /// Header height in logical pixels.
  double get headerHeight => style.headerHeight;

  /// Default text style for table header labels.
  TextStyle get headerTextStyle => style.headerTextStyle;

  /// Default text style for table body cells / rows.
  TextStyle get rowTextStyle => style.rowTextStyle;

  /// Convenient alias for [rowTextStyle].
  TextStyle get cellTextStyle => style.rowTextStyle;

  /// Default text style for column context menu items.
  TextStyle get menuTextStyle => style.menuTextStyle;

  /// Whether to render horizontal grid lines / dividers between table rows.
  bool get showHorizontalGridLines => style.showHorizontalGridLines;

  /// Whether to render vertical grid lines / dividers between table columns.
  bool get showVerticalGridLines => style.showVerticalGridLines;

  /// Whether to display the interactive horizontal scrollbar at the bottom of the center pane.
  bool get showHorizontalScrollbar => style.showHorizontalScrollbar;

  /// Whether to display the interactive vertical scrollbar on the right edge.
  bool get showVerticalScrollbar => style.showVerticalScrollbar;

  /// Thickness of the horizontal and vertical scrollbars.
  double get scrollbarThickness => style.scrollbarThickness;

  /// Size of header icons.
  double get iconSize => style.iconSize;

  /// Resolves the effective visibility behavior for the vertical scrollbar.
  AppGridScrollbarVisibility get effectiveVerticalScrollbarVisibility {
    if (style.verticalScrollbarVisibility != null) {
      return style.verticalScrollbarVisibility!;
    }
    if (style.scrollbarVisibility != null) {
      return style.scrollbarVisibility!;
    }
    if (!style.showVerticalScrollbar) {
      return AppGridScrollbarVisibility.hidden;
    }
    return AppGridScrollbarVisibility.onHover;
  }

  /// Resolves the effective visibility behavior for the horizontal scrollbar.
  AppGridScrollbarVisibility get effectiveHorizontalScrollbarVisibility {
    if (style.horizontalScrollbarVisibility != null) {
      return style.horizontalScrollbarVisibility!;
    }
    if (style.scrollbarVisibility != null) {
      return style.scrollbarVisibility!;
    }
    if (!style.showHorizontalScrollbar) {
      return AppGridScrollbarVisibility.hidden;
    }
    return AppGridScrollbarVisibility.onHover;
  }

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
    if (widget.compactMode) {
      widget.controller.compactMode = true;
    }
    _layoutManager = ColumnLayoutManager(
      autoStretchEnabled: widget.autoStretch,
      compactMode: widget.controller.compactMode,
    );
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
    if (widget.onRowReorder != null) {
      widget.controller.onRowReorder = widget.onRowReorder;
    }

    if ((widget.readOnly || widget.controller.isReadOnly) &&
        widget.controller.selectedOriginalIndex != null) {
      widget.controller.clearSelection();
    }

    if (widget.data != null && widget.controller.originalRowCount == 0) {
      widget.controller.setRows(widget.data!);
    }

    _lastSelectedDisplayIndex = widget.controller.selectedDisplayIndex;
    _lastRowCount = widget.controller.displayRowCount;
    _lastVisibleColCount = widget.controller.visibleColumns.length;
    _lastIsLoading = widget.isLoading ?? widget.controller.isLoading;
    _lastFetchMode = widget.controller.fetchMode;
    _lastSortCriteria = widget.controller.sortCriteria;
    _lastCompactMode = widget.controller.compactMode;

    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AppGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onRowSelected != null) {
      widget.controller.onRowSelected = widget.onRowSelected;
    }
    if (widget.onRowReorder != null) {
      widget.controller.onRowReorder = widget.onRowReorder;
    }
    if (widget.compactMode != oldWidget.compactMode) {
      widget.controller.compactMode = widget.compactMode;
      _layoutManager.compactMode = widget.compactMode;
    }
    if (widget.readOnly != oldWidget.readOnly && widget.readOnly) {
      if (widget.controller.selectedOriginalIndex != null) {
        widget.controller.clearSelection();
      }
    }
    if (widget.data != null && !identical(widget.data, oldWidget.data)) {
      widget.controller.updateData(
        widget.data!,
        rowEquality: widget.rowEquality,
      );
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
  int? _lastSelectedDisplayIndex;
  int _lastRowCount = 0;
  int _lastVisibleColCount = 0;
  bool _lastIsLoading = false;
  bool _lastIsColumnChooserOpen = false;
  bool _lastCompactMode = false;
  DataFetchMode _lastFetchMode = DataFetchMode.infiniteScroll;

  void _onControllerChanged() {
    final currentSort = widget.controller.sortCriteria;
    final currentSelection = widget.controller.selectedDisplayIndex;
    final currentRows = widget.controller.displayRowCount;
    final currentCols = widget.controller.visibleColumns.length;
    final currentLoading = widget.isLoading ?? widget.controller.isLoading;
    final currentFetchMode = widget.controller.fetchMode;
    final currentColumnChooser = widget.controller.isColumnChooserOpen;
    final currentCompact = widget.controller.compactMode;

    final sortChanged = _lastSortCriteria != currentSort;
    if (sortChanged) {
      _lastSortCriteria = currentSort;
      if (_verticalScrollController.hasClients &&
          _verticalScrollController.offset != 0.0) {
        _verticalScrollController.jumpTo(0.0);
      }
    }

    final compactChanged = _lastCompactMode != currentCompact;
    if (compactChanged) {
      _lastCompactMode = currentCompact;
      _layoutManager.compactMode = currentCompact;
    }

    final onlySelectionChanged = !sortChanged &&
        !compactChanged &&
        _lastSelectedDisplayIndex != currentSelection &&
        _lastRowCount == currentRows &&
        _lastVisibleColCount == currentCols &&
        _lastIsLoading == currentLoading &&
        _lastFetchMode == currentFetchMode &&
        _lastIsColumnChooserOpen == currentColumnChooser;

    _lastSelectedDisplayIndex = currentSelection;
    _lastRowCount = currentRows;
    _lastVisibleColCount = currentCols;
    _lastIsLoading = currentLoading;
    _lastFetchMode = currentFetchMode;
    _lastIsColumnChooserOpen = currentColumnChooser;

    // Granular selection update: if only the active selected row changed,
    // skip rebuilding the full AppGrid tree (header, columnLayout, footer, pagination).
    // AppGridViewport updates visible rows directly via its isolated controller listener.
    if (onlySelectionChanged) {
      return;
    }

    setState(() {});
  }

  void _handleAutoFit(GridColumn column) {
    // Measure longest text representation across current data
    double maxTextLength = column.label.length.toDouble();
    final rowCount = widget.controller.displayRowCount;
    final sampleCount =
        math.min(rowCount, 200); // Check first 200 rows for speed

    for (var r = 0; r < sampleCount; r++) {
      final rowData = widget.controller.getRowByDisplayIndex(r);
      final val =
          column.valueGetter != null ? column.valueGetter!(rowData) : '';
      final strLen = val?.toString().length.toDouble() ?? 0.0;
      if (strLen > maxTextLength) {
        maxTextLength = strLen;
      }
    }

    // Estimate width at ~9px per character + padding
    final estimatedWidth =
        math.max(column.minWidth, maxTextLength * 9.5 + 32.0);
    _layoutManager.autoFitColumn(
        column: column, contentWidth: estimatedWidth, horizontalPadding: 0.0);
  }

  void _handleAutoFitGroup(CompactColumnGroup group) {
    double maxTextLength = math.max(
      group.topColumn.label.length.toDouble(),
      group.bottomColumn?.label.length.toDouble() ?? 0.0,
    );
    final rowCount = widget.controller.displayRowCount;
    final sampleCount = math.min(rowCount, 200);

    for (var r = 0; r < sampleCount; r++) {
      final rowData = widget.controller.getRowByDisplayIndex(r);
      final topVal = group.topColumn.valueGetter != null
          ? group.topColumn.valueGetter!(rowData)
          : '';
      final topLen = topVal?.toString().length.toDouble() ?? 0.0;
      if (topLen > maxTextLength) maxTextLength = topLen;

      if (group.bottomColumn != null) {
        final botVal = group.bottomColumn!.valueGetter != null
            ? group.bottomColumn!.valueGetter!(rowData)
            : '';
        final botLen = botVal?.toString().length.toDouble() ?? 0.0;
        if (botLen > maxTextLength) maxTextLength = botLen;
      }
    }

    final estimatedWidth = math.max(group.minWidth, maxTextLength * 9.5 + 32.0);
    _layoutManager.autoFitColumnGroup(
        group: group, contentWidth: estimatedWidth, horizontalPadding: 0.0);
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
            widget.style.footerHeight != null ||
            widget.controller.visibleColumns
                .any((c) => c.footerBuilder != null);
        final bool isCompact = widget.controller.compactMode;
        final double effectiveRowHeight =
            isCompact ? widget.rowHeight * 2.0 : widget.rowHeight;
        final double effectiveHeaderHeight =
            isCompact ? widget.headerHeight * 2.0 : widget.headerHeight;
        final footerH = hasFooter
            ? ((widget.style.footerHeight ?? 40.0) * (isCompact ? 2.0 : 1.0))
            : 0.0;
        final hasPagination = widget.showPaginationBar &&
            widget.controller.fetchMode == DataFetchMode.pagination;
        final paginationH = hasPagination ? 52.0 : 0.0;
        final viewportHeight = math.max(
            0.0, totalHeight - effectiveHeaderHeight - footerH - paginationH);

        final computedLayout = _layoutManager.computeLayout(
          visibleColumns: widget.controller.visibleColumns,
          availableViewportWidth: innerWidth,
          compactMode: isCompact,
        );

        final double leftWidth = computedLayout.leftPane.totalWidth;
        final double rightWidth = computedLayout.rightPane.totalWidth;
        final double centerWidth =
            math.max(0.0, innerWidth - leftWidth - rightWidth);
        final bool effectiveReadOnly =
            widget.readOnly || widget.controller.isReadOnly;

        return ScrollConfiguration(
          behavior: const AppGridScrollBehavior(),
          child: GridKeyboardHandler<T>(
            controller: widget.controller,
            verticalScrollController: _verticalScrollController,
            viewportHeight: viewportHeight,
            rowHeight: effectiveRowHeight,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            readOnly: effectiveReadOnly,
            clock: widget.clock,
            child: ClipRect(
              child: Material(
                type: MaterialType.transparency,
                clipBehavior: Clip.hardEdge,
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.style.borderColor ??
                          (_focusNode.hasFocus
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withAlpha(120)
                              : Theme.of(context).dividerColor.withAlpha(60)),
                      width: 1.0,
                    ),
                  ),
                  child: MouseRegion(
                    onEnter: (_) => _isGridHovered.value = true,
                    onExit: (_) => _isGridHovered.value = false,
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            // 1. Header Bar
                            SizedBox(
                              height: effectiveHeaderHeight,
                              width: innerWidth,
                              child: _buildHeader(
                                totalWidth: innerWidth,
                                leftWidth: leftWidth,
                                centerWidth: centerWidth,
                                rightWidth: rightWidth,
                                layout: computedLayout,
                                height: effectiveHeaderHeight,
                              ),
                            ),

                            // 2. Body Viewport or Empty State with Loading Overlay
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final effectiveIsLoading = widget.isLoading ??
                                      widget.controller.isLoading;
                                  final isEmpty =
                                      widget.controller.displayRowCount == 0;

                                  Widget bodyContent;
                                  if (isEmpty &&
                                      !effectiveIsLoading &&
                                      widget.emptyWidget != null) {
                                    bodyContent = widget.emptyWidget!;
                                  } else {
                                    bodyContent = AppGridViewport<T>(
                                      controller: widget.controller,
                                      layoutManager: _layoutManager,
                                      computedLayout: computedLayout,
                                      verticalScrollController:
                                          _verticalScrollController,
                                      horizontalScrollController:
                                          _horizontalScrollController,
                                      hasFooter: hasFooter,
                                      style: widget.style,
                                      readOnly: effectiveReadOnly,
                                      onRowTap: widget.onRowTap,
                                      onRowDoubleTap: widget.onRowDoubleTap,
                                      infiniteScrollThreshold:
                                          widget.infiniteScrollThreshold,
                                      enableMouseDragScroll:
                                          widget.enableMouseDragScroll,
                                      horizontalScrollbarVisibility: widget
                                          .effectiveHorizontalScrollbarVisibility,
                                      verticalScrollbarVisibility: widget
                                          .effectiveVerticalScrollbarVisibility,
                                      isParentHovered: _isGridHovered,
                                      physics: widget.physics,
                                      enableRowReorder: widget.enableRowReorder,
                                      onRowReorder: widget.onRowReorder,
                                    );
                                  }

                                  if (!effectiveIsLoading) {
                                    return bodyContent;
                                  }

                                  return Stack(
                                    children: [
                                      Positioned.fill(child: bodyContent),
                                      Positioned.fill(
                                        child: widget.loadingWidget ??
                                            const AppGridLoadingOverlay(),
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
                                widget.controller.fetchMode ==
                                    DataFetchMode.pagination)
                              AppGridPaginationBar<T>(
                                controller: widget.controller,
                                onPageChanged: widget.onPageChanged,
                              ),
                          ],
                        ),

                        // In-grid Column Chooser Overlay (Blocks strictly the table, not the parent app)
                        if (widget.controller.isColumnChooserOpen)
                          Positioned.fill(
                            child: AppGridColumnChooserOverlay<T>(
                              controller: widget.controller,
                              onClose: widget.controller.closeColumnChooser,
                            ),
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
    required double height,
  }) {
    return ClipRect(
      child: Stack(
        children: [
          // Center Scrollable Header (Horizontally Virtualized)
          if (centerWidth > 0 && layout.centerPane.groups.isNotEmpty)
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
                      final centerGroupRange =
                          VirtualizedGridLayout.computeGroupRange(
                        scrollOffset: hScroll,
                        viewportWidth: centerWidth,
                        groups: layout.centerPane.groups,
                        widths: layout.centerPane.widths,
                        offsets: layout.centerPane.offsets,
                      );
                      final visibleGroups = centerGroupRange.count > 0
                          ? layout.centerPane.groups.sublist(
                              centerGroupRange.startIndex,
                              centerGroupRange.endIndex + 1,
                            )
                          : <CompactColumnGroup>[];
                      if (visibleGroups.isEmpty) return const SizedBox.shrink();

                      final firstOffset = layout.centerPane
                              .offsets[visibleGroups.first.topColumn.id] ??
                          0.0;

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
                                for (final grp in visibleGroups)
                                  AppGridHeaderCell<T>(
                                    controller: widget.controller,
                                    layoutManager: _layoutManager,
                                    column: grp.topColumn,
                                    group: grp,
                                    width: layout
                                        .centerPane.widths[grp.topColumn.id]!,
                                    height: height,
                                    customHeaderBuilder: widget.headerBuilder,
                                    onAutoFit: _handleAutoFit,
                                    onAutoFitGroup: _handleAutoFitGroup,
                                    style: widget.style,
                                    headerConfig: widget.headerConfig,
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
          if (leftWidth > 0 && layout.leftPane.groups.isNotEmpty)
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
                      for (final grp in layout.leftPane.groups)
                        AppGridHeaderCell<T>(
                          controller: widget.controller,
                          layoutManager: _layoutManager,
                          column: grp.topColumn,
                          group: grp,
                          width: layout.leftPane.widths[grp.topColumn.id]!,
                          height: height,
                          customHeaderBuilder: widget.headerBuilder,
                          onAutoFit: _handleAutoFit,
                          onAutoFitGroup: _handleAutoFitGroup,
                          style: widget.style,
                          headerConfig: widget.headerConfig,
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Right Pinned Header (Stays static)
          if (rightWidth > 0 && layout.rightPane.groups.isNotEmpty)
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
                      for (final grp in layout.rightPane.groups)
                        AppGridHeaderCell<T>(
                          controller: widget.controller,
                          layoutManager: _layoutManager,
                          column: grp.topColumn,
                          group: grp,
                          width: layout.rightPane.widths[grp.topColumn.id]!,
                          height: height,
                          customHeaderBuilder: widget.headerBuilder,
                          onAutoFit: _handleAutoFit,
                          onAutoFitGroup: _handleAutoFitGroup,
                          style: widget.style,
                          headerConfig: widget.headerConfig,
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
    final double maxHorizontalScroll =
        math.max(0.0, layout.centerPane.totalWidth - centerWidth);
    final bool hasHScrollbar = widget.effectiveHorizontalScrollbarVisibility !=
            AppGridScrollbarVisibility.hidden &&
        widget.showHorizontalScrollbar &&
        maxHorizontalScroll > 0;

    return ClipRect(
      child: Stack(
        children: [
          // Center Scrollable Footer (Horizontally Virtualized)
          if (centerWidth > 0 && layout.centerPane.groups.isNotEmpty)
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
                      final centerGroupRange =
                          VirtualizedGridLayout.computeGroupRange(
                        scrollOffset: hScroll,
                        viewportWidth: centerWidth,
                        groups: layout.centerPane.groups,
                        widths: layout.centerPane.widths,
                        offsets: layout.centerPane.offsets,
                      );
                      final visibleGroups = centerGroupRange.count > 0
                          ? layout.centerPane.groups.sublist(
                              centerGroupRange.startIndex,
                              centerGroupRange.endIndex + 1,
                            )
                          : <CompactColumnGroup>[];
                      if (visibleGroups.isEmpty) return const SizedBox.shrink();

                      final firstOffset = layout.centerPane
                              .offsets[visibleGroups.first.topColumn.id] ??
                          0.0;

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
                                for (final grp in visibleGroups)
                                  AppGridFooterCell(
                                    column: grp.topColumn,
                                    group: grp,
                                    width: layout
                                        .centerPane.widths[grp.topColumn.id]!,
                                    height: footerHeight,
                                    currentVisibleData: visibleData,
                                    customFooterBuilder: widget.footerBuilder,
                                    style: widget.style,
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
          if (leftWidth > 0 && layout.leftPane.groups.isNotEmpty)
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
                      for (final grp in layout.leftPane.groups)
                        AppGridFooterCell(
                          column: grp.topColumn,
                          group: grp,
                          width: layout.leftPane.widths[grp.topColumn.id]!,
                          height: footerHeight,
                          currentVisibleData: visibleData,
                          customFooterBuilder: widget.footerBuilder,
                          style: widget.style,
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Right Pinned Footer
          if (rightWidth > 0 && layout.rightPane.groups.isNotEmpty)
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
                      for (final grp in layout.rightPane.groups)
                        AppGridFooterCell(
                          column: grp.topColumn,
                          group: grp,
                          width: layout.rightPane.widths[grp.topColumn.id]!,
                          height: footerHeight,
                          currentVisibleData: visibleData,
                          customFooterBuilder: widget.footerBuilder,
                          style: widget.style,
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Horizontal Scrollbar (at the bottom of the footer)
          if (hasHScrollbar && centerWidth > 0)
            Positioned(
              left: leftWidth,
              width: centerWidth,
              bottom: 0,
              height: widget.scrollbarThickness,
              child: AppGridHorizontalScrollbar(
                controller: _horizontalScrollController,
                trackWidth: centerWidth,
                contentWidth: layout.centerPane.totalWidth,
                thickness: widget.scrollbarThickness,
                thumbColor: widget.style.scrollbarThumbColor,
                trackColor: widget.style.scrollbarTrackColor,
                visibility: widget.effectiveHorizontalScrollbarVisibility,
                isParentHovered: _isGridHovered,
              ),
            ),
        ],
      ),
    );
  }
}
