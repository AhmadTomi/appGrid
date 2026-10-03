import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('PlutoGrid Icon Style & Custom Icons Tests', () {
    testWidgets(
        'AppGridIconStyle.pluto displays PlutoGrid dehaze and sort icons',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Item A', 'score': 90},
          {'id': 2, 'name': 'Item B', 'score': 80},
        ],
        columns: [
          GridColumn(id: 'id', label: 'ID', valueGetter: (r) => r['id']),
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => r['name']),
          GridColumn(
              id: 'score', label: 'Score', valueGetter: (r) => r['score']),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                // Default is AppGridIconStyle.pluto
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial State: All columns display Pluto's Icons.dehaze ('≡')
      final dehazeIcons = find.byIcon(Icons.dehaze);
      expect(dehazeIcons, findsNWidgets(3));
      expect(find.byIcon(Icons.sort), findsNothing);

      // 2. Click 'Score' column header to sort Ascending
      final scoreHeader = find.text('Score');
      await tester.tap(scoreHeader);
      await tester.pumpAndSettle();

      expect(controller.sortCriteria?.columnId, equals('score'));
      expect(
          controller.sortCriteria?.direction, equals(SortDirection.ascending));

      // The sorted column now displays Icons.sort
      expect(find.byIcon(Icons.sort), findsOneWidget);
      // The other two columns still display Icons.dehaze
      expect(find.byIcon(Icons.dehaze), findsNWidgets(2));

      // Check that the sort icon is green
      final sortWidget = tester.widget<Icon>(find.byIcon(Icons.sort));
      expect(sortWidget.color, equals(Colors.green));

      // 3. Click 'Score' again to sort Descending
      await tester.tap(scoreHeader);
      await tester.pumpAndSettle();

      expect(
          controller.sortCriteria?.direction, equals(SortDirection.descending));

      // Check that the descending sort icon is red
      final descSortWidget = tester.widget<Icon>(find.byIcon(Icons.sort));
      expect(descSortWidget.color, equals(Colors.red));

      // 4. Open context menu on Score column to verify popup sort icons
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      expect(find.text('Sort Ascending'), findsOneWidget);
      expect(find.text('Sort Descending'), findsOneWidget);
      expect(find.text('Clear Sort'), findsOneWidget);

      controller.dispose();
    });

    testWidgets(
        'Custom grid-level icons (columnMenuIcon, columnAscendingIcon, columnDescendingIcon) display properly',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Item A'},
        ],
        columns: [
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => r['name']),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                style: const AppGridStyle(
                  columnMenuIcon: Icon(Icons.unfold_more),
                  columnAscendingIcon: Icon(Icons.arrow_upward),
                  columnDescendingIcon: Icon(Icons.arrow_downward),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Custom icon displays Icons.unfold_more
      expect(find.byIcon(Icons.unfold_more), findsOneWidget);
      expect(find.byIcon(Icons.dehaze), findsNothing);

      // Tap header to sort Ascending
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      // Tap header to sort Descending
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

      controller.dispose();
    });

    testWidgets(
        'Custom grid-level and column-level icon overrides take precedence',
        (tester) async {
      const customAscKey = Key('custom_asc');
      const customDescKey = Key('custom_desc');
      const customMenuKey = Key('custom_menu');

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Alpha'},
        ],
        columns: [
          GridColumn(
            id: 'name',
            label: 'Name',
            valueGetter: (r) => r['name'],
            menuIcon: const Icon(Icons.star, key: customMenuKey),
            sortAscendingIcon: const Icon(Icons.thumb_up, key: customAscKey),
            sortDescendingIcon:
                const Icon(Icons.thumb_down, key: customDescKey),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Custom menu icon takes precedence
      expect(find.byKey(customMenuKey), findsOneWidget);
      expect(find.byIcon(Icons.dehaze), findsNothing);

      // Sort Ascending
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      expect(find.byKey(customAscKey), findsOneWidget);

      // Sort Descending
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      expect(find.byKey(customDescKey), findsOneWidget);

      controller.dispose();
    });
  });
}
