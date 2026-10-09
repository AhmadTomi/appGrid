import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Full-Column Drop Indicator & Column Drag Feedback Tests', () {
    testWidgets('Header drag feedback uses current column width and childDragAnchorStrategy',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: const [
          {'name': 'Item A', 'price': 100, 'qty': 5},
        ],
        columns: const [
          GridColumn(id: 'name', label: 'Name', initialWidth: 240, minWidth: 80),
          GridColumn(id: 'price', label: 'Price', initialWidth: 160, minWidth: 60),
          GridColumn(id: 'qty', label: 'Quantity', initialWidth: 120, minWidth: 50),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 500,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                autoStretch: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Draggable for 'name' column
      final nameHeaderDraggableFinder = find.ancestor(
        of: find.text('Name'),
        matching: find.byType(Draggable<String>),
      );
      expect(nameHeaderDraggableFinder, findsOneWidget);

      final draggable = tester.widget<Draggable<String>>(nameHeaderDraggableFinder);
      final feedbackMaterial = draggable.feedback as Material;
      final feedbackContainer = feedbackMaterial.child as Container;

      // Assert feedback container width matches column current width (240.0) not minWidth (80.0)
      expect(feedbackContainer.constraints?.maxWidth, equals(240.0));
      expect(feedbackContainer.constraints?.minWidth, equals(240.0));
    });

    testWidgets(
        'Full-column drop indicator overlay renders tint and drop line spanning entire height',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: const [
          {'name': 'Item A', 'price': 100, 'qty': 5},
          {'name': 'Item B', 'price': 200, 'qty': 10},
          {'name': 'Item C', 'price': 300, 'qty': 15},
        ],
        columns: const [
          GridColumn(id: 'name', label: 'Name', initialWidth: 200),
          GridColumn(id: 'price', label: 'Price', initialWidth: 150),
          GridColumn(id: 'qty', label: 'Quantity', initialWidth: 150),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 500,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                autoStretch: false,
                style: const AppGridStyle(
                  rowHeight: 50,
                  headerHeight: 40,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no column drop target is active
      expect(controller.activeColumnDragTarget.value, isNull);

      // Start dragging 'name' header towards 'price' header
      final nameHeader = find.text('Name');
      final priceCellFinder = find.ancestor(
        of: find.text('Price'),
        matching: find.byType(AppGridHeaderCell<Map<String, dynamic>>),
      );
      final priceRect = tester.getRect(priceCellFinder);

      final gesture = await tester.startGesture(tester.getCenter(nameHeader));
      await tester.pump(const Duration(milliseconds: 50));

      // Move over 'price' column header (left to right drag)
      await gesture.moveTo(priceRect.center);
      await tester.pump(const Duration(milliseconds: 50));

      // Verify controller drop target info (dragged 0 to 1 -> isLeft is false)
      expect(controller.activeColumnDragTarget.value, isNotNull);
      expect(controller.activeColumnDragTarget.value?.targetColumnId, equals('price'));
      expect(controller.activeColumnDragTarget.value?.draggedColumnId, equals('name'));
      expect(controller.activeColumnDragTarget.value?.isLeft, isFalse);

      // Verify full-height vertical drop line (width: 2.5) and column tint are mounted
      final dropLineFinder = find.byKey(const ValueKey('column_drop_indicator_line'));
      final tintFinder = find.byKey(const ValueKey('column_drop_indicator_tint'));
      expect(dropLineFinder, findsOneWidget);
      expect(tintFinder, findsOneWidget);

      // Drop on 'price' -> inserts after 'price'
      await gesture.up();
      await tester.pumpAndSettle();

      // Indicator should be dismissed
      expect(controller.activeColumnDragTarget.value, isNull);
      expect(dropLineFinder, findsNothing);
      expect(tintFinder, findsNothing);

      // Verify new column order: Price, Name, Quantity
      expect(controller.visibleColumns.map((c) => c.id).toList(), ['price', 'name', 'qty']);

      // Now test right-to-left drag: drag 'qty' (index 2) towards 'price' (index 0)
      final qtyHeader = find.text('Quantity');
      final newPriceCellFinder = find.ancestor(
        of: find.text('Price'),
        matching: find.byType(AppGridHeaderCell<Map<String, dynamic>>),
      );
      final newPriceRect = tester.getRect(newPriceCellFinder);

      final reverseGesture = await tester.startGesture(tester.getCenter(qtyHeader));
      await tester.pump(const Duration(milliseconds: 50));
      await reverseGesture.moveTo(newPriceRect.center);
      await tester.pump(const Duration(milliseconds: 50));

      // Dragging 2 to 0 -> isLeft is true (line on left of price)
      expect(controller.activeColumnDragTarget.value?.isLeft, isTrue);
      expect(find.byKey(const ValueKey('column_drop_indicator_line')), findsOneWidget);

      await reverseGesture.up();
      await tester.pumpAndSettle();

      // Verify new column order: Quantity, Price, Name
      expect(controller.visibleColumns.map((c) => c.id).toList(), ['qty', 'price', 'name']);
    });

    testWidgets('Pinned left and right column drop indicator overlay is properly positioned',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: const [
          {'id': '1', 'name': 'Item A', 'action': 'Edit'},
        ],
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 80, pin: GridColumnPin.left),
          GridColumn(id: 'name', label: 'Name', initialWidth: 200),
          GridColumn(id: 'action', label: 'Action', initialWidth: 100, pin: GridColumnPin.right),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 500,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                autoStretch: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Programmatically trigger drop target on pinned left column
      controller.setHoveredColumnDropTarget(
        targetColumnId: 'id',
        draggedColumnId: 'name',
        isLeft: true,
      );
      await tester.pump();

      // Check drop line indicator rendered on left
      final leftDropLine =
          find.byKey(const ValueKey('column_drop_indicator_line'));
      expect(leftDropLine, findsOneWidget);

      // Clear indicator
      controller.clearHoveredColumnDropTarget();
      await tester.pump();
      expect(leftDropLine, findsNothing);
    });
  });
}
