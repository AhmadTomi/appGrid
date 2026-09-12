import 'package:flutter/material.dart';
import '../models/grid_column.dart';
import '../models/sort_criteria.dart';
import '../column_layout/column_layout_manager.dart';
import '../controllers/app_grid_controller.dart';
import '../rendering_engine/grid_builders.dart';

/// Renders column headers with interactive drag-reordering, drag-resizing,
/// auto-fit on double-click, and sorting toggles.
class AppGridHeaderCell<T> extends StatefulWidget {
  final AppGridController<T> controller;
  final ColumnLayoutManager layoutManager;
  final GridColumn column;
  final double width;
  final double height;
  final GridHeaderBuilder? customHeaderBuilder;
  final void Function(GridColumn column)? onAutoFit;
  final Color? headerBackgroundColor;
  final Color? gridLineColor;
  final Color? verticalGridLineColor;
  final bool showHorizontalGridLines;
  final bool showVerticalGridLines;

  const AppGridHeaderCell({
    super.key,
    required this.controller,
    required this.layoutManager,
    required this.column,
    required this.width,
    required this.height,
    this.customHeaderBuilder,
    this.onAutoFit,
    this.headerBackgroundColor,
    this.gridLineColor,
    this.verticalGridLineColor,
    this.showHorizontalGridLines = true,
    this.showVerticalGridLines = false,
  });

  @override
  State<AppGridHeaderCell<T>> createState() => _AppGridHeaderCellState<T>();
}

class _AppGridHeaderCellState<T> extends State<AppGridHeaderCell<T>> {
  double _dragStartWidth = 0.0;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sortCrit = widget.controller.sortCriteria;
    final isCurrentSort = sortCrit?.columnId == widget.column.id;
    final sortDirection = isCurrentSort ? sortCrit!.direction : SortDirection.none;

    void onSortToggle() {
      if (widget.column.isSortable) {
        widget.controller.sortByColumn(widget.column.id);
      }
    }

