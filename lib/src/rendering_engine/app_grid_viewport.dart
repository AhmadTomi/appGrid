import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../models/grid_column.dart';
import '../models/data_fetch_mode.dart';
import '../models/row_index_info.dart';
import '../controllers/app_grid_controller.dart';
import '../column_layout/column_layout_manager.dart';
import 'virtualized_grid_layout.dart';
import 'row_widget.dart';
import '../widgets/app_grid_scrollbar.dart';

/// Core 2D virtualized viewport implementing freeze panes, 2D cell recycling,
/// and synchronized scrolling.
class AppGridViewport<T> extends StatefulWidget {
  final AppGridController<T> controller;
  final ColumnLayoutManager layoutManager;
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;
  final double rowHeight;
  final double headerHeight;
  final double? footerHeight;
  final bool hasFooter;
  final Color? selectedRowColor;
  final Color? alternateRowColor;
  final Color? evenRowColor;
  final Color? oddRowColor;
  final double infiniteScrollThreshold;
  final bool enableMouseDragScroll;
  final bool showHorizontalScrollbar;
  final bool showVerticalScrollbar;
  final AppGridScrollbarVisibility horizontalScrollbarVisibility;
  final AppGridScrollbarVisibility verticalScrollbarVisibility;
  final ValueListenable<bool>? isParentHovered;
  final double scrollbarThickness;
  final Color? scrollbarThumbColor;
  final Color? scrollbarTrackColor;
  final Color? gridLineColor;
  final bool showHorizontalGridLines;
  final bool showVerticalGridLines;
  final Color? verticalGridLineColor;
  final ScrollPhysics? physics;
  final ComputedGridLayout? computedLayout;
  final bool readOnly;

  const AppGridViewport({
    super.key,
    required this.controller,
    required this.layoutManager,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    this.computedLayout,
    this.rowHeight = 48.0,
    this.headerHeight = 48.0,
    this.footerHeight,
    this.hasFooter = false,
    this.selectedRowColor,
    this.alternateRowColor,
    this.evenRowColor,
    this.oddRowColor,
    this.infiniteScrollThreshold = 0.8,
    this.enableMouseDragScroll = true,
    this.showHorizontalScrollbar = true,
    this.showVerticalScrollbar = true,
    this.horizontalScrollbarVisibility = AppGridScrollbarVisibility.onHover,
    this.verticalScrollbarVisibility = AppGridScrollbarVisibility.onHover,
    this.isParentHovered,
    this.scrollbarThickness = 10.0,
    this.scrollbarThumbColor,
    this.scrollbarTrackColor,
    this.gridLineColor,
    this.showHorizontalGridLines = true,
    this.showVerticalGridLines = false,
    this.verticalGridLineColor,
    this.physics,
    this.readOnly = false,
  });

  @override
  State<AppGridViewport<T>> createState() => _AppGridViewportState<T>();
}

class _AppGridViewportState<T> extends State<AppGridViewport<T>> with TickerProviderStateMixin {
  // Kinetic Ballistic Fling Simulation
  Ticker? _flingTicker;
  ClampingScrollSimulation? _vFlingSimulation;
  ClampingScrollSimulation? _hFlingSimulation;

  @override
  void initState() {
    super.initState();
    widget.verticalScrollController.addListener(_onVerticalScroll);
  }

