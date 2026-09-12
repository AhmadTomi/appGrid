import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('AppGrid Performance Benchmark Suite', () {
    testWidgets('BENCHMARK: 100,000 rows x 50 columns mount time & element virtualization (AC-01)', (tester) async {
      final rows = List.generate(100000, (i) => 'Row $i');
      final columns = List.generate(
        50,
        (c) => GridColumn(
          id: 'col_$c',
          label: 'Column $c',
          initialWidth: 120.0,
          pin: c == 0 ? GridColumnPin.left : (c == 49 ? GridColumnPin.right : GridColumnPin.none),
          cellBuilder: (context, item, info) => Text('$item c$c'),
        ),
      );

      final controller = AppGridController<String>(
        initialData: rows,
        columns: columns,
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1000,
              height: 600,
              child: AppGrid<String>(
                controller: controller,
                rowHeight: 40.0,
                headerHeight: 48.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      stopwatch.stop();

      // Ensure 100k rows initial mount took minimal time (< 1500ms in debug test environment)
      expect(stopwatch.elapsedMilliseconds, lessThan(1500),
          reason: 'Initial layout of 100k rows x 50 cols must be fast');

      // Virtualization verification: only visible rows + buffer rendered
      final renderedRowWidgets = find.byType(RowWidget<String>);
      // Viewport height = 600 - 48 = 552. 552 / 40 = 13.8 rows -> ~14 visible + buffer rows.
      // Left, center, and right panes each render RowWidget for the visible indices.
      // Maximum expected RowWidgets across all 3 panes is <= 60 (16-18 rows * 3 panes).
      expect(renderedRowWidgets.evaluate().length, lessThanOrEqualTo(60));

      // Row far outside viewport must NOT be mounted
      expect(find.text('Row 50000 c0'), findsNothing);
      expect(find.text('Row 99999 c0'), findsNothing);

      controller.dispose();
    });

    testWidgets('BENCHMARK: High-Frequency Streaming Ticks (AC-02) zero root rebuilds & microsecond cell dispatch', (tester) async {
      var rootBuildCount = 0;
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(
          1000,
          (i) => {'id': i, 'ticker': 'SYM_$i', 'price': 100.0 + i},
        ),
        columns: [
          GridColumn(
            id: 'ticker',
            label: 'Ticker',
            initialWidth: 100,
            cellBuilder: (context, item, info) => Text((item as Map)['ticker'] as String),
          ),
          GridColumn(
            id: 'price',
            label: 'Price',
            initialWidth: 100,
            cellBuilder: (context, item, info) => Text('${(item as Map)['price']}'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rootBuildCount++;
                return SizedBox(
                  width: 800,
                  height: 600,
                  child: AppGrid<Map<String, dynamic>>(
                    controller: controller,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(rootBuildCount, equals(1));

      // Benchmark 60 consecutive streaming updates
      final stopwatch = Stopwatch()..start();
      for (var tick = 0; tick < 60; tick++) {
        final targetRow = tick % 10;
        controller.updateRow(targetRow, {
          'id': targetRow,
          'ticker': 'SYM_$targetRow',
          'price': 200.0 + tick,
        });
        await tester.pump();
      }
      stopwatch.stop();

      // Verify root widget was never rebuilt during all 60 ticks!
      expect(rootBuildCount, equals(1), reason: 'Root AppGrid must NEVER rebuild on cell streaming updates');

      // 60 ticks in test environment must complete efficiently (< 600ms total for 60 pumps, ~10ms/frame)
      expect(stopwatch.elapsedMilliseconds, lessThan(600),
          reason: '60 ticks must process smoothly within frame budget');

      controller.dispose();
    });

    testWidgets('BENCHMARK: Rapid Continuous Scrolling Frame Budget (<60ms per pump in debug tester)', (tester) async {
      final rows = List.generate(5000, (i) => 'Item $i');
      final controller = AppGridController<String>(
        initialData: rows,
        columns: [
          GridColumn(
            id: 'col1',
            label: 'Column 1',
            initialWidth: 300,
            cellBuilder: (context, item, info) => Text('$item'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 500,
              child: AppGrid<String>(
                controller: controller,
                rowHeight: 40.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll 30 frames rapidly (simulating mouse drag/fast flick)
      final frameTimes = <int>[];
      for (var i = 0; i < 30; i++) {
        final frameStopwatch = Stopwatch()..start();
        // Drag scroll vertically
        await tester.drag(find.byType(AppGrid<String>), const Offset(0, -50));
        await tester.pump();
        frameStopwatch.stop();
        frameTimes.add(frameStopwatch.elapsedMilliseconds);
      }

      // Average frame pump time in test environment should be fast (< 60ms)
      final avgFrameTime = frameTimes.reduce((a, b) => a + b) / frameTimes.length;
      expect(avgFrameTime, lessThan(60.0), reason: 'Average scroll frame pump time must stay well within frame budget');

      controller.dispose();
    });

    testWidgets('BENCHMARK: Rapid Keyboard Selection Navigation (zero lag & zero root rebuilds)', (tester) async {
      var rootBuildCount = 0;
      final controller = AppGridController<String>(
        initialData: List.generate(500, (i) => 'Item $i'),
        columns: [
          GridColumn(
            id: 'name',
            label: 'Name',
            initialWidth: 300,
            cellBuilder: (context, item, info) => Text(item as String),
          ),
        ],
      );

      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rootBuildCount++;
                return SizedBox(
                  width: 500,
                  height: 500,
                  child: AppGrid<String>(
                    controller: controller,
                    focusNode: focusNode,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      focusNode.requestFocus();
      await tester.pump();

      expect(rootBuildCount, equals(1));

      // Simulate holding ArrowDown for 30 consecutive selections
      final navStopwatch = Stopwatch()..start();
      for (var i = 0; i < 30; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      navStopwatch.stop();

      // Verify selection moved 30 steps
      expect(controller.selectedDisplayIndex, equals(29));
      // Root widget must NOT have rebuilt during keyboard navigation
      expect(rootBuildCount, equals(1), reason: 'Keyboard selection must not trigger root AppGrid rebuilds');
      // Navigation must be fast (< 1000ms in debug test environment for 30 keys)
      expect(navStopwatch.elapsedMilliseconds, lessThan(1000));

      controller.dispose();
    });

    test('BENCHMARK: Sorting Engine Speed (100, 1,000, and 10,000 rows)', () async {
      // 1. 100 rows
      {
        final items100 = List.generate(100, (i) => {'id': i, 'val': (100 - i) * 31 % 100});
        final controller100 = AppGridController<Map<String, dynamic>>(
          initialData: items100,
          columns: [const GridColumn(id: 'val', label: 'Val')],
        );
        final sw = Stopwatch()..start();
        await controller100.sortByColumn('val', direction: SortDirection.ascending);
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(10), reason: '100 rows sort must take < 10ms');
        expect(controller100.getRowByDisplayIndex(0)['val'], equals(0));
        controller100.dispose();
      }

      // 2. 1,000 rows
      {
        final items1k = List.generate(1000, (i) => {'id': i, 'val': (1000 - i) * 37 % 1000});
        final controller1k = AppGridController<Map<String, dynamic>>(
          initialData: items1k,
          columns: [const GridColumn(id: 'val', label: 'Val')],
        );
        final sw = Stopwatch()..start();
        await controller1k.sortByColumn('val', direction: SortDirection.ascending);
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(20), reason: '1,000 rows sort must take < 20ms');
        expect(controller1k.getRowByDisplayIndex(0)['val'], equals(0));
        controller1k.dispose();
      }

      // 3. 10,000 rows
      {
        final items10k = List.generate(10000, (i) => {'id': i, 'val': (10000 - i) * 41 % 10000});
        final controller10k = AppGridController<Map<String, dynamic>>(
          initialData: items10k,
          columns: [const GridColumn(id: 'val', label: 'Val')],
        );
        final sw = Stopwatch()..start();
        await controller10k.sortByColumn('val', direction: SortDirection.ascending);
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(75), reason: '10,000 rows sort must take < 75ms');
        expect(controller10k.getRowByDisplayIndex(0)['val'], equals(0));
        controller10k.dispose();
      }
    });
  });
}
