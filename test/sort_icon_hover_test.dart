import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Sort Icon Real-Time Hover State Tests', () {
    testWidgets('Header sort icon updates immediately while mouse cursor is still hovering over it', (tester) async {
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

      final headerFinder = find.text('Name');
      expect(headerFinder, findsOneWidget);

      // Create a mouse pointer
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Move mouse over the 'Name' header
      await gesture.moveTo(tester.getCenter(headerFinder));
      await tester.pump();

      // Verify no sort icon initially
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);

      // 1. Click while hovering (mouse stays at same position, NO mouse exit!)
      await gesture.down(tester.getCenter(headerFinder));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // The sort icon MUST update to arrow_upward immediately while STILL HOVERING!
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget,
          reason: 'Sort icon must update to ascending immediately without moving mouse out');
      expect(controller.sortCriteria?.direction, equals(SortDirection.ascending));

      // 2. Click again while STILL hovering (mouse does not move)
      await gesture.down(tester.getCenter(headerFinder));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // The sort icon MUST update to arrow_downward immediately while STILL HOVERING!
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget,
          reason: 'Sort icon must update to descending immediately without moving mouse out');
      expect(controller.sortCriteria?.direction, equals(SortDirection.descending));

      controller.dispose();
    });
  });
}
