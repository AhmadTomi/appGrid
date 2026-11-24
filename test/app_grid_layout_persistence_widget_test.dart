import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

class _CountingStore extends InMemoryGridLayoutStore {
  int writes = 0;

  @override
  void write(String key, GridColumnLayout layout) {
    writes++;
    super.write(key, layout);
  }
}

AppGridController<Map<String, dynamic>> _controller({bool compact = false}) {
  return AppGridController<Map<String, dynamic>>(
    initialData: [
      {'a': 1, 'b': 10, 'c': 'x'},
      {'a': 2, 'b': 30, 'c': 'y'},
    ],
    compactMode: compact,
    columns: [
      GridColumn(
          id: 'a',
          label: 'Alpha',
          initialWidth: 120,
          valueGetter: (r) => r['a']),
      GridColumn(
          id: 'b',
          label: 'Bravo',
          initialWidth: 120,
          valueGetter: (r) => r['b']),
      GridColumn(
          id: 'c',
          label: 'Charlie',
          initialWidth: 120,
          valueGetter: (r) => r['c']),
    ],
  );
}

Widget _host({
  required AppGridController<Map<String, dynamic>> controller,
  GridLayoutStore? store,
  String? persistenceKey = 'orders',
}) {
  Widget grid = AppGrid<Map<String, dynamic>>(
    controller: controller,
    persistenceKey: persistenceKey,
  );
  final body = SizedBox(width: 800, height: 400, child: grid);
  final app = MaterialApp(home: Scaffold(body: body));
  return store == null ? app : AppGridLayoutScope(store: store, child: app);
}

List<String> _visible(AppGridController controller) =>
    controller.visibleColumns.map((c) => c.id).toList();

