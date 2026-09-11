import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('IsolateSorter & Background Sorting Tests', () {
    test('Sorts numerical keys ascending and descending in background Isolate', () async {
      final keys = [45, 12, 89, 3, 27, 99, 1];

      final ascIndices = await IsolateSorter.sortKeysAsync(keys: keys, isAscending: true);
      final sortedAsc = ascIndices.map((i) => keys[i]).toList();
      expect(sortedAsc, equals([1, 3, 12, 27, 45, 89, 99]));

      final descIndices = await IsolateSorter.sortKeysAsync(keys: keys, isAscending: false);
      final sortedDesc = descIndices.map((i) => keys[i]).toList();
      expect(sortedDesc, equals([99, 89, 45, 27, 12, 3, 1]));
    });

    test('Sorts large dataset (10,000 items) in background Isolate without frame drop', () async {
      final keys = List.generate(10000, (i) => 10000 - i);

      final ascIndices = await IsolateSorter.sortKeysAsync(keys: keys, isAscending: true);
      expect(ascIndices.length, equals(10000));
      expect(keys[ascIndices[0]], equals(1)); // smallest
      expect(keys[ascIndices[9999]], equals(10000)); // largest
    });

    test('AppGridController automatically offloads to Isolate when row count >= isolateSortThreshold', () async {
      final items = List.generate(3000, (i) => {'id': i, 'val': 3000 - i});
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: items,
        isolateSortThreshold: 1000, // lower threshold to trigger isolate
        columns: [
          GridColumn(id: 'val', label: 'Value', valueGetter: (r) => r['val']),
        ],
      );

      // Sort ascending via Isolate
      await controller.sortByColumn('val', direction: SortDirection.ascending);

      // Visual row 0 must now be item with val: 1 (which was raw index 2999)
      expect(controller.getRowByDisplayIndex(0)['val'], equals(1));
      expect(controller.getRowByDisplayIndex(2999)['val'], equals(3000));

      controller.dispose();
    });

    test('Sorts 100,000 rows in AppGridController', () async {
      final columns = List.generate(
        50,
        (c) => GridColumn(
          id: 'col_$c',
          label: 'Field $c',
          initialWidth: 110,
          valueGetter: (row) => c == 0 ? row : (row * (c + 1) % 10007),
        ),
      );

      final controller = AppGridController<int>(
        initialData: List.generate(100000, (i) => i),
        columns: columns,
      );

      await controller.sortByColumn('col_0', direction: SortDirection.descending);
      expect(controller.getRowByDisplayIndex(0), equals(99999));
      expect(controller.getRowByDisplayIndex(99999), equals(0));

      await controller.sortByColumn('col_1', direction: SortDirection.ascending);
      final firstVal = columns[1].valueGetter!(controller.getRowByDisplayIndex(0)) as int;
      final lastVal = columns[1].valueGetter!(controller.getRowByDisplayIndex(99999)) as int;
      expect(firstVal <= lastVal, isTrue);

      controller.dispose();
    });
  });
}
