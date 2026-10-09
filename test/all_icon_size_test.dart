import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('All Icon Size from AppGridStyle Tests', () {
    testWidgets('iconSize in AppGridStyle scales header sort/dehaze icons',
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
                style: const AppGridStyle(iconSize: 28.0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final grid = tester.widget<AppGrid<Map<String, dynamic>>>(
        find.byType(AppGrid<Map<String, dynamic>>),
      );

      // Verify getter returns style.iconSize
      expect(grid.iconSize, equals(28.0));

      // Header dehaze icon has size 28.0
      final iconFinder = find.byIcon(Icons.dehaze);
      expect(iconFinder, findsOneWidget);
      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.size, equals(28.0));

      controller.dispose();
    });

    testWidgets('Header context menu icons use AppGridStyle.iconSize',
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
                style: const AppGridStyle(iconSize: 24.0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the menu icon to open context menu
      await tester.tap(find.byIcon(Icons.dehaze));
      await tester.pumpAndSettle();

      // Find the menu items
      final sortIcons = find.byIcon(Icons.sort);
      expect(sortIcons, findsNWidgets(2)); // Asc and Desc in popup menu
      for (final element in sortIcons.evaluate()) {
        final iconWidget = element.widget as Icon;
        expect(iconWidget.size, equals(24.0));
      }

      controller.dispose();
    });

    testWidgets('Built-in pagination bar icons inherit iconSize from AppGridStyle',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: List.generate(50, (i) => {'id': i + 1, 'name': 'Item $i'}),
        columns: [
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => r['name']),
        ],
        fetchMode: DataFetchMode.pagination,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
                showPaginationBar: true,
                style: const AppGridStyle(iconSize: 25.0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pagination navigation icons should be sized 25.0
      final firstPageIcon = tester.widget<Icon>(find.byIcon(Icons.first_page));
      expect(firstPageIcon.size, equals(25.0));

      final chevronLeftIcon =
          tester.widget<Icon>(find.byIcon(Icons.chevron_left));
      expect(chevronLeftIcon.size, equals(25.0));

      final chevronRightIcon =
          tester.widget<Icon>(find.byIcon(Icons.chevron_right));
      expect(chevronRightIcon.size, equals(25.0));

      final lastPageIcon = tester.widget<Icon>(find.byIcon(Icons.last_page));
      expect(lastPageIcon.size, equals(25.0));

      controller.dispose();
    });

    testWidgets('Row drag handle icon inherits iconSize from AppGridStyle',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Item A'},
        ],
        columns: [
          GridColumn(
            id: 'name',
            label: 'Name',
            valueGetter: (r) => r['name'],
            enableRowDrag: true,
          ),
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
                style: const AppGridStyle(iconSize: 26.0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dragIcon = tester.widget<Icon>(find.byIcon(Icons.drag_indicator));
      expect(dragIcon.size, equals(26.0));

      controller.dispose();
    });

    testWidgets('Column chooser overlay icons inherit iconSize from AppGridStyle',
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
                style: const AppGridStyle(iconSize: 22.0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open column chooser
      controller.openColumnChooser();
      await tester.pumpAndSettle();

      // Check view_column_outlined icon size in dialog header
      final titleIcon =
          tester.widget<Icon>(find.byIcon(Icons.view_column_outlined));
      expect(titleIcon.size, equals(22.0));

      controller.dispose();
    });

    testWidgets('AppGridButton respects custom iconSize parameter',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppGridButton(
              text: 'Click Me',
              icon: Icon(Icons.download),
              iconSize: 21.0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.download));
      expect(icon.size, equals(21.0));
    });
  });
}
