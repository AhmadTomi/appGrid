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
  });
}
