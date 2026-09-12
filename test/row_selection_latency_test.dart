import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Zero-Latency Row Selection & Conflict-Free Double Tap Tests', () {
    testWidgets('Row selection triggers immediately on pointer down without waiting for pointer up (0ms delay)', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      RowIndexInfo? selectedInfo;

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          10,
          (i) => {'id': i, 'name': 'Item $i'},
        ),
        columns: [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100, valueGetter: (r) => r['id']),
          GridColumn(id: 'name', label: 'Name', initialWidth: 200, valueGetter: (r) => r['name']),
        ],
        onRowSelected: (info) {
          selectedInfo = info;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              enableMouseDragScroll: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.selectedDisplayIndex, isNull);
      expect(selectedInfo, isNull);

      // Start gesture (pointer down) on 'Item 3' WITHOUT releasing pointer up
      final item3Finder = find.text('Item 3');
      final location = tester.getCenter(item3Finder);
      final gesture = await tester.startGesture(location, pointer: 1, kind: PointerDeviceKind.mouse);
      await tester.pump();

      // Row must be selected IMMEDIATELY on pointer down (0ms latency, no wait for pointer up)
      expect(controller.selectedDisplayIndex, equals(3));
      expect(selectedInfo, isNotNull);
      expect(selectedInfo!.displayIndex, equals(3));
      expect(selectedInfo!.originalIndex, equals(3));

      // Now release pointer up (should remain selected cleanly without duplicate notifications)
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.selectedDisplayIndex, equals(3));
      expect(selectedInfo!.displayIndex, equals(3));

      controller.dispose();
    });

    testWidgets('onRowDoubleTap triggers on second click while single click still selects immediately', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      RowIndexInfo? doubleTappedInfo;
      RowIndexInfo? singleTappedInfo;

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          10,
          (i) => {'id': i, 'name': 'Item $i'},
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
              onRowTap: (info) => singleTappedInfo = info,
              onRowDoubleTap: (info) => doubleTappedInfo = info,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final item2Finder = find.text('Item 2');
      final location = tester.getCenter(item2Finder);

      // 1st click:
      final gesture1 = await tester.startGesture(location, pointer: 1, kind: PointerDeviceKind.mouse);
      await tester.pump();

      // Row selected immediately on 1st down!
      expect(controller.selectedDisplayIndex, equals(2));
      expect(singleTappedInfo?.displayIndex, equals(2));
      expect(doubleTappedInfo, isNull);

      await gesture1.up();
      await tester.pump(const Duration(milliseconds: 50));

      // 2nd click within 300ms:
      final gesture2 = await tester.startGesture(location, pointer: 2, kind: PointerDeviceKind.mouse);
      await tester.pump();

      // onRowDoubleTap triggers on the 2nd click!
      expect(doubleTappedInfo, isNotNull);
      expect(doubleTappedInfo!.displayIndex, equals(2));

      await gesture2.up();
      await tester.pumpAndSettle();

      controller.dispose();
    });
  });
}