import 'package:flutter/material.dart';
import '../models/app_grid_style.dart';
import '../models/grid_column.dart';
import '../models/row_index_info.dart';
import '../controllers/app_grid_controller.dart';
import '../widgets/empty_cell.dart';

/// Isolated reactive cell widget listening exclusively to its row's state notifier.
///
/// Satisfies REQ-PERF-03, REQ-PERF-04, and AC-02:
/// High-frequency streaming ticks mutate the row notifier and rebuild ONLY this cell,
/// completely bypassing root widget rebuilds.
class CellWidget<T> extends StatelessWidget {
  final AppGridController<T> controller;
  final RowIndexInfo indexInfo;
  final GridColumn column;
  final double width;
  final double height;
  final AppGridStyle style;

  const CellWidget({
    super.key,
    required this.controller,
    required this.indexInfo,
    required this.column,
    required this.width,
    required this.height,
    this.style = const AppGridStyle(),
  });

  @override
  Widget build(BuildContext context) {
    final notifier = controller.getRowNotifier(indexInfo.originalIndex);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasVerticalDivider = style.showVerticalGridLines;

    final cellContent = ValueListenableBuilder<T>(
      valueListenable: notifier,
      builder: (context, rowData, _) {
        final effectivePadding = column.cellPadding ?? style.rowPadding;

        Widget baseContent;
        bool hasContent = true;

        if (column.cellBuilder != null) {
          final cell = column.cellBuilder!(context, rowData, indexInfo);
          baseContent = effectivePadding != null
              ? Padding(padding: effectivePadding, child: cell)
              : cell;
        } else if (controller.getCellBuilder(column.id) != null) {
          final cell =
              controller.getCellBuilder(column.id)!(context, rowData, indexInfo);
          baseContent = effectivePadding != null
              ? Padding(padding: effectivePadding, child: cell)
              : cell;
        } else {
          final rawValue =
              column.valueGetter != null ? column.valueGetter!(rowData) : null;
          if (rawValue == null || (rawValue is String && rawValue.isEmpty)) {
            hasContent = false;
            baseContent = const EmptyCell();
          } else {
            baseContent = Container(
              alignment: column.cellAlignment,
              padding: column.cellPadding ??
                  style.rowPadding ??
                  const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                rawValue.toString(),
                style: style.rowTextStyle ??
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: _textAlignFromAlignment(column.cellAlignment),
              ),
            );
          }
        }

        // PlutoGrid row drag handle integration
        if (column.enableRowDrag && controller.canReorderRows) {
          final dragHandle = MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Draggable<int>(
              data: indexInfo.displayIndex,
              dragAnchorStrategy: (draggable, context, position) {
                return const Offset(20, 20);
              },
              feedback: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(6),
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(240),
                shadowColor: Colors.black45,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      Icon(Icons.reorder,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Row #${indexInfo.displayIndex + 1}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.25,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    Icons.drag_indicator,
                    size: style.iconSize ?? 18,
                    color: theme.colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  Icons.drag_indicator,
                  size: style.iconSize ?? 18,
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
              ),
            ),
          );

          if (!hasContent) {
            return Align(
              alignment: column.cellAlignment,
              child: dragHandle,
            );
          }

          return Align(
            alignment: column.cellAlignment,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                dragHandle,
                Flexible(child: baseContent),
              ],
            ),
          );
        }

        return Align(
          alignment: column.cellAlignment,
          child: baseContent,
        );
      },
    );

    if (!hasVerticalDivider) {
      return SizedBox(
        width: width,
        height: height,
        child: cellContent,
      );
    }

    final dividerColor = style.verticalGridLineColor ??
        style.gridLineColor ??
        (isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000));

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(right: 1.0),
              child: cellContent,
            ),
          ),
          // Vertical divider on top
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 1.0,
            child: Container(
              color: dividerColor,
            ),
          ),
        ],
      ),
    );
  }
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
