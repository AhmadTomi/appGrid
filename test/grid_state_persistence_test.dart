import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('GridState Persistence Tests (REQ-STATE-01, 02, 03 & AC-05)', () {
    test('AC-05: JSON export strictly excludes columnWidth or width keys', () {
      final controller = AppGridController<Map<String, dynamic>>(
        columns: const [
          GridColumn(id: 'col_a', label: 'A', initialWidth: 150),
          GridColumn(id: 'col_b', label: 'B', initialWidth: 200),
          GridColumn(id: 'col_c', label: 'C', initialWidth: 100),
        ],
      );

      // Reorder and toggle visibility
      controller.reorderColumn(0, 2); // col_b, col_c, col_a
      controller.setColumnVisibility('col_b', false);
      controller.sortByColumn('col_c', direction: SortDirection.ascending);

      final state = controller.exportState();
      final jsonStr = state.toJson();
      final decodedMap = jsonDecode(jsonStr) as Map<String, dynamic>;

      // STRICT VERIFICATION:
      expect(decodedMap.containsKey('width'), isFalse);
      expect(decodedMap.containsKey('columnWidth'), isFalse);
      expect(decodedMap.containsKey('columnWidths'), isFalse);
      expect(jsonStr.contains('width'), isFalse);

      // Check allowed keys only
      expect(decodedMap.keys.toSet(), equals({'columnOrder', 'sortCriteria', 'columnVisibility', 'compactMode'}));
      expect(decodedMap['columnOrder'], equals(['col_b', 'col_c', 'col_a']));
      expect(decodedMap['columnVisibility']['col_b'], equals(false));
      expect(decodedMap['sortCriteria']['columnId'], equals('col_c'));
      expect(decodedMap['sortCriteria']['direction'], equals('ascending'));

      controller.dispose();
    });

    test('Restoring state applies columnOrder, sortCriteria, and visibility', () {
      final controller = AppGridController<Map<String, dynamic>>(
        columns: const [
          GridColumn(id: 'id', label: 'ID'),
          GridColumn(id: 'name', label: 'Name'),
          GridColumn(id: 'score', label: 'Score'),
        ],
      );

      final importedState = GridState.fromJson(
        '{"columnOrder":["score","id","name"],"sortCriteria":{"columnId":"score","direction":"descending"},"columnVisibility":{"id":false,"name":true,"score":true}}',
      );

      controller.restoreState(importedState);

      expect(controller.visibleColumns.map((c) => c.id).toList(), equals(['score', 'name']));
      expect(controller.sortCriteria?.columnId, equals('score'));
      expect(controller.sortCriteria?.direction, equals(SortDirection.descending));

      controller.dispose();
    });
  });
}
