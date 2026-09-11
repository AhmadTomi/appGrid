import 'package:flutter/widgets.dart';
import '../models/grid_column.dart';
import '../models/row_index_info.dart';
import '../models/sort_criteria.dart';

/// Custom builder for column headers in [AppGrid].
typedef GridHeaderBuilder = Widget Function(
  BuildContext context,
  GridColumn column,
  SortDirection sortDirection,
  VoidCallback onSortToggle,
);

/// Custom builder for individual grid cells in [AppGrid].
typedef GridCellBuilder<T> = Widget Function(
  BuildContext context,
  T rowData,
  RowIndexInfo indexInfo,
  String columnId,
);

/// Custom builder for column footers in [AppGrid].
typedef GridFooterBuilder = Widget Function(
  BuildContext context,
  GridColumn column,
  List<dynamic> currentVisibleData,
);
