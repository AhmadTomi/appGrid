import 'package:flutter/material.dart';
import '../models/app_grid_style.dart';
import '../models/grid_column.dart';
import '../models/compact_column_group.dart';
import '../models/row_index_info.dart';
import '../controllers/app_grid_controller.dart';
import 'cell_widget.dart';
import 'compact_cell_widget.dart';

/// Renders a single virtualized row with cell composition and selection highlighting.
class RowWidget<T> extends StatelessWidget {
  final AppGridController<T> controller;
  final RowIndexInfo indexInfo;
  final List<GridColumn> columns;
  final List<CompactColumnGroup>? groups;
  final Map<String, double> columnWidths;
  final Map<String, double>? columnOffsets;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool readOnly;
  final AppGridStyle style;

  const RowWidget({
    super.key,
    required this.controller,
    required this.indexInfo,
    required this.columns,
    this.groups,
    required this.columnWidths,
    this.columnOffsets,
    required this.isSelected,
    this.onTap,
    this.readOnly = false,
    this.style = const AppGridStyle(),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveReadOnly = readOnly || controller.isReadOnly;
    final showSelected = isSelected && !effectiveReadOnly;

    Color? backgroundColor;
    if (showSelected) {
      backgroundColor = style.selectedRowColor ??
          (isDark
              ? theme.colorScheme.primary.withAlpha(75)
              : theme.colorScheme.primary.withAlpha(45));
    } else {
      final isOdd = indexInfo.displayIndex % 2 == 1;
      backgroundColor = isOdd ? style.oddRowColor : style.evenRowColor;
    }

    final double effectiveRowHeight =
        controller.compactMode ? style.rowHeight * 2.0 : style.rowHeight;

    final children = <Widget>[];

    if (groups != null && groups!.isNotEmpty) {
      for (final group in groups!) {
        final width = columnWidths[group.topColumn.id] ?? group.initialWidth;
        if (group.isPair) {
          children.add(
            CompactCellWidget<T>(
              key: ValueKey('cell_${indexInfo.originalIndex}_${group.id}'),
              controller: controller,
              indexInfo: indexInfo,
              group: group,
              width: width,
              height: effectiveRowHeight,
              style: style,
            ),
          );
        } else {
          children.add(
            CellWidget<T>(
              key: ValueKey(
                  'cell_${indexInfo.originalIndex}_${group.topColumn.id}'),
              controller: controller,
              indexInfo: indexInfo,
              column: group.topColumn,
              width: width,
              height: effectiveRowHeight,
              style: style,
            ),
          );
        }
      }
    } else {
      for (final col in columns) {
        final width = columnWidths[col.id] ?? col.initialWidth;
        children.add(
          CellWidget<T>(
            key: ValueKey('cell_${indexInfo.originalIndex}_${col.id}'),
            controller: controller,
            indexInfo: indexInfo,
            column: col,
            width: width,
            height: effectiveRowHeight,
            style: style,
          ),
        );
      }
    }

    final totalWidth = groups != null && groups!.isNotEmpty
        ? groups!.fold<double>(
            0.0,
            (sum, g) => sum + (columnWidths[g.topColumn.id] ?? g.initialWidth),
          )
        : columns.fold<double>(
            0.0,
            (sum, col) => sum + (columnWidths[col.id] ?? col.initialWidth),
          );

    final horizontalLineColor = style.gridLineColor ??
        (isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000));

    final rowContainer = Container(
      width: totalWidth,
      height: effectiveRowHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: style.showHorizontalGridLines
          ? Stack(
              clipBehavior: Clip.hardEdge,
              children: [
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
    );

    if (onTap != null && !effectiveReadOnly) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: rowContainer,
      );
    }

    return rowContainer;
  }
}
