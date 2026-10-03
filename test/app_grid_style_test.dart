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
      expect(style.headerTextStyle.fontSize, equals(13.0));
      expect(style.headerTextStyle.fontWeight, equals(FontWeight.bold));
      expect(style.rowTextStyle.fontSize, equals(13.0));
      expect(style.rowTextStyle.fontWeight, equals(FontWeight.normal));
      expect(style.menuTextStyle.fontSize, equals(13.0));
      expect(style.menuTextStyle.fontWeight, equals(FontWeight.normal));
      expect(style.footerTextStyle.fontSize, equals(12.0));
      expect(style.footerTextStyle.fontWeight, equals(FontWeight.bold));

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
        'copyWith updates specified fields including font styles while preserving existing values',
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

      final updated = base.copyWith(
        rowHeight: 52.0,
        selectedRowColor: Colors.blue,
        showVerticalGridLines: true,
        headerTextStyle: customFont,
        menuTextStyle: customMenuFont,
      );

      // Changed fields
      expect(updated.rowHeight, equals(52.0));
      expect(updated.selectedRowColor, equals(Colors.blue));
      expect(updated.showVerticalGridLines, isTrue);
      expect(updated.headerTextStyle, equals(customFont));
      expect(updated.menuTextStyle, equals(customMenuFont));

      // Preserved fields
      expect(updated.headerHeight, equals(45.0));
      expect(updated.evenRowColor, equals(Colors.white));
      expect(updated.oddRowColor, equals(Colors.grey));
      expect(updated.borderColor, equals(Colors.black));
      expect(updated.showHorizontalGridLines, isTrue);
      expect(updated.rowTextStyle.fontSize, equals(13.0));
    });

    test('AppGridStyle supports equality and hashCode', () {
      const style1 = AppGridStyle(
        rowHeight: 50.0,
        evenRowColor: Colors.white,
        oddRowColor: Colors.grey,
      );
      const style2 = AppGridStyle(
        rowHeight: 50.0,
        evenRowColor: Colors.white,
        oddRowColor: Colors.grey,
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
      expect(style.headerTextStyle.fontSize, equals(13.0));
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
  });
}
