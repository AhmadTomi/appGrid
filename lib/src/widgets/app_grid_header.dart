import 'package:flutter/material.dart';
import '../models/grid_column.dart';
import '../models/compact_column_group.dart';
import '../models/sort_criteria.dart';
import '../column_layout/column_layout_manager.dart';
import '../controllers/app_grid_controller.dart';
import '../rendering_engine/grid_builders.dart';

/// Renders column headers with interactive drag-reordering, drag-resizing,
/// auto-fit on double-click, and sorting toggles.
/// Supports both standard and compact (two-level paired) modes.
class AppGridHeaderCell<T> extends StatefulWidget {
  final AppGridController<T> controller;
  final ColumnLayoutManager layoutManager;
  final GridColumn column;
  final CompactColumnGroup? group;
  final double width;
  final double height;
  final GridHeaderBuilder? customHeaderBuilder;
  final void Function(GridColumn column)? onAutoFit;
  final void Function(CompactColumnGroup group)? onAutoFitGroup;
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
    this.group,
    required this.width,
    required this.height,
    this.customHeaderBuilder,
    this.onAutoFit,
    this.onAutoFitGroup,
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

  CompactColumnGroup get effectiveGroup =>
      widget.group ?? CompactColumnGroup(topColumn: widget.column);
  GridColumn get topCol => effectiveGroup.topColumn;
  GridColumn? get bottomCol => effectiveGroup.bottomColumn;
  bool get isPair => effectiveGroup.isPair;
  bool get isCompact => widget.controller.compactMode;
  bool get canSort => !isCompact && topCol.isSortable;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant AppGridHeaderCell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Widget _buildColumnHeaderContent({
    required BuildContext context,
    required GridColumn col,
    required ThemeData theme,
    required SortDirection sortDirection,
    required VoidCallback onSortToggle,
    required bool allowSort,
  }) {
    final columnHeaderBuilder = col.headerBuilder ?? widget.controller.getHeaderBuilder(col.id);
    if (columnHeaderBuilder != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: allowSort ? onSortToggle : null,
        child: Align(
          alignment: col.headerAlignment,
          child: columnHeaderBuilder(
            context,
            sortDirection,
            onSortToggle,
          ),
        ),
      );
    } else if (widget.customHeaderBuilder != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: allowSort ? onSortToggle : null,
        child: Align(
          alignment: col.headerAlignment,
          child: widget.customHeaderBuilder!(
            context,
            col,
            sortDirection,
            onSortToggle,
          ),
        ),
      );
    } else if (widget.controller.globalHeaderBuilder != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: allowSort ? onSortToggle : null,
        child: Align(
          alignment: col.headerAlignment,
          child: widget.controller.globalHeaderBuilder!(
            context,
            col,
            sortDirection,
            onSortToggle,
          ),
        ),
      );
    } else {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: allowSort ? onSortToggle : null,
        child: Container(
          alignment: col.headerAlignment,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            col.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: _textAlignFromAlignment(col.headerAlignment),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sortCrit = widget.controller.sortCriteria;
    final isCurrentSort = !isCompact && sortCrit?.columnId == topCol.id;
    final sortDirection = isCurrentSort ? sortCrit!.direction : SortDirection.none;

    void onSortToggle() {
      if (canSort) {
        widget.controller.sortByColumn(topCol.id);
        if (mounted) setState(() {});
      }
    }

    Widget content;
    final horizontalSubDividerColor = widget.gridLineColor ??
        (isDark ? const Color(0x3FFFFFFF) : const Color(0x3F000000));

    if (isPair) {
      final topHeader = _buildColumnHeaderContent(
        context: context,
        col: topCol,
        theme: theme,
        sortDirection: SortDirection.none,
        onSortToggle: onSortToggle,
        allowSort: false,
      );
      final bottomHeader = _buildColumnHeaderContent(
        context: context,
        col: bottomCol!,
        theme: theme,
        sortDirection: SortDirection.none,
        onSortToggle: onSortToggle,
        allowSort: false,
      );

      final bool showMenu = topCol.pin != GridColumnPin.none || _isHovered;

      content = Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: topHeader),
                if (showMenu)
                  Positioned(
                    right: 4.0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _buildSortMenuButton(SortDirection.none),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 0.8,
            color: horizontalSubDividerColor,
          ),
          Expanded(
            child: bottomHeader,
          ),
        ],
      );
    } else {
      final singleHeader = _buildColumnHeaderContent(
        context: context,
        col: topCol,
        theme: theme,
        sortDirection: sortDirection,
        onSortToggle: onSortToggle,
        allowSort: canSort,
      );

      final bool showMenu = canSort || topCol.pin != GridColumnPin.none || _isHovered;

      if (isCompact) {
        // In compact mode with canCompact: false, the header cell has double height (widget.height).
        // Position the menu icon at the top-right (matching the paired column's top row position)
        // so it remains visually consistent across all header columns, while singleHeader occupies
        // the full cell area so text remains perfectly centered.
        content = Stack(
          children: [
            Positioned.fill(child: singleHeader),
            if (showMenu)
              Positioned(
                right: 4.0,
                top: 0,
                height: widget.height / 2,
                child: Center(
                  child: _buildSortMenuButton(sortDirection),
                ),
              ),
          ],
        );
      } else {
        // Standard mode: overlay menu button on the right in a Stack so it doesn't shift centered text
        content = Stack(
          children: [
            Positioned.fill(child: singleHeader),
            if (showMenu)
              Positioned(
                right: 4.0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _buildSortMenuButton(sortDirection),
                ),
              ),
          ],
        );
      }
    }

    content = MouseRegion(
      cursor: canSort ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: content,
    );

    // Wrap with drag target and draggable for reordering if enabled
    final bool isReorderable = topCol.isReorderable && (bottomCol == null || bottomCol!.isReorderable);
    Widget headerNode = content;
    if (isReorderable) {
      headerNode = DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          final data = details.data;
          final draggedIds = data.contains('::') ? data.split('::') : [data];
          return !draggedIds.any((id) => effectiveGroup.columnIds.contains(id));
        },
        onAcceptWithDetails: (details) {
          final data = details.data;
          final draggedIds = data.contains('::') ? data.split('::') : [data];
          widget.controller.reorderColumnGroup(
            draggedIds: draggedIds,
            targetColumnId: topCol.id,
          );
        },
        builder: (context, candidateData, rejectedData) {
          final isDragHovered = candidateData.isNotEmpty;
          final labelText = isPair ? '${topCol.label} / ${bottomCol!.label}' : topCol.label;
          final dragData = isPair ? effectiveGroup.columnIds.join('::') : topCol.id;
          return Draggable<String>(
            data: dragData,
            dragAnchorStrategy: (draggable, context, position) {
              return Offset(effectiveGroup.minWidth / 2, widget.height / 2);
            },
            feedback: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: effectiveGroup.minWidth,
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                color: theme.colorScheme.primaryContainer.withAlpha(220),
                alignment: Alignment.center,
                child: Text(
                  labelText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
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

    final bool isResizable = topCol.isResizable && (bottomCol == null || bottomCol!.isResizable);

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
            if (isResizable)
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
                      if (widget.onAutoFitGroup != null) {
                        widget.onAutoFitGroup!(effectiveGroup);
                      } else if (widget.onAutoFit != null) {
                        widget.onAutoFit!(topCol);
                      }
                    },
                    onHorizontalDragStart: (details) {
                      _dragStartWidth = widget.width;
                    },
                    onHorizontalDragUpdate: (details) {
                      _dragStartWidth += details.delta.dx;
                      widget.layoutManager.resizeColumnGroup(
                        group: effectiveGroup,
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

  Widget _buildSortMenuButton(SortDirection direction) {
    IconData icon;
    Color? color;

    if (isCompact) {
      if (topCol.pin != GridColumnPin.none) {
        icon = Icons.push_pin;
        color = Theme.of(context).colorScheme.primary.withAlpha(200);
      } else {
        icon = Icons.more_vert;
        color = Colors.grey.withAlpha(140);
      }
    } else if (!topCol.isSortable) {
      if (topCol.pin != GridColumnPin.none) {
        icon = Icons.push_pin;
        color = Theme.of(context).colorScheme.primary.withAlpha(200);
      } else {
        icon = Icons.more_vert;
        color = Colors.grey.withAlpha(140);
      }
    } else {
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
          if (topCol.pin != GridColumnPin.none) {
            icon = Icons.push_pin;
            color = Theme.of(context).colorScheme.primary.withAlpha(200);
          } else {
            icon = Icons.unfold_more;
            color = Colors.grey.withAlpha(140);
          }
          break;
      }
    }

    return Builder(
      builder: (btnContext) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showColumnMenu(btnContext),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              color: Colors.transparent,
              child: Icon(icon, size: 16, color: color),
            ),
          ),
        );
      },
    );
  }

  void _showColumnMenu(BuildContext buttonContext) {
    final navigator = Navigator.maybeOf(context);
    final RenderBox? overlay = (navigator?.overlay?.context.findRenderObject() as RenderBox?) ??
        (Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?);
    if (overlay == null) return;

    final RenderBox? buttonBox = buttonContext.findRenderObject() as RenderBox?;
    if (buttonBox == null) return;

    // Convert button coordinates directly into overlay local coordinate space
    final buttonTopLeft = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final buttonBottomRight = buttonBox.localToGlobal(
      buttonBox.size.bottomRight(Offset.zero),
      ancestor: overlay,
    );

    final position = RelativeRect.fromRect(
      Rect.fromPoints(buttonTopLeft, buttonBottomRight),
      Offset.zero & overlay.size,
    );

    final theme = Theme.of(context);
    final sortCrit = widget.controller.sortCriteria;
    final isCurrentSort = !isCompact && sortCrit?.columnId == topCol.id;
    final sortDirection = isCurrentSort ? sortCrit!.direction : SortDirection.none;

    final items = <PopupMenuEntry<_HeaderMenuAction>>[];

    // Sorting options (strictly disabled when compactMode is active)
    if (!isCompact && topCol.isSortable) {
      items.addAll([
        PopupMenuItem<_HeaderMenuAction>(
          value: _HeaderMenuAction.sortAscending,
          child: Row(
            children: [
              Icon(
                Icons.arrow_upward,
                size: 18,
                color: sortDirection == SortDirection.ascending
                    ? theme.colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sort Ascending',
                  style: TextStyle(
                    fontWeight: sortDirection == SortDirection.ascending
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: sortDirection == SortDirection.ascending
                        ? theme.colorScheme.primary
                        : null,
                  ),
                ),
              ),
              if (sortDirection == SortDirection.ascending)
                Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
            ],
          ),
        ),
        PopupMenuItem<_HeaderMenuAction>(
          value: _HeaderMenuAction.sortDescending,
          child: Row(
            children: [
              Icon(
                Icons.arrow_downward,
                size: 18,
                color: sortDirection == SortDirection.descending
                    ? theme.colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sort Descending',
                  style: TextStyle(
                    fontWeight: sortDirection == SortDirection.descending
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: sortDirection == SortDirection.descending
                        ? theme.colorScheme.primary
                        : null,
                  ),
                ),
              ),
              if (sortDirection == SortDirection.descending)
                Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
            ],
          ),
        ),
        if (sortDirection != SortDirection.none)
          const PopupMenuItem<_HeaderMenuAction>(
            value: _HeaderMenuAction.clearSort,
            child: Row(
              children: [
                Icon(Icons.clear, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Clear Sort')),
              ],
            ),
          ),
        const PopupMenuDivider(),
      ]);
    }

    // Pinning options
    items.addAll([
      PopupMenuItem<_HeaderMenuAction>(
        value: _HeaderMenuAction.pinLeft,
        child: Row(
          children: [
            Icon(
              Icons.push_pin,
              size: 18,
              color: topCol.pin == GridColumnPin.left
                  ? theme.colorScheme.primary
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pin to Left',
                style: TextStyle(
                  fontWeight: topCol.pin == GridColumnPin.left
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: topCol.pin == GridColumnPin.left
                      ? theme.colorScheme.primary
                      : null,
                ),
              ),
            ),
            if (topCol.pin == GridColumnPin.left)
              Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
          ],
        ),
      ),
      PopupMenuItem<_HeaderMenuAction>(
        value: _HeaderMenuAction.pinRight,
        child: Row(
          children: [
            Icon(
              Icons.push_pin_outlined,
              size: 18,
              color: topCol.pin == GridColumnPin.right
                  ? theme.colorScheme.primary
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pin to Right',
                style: TextStyle(
                  fontWeight: topCol.pin == GridColumnPin.right
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: topCol.pin == GridColumnPin.right
                      ? theme.colorScheme.primary
                      : null,
                ),
              ),
            ),
            if (topCol.pin == GridColumnPin.right)
              Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
          ],
        ),
      ),
      PopupMenuItem<_HeaderMenuAction>(
        value: _HeaderMenuAction.unpin,
        child: Row(
          children: [
            const Icon(Icons.lock_open, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unpin (Scrollable)',
                style: TextStyle(
                  fontWeight: topCol.pin == GridColumnPin.none
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (topCol.pin == GridColumnPin.none)
              Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
          ],
        ),
      ),
    ]);

    final bool isResizable = topCol.isResizable && (bottomCol == null || bottomCol!.isResizable);
    if (isResizable && (widget.onAutoFit != null || widget.onAutoFitGroup != null)) {
      items.add(const PopupMenuDivider());
      items.add(
        const PopupMenuItem<_HeaderMenuAction>(
          value: _HeaderMenuAction.autoFit,
          child: Row(
            children: [
              Icon(Icons.fit_screen, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Auto-fit Width')),
            ],
          ),
        ),
      );
    }

    // Column hiding & management (strictly disabled when compactMode is active)
    if (!isCompact) {
      items.add(const PopupMenuDivider());
      if (topCol.canHide) {
        final canHideColumn = widget.controller.visibleColumns.length > 1;
        items.add(
          PopupMenuItem<_HeaderMenuAction>(
            value: _HeaderMenuAction.hideColumn,
            enabled: canHideColumn,
            child: Row(
              children: [
                Icon(
                  Icons.visibility_off_outlined,
                  size: 18,
                  color: canHideColumn ? null : theme.disabledColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hide Column',
                    style: TextStyle(
                      color: canHideColumn ? null : theme.disabledColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      items.add(
        const PopupMenuItem<_HeaderMenuAction>(
          value: _HeaderMenuAction.manageColumns,
          child: Row(
            children: [
              Icon(Icons.view_column_outlined, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Manage Columns...')),
            ],
          ),
        ),
      );
    }

    showMenu<_HeaderMenuAction>(
      context: context,
      position: position,
      items: items,
    ).then((selected) {
      if (selected == null || !mounted) return;
      switch (selected) {
        case _HeaderMenuAction.sortAscending:
          widget.controller.sortByColumn(topCol.id, direction: SortDirection.ascending);
          if (mounted) setState(() {});
          break;
        case _HeaderMenuAction.sortDescending:
          widget.controller.sortByColumn(topCol.id, direction: SortDirection.descending);
          if (mounted) setState(() {});
          break;
        case _HeaderMenuAction.clearSort:
          widget.controller.sortByColumn(topCol.id, direction: SortDirection.none);
          if (mounted) setState(() {});
          break;
        case _HeaderMenuAction.pinLeft:
          for (final colId in effectiveGroup.columnIds) {
            widget.controller.setColumnPin(colId, GridColumnPin.left);
          }
          break;
        case _HeaderMenuAction.pinRight:
          for (final colId in effectiveGroup.columnIds) {
            widget.controller.setColumnPin(colId, GridColumnPin.right);
          }
          break;
        case _HeaderMenuAction.unpin:
          for (final colId in effectiveGroup.columnIds) {
            widget.controller.setColumnPin(colId, GridColumnPin.none);
          }
          break;
        case _HeaderMenuAction.autoFit:
          if (widget.onAutoFitGroup != null) {
            widget.onAutoFitGroup!(effectiveGroup);
          } else {
            widget.onAutoFit?.call(topCol);
          }
          break;
        case _HeaderMenuAction.hideColumn:
          widget.controller.setColumnVisibility(topCol.id, false);
          break;
        case _HeaderMenuAction.manageColumns:
          widget.controller.openColumnChooser();
          break;
      }
    });
  }
}

enum _HeaderMenuAction {
  sortAscending,
  sortDescending,
  clearSort,
  pinLeft,
  pinRight,
  unpin,
  autoFit,
  hideColumn,
  manageColumns,
}

TextAlign _textAlignFromAlignment(Alignment alignment) {
  if (alignment.x < -0.33) {
    return TextAlign.left;
  } else if (alignment.x > 0.33) {
    return TextAlign.right;
  } else {
    return TextAlign.center;
  }
}
