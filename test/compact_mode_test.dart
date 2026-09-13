import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Compact Mode Grouping & Model Tests', () {
    test('CompactColumnGroup.buildGroups pairs adjacent canCompact:true columns when compactMode is true', () {
      const cols = [
        GridColumn(id: 'c1', label: 'Col 1', canCompact: true, initialWidth: 100),
        GridColumn(id: 'c2', label: 'Col 2', canCompact: true, initialWidth: 150),
        GridColumn(id: 'c3', label: 'Col 3', canCompact: false, initialWidth: 80),
        GridColumn(id: 'c4', label: 'Col 4', canCompact: true, initialWidth: 120),
      ];

      final groups = CompactColumnGroup.buildGroups(columns: cols, compactMode: true);
      expect(groups.length, equals(3));

      // Group 0: c1 + c2 pair
      expect(groups[0].isPair, isTrue);
      expect(groups[0].topColumn.id, equals('c1'));
      expect(groups[0].bottomColumn?.id, equals('c2'));
      expect(groups[0].initialWidth, equals(150.0)); // max(100, 150)

      // Group 1: c3 standalone (canCompact == false)
      expect(groups[1].isPair, isFalse);
      expect(groups[1].topColumn.id, equals('c3'));
      expect(groups[1].bottomColumn, isNull);
      expect(groups[1].initialWidth, equals(80.0));

      // Group 2: c4 standalone (no adjacent pair available)
      expect(groups[2].isPair, isFalse);
      expect(groups[2].topColumn.id, equals('c4'));
      expect(groups[2].bottomColumn, isNull);
      expect(groups[2].initialWidth, equals(120.0));
    });

    test('CompactColumnGroup.buildGroups does not pair when compactMode is false', () {
      const cols = [
        GridColumn(id: 'c1', label: 'Col 1', canCompact: true),
        GridColumn(id: 'c2', label: 'Col 2', canCompact: true),
      ];

      final groups = CompactColumnGroup.buildGroups(columns: cols, compactMode: false);
      expect(groups.length, equals(2));
      expect(groups[0].isPair, isFalse);
      expect(groups[1].isPair, isFalse);
    });

    test('Groups calculate minWidth, maxWidth, and initialWidth taking max of pair', () {
      const colA = GridColumn(id: 'a', label: 'A', initialWidth: 100, minWidth: 60, maxWidth: 200);
      const colB = GridColumn(id: 'b', label: 'B', initialWidth: 140, minWidth: 80, maxWidth: 300);

      const group = CompactColumnGroup(topColumn: colA, bottomColumn: colB);
      expect(group.isPair, isTrue);
      expect(group.initialWidth, equals(140.0));
      expect(group.minWidth, equals(80.0));
      expect(group.maxWidth, equals(300.0));
    });
  });

  group('Controller & Layout Manager Compact Tests', () {
    test('Enabling compactMode resets active sort and disables sort/hide/column chooser', () {
      final controller = AppGridController<Map<String, dynamic>>(
        columns: const [
          GridColumn(id: 'c1', label: 'Col 1'),
          GridColumn(id: 'c2', label: 'Col 2'),
        ],
        initialData: const [
          {'c1': 2, 'c2': 'b'},
          {'c1': 1, 'c2': 'a'},
        ],
      );

      // Apply initial sort
      controller.sortByColumn('c1', direction: SortDirection.ascending);
      expect(controller.sortCriteria?.columnId, equals('c1'));

      // Enable compactMode -> sort must be cleared
      controller.compactMode = true;
      expect(controller.compactMode, isTrue);
      expect(controller.sortCriteria, isNull);

      // Attempting to sort while compactMode is true should be ignored
      controller.sortByColumn('c2', direction: SortDirection.descending);
      expect(controller.sortCriteria, isNull);

      // Attempting to hide column should be ignored
      controller.setColumnVisibility('c1', false);
      expect(controller.visibleColumns.any((c) => c.id == 'c1'), isTrue);

      // Attempting to open column chooser should be ignored
      controller.openColumnChooser();
      expect(controller.isColumnChooserOpen, isFalse);

      controller.dispose();
    });

    test('reorderColumnGroup moves both columns of the group together', () {
      final controller = AppGridController<Map<String, dynamic>>(
        columns: const [
          GridColumn(id: 'a', label: 'A', canCompact: true),
          GridColumn(id: 'b', label: 'B', canCompact: true),
          GridColumn(id: 'c', label: 'C', canCompact: true),
          GridColumn(id: 'd', label: 'D', canCompact: true),
        ],
        initialData: const [
          {'a': 1, 'b': 2, 'c': 3, 'd': 4},
        ],
        compactMode: true,
      );

      // Initial column order: a, b, c, d
      // Groups: [a, b] and [c, d]
      expect(controller.visibleColumns.map((c) => c.id).toList(), equals(['a', 'b', 'c', 'd']));

      // Reorder group [c, d] before group [a, b] (target: 'a')
      controller.reorderColumnGroup(draggedIds: ['c', 'd'], targetColumnId: 'a');
      expect(controller.visibleColumns.map((c) => c.id).toList(), equals(['c', 'd', 'a', 'b']));

      // Reorder group [a, b] before group [c, d] (target: 'c')
      controller.reorderColumnGroup(draggedIds: ['a', 'b'], targetColumnId: 'c');
      expect(controller.visibleColumns.map((c) => c.id).toList(), equals(['a', 'b', 'c', 'd']));

      controller.dispose();
    });

    test('Resizing compact column group assigns identical width to both columns in layout manager', () {
      final layoutManager = ColumnLayoutManager(autoStretchEnabled: false, compactMode: true);
      const cols = [
        GridColumn(id: 'c1', label: 'C1', initialWidth: 100, minWidth: 50, maxWidth: 400),
        GridColumn(id: 'c2', label: 'C2', initialWidth: 120, minWidth: 60, maxWidth: 400),
      ];

      final groups = CompactColumnGroup.buildGroups(columns: cols, compactMode: true);
      expect(groups.length, equals(1));
      final pairGroup = groups.first;

      layoutManager.resizeColumnGroup(group: pairGroup, newWidth: 250.0);

      final layout = layoutManager.computeLayout(
        visibleColumns: cols,
        availableViewportWidth: 800,
        compactMode: true,
      );

      expect(layout.allWidths['c1'], equals(250.0));
      expect(layout.allWidths['c2'], equals(250.0));

      layoutManager.dispose();
    });

    test('GridState exports and restores compactMode without persisting column width (REQ-STATE-03)', () {
      final controller = AppGridController<Map<String, dynamic>>(
        columns: const [
          GridColumn(id: 'c1', label: 'Col 1'),
          GridColumn(id: 'c2', label: 'Col 2'),
        ],
        compactMode: true,
      );

      final state = controller.exportState();
      expect(state.compactMode, isTrue);

      final jsonStr = state.toJson();
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['compactMode'], isTrue);
      // STRICT: No column width keys
      expect(decoded.containsKey('width'), isFalse);
      expect(decoded.containsKey('columnWidth'), isFalse);
      expect(decoded.containsKey('columnWidths'), isFalse);

      // Restore to a fresh controller
      final newController = AppGridController<Map<String, dynamic>>(
        columns: const [
          GridColumn(id: 'c1', label: 'Col 1'),
          GridColumn(id: 'c2', label: 'Col 2'),
        ],
        compactMode: false,
      );
      expect(newController.compactMode, isFalse);

      newController.restoreState(state);
      expect(newController.compactMode, isTrue);

      controller.dispose();
      newController.dispose();
    });
  });

  group('AppGrid Compact Mode UI & Widget Tests', () {
    testWidgets('AppGrid in compactMode doubles row height and header height, rendering 2-level headers and cells', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: const [
          {'name': 'Alice', 'role': 'Developer', 'dept': 'Eng', 'level': 'Senior'},
          {'name': 'Bob', 'role': 'Designer', 'dept': 'Product', 'level': 'Lead'},
        ],
        columns: const [
          GridColumn(id: 'name', label: 'Name', canCompact: true, initialWidth: 150),
          GridColumn(id: 'role', label: 'Role', canCompact: true, initialWidth: 150),
          GridColumn(id: 'dept', label: 'Department', canCompact: true, initialWidth: 150),
          GridColumn(id: 'level', label: 'Level', canCompact: true, initialWidth: 150),
        ],
        compactMode: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              rowHeight: 40.0,
              headerHeight: 40.0,
              autoStretch: false,
              compactMode: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Headers should be paired: 'Name / Role' and 'Department / Level'
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Department'), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);

      // Header cell height should be 2 * headerHeight = 80.0
      final headerCells = find.byType(AppGridHeaderCell<Map<String, dynamic>>);
      expect(headerCells, findsNWidgets(2)); // 2 pair groups
      final firstHeaderSize = tester.getSize(headerCells.first);
      expect(firstHeaderSize.height, equals(80.0));

      // Cells should render CompactCellWidget
      final compactCells = find.byType(CompactCellWidget<Map<String, dynamic>>);
      expect(compactCells, findsWidgets);

      // Values in cell should be Alice (top) and Developer (bottom)
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Developer'), findsOneWidget);

      // Row height should be 2 * rowHeight = 80.0
      final rows = find.byType(RowWidget<Map<String, dynamic>>);
      expect(rows, findsWidgets);
      final firstRowSize = tester.getSize(rows.first);
      expect(firstRowSize.height, equals(80.0));

      // Sorting clicks on header must NOT trigger sort
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(controller.sortCriteria, isNull);

      controller.dispose();
    });

    testWidgets('Header menu icon does not shift centered text, and canCompact:false icon is on top-right', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: const [
          {'sku': 'SKU-001', 'name': 'MacBook Pro', 'cat': 'Laptops'},
        ],
        columns: const [
          GridColumn(
            id: 'sku',
            label: 'SKU',
            canCompact: true,
            initialWidth: 200,
            headerAlignment: Alignment.center,
          ),
          GridColumn(
            id: 'name',
            label: 'Product Name',
            canCompact: true,
            initialWidth: 200,
            headerAlignment: Alignment.center,
          ),
          GridColumn(
            id: 'cat',
            label: 'Category',
            canCompact: false,
            initialWidth: 200,
            headerAlignment: Alignment.center,
          ),
        ],
        compactMode: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              rowHeight: 48.0,
              headerHeight: 48.0,
              autoStretch: false,
              compactMode: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Hover over first header to reveal menu icon
      final firstHeaderCell = find.byType(AppGridHeaderCell<Map<String, dynamic>>).first;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(firstHeaderCell));
      await tester.pumpAndSettle();

      // Verify that SKU and Product Name horizontal center coordinates are exactly identical!
      final skuCenter = tester.getCenter(find.text('SKU'));
      final productNameCenter = tester.getCenter(find.text('Product Name'));
      expect(skuCenter.dx, equals(productNameCenter.dx));

      // Now hover over the second header cell (cat: canCompact: false)
      final catHeaderCell = find.byType(AppGridHeaderCell<Map<String, dynamic>>).at(1);
      await mouse.moveTo(tester.getCenter(catHeaderCell));
      await tester.pumpAndSettle();

      // The Category header cell has total height 96 (2 * 48).
      // Find the menu icon inside catHeaderCell.
      final menuIcons = find.descendant(of: catHeaderCell, matching: find.byIcon(Icons.more_vert));
      expect(menuIcons, findsOneWidget);
      final catMenuIconCenter = tester.getCenter(menuIcons);
      final catCellRect = tester.getRect(catHeaderCell);

      // The menu icon should be in the top half (top-right), i.e. Y < catCellRect.top + 48
      expect(catMenuIconCenter.dy, lessThan(catCellRect.top + 48.0));
      // And on the right edge, i.e. X > catCellRect.center.dx
      expect(catMenuIconCenter.dx, greaterThan(catCellRect.center.dx));

      controller.dispose();
    });
  });
}
