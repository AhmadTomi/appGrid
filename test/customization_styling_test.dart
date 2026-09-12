import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Table Customization & Styling Tests', () {
    testWidgets('AppGrid applies custom headerBackgroundColor, borderColor, and gridLineColor', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Alpha', 'category': 'A'},
          {'id': 2, 'name': 'Beta', 'category': 'B'},
        ],
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100),
          GridColumn(id: 'name', label: 'Name', initialWidth: 150),
          GridColumn(id: 'category', label: 'Category', initialWidth: 120),
        ],
      );

      const customHeaderBg = Color(0xFF1E293B);
      const customBorderColor = Color(0xFF6366F1);
      const customGridLineColor = Color(0xFFE2E8F0);
      const customSelectedColor = Color(0xFFC7D2FE);
      const customEvenColor = Color(0xFFFFFFFF);
      const customOddColor = Color(0xFFF8FAFC);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                headerHeight: 56.0,
                rowHeight: 52.0,
                headerBackgroundColor: customHeaderBg,
                borderColor: customBorderColor,
                gridLineColor: customGridLineColor,
                selectedRowColor: customSelectedColor,
                evenRowColor: customEvenColor,
                oddRowColor: customOddColor,
                scrollbarThickness: 12.0,
                scrollbarThumbColor: Colors.blueAccent,
                scrollbarTrackColor: Colors.grey.shade200,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify outer border has customBorderColor
      final containerFinder = find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final box = w.decoration as BoxDecoration;
          if (box.border != null && box.border!.top.color == customBorderColor) {
            return true;
          }
        }
        return false;
      });
      expect(containerFinder, findsOneWidget);

      // Verify header cells have customHeaderBg
      final headerCellFinder = find.byType(AppGridHeaderCell<Map<String, dynamic>>);
      expect(headerCellFinder, findsNWidgets(3));

      for (final element in headerCellFinder.evaluate()) {
        final cell = element.widget as AppGridHeaderCell<Map<String, dynamic>>;
        expect(cell.headerBackgroundColor, equals(customHeaderBg));
        expect(cell.gridLineColor, equals(customGridLineColor));
        expect(cell.height, equals(56.0));
      }

      // Verify row widget receives rowHeight and colors
      final rowFinder = find.byType(RowWidget<Map<String, dynamic>>);
      expect(rowFinder, findsWidgets);

      final firstRow = tester.widget<RowWidget<Map<String, dynamic>>>(rowFinder.first);
      expect(firstRow.rowHeight, equals(52.0));
      expect(firstRow.evenRowColor, equals(customEvenColor));
      expect(firstRow.oddRowColor, equals(customOddColor));
      expect(firstRow.gridLineColor, equals(customGridLineColor));

      controller.dispose();
    });

    testWidgets('AppGrid applies optional vertical grid dividers and verticalGridLineColor to cells and headers', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Item A'},
          {'id': 2, 'name': 'Item B'},
        ],
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100),
          GridColumn(id: 'name', label: 'Name', initialWidth: 200),
        ],
      );

      const customVerticalLineColor = Color(0xFFFF5722);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                showVerticalGridLines: true,
                verticalGridLineColor: customVerticalLineColor,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header cells have verticalGridLineColor on right border
      final headerFinder = find.byType(AppGridHeaderCell<Map<String, dynamic>>);
      expect(headerFinder, findsNWidgets(2));
      for (final el in headerFinder.evaluate()) {
        final cell = el.widget as AppGridHeaderCell<Map<String, dynamic>>;
        expect(cell.verticalGridLineColor, equals(customVerticalLineColor));
      }

      // Check row widget has showVerticalGridLines and verticalGridLineColor
      final rowFinder = find.byType(RowWidget<Map<String, dynamic>>);
      expect(rowFinder, findsWidgets);
      final row = tester.widget<RowWidget<Map<String, dynamic>>>(rowFinder.first);
      expect(row.showVerticalGridLines, isTrue);
      expect(row.verticalGridLineColor, equals(customVerticalLineColor));

      // Check cell widgets receive showVerticalGridLine and verticalGridLineColor
      final cellFinder = find.byType(CellWidget<Map<String, dynamic>>);
      expect(cellFinder, findsWidgets);
      final cell = tester.widget<CellWidget<Map<String, dynamic>>>(cellFinder.first);
      expect(cell.showVerticalGridLine, isTrue);
      expect(cell.verticalGridLineColor, equals(customVerticalLineColor));

      controller.dispose();
    });

    testWidgets('AppGrid hides vertical grid dividers from headers, cells, and footers when showVerticalGridLines is false', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Item A'},
        ],
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100),
          GridColumn(id: 'name', label: 'Name', initialWidth: 200),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                showVerticalGridLines: false,
                footerHeight: 36.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header cells have showVerticalGridLines == false
      final headerFinder = find.byType(AppGridHeaderCell<Map<String, dynamic>>);
      expect(headerFinder, findsNWidgets(2));
      for (final el in headerFinder.evaluate()) {
        final cell = el.widget as AppGridHeaderCell<Map<String, dynamic>>;
        expect(cell.showVerticalGridLines, isFalse);
      }

      // Check row widget has showVerticalGridLines == false
      final rowFinder = find.byType(RowWidget<Map<String, dynamic>>);
      expect(rowFinder, findsWidgets);
      final row = tester.widget<RowWidget<Map<String, dynamic>>>(rowFinder.first);
      expect(row.showVerticalGridLines, isFalse);

      // Check cell widgets have showVerticalGridLine == false
      final cellFinder = find.byType(CellWidget<Map<String, dynamic>>);
      expect(cellFinder, findsWidgets);
      final cell = tester.widget<CellWidget<Map<String, dynamic>>>(cellFinder.first);
      expect(cell.showVerticalGridLine, isFalse);

      // Check footer cells have showVerticalGridLines == false
      final footerFinder = find.byType(AppGridFooterCell);
      expect(footerFinder, findsNWidgets(2));
      for (final el in footerFinder.evaluate()) {
        final cell = el.widget as AppGridFooterCell;
        expect(cell.showVerticalGridLines, isFalse);
      }

      controller.dispose();
    });

    testWidgets('AppGrid hides horizontal grid dividers when showHorizontalGridLines is false', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Item A'},
          {'id': 2, 'name': 'Item B'},
        ],
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100, pin: GridColumnPin.left),
          GridColumn(id: 'name', label: 'Name', initialWidth: 200),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                showHorizontalGridLines: false,
                showVerticalGridLines: false,
                footerHeight: 36.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header cells have showHorizontalGridLines == false and showVerticalGridLines == false
      final headerFinder = find.byType(AppGridHeaderCell<Map<String, dynamic>>);
      expect(headerFinder, findsNWidgets(2));
      for (final el in headerFinder.evaluate()) {
        final cell = el.widget as AppGridHeaderCell<Map<String, dynamic>>;
        expect(cell.showHorizontalGridLines, isFalse);
        expect(cell.showVerticalGridLines, isFalse);
      }

      // Check row widget has showHorizontalGridLines == false
      final rowFinder = find.byType(RowWidget<Map<String, dynamic>>);
      expect(rowFinder, findsWidgets);
      for (final el in rowFinder.evaluate()) {
        final row = el.widget as RowWidget<Map<String, dynamic>>;
        expect(row.showHorizontalGridLines, isFalse);
        expect(row.showVerticalGridLines, isFalse);
      }

      // Check footer cells have showHorizontalGridLines == false
      final footerFinder = find.byType(AppGridFooterCell);
      expect(footerFinder, findsNWidgets(2));
      for (final el in footerFinder.evaluate()) {
        final cell = el.widget as AppGridFooterCell;
        expect(cell.showHorizontalGridLines, isFalse);
        expect(cell.showVerticalGridLines, isFalse);
      }

      controller.dispose();
    });

    testWidgets('Vertical grid dividers are perfectly aligned between header cells and body row cells', (tester) async {
      final columns = [
        const GridColumn(id: 'num1', label: '#', minWidth: 40, initialWidth: 40),
        const GridColumn(id: 'bvol', label: 'B.vol', minWidth: 80, initialWidth: 80),
        const GridColumn(id: 'bid', label: 'Bid', minWidth: 80, initialWidth: 80),
        const GridColumn(id: 'offer', label: 'Offer', minWidth: 80, initialWidth: 80),
        const GridColumn(id: 'ovol', label: 'O.Vol', minWidth: 80, initialWidth: 80),
        const GridColumn(id: 'num2', label: '#', minWidth: 40, initialWidth: 40),
      ];

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'num1': 1, 'bvol': 100, 'bid': 50.5, 'offer': 51.0, 'ovol': 200, 'num2': 1},
          {'num1': 2, 'bvol': 150, 'bid': 50.4, 'offer': 51.1, 'ovol': 250, 'num2': 2},
        ],
        columns: columns,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                autoStretch: true,
                showVerticalGridLines: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final headerCellFinder = find.byType(AppGridHeaderCell<Map<String, dynamic>>);
      expect(headerCellFinder, findsNWidgets(6));

      for (int i = 0; i < columns.length; i++) {
        final col = columns[i];
        final headerRect = tester.getRect(headerCellFinder.at(i));

        // Find cell in first row
        final cellFinder = find.byKey(ValueKey('cell_0_${col.id}'));
        expect(cellFinder, findsOneWidget);
        final cellRect = tester.getRect(cellFinder);

        // Header and body cell must have IDENTICAL x coordinates and width
        expect(headerRect.left, closeTo(cellRect.left, 0.001),
            reason: 'Column ${col.id} left edge must align perfectly');
        expect(headerRect.right, closeTo(cellRect.right, 0.001),
            reason: 'Column ${col.id} right edge (vertical divider) must align perfectly');
        expect(headerRect.width, closeTo(cellRect.width, 0.001),
            reason: 'Column ${col.id} width must be identical');
      }

      controller.dispose();
    });

    testWidgets('Vertical grid dividers span full cell height and render on top of horizontal grid lines', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Alpha'},
          {'id': 2, 'name': 'Beta'},
        ],
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100),
          GridColumn(id: 'name', label: 'Name', initialWidth: 200),
        ],
      );

      const verticalColor = Color(0xFF2196F3);
      const horizontalColor = Color(0xFF9E9E9E);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                rowHeight: 48,
                headerHeight: 40,
                showVerticalGridLines: true,
                showHorizontalGridLines: true,
                verticalGridLineColor: verticalColor,
                gridLineColor: horizontalColor,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify in CellWidget: vertical divider is rendered in a Stack spanning top: 0 to bottom: 0
      final cellWidgetFinder = find.byKey(const ValueKey('cell_0_id'));
      expect(cellWidgetFinder, findsOneWidget);

      final cellStack = tester.widget<Stack>(
        find.descendant(of: cellWidgetFinder, matching: find.byType(Stack)).first,
      );
      // Last child of CellWidget's stack must be the vertical divider
      final lastPositioned = cellStack.children.last as Positioned;
      expect(lastPositioned.right, equals(0.0));
      expect(lastPositioned.top, equals(0.0));
      expect(lastPositioned.bottom, equals(0.0));
      expect(lastPositioned.width, equals(1.0));
      final dividerContainer = lastPositioned.child as Container;
      expect(dividerContainer.color, equals(verticalColor));

      // 2. Verify in RowWidget: Stack renders horizontal line first, then cells on top
      final rowFinder = find.byType(RowWidget<Map<String, dynamic>>).first;
      final rowStack = tester.widget<Stack>(
        find.descendant(of: rowFinder, matching: find.byType(Stack)).first,
      );
      expect(rowStack.children.length, equals(2));
      // First child is the horizontal divider line
      final hLinePositioned = rowStack.children.first as Positioned;
      expect(hLinePositioned.bottom, equals(0.0));
      expect(hLinePositioned.height, equals(1.0));
      final hLineContainer = hLinePositioned.child as Container;
      expect(hLineContainer.color, equals(horizontalColor));

      // Second child is the Row containing cells (rendered on top of horizontal line)
      expect(rowStack.children[1], isA<Positioned>());
      final cellsPositioned = rowStack.children[1] as Positioned;
      expect(cellsPositioned.child, isA<Row>());

      // 3. Verify in HeaderCell: vertical divider is rendered after horizontal line in Stack
      final headerCellFinder = find.byType(AppGridHeaderCell<Map<String, dynamic>>).first;
      final headerStack = tester.widget<Stack>(
        find.descendant(of: headerCellFinder, matching: find.byType(Stack)).first,
      );
      // Find the vertical divider positioned child
      final headerPositionedList = headerStack.children.whereType<Positioned>().toList();
      final headerVDivider = headerPositionedList.firstWhere(
        (p) => p.right == 0.0 && p.top == 0.0 && p.bottom == 0.0 && p.width == 1.0,
      );
      final headerVContainer = headerVDivider.child as Container;
      expect(headerVContainer.color, equals(verticalColor));

      // Find horizontal bottom line in header
      final headerHLine = headerPositionedList.firstWhere(
        (p) => p.bottom == 0.0 && p.height == 1.5,
      );
      final headerHContainer = headerHLine.child as Container;
      expect(headerHContainer.color, equals(horizontalColor));

      // Header vertical divider index in children must be greater than horizontal line index (drawn on top)
      final hLineIdx = headerStack.children.indexOf(headerHLine);
      final vLineIdx = headerStack.children.indexOf(headerVDivider);
      expect(vLineIdx, greaterThan(hLineIdx),
          reason: 'Vertical divider must be rendered after/on top of horizontal line');

      controller.dispose();
    });
  });
}

