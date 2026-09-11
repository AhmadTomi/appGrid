import 'package:flutter/widgets.dart';
import '../models/grid_column.dart';
import '../models/row_index_info.dart';
import '../controllers/app_grid_controller.dart';
import 'grid_builders.dart';

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
  final GridCellBuilder<T>? customCellBuilder;

  const CellWidget({
    super.key,
    required this.controller,
    required this.indexInfo,
    required this.column,
    required this.width,
    required this.height,
    this.customCellBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = controller.getRowNotifier(indexInfo.originalIndex);

    return SizedBox(
      width: width,
      height: height,
      child: ValueListenableBuilder<T>(
        valueListenable: notifier,
        builder: (context, rowData, _) {
          final columnBuilder = controller.getCellBuilder(column.id);
          if (columnBuilder != null) {
            return columnBuilder(context, rowData, indexInfo);
          }

          if (customCellBuilder != null) {
            return customCellBuilder!(context, rowData, indexInfo, column.id);
          }

          if (controller.globalCellBuilder != null) {
            return controller.globalCellBuilder!(context, rowData, indexInfo, column.id);
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
