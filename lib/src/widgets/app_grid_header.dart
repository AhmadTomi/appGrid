import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/app_grid_header_config.dart';
import '../models/grid_column.dart';
import '../models/compact_column_group.dart';
import '../models/sort_criteria.dart';
import '../models/app_grid_style.dart';
import '../models/app_grid_menu_style.dart';
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
  final AppGridStyle style;
  final AppGridHeaderConfig headerConfig;

  TextStyle? get headerTextStyle => style.headerTextStyle;
  EdgeInsetsGeometry? get headerPadding => style.headerPadding;
  TextStyle get menuTextStyle => style.menuTextStyle;
  Color? get headerBackgroundColor => style.headerBackgroundColor;
  Color? get gridLineColor => style.gridLineColor;
  Color? get verticalGridLineColor => style.verticalGridLineColor;
  bool get showHorizontalGridLines => style.showHorizontalGridLines;
  bool get showVerticalGridLines => style.showVerticalGridLines;
  Widget? get columnMenuIcon => style.columnMenuIcon;
  Widget? get columnAscendingIcon => style.columnAscendingIcon;
  Widget? get columnDescendingIcon => style.columnDescendingIcon;
  Color? get iconColor => style.iconColor;
  double get iconSize => style.iconSize;
  bool get showPinIcon => style.showPinIcon;
  AppGridMenuStyle get menuStyle => style.menuStyle;

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
    this.style = const AppGridStyle(),
    this.headerConfig = const AppGridHeaderConfig(),
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
  AppGridHeaderConfig get effectiveHeaderConfig =>
      topCol.headerConfig ?? widget.headerConfig;
  bool get canSort =>
      !isCompact && topCol.isSortable && effectiveHeaderConfig.enableSort;

  void _onSortToggle() {
    if (canSort) {
      widget.controller.sortByColumn(topCol.id);
      if (mounted) setState(() {});
    }
  }

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
    final headerPadding = widget.headerPadding;
    final effectiveHeaderTextStyle = widget.headerTextStyle ??
        const TextStyle(fontSize: 13, fontWeight: FontWeight.bold);

    final columnHeaderBuilder =
        col.headerBuilder ?? widget.controller.getHeaderBuilder(col.id);
    if (columnHeaderBuilder != null) {
      final headerWidget = columnHeaderBuilder(
        context,
        sortDirection,
        onSortToggle,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: allowSort ? onSortToggle : null,
        child: Align(
          alignment: col.headerAlignment,
          child: headerPadding != null
              ? Padding(padding: headerPadding, child: headerWidget)
              : headerWidget,
        ),
      );
    } else if (widget.customHeaderBuilder != null) {
      final headerWidget = widget.customHeaderBuilder!(
        context,
        col,
        sortDirection,
        onSortToggle,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: allowSort ? onSortToggle : null,
        child: Align(
          alignment: col.headerAlignment,
          child: headerPadding != null
              ? Padding(padding: headerPadding, child: headerWidget)
              : headerWidget,
        ),
      );
    } else if (widget.controller.globalHeaderBuilder != null) {
      final headerWidget = widget.controller.globalHeaderBuilder!(
        context,
        col,
        sortDirection,
        onSortToggle,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: allowSort ? onSortToggle : null,
        child: Align(
          alignment: col.headerAlignment,
          child: headerPadding != null
              ? Padding(padding: headerPadding, child: headerWidget)
              : headerWidget,
        ),
      );
    } else {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: allowSort ? onSortToggle : null,
        child: Container(
          alignment: col.headerAlignment,
          padding: headerPadding ?? const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            col.label,
            style: effectiveHeaderTextStyle,
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
    final bool effectiveShowPin = widget.showPinIcon;

    final sortCrit = widget.controller.sortCriteria;
    final isCurrentSort = !isCompact && sortCrit?.columnId == topCol.id;
    final sortDirection =
        isCurrentSort ? sortCrit!.direction : SortDirection.none;

    Widget content;
    final horizontalSubDividerColor = widget.gridLineColor ??
        (isDark ? const Color(0x3FFFFFFF) : const Color(0x3F000000));

    if (isPair) {
      final topHeader = _buildColumnHeaderContent(
        context: context,
        col: topCol,
        theme: theme,
        sortDirection: SortDirection.none,
        onSortToggle: _onSortToggle,
        allowSort: false,
      );
      final bottomHeader = _buildColumnHeaderContent(
        context: context,
        col: bottomCol!,
        theme: theme,
        sortDirection: SortDirection.none,
        onSortToggle: _onSortToggle,
        allowSort: false,
      );

      final bool showMenu = effectiveHeaderConfig.showIcon &&
          (effectiveHeaderConfig.enableMenu ||
              (effectiveShowPin && topCol.pin != GridColumnPin.none));

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
        onSortToggle: _onSortToggle,
        allowSort: canSort,
      );

      final bool showMenu = effectiveHeaderConfig.showIcon &&
          (effectiveHeaderConfig.enableMenu ||
              canSort ||
              sortDirection != SortDirection.none ||
              (effectiveShowPin && topCol.pin != GridColumnPin.none));

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

    final defaultBg = widget.headerBackgroundColor ??
        (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5));

    // Wrap with drag target and draggable for reordering if enabled
    final bool isReorderable = topCol.isReorderable &&
        (bottomCol == null || bottomCol!.isReorderable) &&
        effectiveHeaderConfig.enableReorder;
    Widget headerNode = content;
    if (isReorderable) {
      headerNode = DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          final data = details.data;
          final draggedIds = data.contains('::') ? data.split('::') : [data];
          return !draggedIds.any((id) => effectiveGroup.columnIds.contains(id));
        },
        onMove: (details) {
          final data = details.data;
          final draggedIds = data.contains('::') ? data.split('::') : [data];
          if (draggedIds.any((id) => effectiveGroup.columnIds.contains(id))) {
            widget.controller.clearHoveredColumnDropTarget();
            return;
          }
          final draggedIndex = widget.controller.visibleColumns
              .indexWhere((c) => draggedIds.contains(c.id));
          final targetIndex = widget.controller.visibleColumns
              .indexWhere((c) => c.id == topCol.id);
          final isLeft = (draggedIndex != -1 && targetIndex != -1)
              ? draggedIndex > targetIndex
              : true;
          widget.controller.setHoveredColumnDropTarget(
            targetColumnId: topCol.id,
            draggedColumnId: data,
            isLeft: isLeft,
          );
        },
        onLeave: (data) {
          widget.controller.clearHoveredColumnDropTarget();
        },
        onAcceptWithDetails: (details) {
          final data = details.data;
          final draggedIds = data.contains('::') ? data.split('::') : [data];
          final draggedIndex = widget.controller.visibleColumns
              .indexWhere((c) => draggedIds.contains(c.id));
          final targetIndex = widget.controller.visibleColumns
              .indexWhere((c) => c.id == topCol.id);
          final isLeft = (draggedIndex != -1 && targetIndex != -1)
              ? draggedIndex > targetIndex
              : true;
          widget.controller.clearHoveredColumnDropTarget();
          widget.controller.reorderColumnGroup(
            draggedIds: draggedIds,
            targetColumnId: topCol.id,
            insertAfter: !isLeft,
          );
        },
        builder: (context, candidateData, rejectedData) {
          final labelText =
              isPair ? '${topCol.label} / ${bottomCol!.label}' : topCol.label;
          final dragData =
              isPair ? effectiveGroup.columnIds.join('::') : topCol.id;
          return Draggable<String>(
            data: dragData,
            dragAnchorStrategy: childDragAnchorStrategy,
            onDragEnd: (_) {
              widget.controller.clearHoveredColumnDropTarget();
            },
            feedback: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(4),
              color: defaultBg.withAlpha(240),
              shadowColor: Colors.black54,
              child: Container(
                width: widget.width,
                height: widget.height,
                padding: widget.headerPadding ??
                    const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(180),
                    width: 1.5,
                  ),
                ),
                alignment: topCol.headerAlignment,
                child: Text(
                  labelText,
                  style: (widget.headerTextStyle ??
                          const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ))
                      .copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: _textAlignFromAlignment(topCol.headerAlignment),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.35, child: content),
            child: content,
          );
        },
      );
    }
    final hoverBg = widget.headerBackgroundColor != null
        ? widget.headerBackgroundColor!.withAlpha(220)
        : (isDark ? const Color(0xFF282828) : const Color(0xFFECECEC));

    final horizontalLineColor = widget.gridLineColor ??
        (isDark ? const Color(0x3FFFFFFF) : const Color(0x3F000000));
    final verticalDividerColor = widget.verticalGridLineColor ??
        widget.gridLineColor ??
        (isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000));

    final bool isResizable = topCol.isResizable &&
        (bottomCol == null || bottomCol!.isResizable) &&
        effectiveHeaderConfig.enableResize;

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
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () {
                      if (!effectiveHeaderConfig.enableAutoFit) return;
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
                      color: Colors.transparent,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool effectiveShowPin = widget.showPinIcon;

    Widget iconWidget;

    if (direction == SortDirection.ascending) {
      if (topCol.sortAscendingIcon != null) {
        iconWidget = topCol.sortAscendingIcon!;
      } else if (widget.columnAscendingIcon != null) {
        iconWidget = widget.columnAscendingIcon!;
      } else {
        iconWidget = Transform.rotate(
          angle: math.pi,
          child: Icon(
            Icons.sort,
            size: widget.iconSize,
            color: Colors.green,
          ),
        );
      }
    } else if (direction == SortDirection.descending) {
      if (topCol.sortDescendingIcon != null) {
        iconWidget = topCol.sortDescendingIcon!;
      } else if (widget.columnDescendingIcon != null) {
        iconWidget = widget.columnDescendingIcon!;
      } else {
        iconWidget = Icon(
          Icons.sort,
          size: widget.iconSize,
          color: Colors.red,
        );
      }
    } else {
      // SortDirection.none (unsorted context menu)
      if (topCol.menuIcon != null) {
        iconWidget = topCol.menuIcon!;
      } else if (widget.columnMenuIcon != null) {
        iconWidget = widget.columnMenuIcon!;
      } else if (effectiveShowPin && topCol.pin != GridColumnPin.none) {
        iconWidget = Icon(
          Icons.push_pin,
          size: widget.iconSize,
          color: theme.colorScheme.primary.withAlpha(200),
        );
      } else if (isCompact) {
        iconWidget = Icon(
          Icons.more_vert,
          size: widget.iconSize,
          color: Colors.grey.withAlpha(140),
        );
      } else {
        final defaultColor =
            widget.iconColor ?? (isDark ? Colors.white38 : Colors.black26);
        final hoverColor = isDark ? Colors.white70 : Colors.black54;
        iconWidget = Icon(
          Icons.dehaze,
          size: widget.iconSize,
          color: _isHovered ? hoverColor : defaultColor,
        );
      }
    }

    iconWidget = IconTheme(
      data: IconThemeData(
        size: widget.iconSize,
        color: widget.iconColor,
      ),
      child: iconWidget,
    );

    final bool canClickMenu = effectiveHeaderConfig.enableMenu;
    final bool canClickSort = canSort;
    final bool isClickable = canClickMenu || canClickSort;

    return Builder(
      builder: (btnContext) {
        return MouseRegion(
          cursor: isClickable ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (canClickMenu) {
                _showColumnMenu(btnContext);
              } else if (canClickSort) {
                _onSortToggle();
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              color: Colors.transparent,
              child: iconWidget,
            ),
          ),
        );
      },
    );
  }

  void _showColumnMenu(BuildContext buttonContext) {
    final navigator = Navigator.maybeOf(context);
    final RenderBox? overlay = (navigator?.overlay?.context.findRenderObject()
            as RenderBox?) ??
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
    final sortDirection =
        isCurrentSort ? sortCrit!.direction : SortDirection.none;

    final items = <PopupMenuEntry<_HeaderMenuAction>>[];

    // Sorting options (strictly disabled when compactMode is active)
    final menuStyle = widget.menuStyle;
    final baseMenuTextStyle = menuStyle.textStyle ?? widget.menuTextStyle;
    final double itemHeight = menuStyle.itemHeight;
    final EdgeInsets itemPadding = menuStyle.itemPadding;
    final double menuIconSize = menuStyle.iconSize ?? widget.iconSize;
    final double checkIconSize = (menuIconSize * 0.9).clamp(10.0, 32.0);
    final double dividerHeight = menuStyle.dividerHeight;

    if (!isCompact && topCol.isSortable) {
      const ascColor = Colors.green;
      const descColor = Colors.red;

      items.addAll([
        PopupMenuItem<_HeaderMenuAction>(
          value: _HeaderMenuAction.sortAscending,
          height: itemHeight,
          padding: itemPadding,
          mouseCursor: SystemMouseCursors.click,
          child: Row(
            children: [
              Transform.rotate(
                angle: math.pi,
                child: Icon(
                  Icons.sort,
                  size: menuIconSize,
                  color: sortDirection == SortDirection.ascending
                      ? ascColor
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sort Ascending',
                  style: baseMenuTextStyle.copyWith(
                    fontWeight: sortDirection == SortDirection.ascending
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: sortDirection == SortDirection.ascending
                        ? ascColor
                        : null,
                  ),
                ),
              ),
              if (sortDirection == SortDirection.ascending)
                Icon(Icons.check, size: checkIconSize, color: ascColor),
            ],
          ),
        ),
        PopupMenuItem<_HeaderMenuAction>(
          value: _HeaderMenuAction.sortDescending,
          height: itemHeight,
          padding: itemPadding,
          mouseCursor: SystemMouseCursors.click,
          child: Row(
            children: [
              Icon(
                Icons.sort,
                size: menuIconSize,
                color: sortDirection == SortDirection.descending
                    ? descColor
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sort Descending',
                  style: baseMenuTextStyle.copyWith(
                    fontWeight: sortDirection == SortDirection.descending
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: sortDirection == SortDirection.descending
                        ? descColor
                        : null,
                  ),
                ),
              ),
              if (sortDirection == SortDirection.descending)
                Icon(Icons.check, size: checkIconSize, color: descColor),
            ],
          ),
        ),
        if (sortDirection != SortDirection.none)
          PopupMenuItem<_HeaderMenuAction>(
            value: _HeaderMenuAction.clearSort,
            height: itemHeight,
            padding: itemPadding,
            mouseCursor: SystemMouseCursors.click,
            child: Row(
              children: [
                Icon(Icons.clear, size: menuIconSize),
                const SizedBox(width: 8),
                Expanded(child: Text('Clear Sort', style: baseMenuTextStyle)),
              ],
            ),
          ),
        PopupMenuDivider(height: dividerHeight),
      ]);
    }

    // Pinning options
    items.addAll([
      PopupMenuItem<_HeaderMenuAction>(
        value: _HeaderMenuAction.pinLeft,
        height: itemHeight,
        padding: itemPadding,
        mouseCursor: SystemMouseCursors.click,
        child: Row(
          children: [
            Icon(
              Icons.push_pin,
              size: menuIconSize,
              color: topCol.pin == GridColumnPin.left
                  ? theme.colorScheme.primary
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pin to Left',
                style: baseMenuTextStyle.copyWith(
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
              Icon(Icons.check, size: checkIconSize, color: theme.colorScheme.primary),
          ],
        ),
      ),
      PopupMenuItem<_HeaderMenuAction>(
        value: _HeaderMenuAction.pinRight,
        height: itemHeight,
        padding: itemPadding,
        mouseCursor: SystemMouseCursors.click,
        child: Row(
          children: [
            Icon(
              Icons.push_pin_outlined,
              size: menuIconSize,
              color: topCol.pin == GridColumnPin.right
                  ? theme.colorScheme.primary
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pin to Right',
                style: baseMenuTextStyle.copyWith(
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
              Icon(Icons.check, size: checkIconSize, color: theme.colorScheme.primary),
          ],
        ),
      ),
      PopupMenuItem<_HeaderMenuAction>(
        value: _HeaderMenuAction.unpin,
        height: itemHeight,
        padding: itemPadding,
        mouseCursor: SystemMouseCursors.click,
        child: Row(
          children: [
            Icon(Icons.lock_open, size: menuIconSize),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unpin (Scrollable)',
                style: baseMenuTextStyle.copyWith(
                  fontWeight: topCol.pin == GridColumnPin.none
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (topCol.pin == GridColumnPin.none)
              Icon(Icons.check, size: checkIconSize, color: theme.colorScheme.primary),
          ],
        ),
      ),
    ]);

    final bool isResizable =
        topCol.isResizable && (bottomCol == null || bottomCol!.isResizable);
    if (isResizable &&
        (widget.onAutoFit != null || widget.onAutoFitGroup != null)) {
      items.add(PopupMenuDivider(height: dividerHeight));
      items.add(
        PopupMenuItem<_HeaderMenuAction>(
          value: _HeaderMenuAction.autoFit,
          height: itemHeight,
          padding: itemPadding,
          mouseCursor: SystemMouseCursors.click,
          child: Row(
            children: [
              Icon(Icons.fit_screen, size: menuIconSize),
              const SizedBox(width: 8),
              Expanded(child: Text('Auto-fit Width', style: baseMenuTextStyle)),
            ],
          ),
        ),
      );
    }

    // Column hiding & management (strictly disabled when compactMode is active)
    if (!isCompact) {
      items.add(PopupMenuDivider(height: dividerHeight));
      if (topCol.canHide) {
        final canHideColumn = widget.controller.visibleColumns.length > 1;
        items.add(
          PopupMenuItem<_HeaderMenuAction>(
            value: _HeaderMenuAction.hideColumn,
            enabled: canHideColumn,
            height: itemHeight,
            padding: itemPadding,
            mouseCursor: canHideColumn
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: Row(
              children: [
                Icon(
                  Icons.visibility_off_outlined,
                  size: menuIconSize,
                  color: canHideColumn ? null : theme.disabledColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hide Column',
                    style: baseMenuTextStyle.copyWith(
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
        PopupMenuItem<_HeaderMenuAction>(
          value: _HeaderMenuAction.manageColumns,
          height: itemHeight,
          padding: itemPadding,
          mouseCursor: SystemMouseCursors.click,
          child: Row(
            children: [
              Icon(Icons.view_column_outlined, size: menuIconSize),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Manage Columns...', style: baseMenuTextStyle)),
            ],
          ),
        ),
      );
    }

    showMenu<_HeaderMenuAction>(
      context: context,
      position: position,
      items: items,
      elevation: menuStyle.elevation,
      color: menuStyle.backgroundColor,
      shape: (menuStyle.borderRadius != null || menuStyle.borderSide != null)
          ? RoundedRectangleBorder(
              borderRadius:
                  menuStyle.borderRadius ?? BorderRadius.circular(4.0),
              side: menuStyle.borderSide ?? BorderSide.none,
            )
          : null,
      constraints: menuStyle.constraints,
    ).then((selected) {
      if (selected == null || !mounted) return;
      switch (selected) {
        case _HeaderMenuAction.sortAscending:
          widget.controller
              .sortByColumn(topCol.id, direction: SortDirection.ascending);
          if (mounted) setState(() {});
          break;
        case _HeaderMenuAction.sortDescending:
          widget.controller
              .sortByColumn(topCol.id, direction: SortDirection.descending);
          if (mounted) setState(() {});
          break;
        case _HeaderMenuAction.clearSort:
          widget.controller
              .sortByColumn(topCol.id, direction: SortDirection.none);
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
