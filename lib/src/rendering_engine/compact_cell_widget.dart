import 'package:flutter/material.dart';
import '../models/compact_column_group.dart';
import '../models/grid_column.dart';
import '../models/row_index_info.dart';
import '../controllers/app_grid_controller.dart';
import '../widgets/empty_cell.dart';

/// Renders a cell in compact mode.
///
/// If [group] is a pair, it renders [group.topColumn]'s value in the top half and
/// [group.bottomColumn]'s value in the bottom half, separated by a subtle horizontal divider.
/// If [group] is a single column, it renders the value spanning the full height.
///
/// Conforms to REQ-PERF-03, REQ-PERF-04, and AC-02 (granular row notifier reactivity).
class CompactCellWidget<T> extends StatelessWidget {
  final AppGridController<T> controller;
  final RowIndexInfo indexInfo;
  final CompactColumnGroup group;
  final double width;
  final double height;
  final bool showVerticalGridLine;
  final Color? verticalGridLineColor;
  final Color? gridLineColor;

  const CompactCellWidget({
    super.key,
    required this.controller,
    required this.indexInfo,
    required this.group,
    required this.width,
    required this.height,
    this.showVerticalGridLine = false,
    this.verticalGridLineColor,
    this.gridLineColor,
  });

  Widget _buildSubCell({
    required BuildContext context,
    required GridColumn column,
    required T rowData,
  }) {
    // 1. Column-specific modular cell builder
    if (column.cellBuilder != null) {
      return Align(
        alignment: column.cellAlignment,
        child: column.cellBuilder!(context, rowData, indexInfo),
      );
    }

    // 2. Controller-level registered cell builder
    final columnBuilder = controller.getCellBuilder(column.id);
    if (columnBuilder != null) {
      return Align(
        alignment: column.cellAlignment,
        child: columnBuilder(context, rowData, indexInfo),
      );
    }

    // Default cell presentation
    final rawValue = column.valueGetter != null
        ? column.valueGetter!(rowData)
        : (rowData is Map ? (rowData as Map)[column.id] : null);

    if (rawValue == null || (rawValue is String && rawValue.isEmpty)) {
      return Align(
        alignment: column.cellAlignment,
        child: const EmptyCell(),
      );
    }

    final displayText = rawValue.toString();

    return Container(
      alignment: column.cellAlignment,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        displayText,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: _textAlignFromAlignment(column.cellAlignment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = controller.getRowNotifier(indexInfo.originalIndex);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subDividerColor = gridLineColor ??
        (isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000));

    final cellContent = ValueListenableBuilder<T>(
      valueListenable: notifier,
      builder: (context, rowData, _) {
        if (!group.isPair) {
          return _buildSubCell(
            context: context,
            column: group.topColumn,
            rowData: rowData,
          );
        }

        return Column(
          children: [
            Expanded(
              child: _buildSubCell(
                context: context,
                column: group.topColumn,
                rowData: rowData,
              ),
            ),
            Container(
              height: 0.8,
              color: subDividerColor,
            ),
            Expanded(
              child: _buildSubCell(
                context: context,
                column: group.bottomColumn!,
                rowData: rowData,
              ),
            ),
          ],
        );
      },
    );

    if (!showVerticalGridLine) {
      return SizedBox(
        width: width,
        height: height,
        child: cellContent,
      );
    }

    final dividerColor = verticalGridLineColor ??
        gridLineColor ??
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
