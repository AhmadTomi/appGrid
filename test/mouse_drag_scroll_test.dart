import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Interactive Scroll & Mouse Drag Scrolling Tests', () {
    testWidgets('Horizontal scrollbar renders when content width exceeds viewport', (tester) async {
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          20,
          (i) => {'id': i, 'col1': 'Val 1-$i', 'col2': 'Val 2-$i', 'col3': 'Val 3-$i', 'col4': 'Val 4-$i', 'col5': 'Val 5-$i'},
        ),
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 80, pin: GridColumnPin.left),
          GridColumn(id: 'col1', label: 'Column 1', initialWidth: 150),
          GridColumn(id: 'col2', label: 'Column 2', initialWidth: 150),
          GridColumn(id: 'col3', label: 'Column 3', initialWidth: 150),
          GridColumn(id: 'col4', label: 'Column 4', initialWidth: 150),
          GridColumn(id: 'col5', label: 'Column 5', initialWidth: 150),
        ],
      );

      final hController = ScrollController();
      final vController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              horizontalScrollController: hController,
              verticalScrollController: vController,
              autoStretch: false,
              showHorizontalScrollbar: true,
              showVerticalScrollbar: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Horizontal and vertical scrollbars must be present
      expect(find.byType(AppGridHorizontalScrollbar), findsOneWidget);
      expect(find.byType(AppGridVerticalScrollbar), findsOneWidget);

      // Default framework Scrollbar and RawScrollbar must NOT be rendered (suppressed to prevent duplicate/ghost scrollbars)
      expect(find.byType(Scrollbar), findsNothing);
      expect(find.byType(RawScrollbar), findsNothing);

      controller.dispose();
      hController.dispose();
      vController.dispose();
    });

    testWidgets('Mouse click-drag smoothly scrolls horizontally and vertically', (tester) async {
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          50,
          (i) => {'id': i, 'name': 'Item $i', 'details': 'Long details data for item $i in list'},
        ),
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 80, pin: GridColumnPin.left),
          GridColumn(id: 'name', label: 'Name', initialWidth: 250),
          GridColumn(id: 'details', label: 'Details', initialWidth: 400),
        ],
      );

      final hController = ScrollController();
      final vController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              horizontalScrollController: hController,
              verticalScrollController: vController,
              autoStretch: false,
              enableMouseDragScroll: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(hController.offset, equals(0.0));
      expect(vController.offset, equals(0.0));

      // Click and drag with mouse diagonally: (-120 horizontally, -80 vertically)
      await tester.drag(
        find.byType(AppGrid<Map<String, dynamic>>),
        const Offset(-120, -80),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      // Offsets must have increased (scrolled right and down)
      expect(hController.offset, greaterThan(50.0));
      expect(vController.offset, greaterThan(50.0));

      controller.dispose();
      hController.dispose();
      vController.dispose();
    });

    testWidgets('Simple mouse click selects row without triggering drag scroll', (tester) async {
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      RowIndexInfo? selectedInfo;

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          10,
          (i) => {'id': i, 'name': 'Row $i'},
        ),
        columns: [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100, valueGetter: (r) => r['id']),
          GridColumn(id: 'name', label: 'Name', initialWidth: 200, valueGetter: (r) => r['name']),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              enableMouseDragScroll: true,
              onRowSelected: (info) {
                selectedInfo = info;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Row 2 with mouse
      await tester.tap(find.text('Row 2'));
      await tester.pumpAndSettle();

      expect(selectedInfo, isNotNull);
      expect(selectedInfo!.displayIndex, equals(2));
      expect(controller.selectedDisplayIndex, equals(2));

      controller.dispose();
    });

    testWidgets('Dragging horizontal scrollbar thumb updates horizontal offset', (tester) async {
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          5,
          (i) => {'col1': 'V1-$i', 'col2': 'V2-$i', 'col3': 'V3-$i', 'col4': 'V4-$i'},
        ),
        columns: const [
          GridColumn(id: 'col1', label: 'C1', initialWidth: 200),
          GridColumn(id: 'col2', label: 'C2', initialWidth: 200),
          GridColumn(id: 'col3', label: 'C3', initialWidth: 200),
          GridColumn(id: 'col4', label: 'C4', initialWidth: 200),
        ],
      );

      final hController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              horizontalScrollController: hController,
              autoStretch: false,
              showHorizontalScrollbar: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(hController.offset, equals(0.0));

      // Locate the horizontal scrollbar
      final scrollbarFinder = find.byType(AppGridHorizontalScrollbar);
      expect(scrollbarFinder, findsOneWidget);

      // Drag the scrollbar thumb horizontally to the right
      final scrollbarCenter = tester.getCenter(scrollbarFinder);
      await tester.dragFrom(scrollbarCenter, const Offset(60, 0), kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      expect(hController.offset, greaterThan(0.0));

      controller.dispose();
      hController.dispose();
    });

    testWidgets('Mouse click correctly changes row selection after vertical scroll', (tester) async {
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      RowIndexInfo? selectedInfo;

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          100,
          (i) => {'id': i, 'name': 'Item $i'},
        ),
        columns: [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100, valueGetter: (r) => r['id'].toString()),
          GridColumn(id: 'name', label: 'Name', initialWidth: 300, valueGetter: (r) => r['name'].toString()),
        ],
        onRowSelected: (info) => selectedInfo = info,
      );

      final vController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              verticalScrollController: vController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.selectedDisplayIndex, isNull);

      // Scroll vertically by 300px (e.g. items ~6-15 now visible)
      vController.jumpTo(300.0);
      await tester.pumpAndSettle();

      expect(vController.offset, equals(300.0));

      // Find an item scrolled into view (e.g. 'Item 9')
      final itemFinder = find.text('Item 9');
      expect(itemFinder, findsOneWidget);

      // Tap on 'Item 9'
      await tester.tap(itemFinder);
      await tester.pumpAndSettle();

      // Selection must be updated!
      expect(selectedInfo, isNotNull);
      expect(selectedInfo!.displayIndex, equals(9));
      expect(controller.selectedDisplayIndex, equals(9));

      controller.dispose();
      vController.dispose();
    });
  });
}
