import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('AppGrid Scrollbar Visibility Tests', () {
    testWidgets('Default visibility is onHover: scrollbars are mounted with AnimatedOpacity', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          20,
          (i) => {'col1': 'V1-$i', 'col2': 'V2-$i', 'col3': 'V3-$i', 'col4': 'V4-$i'},
        ),
        columns: const [
          GridColumn(id: 'col1', label: 'C1', initialWidth: 200),
          GridColumn(id: 'col2', label: 'C2', initialWidth: 200),
          GridColumn(id: 'col3', label: 'C3', initialWidth: 200),
          GridColumn(id: 'col4', label: 'C4', initialWidth: 200),
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

      // Scrollbars should be present in the tree
      final hScrollbarFinder = find.byType(AppGridHorizontalScrollbar);
      final vScrollbarFinder = find.byType(AppGridVerticalScrollbar);
      expect(hScrollbarFinder, findsOneWidget);
      expect(vScrollbarFinder, findsOneWidget);

      // Initially without hover, opacity is 0.0
      AnimatedOpacity hOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(of: hScrollbarFinder, matching: find.byType(AnimatedOpacity)),
      );
      expect(hOpacity.opacity, equals(0.0));

      // Simulate mouse enter into table
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(200, 150));
      await tester.pumpAndSettle();

      // On hover, opacity animates to 1.0
      hOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(of: hScrollbarFinder, matching: find.byType(AnimatedOpacity)),
      );
      expect(hOpacity.opacity, equals(1.0));

      AnimatedOpacity vOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(of: vScrollbarFinder, matching: find.byType(AnimatedOpacity)),
      );
      expect(vOpacity.opacity, equals(1.0));

      // Simulate mouse exit outside table
      await gesture.moveTo(const Offset(600, 600));
      await tester.pumpAndSettle();

      // After mouse exit, opacity animates back to 0.0
      hOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(of: hScrollbarFinder, matching: find.byType(AnimatedOpacity)),
      );
      expect(hOpacity.opacity, equals(0.0));

      controller.dispose();
    });

    testWidgets('ScrollbarVisibility.always keeps scrollbars visible without hover', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          20,
          (i) => {'col1': 'V1-$i', 'col2': 'V2-$i', 'col3': 'V3-$i', 'col4': 'V4-$i'},
        ),
        columns: const [
          GridColumn(id: 'col1', label: 'C1', initialWidth: 200),
          GridColumn(id: 'col2', label: 'C2', initialWidth: 200),
          GridColumn(id: 'col3', label: 'C3', initialWidth: 200),
          GridColumn(id: 'col4', label: 'C4', initialWidth: 200),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              autoStretch: false,
              scrollbarVisibility: ScrollbarVisibility.always,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hScrollbarFinder = find.byType(AppGridHorizontalScrollbar);
      final vScrollbarFinder = find.byType(AppGridVerticalScrollbar);
      expect(hScrollbarFinder, findsOneWidget);
      expect(vScrollbarFinder, findsOneWidget);

      final hOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(of: hScrollbarFinder, matching: find.byType(AnimatedOpacity)),
      );
      expect(hOpacity.opacity, equals(1.0));

      final vOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(of: vScrollbarFinder, matching: find.byType(AnimatedOpacity)),
      );
      expect(vOpacity.opacity, equals(1.0));

      controller.dispose();
    });

    testWidgets('ScrollbarVisibility.hidden completely omits scrollbars from the widget tree', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          20,
          (i) => {'col1': 'V1-$i', 'col2': 'V2-$i', 'col3': 'V3-$i', 'col4': 'V4-$i'},
        ),
        columns: const [
          GridColumn(id: 'col1', label: 'C1', initialWidth: 200),
          GridColumn(id: 'col2', label: 'C2', initialWidth: 200),
          GridColumn(id: 'col3', label: 'C3', initialWidth: 200),
          GridColumn(id: 'col4', label: 'C4', initialWidth: 200),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              autoStretch: false,
              scrollbarVisibility: ScrollbarVisibility.hidden,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppGridHorizontalScrollbar), findsNothing);
      expect(find.byType(AppGridVerticalScrollbar), findsNothing);

      controller.dispose();
    });

    testWidgets('Independent vertical and horizontal visibility works correctly', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          20,
          (i) => {'col1': 'V1-$i', 'col2': 'V2-$i', 'col3': 'V3-$i', 'col4': 'V4-$i'},
        ),
        columns: const [
          GridColumn(id: 'col1', label: 'C1', initialWidth: 200),
          GridColumn(id: 'col2', label: 'C2', initialWidth: 200),
          GridColumn(id: 'col3', label: 'C3', initialWidth: 200),
          GridColumn(id: 'col4', label: 'C4', initialWidth: 200),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              autoStretch: false,
              verticalScrollbarVisibility: ScrollbarVisibility.always,
              horizontalScrollbarVisibility: ScrollbarVisibility.hidden,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Horizontal is hidden (not mounted)
      expect(find.byType(AppGridHorizontalScrollbar), findsNothing);

      // Vertical is always visible (mounted with opacity 1.0)
      final vScrollbarFinder = find.byType(AppGridVerticalScrollbar);
      expect(vScrollbarFinder, findsOneWidget);
      final vOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(of: vScrollbarFinder, matching: find.byType(AnimatedOpacity)),
      );
      expect(vOpacity.opacity, equals(1.0));

      controller.dispose();
    });

    testWidgets('Backward compatibility: showHorizontalScrollbar: false hides horizontal scrollbar', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          20,
          (i) => {'col1': 'V1-$i', 'col2': 'V2-$i', 'col3': 'V3-$i', 'col4': 'V4-$i'},
        ),
        columns: const [
          GridColumn(id: 'col1', label: 'C1', initialWidth: 200),
          GridColumn(id: 'col2', label: 'C2', initialWidth: 200),
          GridColumn(id: 'col3', label: 'C3', initialWidth: 200),
          GridColumn(id: 'col4', label: 'C4', initialWidth: 200),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              autoStretch: false,
              showHorizontalScrollbar: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppGridHorizontalScrollbar), findsNothing);
      expect(find.byType(AppGridVerticalScrollbar), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Horizontal scrollbar is positioned at the bottom of the footer when showFooter is true', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          20,
          (i) => {'col1': 'V1-$i', 'col2': 'V2-$i', 'col3': 'V3-$i'},
        ),
        columns: const [
          GridColumn(id: 'col1', label: 'C1', initialWidth: 300),
          GridColumn(id: 'col2', label: 'C2', initialWidth: 300),
          GridColumn(id: 'col3', label: 'C3', initialWidth: 300),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              autoStretch: false,
              footerHeight: 40.0,
              scrollbarThickness: 10.0,
              horizontalScrollbarVisibility: AppGridScrollbarVisibility.always,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Horizontal scrollbar is present in the grid
      final hScrollbarFinder = find.byType(AppGridHorizontalScrollbar);
      expect(hScrollbarFinder, findsOneWidget);

      // 2. Horizontal scrollbar is NOT inside AppGridViewport (it was moved out to footer)
      final viewportHScrollbarFinder = find.descendant(
        of: find.byType(AppGridViewport<Map<String, dynamic>>),
        matching: find.byType(AppGridHorizontalScrollbar),
      );
      expect(viewportHScrollbarFinder, findsNothing);

      // 3. Footer cells are present
      final footerCellFinder = find.byType(AppGridFooterCell);
      expect(footerCellFinder, findsWidgets);

      // 4. Horizontal scrollbar bottom edge aligns with footer bottom edge
      final footerCellRect = tester.getRect(footerCellFinder.first);
      final hScrollbarRect = tester.getRect(hScrollbarFinder);
      expect(hScrollbarRect.bottom, closeTo(footerCellRect.bottom, 1.0),
          reason: 'Horizontal scrollbar must be positioned at the bottom of the footer');
      expect(hScrollbarRect.top, greaterThanOrEqualTo(footerCellRect.top),
          reason: 'Horizontal scrollbar must sit inside/at the bottom of the footer area');

      controller.dispose();
    });
  });
}
