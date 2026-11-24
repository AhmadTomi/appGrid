import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('GridColumnLayout', () {
    test('toMap/fromMap round-trips', () {
      const withSort = GridColumnLayout(
        columnOrder: ['a', 'b'],
        columnVisibility: {'a': true, 'b': false},
        sortCriteria:
            SortCriteria(columnId: 'b', direction: SortDirection.ascending),
      );
      const withoutSort = GridColumnLayout(
        columnOrder: ['b', 'a'],
        columnVisibility: {'a': false, 'b': true},
      );

      expect(GridColumnLayout.fromMap(withSort.toMap()), withSort);
      expect(GridColumnLayout.fromMap(withoutSort.toMap()), withoutSort);
      expect(withoutSort.toMap()['sortCriteria'], isNull);
    });

    test('fromMap tolerates missing and wrong-typed fields', () {
      final layout = GridColumnLayout.fromMap({
        'columnOrder': 5,
        'columnVisibility': ['x'],
        'sortCriteria': 'bad',
      });
      expect(layout.columnOrder, isEmpty);
      expect(layout.columnVisibility, isEmpty);
      expect(layout.sortCriteria, isNull);

      final mixed = GridColumnLayout.fromMap({
        'columnOrder': ['a', 1, 'b'],
        'columnVisibility': {'a': false, 'b': 'yes'},
        'sortCriteria': {'columnId': 3, 'direction': 'ascending'},
      });
      expect(mixed.columnOrder, ['a', 'b']);
      expect(mixed.columnVisibility, {'a': false});
      expect(mixed.sortCriteria, isNull);
    });

    test('mergedOnto null returns this', () {
      const layout = GridColumnLayout(
        columnOrder: ['a'],
        columnVisibility: {'a': true},
      );
      expect(layout.mergedOnto(null), layout);
    });

    test('mergedOnto takes sortCriteria from current, even when null', () {
      const stored = GridColumnLayout(
        columnOrder: ['a'],
        columnVisibility: {'a': true},
        sortCriteria:
            SortCriteria(columnId: 'a', direction: SortDirection.descending),
      );
      const current = GridColumnLayout(
        columnOrder: ['a'],
        columnVisibility: {'a': true},
      );
      expect(current.mergedOnto(stored).sortCriteria, isNull);
    });

    test('mergedOnto keeps visibility of columns absent from current', () {
      const current = GridColumnLayout(
        columnOrder: ['a', 'b', 'c'],
        columnVisibility: {'a': true, 'b': true, 'c': true},
      );
      const stored = GridColumnLayout(
        columnOrder: ['a', 'x', 'b', 'c'],
        columnVisibility: {'x': false, 'b': false},
      );
      final merged = current.mergedOnto(stored);
      expect(merged.columnVisibility,
          {'x': false, 'a': true, 'b': true, 'c': true});
      expect(merged.columnOrder, ['a', 'x', 'b', 'c']);
    });

    test('mergedOnto inserts stored-only ids after their previous stored neighbour',
        () {
      const current = GridColumnLayout(
        columnOrder: ['c', 'a', 'b'],
        columnVisibility: {},
      );
      const stored = GridColumnLayout(
        columnOrder: ['x', 'a', 'y', 'b'],
        columnVisibility: {},
      );
      expect(current.mergedOnto(stored).columnOrder, ['x', 'c', 'a', 'y', 'b']);
    });
  });
}
