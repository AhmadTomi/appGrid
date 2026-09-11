import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('DualIndexMap & RowIndexInfo Tests', () {
    test('Initial 1:1 mapping when unsorted and unfiltered', () {
      final map = DualIndexMap(totalCount: 5);
      expect(map.displayRowCount, equals(5));
      expect(map.originalRowCount, equals(5));

      for (var i = 0; i < 5; i++) {
        final info = map.getInfoForDisplayIndex(i);
        expect(info.displayIndex, equals(i));
        expect(info.originalIndex, equals(i));
        expect(map.getDisplayIndex(i), equals(i));
      }
    });

    test('AC-03: Descending sort maps visual index 0 to highest raw item and retains originalIndex', () {
      final items = [10, 50, 30, 90, 20];
      final map = DualIndexMap(totalCount: items.length);

      map.recompute<int>(
        items: items,
        comparator: (a, b) => a.compareTo(b),
        sortDirection: SortDirection.descending,
      );

      expect(map.displayRowCount, equals(5));

      // Visual index 0 must be 90 (which was at raw index 3)
      final info0 = map.getInfoForDisplayIndex(0);
      expect(info0.displayIndex, equals(0));
      expect(info0.originalIndex, equals(3));
      expect(items[info0.originalIndex], equals(90));

      // Visual index 1 must be 50 (raw index 1)
      final info1 = map.getInfoForDisplayIndex(1);
      expect(info1.displayIndex, equals(1));
      expect(info1.originalIndex, equals(1));
      expect(items[info1.originalIndex], equals(50));

      // Inverse lookup
      expect(map.getDisplayIndex(3), equals(0)); // item 90
      expect(map.getDisplayIndex(1), equals(1)); // item 50
    });

    test('Filtering excludes unmatching rows and updates display count', () {
      final items = ['apple', 'banana', 'cherry', 'apricot'];
      final map = DualIndexMap(totalCount: items.length);

      map.recompute<String>(
        items: items,
        filter: (item) => item.startsWith('a'),
      );

      // Only 'apple' (0) and 'apricot' (3) match
      expect(map.displayRowCount, equals(2));
      expect(map.getInfoForDisplayIndex(0).originalIndex, equals(0));
      expect(map.getInfoForDisplayIndex(1).originalIndex, equals(3));

      // banana (1) and cherry (2) are filtered out (-1)
      expect(map.getDisplayIndex(1), equals(-1));
      expect(map.getDisplayIndex(2), equals(-1));
    });
  });
}
