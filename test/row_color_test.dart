import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Row Color Customization Tests', () {
    testWidgets('AppGrid applies evenRowColor and oddRowColor correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': '1', 'name': 'Item 1'},
          {'id': '2', 'name': 'Item 2'},
          {'id': '3', 'name': 'Item 3'},
          {'id': '4', 'name': 'Item 4'},
        ],
        columns: [
          GridColumn(
            id: 'id',
            label: 'ID',
            valueGetter: (row) => row['id'],
          ),
          GridColumn(
            id: 'name',
            label: 'Name',
            valueGetter: (row) => row['name'],
          ),
        ],
      );

      const evenColor = Color(0xFFF0F0F0);
      const oddColor = Color(0xFFE0E0E0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              evenRowColor: evenColor,
              oddRowColor: oddColor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rowWidgets = tester.widgetList<RowWidget<Map<String, dynamic>>>(
        find.byType(RowWidget<Map<String, dynamic>>),
      ).toList();

      expect(rowWidgets.isNotEmpty, isTrue);

      // Find center pane rows
      final row0 = rowWidgets.firstWhere((r) => r.indexInfo.displayIndex == 0);
      final row1 = rowWidgets.firstWhere((r) => r.indexInfo.displayIndex == 1);

      expect(row0.evenRowColor, equals(evenColor));
      expect(row0.oddRowColor, equals(oddColor));
      expect(row1.evenRowColor, equals(evenColor));
      expect(row1.oddRowColor, equals(oddColor));

      // Verify the Container decorations inside RowWidget
      final containerFinder = find.descendant(
        of: find.byWidget(row0),
        matching: find.byType(Container),
      );
      final container0 = tester.widget<Container>(containerFinder.first);
      final boxDec0 = container0.decoration as BoxDecoration;
      expect(boxDec0.color, equals(evenColor));

      final containerFinder1 = find.descendant(
        of: find.byWidget(row1),
        matching: find.byType(Container),
      );
      final container1 = tester.widget<Container>(containerFinder1.first);
      final boxDec1 = container1.decoration as BoxDecoration;
      expect(boxDec1.color, equals(oddColor));
    });

    testWidgets('AppGrid falls back to alternateRowColor for odd rows when oddRowColor is null', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': '1', 'name': 'Item 1'},
          {'id': '2', 'name': 'Item 2'},
        ],
        columns: [
          GridColumn(
            id: 'id',
            label: 'ID',
            valueGetter: (row) => row['id'],
          ),
        ],
      );

      const altColor = Color(0xFFEEEEEE);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              alternateRowColor: altColor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rowWidgets = tester.widgetList<RowWidget<Map<String, dynamic>>>(
        find.byType(RowWidget<Map<String, dynamic>>),
      ).toList();

      final row0 = rowWidgets.firstWhere((r) => r.indexInfo.displayIndex == 0);
      final row1 = rowWidgets.firstWhere((r) => r.indexInfo.displayIndex == 1);

      final container0 = tester.widget<Container>(
        find.descendant(of: find.byWidget(row0), matching: find.byType(Container)).first,
      );
      final boxDec0 = container0.decoration as BoxDecoration;
      expect(boxDec0.color, isNull);

      final container1 = tester.widget<Container>(
        find.descendant(of: find.byWidget(row1), matching: find.byType(Container)).first,
      );
      final boxDec1 = container1.decoration as BoxDecoration;
      expect(boxDec1.color, equals(altColor));
    });
  });
}
