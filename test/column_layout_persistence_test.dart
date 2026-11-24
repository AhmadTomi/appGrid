import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

AppGridController<Map<String, dynamic>> _controller({
  List<GridColumn>? columns,
  bool compactMode = false,
}) {
  return AppGridController<Map<String, dynamic>>(
    initialData: [
      {'a': 1, 'b': 10, 'c': 'x'},
      {'a': 2, 'b': 30, 'c': 'y'},
      {'a': 3, 'b': 20, 'c': 'z'},
    ],
    compactMode: compactMode,
    columns: columns ??
        [
          GridColumn(id: 'a', label: 'A', valueGetter: (r) => r['a']),
          GridColumn(id: 'b', label: 'B', valueGetter: (r) => r['b']),
          GridColumn(id: 'c', label: 'C', valueGetter: (r) => r['c']),
        ],
  );
}

List<String> _visibleIds(AppGridController controller) =>
    controller.visibleColumns.map((c) => c.id).toList();

void main() {
  group('AppGridController column layout', () {
    test('defaultLayout reflects column definitions', () {
      final controller = _controller(columns: const [
        GridColumn(id: 'a', label: 'A'),
        GridColumn(id: 'b', label: 'B', isVisible: false),
      ]);
      expect(
        controller.defaultLayout,
        const GridColumnLayout(
          columnOrder: ['a', 'b'],
          columnVisibility: {'a': true, 'b': false},
        ),
      );
    });

    test('applyLayout reorders and hides, and exportLayout returns it', () {
      final controller = _controller();
      const layout = GridColumnLayout(
        columnOrder: ['c', 'a', 'b'],
        columnVisibility: {'a': true, 'b': false, 'c': true},
      );
      controller.applyLayout(layout);
      expect(_visibleIds(controller), ['c', 'a']);
      expect(controller.exportLayout(), layout);
    });

    test('applyLayout drops unknown ids and keeps new columns at default position',
        () {
      final controller = _controller();
      controller.applyLayout(const GridColumnLayout(
        columnOrder: ['c', 'zz', 'a'],
        columnVisibility: {'zz': false},
      ));
      expect(controller.exportLayout().columnOrder, ['c', 'b', 'a']);
      expect(controller.exportLayout().columnVisibility.containsKey('zz'),
          isFalse);

      final withNew = _controller(columns: const [
        GridColumn(id: 'a', label: 'A'),
        GridColumn(id: 'n', label: 'N', isVisible: false),
        GridColumn(id: 'b', label: 'B'),
      ]);
      withNew.applyLayout(const GridColumnLayout(
        columnOrder: ['b', 'a'],
        columnVisibility: {'a': true, 'b': true},
      ));
      expect(withNew.exportLayout().columnOrder, ['b', 'n', 'a']);
      expect(withNew.exportLayout().columnVisibility['n'], isFalse);
    });

    test('applyLayout never leaves zero visible columns', () {
      final controller = _controller(columns: const [
        GridColumn(id: 'a', label: 'A'),
        GridColumn(id: 'b', label: 'B', canHide: false),
      ]);
      controller.applyLayout(const GridColumnLayout(
        columnOrder: ['a', 'b'],
        columnVisibility: {'a': false, 'b': false},
      ));
      expect(_visibleIds(controller), ['b']);

      final hideable = _controller();
      hideable.applyLayout(const GridColumnLayout(
        columnOrder: ['c', 'a', 'b'],
        columnVisibility: {'a': false, 'b': false, 'c': false},
      ));
      expect(_visibleIds(hideable), ['c']);
    });

    test('applyLayout applies sortCriteria and display order', () {
      final controller = _controller();
      const sort =
          SortCriteria(columnId: 'b', direction: SortDirection.descending);
      controller.applyLayout(const GridColumnLayout(
        columnOrder: ['a', 'b', 'c'],
        columnVisibility: {},
        sortCriteria: sort,
      ));
      expect(controller.sortCriteria, sort);
      expect(controller.getRowByDisplayIndex(0)['b'], 30);
    });

    test('applyLayout drops sort on unknown or non-sortable column', () {
      final controller = _controller(columns: const [
        GridColumn(id: 'a', label: 'A'),
        GridColumn(id: 'b', label: 'B', isSortable: false),
      ]);
      controller.applyLayout(const GridColumnLayout(
        columnOrder: ['a', 'b'],
        columnVisibility: {},
        sortCriteria:
            SortCriteria(columnId: 'b', direction: SortDirection.ascending),
      ));
      expect(controller.sortCriteria, isNull);
      controller.applyLayout(const GridColumnLayout(
        columnOrder: ['a', 'b'],
        columnVisibility: {},
        sortCriteria:
            SortCriteria(columnId: 'zz', direction: SortDirection.ascending),
      ));
      expect(controller.sortCriteria, isNull);
    });

    test('applyLayout ignores sort in compact mode', () {
      final controller = _controller(compactMode: true);
      controller.applyLayout(const GridColumnLayout(
        columnOrder: ['a', 'b', 'c'],
        columnVisibility: {},
        sortCriteria:
            SortCriteria(columnId: 'a', direction: SortDirection.ascending),
      ));
      expect(controller.sortCriteria, isNull);
      expect(controller.compactMode, isTrue);
    });

    test('resetLayout restores defaults and clears sort', () async {
      final controller = _controller();
      controller.reorderColumn(0, 2);
      controller.setColumnVisibility('b', false);
      await controller.sortByColumn('a', direction: SortDirection.descending);

      controller.resetLayout();
      expect(controller.exportLayout(), controller.defaultLayout);
      expect(controller.sortCriteria, isNull);
    });

    test('layoutRevision increments on each layout mutation', () async {
      final controller = _controller();
      var revision = controller.layoutRevision.value;
      void expectBumped() {
        expect(controller.layoutRevision.value, greaterThan(revision));
        revision = controller.layoutRevision.value;
      }

      controller.reorderColumn(0, 1);
      expectBumped();
      controller.reorderColumnGroup(draggedIds: ['c'], targetColumnId: 'b');
      expectBumped();
      controller.setColumnVisibility('a', false);
      expectBumped();
      await controller.sortByColumn('b', direction: SortDirection.ascending);
      expectBumped();
      controller.applyLayout(const GridColumnLayout(
        columnOrder: ['a', 'b', 'c'],
        columnVisibility: {'a': true},
      ));
      expectBumped();
      controller.setColumnVisibility('c', false);
      expectBumped();
      controller.resetLayout();
      expectBumped();
    });

    test('layoutRevision does not change when the call is a no-op', () {
      final controller = _controller();
      final revision = controller.layoutRevision.value;
      controller.setColumnVisibility('a', true);
      controller.applyLayout(controller.exportLayout());
      controller.resetLayout();
      expect(controller.layoutRevision.value, revision);
    });

    test('layoutRevision does not change on setRows/updateData', () {
      final controller = _controller();
      final revision = controller.layoutRevision.value;
      controller.setRows([
        {'a': 9, 'b': 9, 'c': 'q'},
      ]);
      controller.updateData([
        {'a': 8, 'b': 8, 'c': 'r'},
      ]);
      expect(controller.layoutRevision.value, revision);
    });
  });
}
