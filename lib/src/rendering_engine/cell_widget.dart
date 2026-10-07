import 'package:flutter/material.dart';
import '../models/app_grid_style.dart';
import '../models/grid_column.dart';
import '../models/row_index_info.dart';
import '../controllers/app_grid_controller.dart';
import '../widgets/app_grid_row_drag_handle.dart';

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
        // Dedicated row drag handle column
        if (column.isRowDragHandle) {
          return Align(
            alignment: column.cellAlignment,
            child: AppGridRowDragHandle<T>(
              controller: controller,
              displayIndex: indexInfo.displayIndex,
              icon: column.rowDragIcon,
              disabledIcon: column.rowDragDisabledIcon,
            ),
          );
        }

        final effectivePadding = column.cellPadding ?? style.rowPadding;

        // 1. Column-specific modular cell builder
        if (column.cellBuilder != null) {
          final cell = column.cellBuilder!(context, rowData, indexInfo);
          return Align(
            alignment: column.cellAlignment,
            child: effectivePadding != null
                ? Padding(padding: effectivePadding, child: cell)
                : cell,
          );
        }

        // 2. Controller-level registered cell builder
        final columnBuilder = controller.getCellBuilder(column.id);
        if (columnBuilder != null) {
          final cell = columnBuilder(context, rowData, indexInfo);
          return Align(
            alignment: column.cellAlignment,
            child: effectivePadding != null
                ? Padding(padding: effectivePadding, child: cell)
                : cell,
          );
        }

        // Default cell presentation
        final rawValue =
            column.valueGetter != null ? column.valueGetter!(rowData) : null;
        if (rawValue == null || (rawValue is String && rawValue.isEmpty)) {
          return Align(
            alignment: column.cellAlignment,
            child: const EmptyCell(),
          );
        }

        final displayText = rawValue.toString();

        return Container(
          alignment: column.cellAlignment,
          padding: column.cellPadding ?? style.rowPadding ?? const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            displayText,
            style: style.rowTextStyle ??
                const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: _textAlignFromAlignment(column.cellAlignment),
          ),
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
