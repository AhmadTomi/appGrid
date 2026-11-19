import 'package:app_grid/app_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpGrid(WidgetTester tester, List<GridColumn> columns) async {
    final controller = AppGridController<Map<String, dynamic>>(
      initialData: [
        {'name': 'Item A', 'price': 2480},
      ],
      columns: columns,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 300,
            child: AppGrid<Map<String, dynamic>>(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The rendered label text, which may be narrower than its header box.
  Rect labelRect(WidgetTester tester, String label) =>
      tester.getRect(find.text(label));

  Rect menuIconRect(WidgetTester tester, int index) =>
      tester.getRect(find.byIcon(Icons.dehaze).at(index));

  testWidgets('a right-aligned label keeps its icon on the left', (
    tester,
  ) async {
    await pumpGrid(tester, [
      GridColumn(
        id: 'name',
        label: 'Name',
        initialWidth: 120,
        valueGetter: (r) => r['name'],
      ),
      GridColumn(
        id: 'price',
        label: 'Price',
        initialWidth: 120,
        headerAlignment: Alignment.centerRight,
        cellAlignment: Alignment.centerRight,
        valueGetter: (r) => r['price'],
      ),
    ]);

    final label = labelRect(tester, 'Price');
    final icon = menuIconRect(tester, 1);

    expect(icon.right, lessThanOrEqualTo(label.left));
  });

  testWidgets('a left-aligned label keeps its icon on the right', (
    tester,
  ) async {
    await pumpGrid(tester, [
      GridColumn(
        id: 'name',
        label: 'A fairly long column name',
        initialWidth: 120,
        headerAlignment: Alignment.centerLeft,
        valueGetter: (r) => r['name'],
      ),
    ]);

    final label = labelRect(tester, 'A fairly long column name');
    final icon = menuIconRect(tester, 0);

    // The long label is cut short before the icon instead of running under
    // it.
    expect(label.right, lessThanOrEqualTo(icon.left));
  });

  testWidgets('a centered label stays centered in its column', (
    tester,
  ) async {
    await pumpGrid(tester, [
      GridColumn(
        id: 'name',
        label: 'Name',
        initialWidth: 160,
        valueGetter: (r) => r['name'],
      ),
    ]);

    final header = tester.getRect(
      find.ancestor(of: find.text('Name'), matching: find.byType(Row)).first,
    );
    final label = labelRect(tester, 'Name');

    expect(label.center.dx, moreOrLessEquals(header.center.dx, epsilon: 1));
  });
}
