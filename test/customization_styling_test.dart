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
  });
}
