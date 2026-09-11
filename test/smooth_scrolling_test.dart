import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Smooth Mouse Scrolling Engine Tests', () {
    testWidgets('Kinetic Ballistic Fling continues gliding and decelerating after mouse drag release', (tester) async {
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          100,
          (i) => {'id': i, 'name': 'Item $i'},
        ),
        columns: [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100, valueGetter: (r) => r['id']),
          GridColumn(id: 'name', label: 'Name', initialWidth: 300, valueGetter: (r) => r['name']),
        ],
      );

      final vController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              verticalScrollController: vController,
              enableMouseDragScroll: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(vController.offset, equals(0.0));

      // Perform a fast fling gesture dragging UP (scroll down)
      final gridFinder = find.byType(AppGrid<Map<String, dynamic>>);
      final center = tester.getCenter(gridFinder);

      // Mouse down
      final gesture = await tester.startGesture(center, kind: PointerDeviceKind.mouse);
      await tester.pump();

      // Move with high velocity
      await gesture.moveBy(const Offset(0, -50), timeStamp: const Duration(milliseconds: 16));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -50), timeStamp: const Duration(milliseconds: 32));
      await tester.pump();

      final offsetAtRelease = vController.offset;
      expect(offsetAtRelease, greaterThanOrEqualTo(50.0));

      // Release the mouse to engage kinetic ballistic fling
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // After release, offset must continue increasing due to momentum
      expect(vController.offset, greaterThan(offsetAtRelease));

      // Further in time, it continues decelerating smoothly
      final offsetMidFling = vController.offset;
      await tester.pump(const Duration(milliseconds: 100));
      expect(vController.offset, greaterThan(offsetMidFling));

      // Pump until momentum settles completely
      await tester.pumpAndSettle();

      controller.dispose();
      vController.dispose();
    });

    testWidgets('Pointer down immediately cancels running ballistic fling', (tester) async {
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          100,
          (i) => {'id': i, 'name': 'Item $i'},
        ),
        columns: [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100, valueGetter: (r) => r['id']),
          GridColumn(id: 'name', label: 'Name', initialWidth: 300, valueGetter: (r) => r['name']),
        ],
      );

      final vController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              verticalScrollController: vController,
              enableMouseDragScroll: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridFinder = find.byType(AppGrid<Map<String, dynamic>>);
      final center = tester.getCenter(gridFinder);

      // Start drag with fling
      final gesture = await tester.startGesture(center, kind: PointerDeviceKind.mouse);
      await gesture.moveBy(const Offset(0, -60), timeStamp: const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(0, -60), timeStamp: const Duration(milliseconds: 32));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final offsetDuringFling = vController.offset;
      expect(offsetDuringFling, greaterThan(60.0));

      // Tap on the grid to immediately halt momentum
      final tapGesture = await tester.startGesture(center, kind: PointerDeviceKind.mouse);
      await tester.pump();
      final offsetAtTap = vController.offset;

      // Pump time forward; offset must NOT move further because fling was halted
      await tester.pump(const Duration(milliseconds: 100));
      expect(vController.offset, equals(offsetAtTap));

      await tapGesture.up();
      await tester.pumpAndSettle();

      controller.dispose();
      vController.dispose();
    });

    testWidgets('PointerScrollEvent applies instant 1:1 wheel scroll response matching PlutoGrid', (tester) async {
      tester.view.physicalSize = const Size(500, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          100,
          (i) => {'id': i, 'name': 'Item $i'},
        ),
        columns: [
          GridColumn(id: 'id', label: 'ID', initialWidth: 300, valueGetter: (r) => r['id']),
          GridColumn(id: 'name', label: 'Name', initialWidth: 400, valueGetter: (r) => r['name']),
        ],
      );

      final vController = ScrollController();
      final hController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              verticalScrollController: vController,
              horizontalScrollController: hController,
              autoStretch: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(vController.offset, equals(0.0));
      expect(hController.offset, equals(0.0));

      final center = tester.getCenter(find.byType(AppGrid<Map<String, dynamic>>));

      // 1. Dispatch mouse wheel scroll event: instant 1:1 tactile response (0ms delay)
      final pointerSignal = PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, 100), // scroll down 100px
      );
      tester.binding.handlePointerEvent(pointerSignal);
      await tester.pump();

      // Zero-latency response: offset updates immediately without waiting for easing timers
      expect(vController.offset, closeTo(100.0, 0.1));

      // 2. Rapid successive ticks accumulate immediately without speed capping
      final secondSignal = PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(0, 50),
      );
      tester.binding.handlePointerEvent(secondSignal);
      await tester.pump();
      expect(vController.offset, closeTo(150.0, 0.1));

      // 3. Horizontal wheel scroll (e.g. trackpad dx or tilt wheel)
      final hSignal = PointerScrollEvent(
        position: center,
        scrollDelta: const Offset(40, 0),
      );
      tester.binding.handlePointerEvent(hSignal);
      await tester.pump();
      expect(hController.offset, closeTo(40.0, 0.1));

      await tester.pumpAndSettle();

      controller.dispose();
      vController.dispose();
      hController.dispose();
    });

    testWidgets('Accepts and applies custom ScrollPhysics', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(10, (i) => {'id': i}),
        columns: const [GridColumn(id: 'id', label: 'ID', initialWidth: 100)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              physics: const BouncingScrollPhysics(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify widget builds without error with custom physics
      expect(find.byType(AppGrid<Map<String, dynamic>>), findsOneWidget);

      controller.dispose();
    });
  });
}
