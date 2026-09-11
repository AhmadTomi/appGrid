import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Pagination & setPageData Tests', () {
    testWidgets('setPageData() updates table cells when navigating between pages', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        fetchMode: DataFetchMode.pagination,
        paginationInfo: const GridPaginationInfo(page: 1, limit: 3, totalCount: 6),
        initialData: [
          {'id': 'ORD-1', 'name': 'Alpha'},
          {'id': 'ORD-2', 'name': 'Beta'},
          {'id': 'ORD-3', 'name': 'Gamma'},
        ],
        columns: [
          GridColumn(
            id: 'id',
            label: 'ID',
            valueGetter: (r) => r['id'],
            cellBuilder: (context, row, info) => Text('${row['id']}'),
          ),
          GridColumn(
            id: 'name',
            label: 'Name',
            valueGetter: (r) => r['name'],
            cellBuilder: (context, row, info) => Text('${row['name']}'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Page 1 assertions
      expect(find.text('ORD-1'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('ORD-2'), findsOneWidget);
      expect(find.text('ORD-4'), findsNothing);

      // Navigate to Page 2
      controller.setPageData(
        rows: [
          {'id': 'ORD-4', 'name': 'Delta'},
          {'id': 'ORD-5', 'name': 'Epsilon'},
          {'id': 'ORD-6', 'name': 'Zeta'},
        ],
        pagination: const GridPaginationInfo(page: 2, limit: 3, totalCount: 6),
      );
      await tester.pumpAndSettle();

      // Page 2 assertions: Page 1 items must be gone, Page 2 items must appear!
      expect(find.text('ORD-1'), findsNothing);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('ORD-4'), findsOneWidget);
      expect(find.text('Delta'), findsOneWidget);
      expect(find.text('ORD-5'), findsOneWidget);
      expect(find.text('ORD-6'), findsOneWidget);

      controller.dispose();
    });
  });
}