void main() {
  const hideBravo = GridColumnLayout(
    columnOrder: ['c', 'a', 'b'],
    columnVisibility: {'a': true, 'b': false, 'c': true},
  );

  testWidgets('applies stored layout on first frame', (tester) async {
    final store = InMemoryGridLayoutStore()..write('orders', hideBravo);
    final controller = _controller();

    await tester.pumpWidget(_host(controller: controller, store: store));

    expect(find.text('Bravo'), findsNothing);
    expect(_visible(controller), ['c', 'a']);
  });

  testWidgets('applies stored sort on first frame', (tester) async {
    const sort =
        SortCriteria(columnId: 'b', direction: SortDirection.descending);
    final store = InMemoryGridLayoutStore()
      ..write(
          'orders',
          const GridColumnLayout(
              columnOrder: ['a', 'b', 'c'],
              columnVisibility: {},
              sortCriteria: sort));
    final controller = _controller();

    await tester.pumpWidget(_host(controller: controller, store: store));

    expect(controller.sortCriteria, sort);
    expect(controller.getRowByDisplayIndex(0)['b'], 30);
  });

  testWidgets('writes layout when a column is hidden', (tester) async {
    final store = InMemoryGridLayoutStore();
    final controller = _controller();
    await tester.pumpWidget(_host(controller: controller, store: store));

    controller.setColumnVisibility('b', false);

    expect(store.read('orders')!.columnVisibility['b'], isFalse);
  });

  testWidgets('writes sort when a header sort is applied', (tester) async {
    final store = InMemoryGridLayoutStore();
    final controller = _controller();
    await tester.pumpWidget(_host(controller: controller, store: store));

    await controller.sortByColumn('a', direction: SortDirection.descending);

    expect(store.read('orders')!.sortCriteria,
        const SortCriteria(columnId: 'a', direction: SortDirection.descending));
  });

  testWidgets('data updates do not write to store', (tester) async {
    final store = _CountingStore();
    final controller = _controller();
    await tester.pumpWidget(_host(controller: controller, store: store));
    final before = store.writes;

    for (var i = 0; i < 3; i++) {
      controller.setRows([
        {'a': i, 'b': i, 'c': '$i'},
      ]);
      await tester.pump();
    }

    expect(store.writes, before);
  });

  testWidgets('writes merge with settings of columns not present',
      (tester) async {
    final store = InMemoryGridLayoutStore()
      ..write(
          'orders',
          const GridColumnLayout(
            columnOrder: ['a', 'x', 'b', 'c'],
            columnVisibility: {'x': false},
          ));
    final controller = _controller();
    await tester.pumpWidget(_host(controller: controller, store: store));

    controller.setColumnVisibility('c', false);

    final stored = store.read('orders')!;
    expect(stored.columnVisibility['x'], isFalse);
    expect(stored.columnVisibility['c'], isFalse);
    expect(stored.columnOrder, ['a', 'x', 'b', 'c']);
  });

  testWidgets('re-applies layout when controller changes', (tester) async {
    final store = InMemoryGridLayoutStore()..write('orders', hideBravo);
    final first = _controller();
    await tester.pumpWidget(_host(controller: first, store: store));

    final second = _controller();
    await tester.pumpWidget(_host(controller: second, store: store));

    expect(_visible(second), ['c', 'a']);

    second.setColumnVisibility('a', false);
    expect(store.read('orders')!.columnVisibility['a'], isFalse);
  });

  testWidgets('no persistence without key, without scope, or in compact mode',
      (tester) async {
    final store = _CountingStore()..write('orders', hideBravo);
    store.writes = 0;

    final noKey = _controller();
    await tester.pumpWidget(
        _host(controller: noKey, store: store, persistenceKey: null));
    expect(_visible(noKey), ['a', 'b', 'c']);
    noKey.setColumnVisibility('a', false);

    final noScope = _controller();
    await tester.pumpWidget(_host(controller: noScope));
    noScope.setColumnVisibility('a', false);

    final compact = _controller(compact: true);
    await tester.pumpWidget(_host(controller: compact, store: store));
    compact.reorderColumn(0, 1);

    expect(store.writes, 0);
    expect(store.read('orders'), hideBravo);
  });

  testWidgets('applies stored layout when compact mode is turned off',
      (tester) async {
    final store = InMemoryGridLayoutStore()..write('orders', hideBravo);
    final controller = _controller(compact: true);
    await tester.pumpWidget(_host(controller: controller, store: store));
    expect(_visible(controller), ['a', 'b', 'c']);

    controller.compactMode = false;
    await tester.pump();

    expect(_visible(controller), ['c', 'a']);
    controller.setColumnVisibility('c', false);
    expect(store.read('orders')!.columnOrder, ['c', 'a', 'b']);
  });

  testWidgets('Reset to Default shown only with active persistence',
      (tester) async {
    final withoutKey = _controller();
    await tester.pumpWidget(_host(
        controller: withoutKey,
        store: InMemoryGridLayoutStore(),
        persistenceKey: null));
    withoutKey.openColumnChooser();
    await tester.pumpAndSettle();
    expect(find.text('Manage Columns'), findsOneWidget);
    expect(find.text('Reset to Default'), findsNothing);

    final withKey = _controller();
    await tester.pumpWidget(
        _host(controller: withKey, store: InMemoryGridLayoutStore()));
    withKey.openColumnChooser();
    await tester.pumpAndSettle();
    expect(find.text('Reset to Default'), findsOneWidget);
  });

  testWidgets(
      'tapping Reset to Default restores defaults and removes the entry',
      (tester) async {
    final store = InMemoryGridLayoutStore()
      ..write(
          'orders',
          const GridColumnLayout(
            columnOrder: ['c', 'a', 'b'],
            columnVisibility: {'b': false},
            sortCriteria:
                SortCriteria(columnId: 'a', direction: SortDirection.ascending),
          ));
    final controller = _controller();
    await tester.pumpWidget(_host(controller: controller, store: store));
    controller.openColumnChooser();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset to Default'));
    await tester.pumpAndSettle();

    expect(controller.exportLayout(), controller.defaultLayout);
    expect(store.read('orders'), isNull);
  });

  testWidgets("open grid is not updated by another grid's write",
      (tester) async {
    final store = InMemoryGridLayoutStore();
    final left = _controller();
    final right = _controller();
    await tester.pumpWidget(AppGridLayoutScope(
      store: store,
      child: MaterialApp(
        home: Scaffold(
          body: Row(children: [
            SizedBox(
                width: 400,
                height: 300,
                child: AppGrid<Map<String, dynamic>>(
                    controller: left, persistenceKey: 'orders')),
            SizedBox(
                width: 400,
                height: 300,
                child: AppGrid<Map<String, dynamic>>(
                    controller: right, persistenceKey: 'orders')),
          ]),
        ),
      ),
    ));

    left.setColumnVisibility('b', false);
    await tester.pumpAndSettle();

    expect(_visible(right), ['a', 'b', 'c']);
  });
}
