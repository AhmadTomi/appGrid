import 'dart:convert';
import '../controllers/app_grid_controller.dart';
import '../models/grid_column.dart';

/// Built-in export utilities converting active display grid data to CSV and JSON formats.
class DataGridExporter {
  const DataGridExporter._();

  /// Converts active display data of [controller] to RFC 4180 compliant CSV format.
  static String toCsv<T>({
    required AppGridController<T> controller,
    List<GridColumn>? targetColumns,
    String delimiter = ',',
    bool includeHeaders = true,
  }) {
    final columns = targetColumns ?? controller.visibleColumns;
    final rowCount = controller.displayRowCount;
    final buffer = StringBuffer();

    // 1. Headers
    if (includeHeaders) {
      final headerLine = columns.map((col) => _escapeCsv(col.label, delimiter)).join(delimiter);
      buffer.writeln(headerLine);
    }

    // 2. Data rows
    for (var r = 0; r < rowCount; r++) {
      final rowData = controller.getRowByDisplayIndex(r);
      final rowValues = columns.map((col) {
        final val = col.valueGetter != null ? col.valueGetter!(rowData) : '';
        return _escapeCsv(val?.toString() ?? '', delimiter);
      }).join(delimiter);

      buffer.writeln(rowValues);
    }

    return buffer.toString();
  }

  /// Converts active display data of [controller] to a formatted JSON string.
  static String toJson<T>({
    required AppGridController<T> controller,
    List<GridColumn>? targetColumns,
    bool pretty = false,
  }) {
    final columns = targetColumns ?? controller.visibleColumns;
    final rowCount = controller.displayRowCount;
    final List<Map<String, dynamic>> records = [];

    for (var r = 0; r < rowCount; r++) {
      final rowData = controller.getRowByDisplayIndex(r);
      final Map<String, dynamic> record = {};
      for (final col in columns) {
        final val = col.valueGetter != null ? col.valueGetter!(rowData) : null;
        record[col.id] = val;
      }
      records.add(record);
    }

    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(records);
    }
    return jsonEncode(records);
  }

  static String _escapeCsv(String value, String delimiter) {
    if (value.contains(delimiter) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }
}