  @override
  void didUpdateWidget(covariant AppGridViewport<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verticalScrollController != widget.verticalScrollController) {
      oldWidget.verticalScrollController.removeListener(_onVerticalScroll);
      widget.verticalScrollController.addListener(_onVerticalScroll);
    }
  }

  @override
  void dispose() {
    widget.verticalScrollController.removeListener(_onVerticalScroll);
    _cancelFling();
    _flingTicker?.dispose();
    super.dispose();
  }

  void _cancelFling() {
    _flingTicker?.stop();
    _vFlingSimulation = null;
    _hFlingSimulation = null;
  }

  void _cancelAllScrollAnimations() {
    _cancelFling();
  }

  void _startFling({
    required double vVelocity,
    required double hVelocity,
    required double maxV,
    required double maxH,
  }) {
    _cancelAllScrollAnimations();

    if (vVelocity.abs() > 40.0 &&
        maxV > 0.0 &&
        widget.verticalScrollController.hasClients &&
        widget.verticalScrollController.positions.isNotEmpty) {
      _vFlingSimulation = ClampingScrollSimulation(
        position: widget.verticalScrollController.positions.first.pixels,
        velocity: vVelocity,
        friction: 0.015,
      );
    } else {
      _vFlingSimulation = null;
    }

    if (hVelocity.abs() > 40.0 &&
        maxH > 0.0 &&
        widget.horizontalScrollController.hasClients &&
        widget.horizontalScrollController.positions.isNotEmpty) {
      _hFlingSimulation = ClampingScrollSimulation(
        position: widget.horizontalScrollController.positions.first.pixels,
        velocity: hVelocity,
        friction: 0.015,
      );
    } else {
      _hFlingSimulation = null;
    }

    if (_vFlingSimulation == null && _hFlingSimulation == null) return;

    _flingTicker ??= createTicker(_onFlingTick);
    if (!_flingTicker!.isActive) {
      _flingTicker!.start();
    }
  }

  void _onFlingTick(Duration elapsed) {
    final double t = elapsed.inMicroseconds / 1000000.0;
    bool vDone = true;
    bool hDone = true;

    if (_vFlingSimulation != null &&
        widget.verticalScrollController.hasClients &&
        widget.verticalScrollController.positions.isNotEmpty) {
      final maxV = widget.verticalScrollController.positions.first.maxScrollExtent;
      if (!_vFlingSimulation!.isDone(t)) {
        final double newV = _vFlingSimulation!.x(t).clamp(0.0, math.max(0.0, maxV)).toDouble();
        widget.verticalScrollController.jumpTo(newV);
        if (newV > 0.0 && newV < maxV) {
          vDone = false;
        }
      }
    }

    if (_hFlingSimulation != null &&
        widget.horizontalScrollController.hasClients &&
        widget.horizontalScrollController.positions.isNotEmpty) {
      final maxH = widget.horizontalScrollController.positions.first.maxScrollExtent;
      if (!_hFlingSimulation!.isDone(t)) {
        final double newH = _hFlingSimulation!.x(t).clamp(0.0, math.max(0.0, maxH)).toDouble();
        widget.horizontalScrollController.jumpTo(newH);
        if (newH > 0.0 && newH < maxH) {
          hDone = false;
        }
      }
    }

    if (vDone && hDone) {
      _cancelFling();
    }
  }

  void _handlePointerSignal(PointerSignalEvent event, double maxV, double maxH) {
    if (event is! PointerScrollEvent) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (resolvedEvent) {
      if (resolvedEvent is! PointerScrollEvent) return;

      // Direct wheel interaction halts any active kinetic drag fling
      _cancelFling();

      final isShift = HardwareKeyboard.instance.isShiftPressed;
      double dx = resolvedEvent.scrollDelta.dx;
      double dy = resolvedEvent.scrollDelta.dy;

      // Shift + mouse wheel scrolls horizontally (desktop convention)
      if (isShift && dx == 0.0 && dy != 0.0) {
        dx = dy;
        dy = 0.0;
      }

      // Instant 1:1 tactile vertical response matching PlutoGrid & native desktop physics
      if (dy != 0.0 &&
          widget.verticalScrollController.hasClients &&
          widget.verticalScrollController.positions.isNotEmpty &&
          maxV > 0.0) {
        final currentV = widget.verticalScrollController.positions.first.pixels;
        final targetV = (currentV + dy).clamp(0.0, maxV);
        if (targetV != currentV) {
          widget.verticalScrollController.jumpTo(targetV);
        }
      }

      // Instant 1:1 tactile horizontal response matching PlutoGrid & native desktop physics
      if (dx != 0.0 &&
          widget.horizontalScrollController.hasClients &&
          widget.horizontalScrollController.positions.isNotEmpty &&
          maxH > 0.0) {
        final currentH = widget.horizontalScrollController.positions.first.pixels;
        final targetH = (currentH + dx).clamp(0.0, maxH);
        if (targetH != currentH) {
          widget.horizontalScrollController.jumpTo(targetH);
        }
      }
    });
  }

  void _onVerticalScroll() {
    if (!widget.verticalScrollController.hasClients ||
        widget.verticalScrollController.positions.isEmpty) {
      return;
    }
    final position = widget.verticalScrollController.positions.first;
    final maxScroll = position.maxScrollExtent;
    if (maxScroll <= 0) {
      return;
    }

    final ratio = position.pixels / maxScroll;
    if (ratio >= widget.infiniteScrollThreshold) {
      if (widget.controller.fetchMode == DataFetchMode.infiniteScroll &&
          !widget.controller.isLoadingMore &&
          widget.controller.onLoadMore != null) {
        widget.controller.setLoadMoreLoading(true);
        widget.controller.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double viewportWidth = constraints.maxWidth;
        final double viewportHeight = constraints.maxHeight;

        final computedLayout = widget.computedLayout ??
            widget.layoutManager.computeLayout(
              visibleColumns: widget.controller.visibleColumns,
              availableViewportWidth: viewportWidth,
            );

        final totalRows = widget.controller.displayRowCount;
        final double totalContentHeight = totalRows * widget.rowHeight;
        final double maxVerticalScroll = math.max(0.0, totalContentHeight - viewportHeight);

        final double leftWidth = computedLayout.leftPane.totalWidth;
        final double rightWidth = computedLayout.rightPane.totalWidth;
        final double centerViewportWidth = math.max(0.0, viewportWidth - leftWidth - rightWidth);
        final double centerContentWidth = computedLayout.centerPane.totalWidth;
        final double maxHorizontalScroll = math.max(0.0, centerContentWidth - centerViewportWidth);

        return Scrollable(
          controller: widget.verticalScrollController,
          axisDirection: AxisDirection.down,
          physics: widget.physics ?? const ClampingScrollPhysics(),
          viewportBuilder: (context, verticalOffset) {
            verticalOffset.applyViewportDimension(viewportHeight);
            verticalOffset.applyContentDimensions(0.0, maxVerticalScroll);

            return Scrollable(
              controller: widget.horizontalScrollController,
              axisDirection: AxisDirection.right,
              physics: widget.physics ?? const ClampingScrollPhysics(),
              viewportBuilder: (context, horizontalOffset) {
                horizontalOffset.applyViewportDimension(centerViewportWidth);
                horizontalOffset.applyContentDimensions(0.0, maxHorizontalScroll);

                Widget bodyContent = Viewport(
                  axisDirection: AxisDirection.down,
                  offset: verticalOffset,
                  // ignore: deprecated_member_use
                  cacheExtent: widget.rowHeight,
                  clipBehavior: Clip.hardEdge,
                  slivers: [
                    SliverFixedExtentList(
                      itemExtent: widget.rowHeight,
                      delegate: SliverChildBuilderDelegate(
                        (context, displayIndex) {
                          return _buildRow(
                            displayIndex: displayIndex,
                            computedLayout: computedLayout,
                            centerViewportWidth: centerViewportWidth,
                            centerContentWidth: centerContentWidth,
                            leftWidth: leftWidth,
                            rightWidth: rightWidth,
                          );
                        },
                        childCount: totalRows,
                        addRepaintBoundaries: false,
                      ),
                    ),
                  ],
                );

                if (widget.enableMouseDragScroll) {
                  bodyContent = GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: (_) {
                      _cancelAllScrollAnimations();
                    },
                    onPanUpdate: (details) {
                      if (widget.horizontalScrollController.hasClients &&
                          widget.horizontalScrollController.positions.isNotEmpty &&
                          maxHorizontalScroll > 0) {
                        final newH = (widget.horizontalScrollController.positions.first.pixels - details.delta.dx)
                            .clamp(0.0, maxHorizontalScroll);
                        widget.horizontalScrollController.jumpTo(newH);
                      }
                      if (widget.verticalScrollController.hasClients &&
                          widget.verticalScrollController.positions.isNotEmpty &&
                          maxVerticalScroll > 0) {
                        final newV = (widget.verticalScrollController.positions.first.pixels - details.delta.dy)
                            .clamp(0.0, maxVerticalScroll);
                        widget.verticalScrollController.jumpTo(newV);
                      }
                    },
                    onPanEnd: (details) {
                      final vVelocity = -details.velocity.pixelsPerSecond.dy;
                      final hVelocity = -details.velocity.pixelsPerSecond.dx;

                      _startFling(
                        vVelocity: vVelocity,
                        hVelocity: hVelocity,
                        maxV: maxVerticalScroll,
                        maxH: maxHorizontalScroll,
                      );
                    },
                    child: bodyContent,
                  );
                }

                // Wrap with Listener to support smooth accumulating mouse wheel scrolling
                // and instant animation cancellation on pointer contact
                bodyContent = Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => _cancelAllScrollAnimations(),
                  onPointerSignal: (event) =>
                      _handlePointerSignal(event, maxVerticalScroll, maxHorizontalScroll),
                  child: bodyContent,
                );

                final bool hasHScrollbar =
                    !widget.hasFooter &&
                    widget.horizontalScrollbarVisibility != AppGridScrollbarVisibility.hidden &&
                    widget.showHorizontalScrollbar &&
                    maxHorizontalScroll > 0;
                final bool hasVScrollbar =
                    widget.verticalScrollbarVisibility != AppGridScrollbarVisibility.hidden &&
                    widget.showVerticalScrollbar &&
                    maxVerticalScroll > 0;

                return ClipRect(
                  child: Stack(
                    children: [
                      // Background canvas
                      Positioned.fill(
                        key: const ValueKey('grid_bg_canvas'),
                        child: Container(
                          color: Theme.of(context).cardColor,
                        ),
                      ),

                      Positioned.fill(child: bodyContent),

                      // Horizontal Scrollbar (at the bottom of the center pane)
                      if (hasHScrollbar && centerViewportWidth > 0)
                        Positioned(
                          left: leftWidth,
                          width: centerViewportWidth,
                          bottom: 0,
                          height: widget.scrollbarThickness,
                          child: AppGridHorizontalScrollbar(
                            controller: widget.horizontalScrollController,
                            trackWidth: centerViewportWidth,
                            contentWidth: centerContentWidth,
                            thickness: widget.scrollbarThickness,
                            thumbColor: widget.scrollbarThumbColor,
                            trackColor: widget.scrollbarTrackColor,
                            visibility: widget.horizontalScrollbarVisibility,
                            isParentHovered: widget.isParentHovered,
                          ),
                        ),

                      // Vertical Scrollbar (along the right edge)
                      if (hasVScrollbar)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: hasHScrollbar ? widget.scrollbarThickness : 0,
                          width: widget.scrollbarThickness,
                          child: AppGridVerticalScrollbar(
                            controller: widget.verticalScrollController,
                            trackHeight: viewportHeight - (hasHScrollbar ? widget.scrollbarThickness : 0),
                            contentHeight: totalContentHeight,
                            thickness: widget.scrollbarThickness,
                            thumbColor: widget.scrollbarThumbColor,
                            trackColor: widget.scrollbarTrackColor,
                            visibility: widget.verticalScrollbarVisibility,
                            isParentHovered: widget.isParentHovered,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRow({
    required int displayIndex,
    required ComputedGridLayout computedLayout,
    required double centerViewportWidth,
    required double centerContentWidth,
    required double leftWidth,
    required double rightWidth,
  }) {
    final effectiveReadOnly = widget.readOnly || widget.controller.isReadOnly;
    final indexInfo = widget.controller.getRowIndexInfo(displayIndex);
    final isSelected = !effectiveReadOnly && widget.controller.selectedDisplayIndex == displayIndex;

    final leftPane = computedLayout.leftPane;
    final centerPane = computedLayout.centerPane;
    final rightPane = computedLayout.rightPane;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: effectiveReadOnly ? null : () => widget.controller.selectRow(indexInfo.displayIndex),
      child: SizedBox(
        key: ValueKey('grid_pos_row_${indexInfo.originalIndex}'),
        height: widget.rowHeight,
        child: Row(
          children: [
            // 1. Left Pinned Columns (Freezing - stays static horizontally)
            if (leftWidth > 0 && leftPane.columns.isNotEmpty)
              SizedBox(
                width: leftWidth,
                height: widget.rowHeight,
                child: ClipRect(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RowWidget<T>(
                          key: ValueKey('row_left_${indexInfo.originalIndex}'),
                          controller: widget.controller,
                          indexInfo: indexInfo,
                          columns: leftPane.columns,
                          columnWidths: leftPane.widths,
                          columnOffsets: leftPane.offsets,
                          rowHeight: widget.rowHeight,
                          isSelected: isSelected,
                          readOnly: effectiveReadOnly,
                          selectedColor: widget.selectedRowColor,
                          alternateRowColor: widget.alternateRowColor,
                          evenRowColor: widget.evenRowColor,
                          oddRowColor: widget.oddRowColor,
                          gridLineColor: widget.gridLineColor,
                          showHorizontalGridLines: widget.showHorizontalGridLines,
                          showVerticalGridLines: widget.showVerticalGridLines,
                          verticalGridLineColor: widget.verticalGridLineColor,
                        ),
                      ),
                      if (widget.showVerticalGridLines)
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          width: 1.5,
                          child: Container(
                            color: widget.verticalGridLineColor ?? widget.gridLineColor ?? Theme.of(context).dividerColor.withAlpha(80),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // 2. Center Scrollable Columns (Horizontally virtualized)
            if (centerViewportWidth > 0 && centerPane.columns.isNotEmpty)
              Expanded(
                child: ClipRect(
                  child: _CenterPaneRow<T>(
                    controller: widget.controller,
                    horizontalScrollController: widget.horizontalScrollController,
                    centerPane: centerPane,
                    centerViewportWidth: centerViewportWidth,
                    centerContentWidth: centerContentWidth,
                    indexInfo: indexInfo,
                    isSelected: isSelected,
                    readOnly: effectiveReadOnly,
                    rowHeight: widget.rowHeight,
                    selectedColor: widget.selectedRowColor,
                    alternateRowColor: widget.alternateRowColor,
                    evenRowColor: widget.evenRowColor,
                    oddRowColor: widget.oddRowColor,
                    gridLineColor: widget.gridLineColor,
                    showHorizontalGridLines: widget.showHorizontalGridLines,
                    showVerticalGridLines: widget.showVerticalGridLines,
                    verticalGridLineColor: widget.verticalGridLineColor,
                  ),
                ),
              ),

            // 3. Right Pinned Columns (Freezing - stays static horizontally)
            if (rightWidth > 0 && rightPane.columns.isNotEmpty)
              SizedBox(
                width: rightWidth,
                height: widget.rowHeight,
                child: ClipRect(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: RowWidget<T>(
                          key: ValueKey('row_right_${indexInfo.originalIndex}'),
                          controller: widget.controller,
                          indexInfo: indexInfo,
                          columns: rightPane.columns,
                          columnWidths: rightPane.widths,
                          columnOffsets: rightPane.offsets,
                          rowHeight: widget.rowHeight,
                          isSelected: isSelected,
                          readOnly: effectiveReadOnly,
                          selectedColor: widget.selectedRowColor,
                          alternateRowColor: widget.alternateRowColor,
                          evenRowColor: widget.evenRowColor,
                          oddRowColor: widget.oddRowColor,
                          gridLineColor: widget.gridLineColor,
                          showHorizontalGridLines: widget.showHorizontalGridLines,
                          showVerticalGridLines: widget.showVerticalGridLines,
                          verticalGridLineColor: widget.verticalGridLineColor,
                        ),
                      ),
                      if (widget.showVerticalGridLines)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 1.5,
                          child: Container(
                            color: widget.verticalGridLineColor ?? widget.gridLineColor ?? Theme.of(context).dividerColor.withAlpha(80),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A horizontally virtualized center row pane that only updates its horizontal
/// projection when [horizontalScrollController] changes, keeping vertical scrolling
/// 100% GPU compositor translated with zero widget rebuilds.
class _CenterPaneRow<T> extends StatelessWidget {
  final AppGridController<T> controller;
  final ScrollController horizontalScrollController;
  final ComputedPaneLayout centerPane;
  final double centerViewportWidth;
  final double centerContentWidth;
  final RowIndexInfo indexInfo;
  final bool isSelected;
  final double rowHeight;
  final Color? selectedColor;
  final Color? alternateRowColor;
  final Color? evenRowColor;
  final Color? oddRowColor;
  final Color? gridLineColor;
  final bool showHorizontalGridLines;
  final bool showVerticalGridLines;
  final Color? verticalGridLineColor;
  final bool readOnly;

  const _CenterPaneRow({
    super.key,
    required this.controller,
    required this.horizontalScrollController,
    required this.centerPane,
    required this.centerViewportWidth,
    required this.centerContentWidth,
    required this.indexInfo,
    required this.isSelected,
    required this.rowHeight,
    this.selectedColor,
    this.alternateRowColor,
    this.evenRowColor,
    this.oddRowColor,
    this.gridLineColor,
    this.showHorizontalGridLines = true,
    this.showVerticalGridLines = false,
    this.verticalGridLineColor,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveReadOnly = readOnly || controller.isReadOnly;
    final showSelected = isSelected && !effectiveReadOnly;

    Color? backgroundColor;
    if (showSelected) {
      backgroundColor = selectedColor ??
          (isDark
              ? theme.colorScheme.primary.withAlpha(75)
              : theme.colorScheme.primary.withAlpha(45));
    } else {
      final isOdd = indexInfo.displayIndex % 2 == 1;
      if (isOdd) {
        backgroundColor = oddRowColor ?? alternateRowColor;
      } else {
        backgroundColor = evenRowColor;
      }
    }

    final horizontalLineColor = gridLineColor ??
        (isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000));

    return Container(
      width: centerViewportWidth,
      height: rowHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Horizontal grid divider line across center viewport
          if (showHorizontalGridLines)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 1.0,
              child: Container(
                color: horizontalLineColor,
              ),
            ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: horizontalScrollController,
              builder: (context, _) {
          final double hScroll = horizontalScrollController.hasClients &&
                  horizontalScrollController.positions.isNotEmpty
              ? horizontalScrollController.positions.first.pixels
              : 0.0;

          final centerColRange = VirtualizedGridLayout.computeColumnRange(
            scrollOffset: hScroll,
            viewportWidth: centerViewportWidth,
            columns: centerPane.columns,
            widths: centerPane.widths,
            offsets: centerPane.offsets,
          );

          final visibleCenterCols = centerColRange.count > 0
              ? centerPane.columns.sublist(
                  centerColRange.startIndex,
                  centerColRange.endIndex + 1,
                )
              : <GridColumn>[];

          if (visibleCenterCols.isEmpty) {
            return const SizedBox.shrink();
          }

          final firstOffset = centerPane.offsets[visibleCenterCols.first.id] ?? 0.0;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: firstOffset - hScroll,
                top: 0,
                bottom: 0,
                width: visibleCenterCols.fold<double>(
                  0.0,
                  (s, c) => s + (centerPane.widths[c.id] ?? c.initialWidth),
                ),
                child: RowWidget<T>(
                  key: ValueKey('row_center_${indexInfo.originalIndex}'),
                  controller: controller,
                  indexInfo: indexInfo,
                  columns: visibleCenterCols,
                  columnWidths: centerPane.widths,
                  columnOffsets: centerPane.offsets,
                  rowHeight: rowHeight,
                  isSelected: showSelected,
                  readOnly: effectiveReadOnly,
                  selectedColor: selectedColor,
                  alternateRowColor: alternateRowColor,
                  evenRowColor: evenRowColor,
                  oddRowColor: oddRowColor,
                  gridLineColor: gridLineColor,
                  showHorizontalGridLines: showHorizontalGridLines,
                  showVerticalGridLines: showVerticalGridLines,
                  verticalGridLineColor: verticalGridLineColor,
                ),
              ),
            ],
          );
        },
      ),
    ),
  ],
),
);
}
}
