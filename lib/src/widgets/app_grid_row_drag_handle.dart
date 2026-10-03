import 'package:flutter/material.dart';
import '../controllers/app_grid_controller.dart';
import '../models/row_index_info.dart';

/// Dedicated drag handle widget for manually reordering table rows.
///
/// Automatically inspects [controller.canReorderRows]. When a column sort is active,
/// this handle transitions to a disabled state (muted opacity and basic cursor) and
/// prevents drag gestures.
class AppGridRowDragHandle<T> extends StatelessWidget {
  /// The grid controller managing the table state and row order.
  final AppGridController<T> controller;

  /// The visual display index of the row this handle belongs to.
  final int displayIndex;

  /// Optional custom drag handle icon or widget.
  final Widget? icon;

  /// Optional custom icon displayed when row reordering is disabled (e.g. sorting active).
  final Widget? disabledIcon;

  /// Optional custom drag feedback builder.
  final Widget Function(BuildContext context, int displayIndex, T data)?
      feedbackBuilder;

  /// Tooltip message shown when reordering is disabled due to active sorting.
  final String? disabledTooltip;

  const AppGridRowDragHandle({
    super.key,
    required this.controller,
    required this.displayIndex,
    this.icon,
    this.disabledIcon,
    this.feedbackBuilder,
    this.disabledTooltip = 'Row reordering is disabled while sorting is active',
  });

  /// Shorthand constructor accepting [RowIndexInfo].
  AppGridRowDragHandle.fromInfo({
    super.key,
    required this.controller,
    required RowIndexInfo indexInfo,
    this.icon,
    this.disabledIcon,
    this.feedbackBuilder,
    this.disabledTooltip = 'Row reordering is disabled while sorting is active',
  }) : displayIndex = indexInfo.displayIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReorderable = controller.canReorderRows;

    final defaultIcon = Icon(
      Icons.drag_indicator,
      size: 20,
      color: theme.colorScheme.onSurface.withAlpha(isReorderable ? 180 : 70),
    );

    if (!isReorderable) {
      Widget disabledChild = disabledIcon ?? defaultIcon;
      if (disabledTooltip != null && disabledTooltip!.isNotEmpty) {
        disabledChild = Tooltip(
          message: disabledTooltip!,
          waitDuration: const Duration(milliseconds: 400),
          child: disabledChild,
        );
      }
      return MouseRegion(
        cursor: SystemMouseCursors.basic,
        child: Center(child: disabledChild),
      );
    }

    final rowData =
        displayIndex >= 0 && displayIndex < controller.displayRowCount
            ? controller.getRowByDisplayIndex(displayIndex)
            : null;

    Widget feedback;
    if (feedbackBuilder != null && rowData != null) {
      feedback = feedbackBuilder!(context, displayIndex, rowData);
    } else {
      feedback = Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(6),
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(240),
        shadowColor: Colors.black45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.colorScheme.primary.withAlpha(160),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.reorder, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Moving Row #${displayIndex + 1}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<int>(
        data: displayIndex,
        dragAnchorStrategy: (draggable, context, position) {
          return const Offset(20, 20);
        },
        feedback: feedback,
        childWhenDragging: Opacity(
          opacity: 0.25,
          child: Center(child: icon ?? defaultIcon),
        ),
        child: Center(child: icon ?? defaultIcon),
      ),
    );
  }
}
