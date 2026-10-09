import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('AppGridMenuStyle & Compact Preset Tests', () {
    test('AppGridMenuStyle.compact has dense desktop ergonomics', () {
      const compact = AppGridMenuStyle.compact();

      expect(compact.itemHeight, equals(28.0));
      expect(compact.itemPadding,
          equals(const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0)));
      expect(compact.textStyle?.fontSize, equals(12.0));
      expect(compact.iconSize, equals(14.0));
      expect(compact.dividerHeight, equals(6.0));
      expect(compact.elevation, equals(4.0));
      expect(compact.borderRadius, equals(BorderRadius.circular(6.0)));
      expect(compact.constraints,
          equals(const BoxConstraints(minWidth: 160.0, maxWidth: 220.0)));
    });

    test('AppGridStyle copyWith updates menuStyle cleanly', () {
      const baseStyle = AppGridStyle();
      expect(baseStyle.menuStyle.itemHeight, equals(48.0));

      final compactStyle =
          baseStyle.copyWith(menuStyle: const AppGridMenuStyle.compact());
      expect(compactStyle.menuStyle.itemHeight, equals(28.0));
      expect(compactStyle.menuStyle.iconSize, equals(14.0));
      expect(compactStyle.menuTextStyle.fontSize, equals(12.0));
    });

    test('menuTextStyle backwards compatibility forwards to menuStyle', () {
      const customFont = TextStyle(fontSize: 15.0, color: Colors.purple);
      const style = AppGridStyle(menuTextStyle: customFont);
      expect(style.menuTextStyle, equals(customFont));

      final updated = style.copyWith(
        menuTextStyle: const TextStyle(fontSize: 16.0, color: Colors.amber),
      );
      expect(updated.menuTextStyle.fontSize, equals(16.0));
      expect(updated.menuTextStyle.color, equals(Colors.amber));
    });

    testWidgets('AppGridMenuStyle.compact applies dense height and padding to popup menu',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Item A'},
        ],
        columns: [
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => r['name']),
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
                style: const AppGridStyle(
                  menuStyle: AppGridMenuStyle.compact(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap header dehaze icon to open context menu
      await tester.tap(find.byIcon(Icons.dehaze));
      await tester.pumpAndSettle();

      // Find all PopupMenuItem widgets
      final menuItemFinder =
          find.byWidgetPredicate((widget) => widget is PopupMenuItem);
      expect(menuItemFinder, findsWidgets);

      // Verify that every menu item has compact height 28.0 and padding
      for (final element in menuItemFinder.evaluate()) {
        final item = element.widget as PopupMenuItem;
        expect(item.height, equals(28.0));
        expect(
          item.padding,
          equals(const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0)),
        );
      }

      // Find all PopupMenuDivider widgets
      final dividerFinder = find.byType(PopupMenuDivider);
      expect(dividerFinder, findsWidgets);
      for (final element in dividerFinder.evaluate()) {
        final div = element.widget as PopupMenuDivider;
        expect(div.height, equals(6.0));
      }

      // Verify menu icons use compact iconSize (14.0)
      final sortIcons = find.byIcon(Icons.sort);
      for (final element in sortIcons.evaluate()) {
        final iconWidget = element.widget as Icon;
        expect(iconWidget.size, equals(14.0));
      }

      controller.dispose();
    });

    testWidgets('Custom AppGridMenuStyle applies custom dimensions and colors',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Item A'},
        ],
        columns: [
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => r['name']),
        ],
      );

      const customMenuStyle = AppGridMenuStyle(
        itemHeight: 26.0,
        itemPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
        dividerHeight: 4.0,
        iconSize: 13.0,
        backgroundColor: Color(0xFFF0F4F8),
        elevation: 2.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                style: const AppGridStyle(
                  menuStyle: customMenuStyle,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.dehaze));
      await tester.pumpAndSettle();

      final menuItemFinder =
          find.byWidgetPredicate((widget) => widget is PopupMenuItem);
      expect(menuItemFinder, findsWidgets);

      for (final element in menuItemFinder.evaluate()) {
        final item = element.widget as PopupMenuItem;
        expect(item.height, equals(26.0));
        expect(
          item.padding,
          equals(const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0)),
        );
      }

      final dividerFinder = find.byType(PopupMenuDivider);
      expect(dividerFinder, findsWidgets);
      for (final element in dividerFinder.evaluate()) {
        final div = element.widget as PopupMenuDivider;
        expect(div.height, equals(4.0));
      }

      controller.dispose();
    });
  });
}
