import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Header Menu & Stack Positioning Tests', () {
    testWidgets('Header menu button opens popup adjacent to button even when AppGrid is inside a Stack', (tester) async {
      final items = [
        {'id': 1, 'name': 'Item A', 'score': 100},
        {'id': 2, 'name': 'Item B', 'score': 85},
      ];

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: items,
        columns: [
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => r['name']),
          GridColumn(id: 'score', label: 'Score', valueGetter: (r) => r['score']),
        ],
      );

      // Embed AppGrid inside a Stack at a specific Positioned offset (120px from top, 80px from left)
      const stackTop = 120.0;
      const stackLeft = 80.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: stackTop,
                  left: stackLeft,
                  child: SizedBox(
                    width: 700,
                    height: 500,
                    child: AppGrid<Map<String, dynamic>>(
                      controller: controller,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the sort menu button on the 'Name' column
      final sortButtons = find.byIcon(Icons.unfold_more);
      expect(sortButtons, findsWidgets);
      final nameSortButton = sortButtons.first;

      // Get button's global rect before opening menu
      final buttonRect = tester.getRect(nameSortButton);
      expect(buttonRect.top, greaterThanOrEqualTo(stackTop));
      expect(buttonRect.left, greaterThanOrEqualTo(stackLeft));

      // Tap sort button to open the column menu
      await tester.tap(nameSortButton);
      await tester.pumpAndSettle();

      // Verify that the menu opened
      expect(find.text('Sort Ascending'), findsOneWidget);
      expect(find.text('Sort Descending'), findsOneWidget);
      expect(find.text('Pin to Left'), findsOneWidget);
      expect(find.text('Pin to Right'), findsOneWidget);
      expect(find.text('Unpin (Scrollable)'), findsOneWidget);

      // Find the menu card/material RenderBox
      final menuItem = find.text('Sort Ascending');
      final menuTopLeft = tester.getTopLeft(menuItem);

      // The menu's vertical position MUST be directly adjacent to the button (button's bottom),
      // NOT offset or misaligned back towards (0, 0)!
      expect(menuTopLeft.dy, greaterThanOrEqualTo(buttonRect.bottom - 2.0),
          reason: 'Menu should open right underneath the header button');
      expect(menuTopLeft.dx, greaterThanOrEqualTo(stackLeft),
          reason: 'Menu horizontal position must respect the Stack left offset');

      // Tap 'Sort Descending'
      await tester.tap(find.text('Sort Descending'));
      await tester.pumpAndSettle();

      // Verify controller updated to descending
      expect(controller.sortCriteria?.columnId, equals('name'));
      expect(controller.sortCriteria?.direction, equals(SortDirection.descending));

      // Re-open menu to test Clear Sort
      final descSortButton = find.byIcon(Icons.arrow_downward).first;
      await tester.tap(descSortButton);
      await tester.pumpAndSettle();

      expect(find.text('Clear Sort'), findsOneWidget);
      await tester.tap(find.text('Clear Sort'));
      await tester.pumpAndSettle();

      // Verify sort cleared
      expect(controller.sortCriteria, isNull);

      controller.dispose();
    });

    testWidgets('Header cell label tap toggles sort directly, while secondary tap does NOT open menu', (tester) async {
      final items = [
        {'id': 1, 'name': 'Item A'},
        {'id': 2, 'name': 'Item B'},
      ];

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: items,
        columns: [
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => r['name']),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final labelFinder = find.text('Name');

      // 1. Right click (secondary button) must NOT open the popup menu
      await tester.tap(labelFinder, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      expect(find.text('Pin to Left'), findsNothing,
          reason: 'Right-click should not trigger menu to avoid conflict with browser context menu');

      // 2. Primary tap on label directly toggles sort
      await tester.tap(labelFinder);
      await tester.pumpAndSettle();

      expect(controller.sortCriteria?.direction, equals(SortDirection.ascending));

      // 3. Primary tap again toggles to descending
      await tester.tap(labelFinder);
      await tester.pumpAndSettle();

      expect(controller.sortCriteria?.direction, equals(SortDirection.descending));

      controller.dispose();
    });

    testWidgets('Pinning from header menu updates column pin state and layout correctly', (tester) async {
      final items = [
        {'id': 1, 'name': 'Item A', 'city': 'Jakarta'},
      ];

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: items,
        columns: [
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => r['name']),
          GridColumn(id: 'city', label: 'City', valueGetter: (r) => r['city']),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap sort/column menu on 'City'
      final citySortBtn = find.byIcon(Icons.unfold_more).last;
      await tester.tap(citySortBtn);
      await tester.pumpAndSettle();

      // Pin City to Right
      await tester.tap(find.text('Pin to Right'));
      await tester.pumpAndSettle();

      expect(controller.columns.firstWhere((c) => c.id == 'city').pin, equals(GridColumnPin.right));

      controller.dispose();
    });
  });
}
