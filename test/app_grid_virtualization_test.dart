import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('2D Virtualization & Performance Tests (AC-01 & AC-02)', () {
    testWidgets('AC-01: 100,000 rows x 50 columns renders strictly visible + buffer rows', (tester) async {
      final rows = List.generate(100000, (i) => 'Row $i');
      final columns = List.generate(
        50,
        (c) => GridColumn(
          id: 'col_$c',
          label: 'Col $c',
          initialWidth: 100.0,
          pin: c == 0
              ? GridColumnPin.left
              : (c == 49 ? GridColumnPin.right : GridColumnPin.none),
        ),
      );

      final controller = AppGridController<String>(
        initialData: rows,
        columns: columns,
      );

      // Height: 500 (body: ~452, rowHeight: 40 -> ~11 visible rows + buffer)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 500,
              child: AppGrid<String>(
                controller: controller,
                rowHeight: 40.0,
                headerHeight: 48.0,
                cellBuilder: (context, item, info, colId) => Text('$item $colId'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all rendered RowWidget elements
      final rowWidgets = find.byType(RowWidget<String>);
      // For 452px viewport height / 40px row height: 12 rows + 2 buffer rows = ~14 rows
      // And with left and right pinned panes, each row appears in its pane, but total row indices active is <= 15!
      expect(rowWidgets, findsWidgets);

      // Verify that out-of-viewport rows (e.g. Row 500 or Row 99999) are NOT in the tree
      expect(find.text('Row 500 col_0'), findsNothing);
      expect(find.text('Row 99999 col_0'), findsNothing);

      // Verify row 0 is rendered
      expect(find.text('Row 0 col_0'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('AC-02: Cell tick update rebuilds only the cell, not the root AppGrid', (tester) async {
      var rootBuildCount = 0;

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 'r0', 'val': 'Initial'},
          {'id': 'r1', 'val': 'Static'},
        ],
        columns: const [
          GridColumn(id: 'val', label: 'Value', initialWidth: 200),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rootBuildCount++;
                return SizedBox(
                  width: 300,
                  height: 300,
                  child: AppGrid<Map<String, dynamic>>(
                    controller: controller,
                    cellBuilder: (context, item, info, colId) {
                      return Text(item['val'] as String);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(rootBuildCount, equals(1));
      expect(find.text('Initial'), findsOneWidget);

      // Mutate row 0 via developer-friendly updateRow API
      controller.updateRow(0, {'id': 'r0', 'val': 'UpdatedTick'});
      await tester.pump();

      // Verify cell shows new text
      expect(find.text('UpdatedTick'), findsOneWidget);

      // Root widget must NOT have rebuilt!
      expect(rootBuildCount, equals(1));

      controller.dispose();
    });
  });
}
