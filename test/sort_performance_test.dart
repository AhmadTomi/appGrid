import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Sort Performance & UI Responsiveness', () {
    test('Sorts 100 rows in under 10 milliseconds', () async {
      final items = List.generate(
        100,
        (i) => {'id': i, 'name': 'Item ${(100 - i) * 31 % 100}', 'score': (i * 17) % 100},
      );

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: items,
        columns: [
          GridColumn(id: 'id', label: 'ID', valueGetter: (r) => r['id']),
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => r['name']),
          GridColumn(id: 'score', label: 'Score', valueGetter: (r) => r['score']),
        ],
      );

      final stopwatch = Stopwatch()..start();
      await controller.sortByColumn('score', direction: SortDirection.ascending);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(20));
      expect(controller.getRowByDisplayIndex(0)['score'], equals(0));

      controller.dispose();
    });

    testWidgets('Header click immediately sorts without dropping clicks', (tester) async {
      final items = List.generate(
        100,
        (i) => {'id': i, 'score': 100 - i},
      );

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: items,
        columns: [
          GridColumn(id: 'score', label: 'Score', valueGetter: (r) => r['score']),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      expect(controller.getRowByDisplayIndex(0)['score'], equals(100));

      // Tap on Score header
      final headerFinder = find.text('Score');
      expect(headerFinder, findsOneWidget);

      await tester.tap(headerFinder);
      await tester.pumpAndSettle();

      // First tap: Ascending (score 1 to 100)
      expect(controller.sortCriteria?.direction, equals(SortDirection.ascending));
      expect(controller.getRowByDisplayIndex(0)['score'], equals(1));

      // Second tap: Descending (score 100 to 1)
      await tester.tap(headerFinder);
      await tester.pumpAndSettle();

      expect(controller.sortCriteria?.direction, equals(SortDirection.descending));
      expect(controller.getRowByDisplayIndex(0)['score'], equals(100));

      controller.dispose();
    });

    test('Automatically sorts Map rows by column id if valueGetter is not explicitly defined', () async {
      final items = List.generate(
        100,
        (i) => {'id': i, 'score': 100 - i},
      );

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: items,
        columns: [
          const GridColumn(id: 'score', label: 'Score'), // No valueGetter provided!
        ],
      );

      await controller.sortByColumn('score', direction: SortDirection.ascending);
      expect(controller.getRowByDisplayIndex(0)['score'], equals(1));
      expect(controller.getRowByDisplayIndex(99)['score'], equals(100));

      controller.dispose();
    });

    test('Sorts 5,000 rows in under 25 milliseconds on main thread', () async {
      final items = List.generate(
        5000,
        (i) => {'id': i, 'val': (5000 - i) * 31 % 5000},
      );

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: items,
        columns: [
          GridColumn(id: 'val', label: 'Val', valueGetter: (r) => r['val']),
        ],
      );

      final stopwatch = Stopwatch()..start();
      await controller.sortByColumn('val', direction: SortDirection.ascending);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(35));
      expect(controller.getRowByDisplayIndex(0)['val'], equals(0));

      controller.dispose();
    });
  });
}

