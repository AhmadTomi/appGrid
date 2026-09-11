import 'package:flutter/material.dart';
import '../models/grid_column.dart';
import '../models/row_index_info.dart';
import '../controllers/app_grid_controller.dart';
import 'grid_builders.dart';
import 'cell_widget.dart';

/// Renders a single virtualized row with cell composition and selection highlighting.
class RowWidget<T> extends StatelessWidget {
  final AppGridController<T> controller;
  final RowIndexInfo indexInfo;
  final List<GridColumn> columns;
  final Map<String, double> columnWidths;
  final Map<String, double>? columnOffsets;
  final double rowHeight;
  final bool isSelected;
  final VoidCallback? onTap;
  final GridCellBuilder<T>? customCellBuilder;
  final Color? selectedColor;
  final Color? alternateRowColor;
  final Color? evenRowColor;
  final Color? oddRowColor;

  const RowWidget({
    super.key,
    required this.controller,
    required this.indexInfo,
    required this.columns,
    required this.columnWidths,
    this.columnOffsets,
    required this.rowHeight,
    required this.isSelected,
    this.onTap,
    this.customCellBuilder,
    this.selectedColor,
    this.alternateRowColor,
    this.evenRowColor,
    this.oddRowColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color? backgroundColor;
    if (isSelected) {
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

    final children = <Widget>[];

    for (final col in columns) {
      final width = columnWidths[col.id] ?? col.initialWidth;
      children.add(
        CellWidget<T>(
          key: ValueKey('cell_${indexInfo.originalIndex}_${col.id}'),
          controller: controller,
          indexInfo: indexInfo,
          column: col,
          width: width,
          height: rowHeight,
          customCellBuilder: customCellBuilder,
        ),
      );
    }

    final totalWidth = columns.fold<double>(
      0.0,
      (sum, col) => sum + (columnWidths[col.id] ?? col.initialWidth),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => controller.selectRow(indexInfo.displayIndex),
      child: Container(
        width: totalWidth,
        height: rowHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000),
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