    void showHeaderContextMenu(Offset globalPosition) {
      final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (overlay == null) return;

      final position = RelativeRect.fromRect(
        globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      );

      showMenu<GridColumnPin>(
        context: context,
        position: position,
        items: [
          PopupMenuItem(
            value: GridColumnPin.left,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.push_pin,
                  size: 18,
                  color: widget.column.pin == GridColumnPin.left
                      ? theme.colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Pin to Left',
                    style: TextStyle(
                      fontWeight: widget.column.pin == GridColumnPin.left
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: GridColumnPin.right,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.push_pin_outlined,
                  size: 18,
                  color: widget.column.pin == GridColumnPin.right
                      ? theme.colorScheme.primary
                      : null,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Pin to Right',
                    style: TextStyle(
                      fontWeight: widget.column.pin == GridColumnPin.right
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: GridColumnPin.none,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_open, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Unpin (Scrollable)',
                    style: TextStyle(
                      fontWeight: widget.column.pin == GridColumnPin.none
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ).then((selectedPin) {
        if (selectedPin != null) {
          widget.controller.setColumnPin(widget.column.id, selectedPin);
        }
      });
    }

    Widget content;
    final columnHeaderBuilder = widget.column.headerBuilder ?? widget.controller.getHeaderBuilder(widget.column.id);
    if (columnHeaderBuilder != null) {
      content = columnHeaderBuilder(
        context,
        sortDirection,
        onSortToggle,
      );
    } else if (widget.customHeaderBuilder != null) {
      content = widget.customHeaderBuilder!(
        context,
        widget.column,
        sortDirection,
        onSortToggle,
      );
    } else if (widget.controller.globalHeaderBuilder != null) {
      content = widget.controller.globalHeaderBuilder!(
        context,
        widget.column,
        sortDirection,
        onSortToggle,
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.column.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.column.isSortable) _buildSortIcon(sortDirection),
          ],
        ),
      );
    }

    content = MouseRegion(
      cursor: widget.column.isSortable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.column.isSortable ? onSortToggle : null,
        onSecondaryTapUp: (details) => showHeaderContextMenu(details.globalPosition),
        child: content,
      ),
    );

    // Wrap with drag target and draggable for reordering if enabled
    Widget headerNode = content;
    if (widget.column.isReorderable) {
      headerNode = DragTarget<String>(
        onWillAcceptWithDetails: (details) => details.data != widget.column.id,
        onAcceptWithDetails: (details) {
          final draggedId = details.data;
          final visibleCols = widget.controller.visibleColumns;
          final oldIdx = visibleCols.indexWhere((c) => c.id == draggedId);
          final newIdx = visibleCols.indexWhere((c) => c.id == widget.column.id);
          if (oldIdx != -1 && newIdx != -1) {
            widget.controller.reorderColumn(oldIdx, newIdx);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isDragHovered = candidateData.isNotEmpty;
          return Draggable<String>(
            data: widget.column.id,
            dragAnchorStrategy: (draggable, context, position) {
              return Offset(widget.column.minWidth / 2, widget.height / 2);
            },
            feedback: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: widget.column.minWidth,
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                color: theme.colorScheme.primaryContainer.withAlpha(220),
                alignment: Alignment.center,
                child: Text(
                  widget.column.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.4, child: content),
            child: Container(
              color: isDragHovered
                  ? theme.colorScheme.primary.withAlpha(40)
                  : Colors.transparent,
              child: content,
            ),
          );
        },
      );
    }

    final defaultBg = widget.headerBackgroundColor ??
        (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5));
    final hoverBg = widget.headerBackgroundColor != null
        ? widget.headerBackgroundColor!.withAlpha(220)
        : (isDark ? const Color(0xFF282828) : const Color(0xFFECECEC));

    final horizontalLineColor = widget.gridLineColor ??
        (isDark ? const Color(0x3FFFFFFF) : const Color(0x3F000000));
    final verticalDividerColor = widget.verticalGridLineColor ??
        widget.gridLineColor ??
        (isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000));

    return ClipRect(
      child: Container(
        width: widget.width,
        height: widget.height,
        color: _isHovered ? hoverBg : defaultBg,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(
                  right: widget.showVerticalGridLines ? 1.0 : 0.0,
                  bottom: widget.showHorizontalGridLines ? 1.5 : 0.0,
                ),
                child: headerNode,
              ),
            ),
            // Horizontal bottom divider
            if (widget.showHorizontalGridLines)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 1.5,
                child: Container(
                  color: horizontalLineColor,
                ),
              ),
            // Vertical right divider rendered on top of horizontal line
            if (widget.showVerticalGridLines)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 1.0,
                child: Container(
                  color: verticalDividerColor,
                ),
              ),
            if (widget.column.isResizable)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 12,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: () {
                      // Double click triggers auto-fit (REQ-COL-03)
                      if (widget.onAutoFit != null) {
                        widget.onAutoFit!(widget.column);
                      }
                    },
                    onHorizontalDragStart: (details) {
                      _dragStartWidth = widget.width;
                    },
                    onHorizontalDragUpdate: (details) {
                      _dragStartWidth += details.delta.dx;
                      widget.layoutManager.resizeColumn(
                        column: widget.column,
                        newWidth: _dragStartWidth,
                      );
                    },
                    child: Container(
                      width: 12,
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 2,
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortIcon(SortDirection direction) {
    IconData icon;
    Color? color;

    switch (direction) {
      case SortDirection.ascending:
        icon = Icons.arrow_upward;
        color = Theme.of(context).colorScheme.primary;
        break;
      case SortDirection.descending:
        icon = Icons.arrow_downward;
        color = Theme.of(context).colorScheme.primary;
        break;
      case SortDirection.none:
        icon = Icons.unfold_more;
        color = Colors.grey.withAlpha(120);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
