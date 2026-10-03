import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Manual Row Reorder (Controller Unit Tests)', () {
    test('canReorderRows is true only when no column sorting is active',
        () async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Alpha'},
          {'id': 2, 'name': 'Beta'},
          {'id': 3, 'name': 'Gamma'},
        ],
        columns: const [
          GridColumn(id: 'name', label: 'Name'),
        ],
      );

      expect(controller.canReorderRows, isTrue);

      // Apply sort
      await controller.sortByColumn('name', direction: SortDirection.ascending);
      expect(controller.sortCriteria?.direction, SortDirection.ascending);
      expect(controller.canReorderRows, isFalse);

      // Reorder attempt should fail while sort is active
      final reorderResult = controller.reorderRow(0, 2);
      expect(reorderResult, isFalse);

      // Clear sort
      await controller.sortByColumn('name', direction: SortDirection.none);
      expect(controller.canReorderRows, isTrue);
    });

    test('reorderRow moves items and calls onRowReorder callback', () {
      int? reportedOldIndex;
      int? reportedNewIndex;

      final controller = AppGridController<String>(
        initialData: ['Item A', 'Item B', 'Item C', 'Item D'],
        columns: const [GridColumn(id: 'name', label: 'Name')],
        onRowReorder: (oldIdx, newIdx) {
          reportedOldIndex = oldIdx;
          reportedNewIndex = newIdx;
        },
      );

      // Reorder Item A (index 0) to index 2 (between B and C)
      final success = controller.reorderRow(0, 2);
      expect(success, isTrue);
      expect(reportedOldIndex, 0);
      expect(reportedNewIndex, 2);

      // Verify dataset order
      expect(controller.getReorderedData(),
          ['Item B', 'Item C', 'Item A', 'Item D']);
      expect(controller.getModifiedData(),
          ['Item B', 'Item C', 'Item A', 'Item D']);
      expect(controller.originalRowCount, 4);
      expect(controller.displayRowCount, 4);
      expect(controller.getRowByDisplayIndex(0), 'Item B');
      expect(controller.getRowByDisplayIndex(1), 'Item C');
      expect(controller.getRowByDisplayIndex(2), 'Item A');
      expect(controller.getRowByDisplayIndex(3), 'Item D');
    });

    test('reorderRow adjusts active row selection correctly', () {
      final controller = AppGridController<String>(
        initialData: ['Row 0', 'Row 1', 'Row 2', 'Row 3'],
        columns: const [GridColumn(id: 'text', label: 'Text')],
      );

      // Select Row 1
      controller.selectRow(1);
      expect(controller.selectedDisplayIndex, 1);
      expect(controller.selectedOriginalIndex, 1);

      // Move Row 1 to index 3
      controller.reorderRow(1, 3);
      // Selection should follow Row 1 to index 3
      expect(controller.selectedDisplayIndex, 3);
      expect(controller.selectedOriginalIndex, 3);
      expect(controller.getRowByDisplayIndex(controller.selectedDisplayIndex!),
          'Row 1');

      // Now move Row 0 to index 3 (which shifts Row 1 from index 3 down to index 2)
      controller.reorderRow(0, 3);
      expect(controller.selectedDisplayIndex, 2);
      expect(controller.getRowByDisplayIndex(controller.selectedDisplayIndex!),
          'Row 1');
    });

    test(
        'State persistence does NOT persist row reordering (REQ-STATE-01, 02, 03)',
        () {
      final controller = AppGridController<String>(
        initialData: ['First', 'Second', 'Third'],
        columns: const [GridColumn(id: 'col', label: 'Col')],
      );

      controller.reorderRow(0, 2);
      expect(controller.getReorderedData(), ['Second', 'Third', 'First']);

      final exportedState = controller.exportState();
      final jsonMap = exportedState.toMap();

      // State serialization must strictly exclude row orders or widths
      expect(jsonMap.containsKey('rowData'), isFalse);
      expect(jsonMap.containsKey('rowOrder'), isFalse);
      expect(jsonMap.containsKey('data'), isFalse);
      expect(jsonMap.containsKey('columnWidth'), isFalse);
      expect(jsonMap.containsKey('width'), isFalse);
    });
  });

  group('Manual Row Reorder (Widget & Drag Handle Tests)', () {
    testWidgets(
        'Renders GridColumn.rowDragHandle and AppGridRowDragHandle in enabled state',
        (tester) async {
      final controller = AppGridController<String>(
        initialData: ['Alpha', 'Beta', 'Gamma'],
        columns: [
          GridColumn.rowDragHandle(),
          GridColumn(id: 'text', label: 'Text', valueGetter: (row) => row),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: AppGrid<String>(
                controller: controller,
                enableRowReorder: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag handles should be rendered
      expect(find.byType(AppGridRowDragHandle<String>), findsWidgets);
      expect(find.byIcon(Icons.drag_indicator), findsWidgets);
      expect(find.byType(Draggable<int>), findsWidgets);
    });

    testWidgets('Disables AppGridRowDragHandle when column sort is active',
        (tester) async {
      final controller = AppGridController<String>(
        initialData: ['Alpha', 'Beta', 'Gamma'],
        columns: [
          GridColumn.rowDragHandle(),
          GridColumn(id: 'text', label: 'Text', valueGetter: (row) => row),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: AppGrid<String>(
                controller: controller,
                enableRowReorder: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially sorting is inactive -> Draggable is present
      expect(find.byType(Draggable<int>), findsWidgets);

      // Now apply sorting
      await controller.sortByColumn('text', direction: SortDirection.ascending);
      await tester.pumpAndSettle();

      // When sorting is active, Draggable must NOT be mounted, cursor is basic, drag is disabled
      expect(controller.canReorderRows, isFalse);
      expect(find.byType(Draggable<int>), findsNothing);

      // Clear sorting -> Draggable is restored
      await controller.sortByColumn('text', direction: SortDirection.none);
      await tester.pumpAndSettle();

      expect(controller.canReorderRows, isTrue);
      expect(find.byType(Draggable<int>), findsWidgets);
    });

    testWidgets(
        'Drag and drop row from index 0 to index 2 updates order and calls callback',
        (tester) async {
      int? reorderedOld;
      int? reorderedNew;

      final controller = AppGridController<String>(
        initialData: ['Row 1', 'Row 2', 'Row 3'],
        columns: [
          GridColumn.rowDragHandle(),
          GridColumn(id: 'name', label: 'Name', valueGetter: (row) => row),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: AppGrid<String>(
                controller: controller,
                enableRowReorder: true,
                onRowReorder: (oldIdx, newIdx) {
                  reorderedOld = oldIdx;
                  reorderedNew = newIdx;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find first drag handle
      final firstHandle = find.byType(AppGridRowDragHandle<String>).first;
      expect(firstHandle, findsOneWidget);

      // Find third row
      final thirdRow = find.byKey(const ValueKey('grid_pos_row_2'));
      expect(thirdRow, findsOneWidget);

      // Drag from first handle to third row
      final firstCenter = tester.getCenter(firstHandle);
      final thirdCenter = tester.getCenter(thirdRow);

      final gesture = await tester.startGesture(firstCenter);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(thirdCenter);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pumpAndSettle();

      // Verify callback was triggered and data was reordered
      expect(reorderedOld, 0);
      expect(reorderedNew, 2);
      expect(controller.getReorderedData(), ['Row 2', 'Row 3', 'Row 1']);
    });
  });
}
