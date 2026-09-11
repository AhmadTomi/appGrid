import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Header & Viewport Clipping Tests', () {
    testWidgets('Resizing column beyond viewport bounds keeps header and cell clipped', (tester) async {
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(5, (i) => {'col1': 'Val-$i', 'col2': 'Val2-$i'}),
        columns: const [
          GridColumn(id: 'col1', label: 'Column 1', initialWidth: 200),
          GridColumn(id: 'col2', label: 'Column 2', initialWidth: 200),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                // Simulated sidebar
                Container(
                  key: const ValueKey('sidebar'),
                  width: 150,
                  color: Colors.black,
                ),
                // AppGrid container
                Expanded(
                  child: AppGrid<Map<String, dynamic>>(
                    controller: controller,
                    autoStretch: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find resize handle on Column 1 and drag it by +600px to exceed viewport
      final resizeHandleFinder = find.byType(MouseRegion);
      expect(resizeHandleFinder, findsWidgets);

      // Drag the first column header resize handle to expand to 800px
      final col1Header = find.text('Column 1');
      expect(col1Header, findsOneWidget);

      final headerCellFinder = find.byType(AppGridHeaderCell<Map<String, dynamic>>).first;
      final handleRect = tester.getRect(headerCellFinder);

      // Drag right edge by 400 pixels to the right
      final gesture = await tester.startGesture(Offset(handleRect.right - 2, handleRect.center.dy));
      await gesture.moveBy(const Offset(400, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      // Scroll horizontally to the right so Column 1 is offset to the left
      final hFinder = find.byType(Scrollable).at(1);
      final scrollable = tester.widget<Scrollable>(hFinder);
      scrollable.controller!.jumpTo(300.0);
      await tester.pumpAndSettle();

      // Find the header position now
      final col1HeaderAfterScroll = find.text('Column 1');
      print('col1HeaderAfterScroll: ${col1HeaderAfterScroll.evaluate().length}');
      if (col1HeaderAfterScroll.evaluate().isNotEmpty) {
        final rect = tester.getRect(col1HeaderAfterScroll);
        print('col1 text rect: $rect');
      }

      final headerCell = find.byType(AppGridHeaderCell<Map<String, dynamic>>).first;
      final cellRect = tester.getRect(headerCell);
      print('headerCell rect: $cellRect');

      // Hover over the header cell inside the visible grid area
      final hoverGesture2 = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await hoverGesture2.addPointer(location: Offset(200, cellRect.center.dy));
      await tester.pump();

      // Verify that no InkWell exists in AppGridHeaderCell (no outside RenderInkFeatures)
      final inkWellFinder = find.descendant(
        of: find.byType(AppGridHeaderCell<Map<String, dynamic>>),
        matching: find.byType(InkWell),
      );
      expect(inkWellFinder, findsNothing);

      // Verify that AppGridHeaderCell is wrapped in ClipRect
      final headerClips = find.descendant(
        of: find.byType(AppGridHeaderCell<Map<String, dynamic>>),
        matching: find.byType(ClipRect),
      );
      expect(headerClips, findsWidgets);

      // Tap on the visible portion of Column 1 header to toggle sort
      await tester.tapAt(Offset(200, cellRect.center.dy));
      await tester.pumpAndSettle();
      expect(controller.sortCriteria?.columnId, equals('col1'));
    });

    testWidgets('Header drag feedback widget uses column minWidth instead of current width', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: const [{'col1': 'Val-1'}],
        columns: const [
          GridColumn(id: 'col1', label: 'Column 1', minWidth: 100, initialWidth: 400),
          GridColumn(id: 'col2', label: 'Column 2', minWidth: 120, initialWidth: 200),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              autoStretch: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final draggableFinder = find.byType(Draggable<String>).first;
      final draggable = tester.widget<Draggable<String>>(draggableFinder);

      final feedbackMaterial = draggable.feedback as Material;
      final container = feedbackMaterial.child as Container;
      // The container width should be exactly col1's minWidth (100.0) rather than initialWidth (400.0)
      expect(container.constraints?.hasTightWidth, isTrue);
      expect(container.constraints?.minWidth, equals(100.0));
      expect(container.constraints?.maxWidth, equals(100.0));

      // Verify anchor strategy positions the cursor at the center of the feedback (minWidth/2, height/2)
      final context = tester.element(draggableFinder);
      final anchorOffset = draggable.dragAnchorStrategy(draggable, context, Offset.zero);
      expect(anchorOffset, equals(const Offset(50.0, 24.0))); // minWidth 100 / 2 = 50, height 48 / 2 = 24
    });
  });
}
