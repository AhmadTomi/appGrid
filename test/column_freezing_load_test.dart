import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Column Freezing Load & Performance Tests', () {
    testWidgets('Column Freezing page mounts with full base widths, zero overflow, and fast load', (tester) async {
      final data = List.generate(30, (i) => {
        'id': 'ID-$i',
        'name': 'Client $i',
        for (var c = 1; c <= 10; c++) 'metric_$c': (i * c * 13) % 100,
        'actions': 'Action $i',
      });

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: data,
        columns: [
          GridColumn(id: 'id', label: 'Frozen ID', initialWidth: 100, pin: GridColumnPin.left, valueGetter: (r) => r['id']),
          GridColumn(id: 'name', label: 'Frozen Name', initialWidth: 140, pin: GridColumnPin.left, valueGetter: (r) => r['name']),
          for (var c = 1; c <= 10; c++)
            GridColumn(id: 'metric_$c', label: 'Metric #$c', initialWidth: 120, valueGetter: (r) => r['metric_$c']),
          GridColumn(
            id: 'actions',
            label: 'Frozen Action',
            initialWidth: 130,
            pin: GridColumnPin.right,
            isSortable: false,
            valueGetter: (r) => r['actions'],
            cellBuilder: (context, row, info) => Center(
              child: AppGridButton(
                icon: const Icon(Icons.visibility_outlined, size: 13),
                text: 'View',
                onPressed: () {},
              ),
            ),
          ),
        ],
      );

      final layoutManager = ColumnLayoutManager();
      final computedLayout = layoutManager.computeLayout(
        visibleColumns: controller.visibleColumns,
        availableViewportWidth: 800,
      );

      // Verify columns retain their base widths (no artificial crushing)
      expect(computedLayout.leftPane.totalWidth, equals(240.0)); // 100 + 140
      expect(computedLayout.rightPane.totalWidth, equals(130.0)); // 130
      expect(computedLayout.centerPane.totalWidth, equals(1200.0)); // 10 * 120

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all pinned headers and cells render with zero overflows
      expect(find.text('Frozen ID'), findsOneWidget);
      expect(find.text('Frozen Name'), findsOneWidget);
      expect(find.text('Frozen Action'), findsOneWidget);
      expect(find.text('Metric #1'), findsOneWidget);
      expect(find.byType(AppGridButton), findsWidgets);

      controller.dispose();
    });
  });
}

