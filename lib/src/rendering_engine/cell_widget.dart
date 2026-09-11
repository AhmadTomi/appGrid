import 'package:flutter/material.dart';
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
  final bool showVerticalGridLine;
  final Color? verticalGridLineColor;
  final Color? gridLineColor;

  const CellWidget({
    super.key,
    required this.controller,
    required this.indexInfo,
    required this.column,
    required this.width,
    required this.height,
    this.showVerticalGridLine = false,
    this.verticalGridLineColor,
    this.gridLineColor,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = controller.getRowNotifier(indexInfo.originalIndex);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasVerticalDivider = showVerticalGridLine;

    final decoration = hasVerticalDivider
        ? BoxDecoration(
            border: Border(
              right: BorderSide(
                color: verticalGridLineColor ??
                    gridLineColor ??
                    (isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000)),
                width: 1.0,
              ),
            ),
          )
        : null;

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: ValueListenableBuilder<T>(
        valueListenable: notifier,
        builder: (context, rowData, _) {
          // 1. Column-specific modular cell builder
          if (column.cellBuilder != null) {
            return column.cellBuilder!(context, rowData, indexInfo);
          }

          // 2. Controller-level registered cell builder
          final columnBuilder = controller.getCellBuilder(column.id);
          if (columnBuilder != null) {
            return columnBuilder(context, rowData, indexInfo);
          }

          // Default cell presentation
          final rawValue = column.valueGetter != null
              ? column.valueGetter!(rowData)
              : null;
          if (rawValue == null || (rawValue is String && rawValue.isEmpty)) {
            return const EmptyCell();
          }

          final displayText = rawValue.toString();

          return Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              displayText,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        },
      ),
    );
  }
}
