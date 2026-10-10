import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('AppGridStyle & copyWith Unit Tests', () {
    test('Default AppGridStyle has expected default properties and font styles',
        () {
      const style = AppGridStyle();
      expect(style.rowHeight, equals(48.0));
      expect(style.headerHeight, equals(48.0));
      expect(style.headerTextStyle, isNull);
      expect(style.headerPadding, isNull);
      expect(style.rowTextStyle, isNull);
      expect(style.rowPadding, isNull);
      expect(style.menuTextStyle.fontSize, equals(13.0));
      expect(style.menuTextStyle.fontWeight, equals(FontWeight.normal));
      expect(style.footerTextStyle, isNull);
      expect(style.footerPadding, isNull);

      expect(style.showHorizontalGridLines, isTrue);
      expect(style.showVerticalGridLines, isFalse);
      expect(style.showHorizontalScrollbar, isTrue);
      expect(style.showVerticalScrollbar, isTrue);
      expect(style.scrollbarThickness, equals(10.0));
      expect(style.iconSize, equals(16.0));
      expect(style.selectedRowColor, isNull);
      expect(style.showPinIcon, isFalse);
    });

    test(
        'copyWith updates specified fields including font styles and padding while preserving existing values',
        () {
      const base = AppGridStyle(
        rowHeight: 40.0,
        headerHeight: 45.0,
        evenRowColor: Colors.white,
        oddRowColor: Colors.grey,
        borderColor: Colors.black,
      );

      const customFont = TextStyle(
          fontSize: 16.0, fontWeight: FontWeight.w500, color: Colors.indigo);
      const customMenuFont =
          TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic);
      const customHeaderPadding = EdgeInsets.all(12.0);
      const customRowPadding = EdgeInsets.symmetric(horizontal: 20.0);
      const customFooterPadding = EdgeInsets.all(8.0);
      const customFooterFont = TextStyle(fontSize: 11.0, color: Colors.green);

      final updated = base.copyWith(
        rowHeight: 52.0,
        selectedRowColor: Colors.blue,
        showVerticalGridLines: true,
        headerTextStyle: customFont,
        headerPadding: customHeaderPadding,
        rowPadding: customRowPadding,
        footerPadding: customFooterPadding,
        footerTextStyle: customFooterFont,
        menuTextStyle: customMenuFont,
      );

      // Changed fields
      expect(updated.rowHeight, equals(52.0));
      expect(updated.selectedRowColor, equals(Colors.blue));
      expect(updated.showVerticalGridLines, isTrue);
      expect(updated.headerTextStyle, equals(customFont));
      expect(updated.headerPadding, equals(customHeaderPadding));
      expect(updated.rowPadding, equals(customRowPadding));
      expect(updated.footerPadding, equals(customFooterPadding));
      expect(updated.footerTextStyle, equals(customFooterFont));
      expect(updated.menuTextStyle, equals(customMenuFont));

      // Preserved fields
      expect(updated.headerHeight, equals(45.0));
      expect(updated.evenRowColor, equals(Colors.white));
      expect(updated.oddRowColor, equals(Colors.grey));
      expect(updated.borderColor, equals(Colors.black));
      expect(updated.showHorizontalGridLines, isTrue);
      expect(updated.rowTextStyle, isNull);
    });

    test('AppGridStyle supports equality and hashCode', () {
      const style1 = AppGridStyle(
        rowHeight: 50.0,
        evenRowColor: Colors.white,
        oddRowColor: Colors.grey,
        rowPadding: EdgeInsets.all(8.0),
      );
      const style2 = AppGridStyle(
        rowHeight: 50.0,
        evenRowColor: Colors.white,
        oddRowColor: Colors.grey,
        rowPadding: EdgeInsets.all(8.0),
      );
      const style3 = AppGridStyle(
        rowHeight: 60.0,
        evenRowColor: Colors.white,
        oddRowColor: Colors.grey,
      );

      expect(style1, equals(style2));
      expect(style1.hashCode, equals(style2.hashCode));
      expect(style1, isNot(equals(style3)));
    });

    test('AppGridStyle is a valid type alias for AppGridStyle', () {
      const AppGridStyle style = AppGridStyle(rowHeight: 55.0);
      expect(style.rowHeight, equals(55.0));
      expect(style.headerTextStyle, isNull);
    });
  });

  group('AppGrid Style Integration Tests', () {
    testWidgets(
        'AppGrid applies properties and default font styles from AppGridStyle and style.copyWith',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Item A'},
          {'id': 2, 'name': 'Item B'},
        ],
        columns: [
          GridColumn(id: 'id', label: 'ID', valueGetter: (r) => r['id']),
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => r['name']),
        ],
      );

      const customHeaderFont = TextStyle(
          fontSize: 15.0, fontWeight: FontWeight.bold, color: Colors.blue);
      const customRowFont = TextStyle(
          fontSize: 14.0, fontWeight: FontWeight.w400, color: Colors.brown);

      const baseStyle = AppGridStyle(
        rowHeight: 60.0,
        headerHeight: 55.0,
        evenRowColor: Color(0xFFEEEEEE),
        oddRowColor: Color(0xFFDDDDDD),
        headerBackgroundColor: Color(0xFFCCCCCC),
      );

      final customStyle = baseStyle.copyWith(
        rowHeight: 64.0,
        iconSize: 20.0,
        headerTextStyle: customHeaderFont,
        rowTextStyle: customRowFont,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                style: customStyle,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final grid = tester.widget<AppGrid<Map<String, dynamic>>>(
        find.byType(AppGrid<Map<String, dynamic>>),
      );

      // AppGrid getters resolve through style
      expect(grid.rowHeight, equals(64.0));
      expect(grid.headerHeight, equals(55.0));
      expect(grid.iconSize, equals(20.0));
      expect(grid.headerTextStyle, equals(customHeaderFont));
      expect(grid.rowTextStyle, equals(customRowFont));
      expect(grid.cellTextStyle, equals(customRowFont));

      // Header label Text uses customHeaderFont
      final headerText = tester.widget<Text>(find.text('Name'));
      expect(headerText.style, equals(customHeaderFont));

      // Row cell Text uses customRowFont
      final cellText = tester.widget<Text>(find.text('Item A'));
      expect(cellText.style, equals(customRowFont));

      controller.dispose();
    });

    testWidgets('AppGrid style properties configure dimensions and font styles',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Item A'},
        ],
        columns: [
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => r['name']),
        ],
      );

      const directHeaderFont =
          TextStyle(fontSize: 18.0, fontWeight: FontWeight.w900);
      const directRowFont =
          TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600);

      const appliedStyle = AppGridStyle(
        rowHeight: 70.0,
        headerHeight: 50.0,
        headerTextStyle: directHeaderFont,
        rowTextStyle: directRowFont,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                style: appliedStyle,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final grid = tester.widget<AppGrid<Map<String, dynamic>>>(
        find.byType(AppGrid<Map<String, dynamic>>),
      );

      expect(grid.rowHeight, equals(70.0));
      expect(grid.headerHeight, equals(50.0));
      expect(grid.headerTextStyle, equals(directHeaderFont));
      expect(grid.rowTextStyle, equals(directRowFont));

      final headerText = tester.widget<Text>(find.text('Name'));
      expect(headerText.style, equals(directHeaderFont));

      final cellText = tester.widget<Text>(find.text('Item A'));
      expect(cellText.style, equals(directRowFont));

      controller.dispose();
    });

    testWidgets('AppGrid applies headerPadding, rowPadding, and footerPadding',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'name': 'Item 1'},
        ],
        columns: [
          GridColumn(
            id: 'name',
            label: 'Name Column',
            valueGetter: (r) => r['name'],
          ),
        ],
      );

      const customHeaderPadding = EdgeInsets.symmetric(horizontal: 22.0);
      const customRowPadding = EdgeInsets.symmetric(horizontal: 18.0);
      const customFooterPadding = EdgeInsets.symmetric(horizontal: 15.0);
      const customFooterStyle = TextStyle(fontSize: 14.0, color: Colors.purple);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                footerBuilder: (context, col, data) =>
                    const Text('Custom Footer Label'),
                style: const AppGridStyle(
                  headerPadding: customHeaderPadding,
                  rowPadding: customRowPadding,
                  footerPadding: customFooterPadding,
                  footerTextStyle: customFooterStyle,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header padding
      final headerContainerFinder = find.ancestor(
        of: find.text('Name Column'),
        matching: find.byType(Container),
      );
      final headerContainer =
          tester.widget<Container>(headerContainerFinder.first);
      expect(headerContainer.padding, equals(customHeaderPadding));

      // Verify row cell padding
      final cellContainerFinder = find.ancestor(
        of: find.text('Item 1'),
        matching: find.byType(Container),
      );
      final cellContainer =
          tester.widget<Container>(cellContainerFinder.first);
      expect(cellContainer.padding, equals(customRowPadding));

      // Verify footer padding
      final footerContainerFinder = find.ancestor(
        of: find.text('Custom Footer Label'),
        matching: find.byType(Container),
      );
      final footerContainer =
          tester.widget<Container>(footerContainerFinder.first);
      expect(footerContainer.padding, equals(customFooterPadding));

      controller.dispose();
    });

    testWidgets(
        'AppGrid applies headerBackgroundColor and footerBackgroundColor',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'name': 'Item 1'},
        ],
        columns: [
          GridColumn(
            id: 'name',
            label: 'Name Column',
            valueGetter: (r) => r['name'],
          ),
        ],
      );

      const customHeaderBg = Color(0xFF123456);
      const customFooterBg = Color(0xFF654321);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                footerBuilder: (context, col, data) =>
                    const Text('Custom Footer Label'),
                style: const AppGridStyle(
                  headerBackgroundColor: customHeaderBg,
                  footerBackgroundColor: customFooterBg,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final grid = tester.widget<AppGrid<Map<String, dynamic>>>(
        find.byType(AppGrid<Map<String, dynamic>>),
      );
      expect(grid.headerBackgroundColor, equals(customHeaderBg));
      expect(grid.footerBackgroundColor, equals(customFooterBg));

      // Verify header cell background
      final headerCell = tester.widget<AppGridHeaderCell>(
        find.byWidgetPredicate((w) => w is AppGridHeaderCell),
      );
      expect(headerCell.headerBackgroundColor, equals(customHeaderBg));

      // Verify footer cell container background
      final footerCell = tester.widget<AppGridFooterCell>(
        find.byType(AppGridFooterCell),
      );
      expect(footerCell.style.footerBackgroundColor, equals(customFooterBg));

      final footerCellContainer = find.descendant(
        of: find.byType(AppGridFooterCell),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.color == customFooterBg,
        ),
      );
      expect(footerCellContainer, findsOneWidget);

      controller.dispose();
    });

    testWidgets(
        'AppGrid applies footerBackgroundColor when using column.footerBuilder and style.footerHeight',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'item': 'Apple', 'price': 10},
          {'item': 'Orange', 'price': 15},
        ],
        columns: [
          GridColumn(
            id: 'item',
            label: 'Item',
            valueGetter: (r) => r['item'],
          ),
          GridColumn(
            id: 'price',
            label: 'Price',
            valueGetter: (r) => r['price'],
            footerBuilder: (context, data) => const Text('Total: 25'),
          ),
        ],
      );

      const customFooterBg = Color(0xFF00796B);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                style: const AppGridStyle(
                  footerHeight: 45.0,
                  footerBackgroundColor: customFooterBg,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final footerCells = find.byType(AppGridFooterCell);
      expect(footerCells, findsNWidgets(2));

      final coloredContainers = find.descendant(
        of: find.byType(AppGridFooterCell),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.color == customFooterBg,
        ),
      );
      expect(coloredContainers, findsNWidgets(2));

      controller.dispose();
    });
  });
}
