import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('GridColumn cellPadding Override Tests', () {
    testWidgets('cellPadding overrides global rowPadding on default text cells',
        (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': '1', 'name': 'Item 1'},
        ],
        columns: [
          GridColumn(
            id: 'id',
            label: 'ID',
            valueGetter: (row) => row['id'],
            cellPadding: const EdgeInsets.symmetric(horizontal: 4.0),
          ),
          GridColumn(
            id: 'name',
            label: 'Name',
            valueGetter: (row) => row['name'],
            // no cellPadding specified: should inherit global rowPadding
          ),
        ],
      );

      const globalPadding = EdgeInsets.symmetric(horizontal: 24.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              style: const AppGridStyle(
                rowPadding: globalPadding,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Container widgets inside CellWidget
      final containers = tester
          .widgetList<Container>(find.descendant(
            of: find.byType(CellWidget<Map<String, dynamic>>),
            matching: find.byType(Container),
          ))
          .toList();

      // The ID cell should have padding 4.0
      final idCell = containers.firstWhere(
        (c) => c.padding == const EdgeInsets.symmetric(horizontal: 4.0),
      );
      expect(idCell, isNotNull);

      // The Name cell should have global padding 24.0
      final nameCell = containers.firstWhere(
        (c) => c.padding == globalPadding,
      );
      expect(nameCell, isNotNull);
    });

    testWidgets('cellPadding overrides global rowPadding on cellBuilder cells',
        (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'custom1': 'A', 'custom2': 'B'},
        ],
        columns: [
          GridColumn(
            id: 'custom1',
            label: 'Custom 1',
            cellPadding: const EdgeInsets.all(2.0),
            cellBuilder: (context, row, info) => Text(
              row['custom1'],
              key: const ValueKey('text1'),
            ),
          ),
          GridColumn(
            id: 'custom2',
            label: 'Custom 2',
            cellBuilder: (context, row, info) => Text(
              row['custom2'],
              key: const ValueKey('text2'),
            ),
          ),
        ],
      );

      const globalPadding = EdgeInsets.all(16.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              style: const AppGridStyle(
                rowPadding: globalPadding,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Padding widget wrapping text1
      final padding1Finder = find.ancestor(
        of: find.byKey(const ValueKey('text1')),
        matching: find.byType(Padding),
      );
      final padding1 = tester.widget<Padding>(padding1Finder.first);
      expect(padding1.padding, equals(const EdgeInsets.all(2.0)));

      // Check Padding widget wrapping text2 inherits global padding
      final padding2Finder = find.ancestor(
        of: find.byKey(const ValueKey('text2')),
        matching: find.byType(Padding),
      );
      final padding2 = tester.widget<Padding>(padding2Finder.first);
      expect(padding2.padding, equals(globalPadding));
    });

    test('GridColumn copyWith and equality with cellPadding', () {
      final col1 = GridColumn(
        id: 'c1',
        label: 'C1',
        cellPadding: const EdgeInsets.all(8.0),
      );
      final col2 = GridColumn(
        id: 'c1',
        label: 'C1',
        cellPadding: const EdgeInsets.all(8.0),
      );
      final col3 = col1.copyWith(cellPadding: const EdgeInsets.all(12.0));

      expect(col1, equals(col2));
      expect(col1.hashCode, equals(col2.hashCode));
      expect(col1, isNot(equals(col3)));
      expect(col3.cellPadding, equals(const EdgeInsets.all(12.0)));
    });
  });
}
