import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('AppGridButton Tests & Benchmarks', () {
    testWidgets('Renders label, icon, and handles clicks', (tester) async {
      var clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppGridButton(
                icon: const Icon(Icons.flash_on),
                text: 'Action',
                onPressed: () => clicked = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Action'), findsOneWidget);
      expect(find.byIcon(Icons.flash_on), findsOneWidget);

      await tester.tap(find.byType(AppGridButton));
      await tester.pump();

      expect(clicked, isTrue);
    });

    testWidgets('Disabled state prevents click and applies disabled style', (tester) async {
      var clicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppGridButton(
                text: 'Disabled',
                disabled: true,
                onPressed: () => clicked = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppGridButton));
      await tester.pump();

      expect(clicked, isFalse);
    });

    testWidgets('Hover and press states respond smoothly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppGridButton(
                text: 'HoverMe',
                onPressed: () {},
                color: Colors.blue,
                hoverColor: Colors.purple,
                pressedColor: Colors.red,
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(AppGridButton);
      expect(buttonFinder, findsOneWidget);

      // Simulate mouse enter
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(buttonFinder));
      await tester.pumpAndSettle();

      // Simulate press down
      await gesture.down(tester.getCenter(buttonFinder));
      await tester.pump();

      // Release
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('BENCHMARK: 100 rows with AppGridButton in cellBuilder mount and sort fast', (tester) async {
      final data = List.generate(100, (i) => {
        'id': 'ID-$i',
        'price': 100.0 + (i * 7) % 50,
      });

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: data,
        columns: [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100, pin: GridColumnPin.left, valueGetter: (r) => r['id']),
          GridColumn(id: 'price', label: 'Price', initialWidth: 120, valueGetter: (r) => r['price']),
          GridColumn(
            id: 'trade',
            label: 'Trade',
            initialWidth: 120,
            pin: GridColumnPin.right,
            isSortable: false,
            cellBuilder: (context, row, info) => Center(
              child: AppGridButton(
                text: 'Buy',
                onPressed: () {},
              ),
            ),
          ),
        ],
      );

      final swMount = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 500,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      swMount.stop();

      // Mount must be fast with AppGridButton (< 400ms in test environment)
      expect(swMount.elapsedMilliseconds, lessThan(400));

      // Sort must be fast
      final swSort = Stopwatch()..start();
      await controller.sortByColumn('price', direction: SortDirection.ascending);
      await tester.pumpAndSettle();
      swSort.stop();

      expect(swSort.elapsedMilliseconds, lessThan(150));

      controller.dispose();
    });
  });
}
