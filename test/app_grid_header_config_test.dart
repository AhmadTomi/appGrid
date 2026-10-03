import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('AppGridHeaderConfig Model Tests', () {
    test('standard constructor has all features enabled by default', () {
      const config = AppGridHeaderConfig();
      expect(config.enableSort, isTrue);
      expect(config.enableMenu, isTrue);
      expect(config.enableReorder, isTrue);
      expect(config.enableResize, isTrue);
      expect(config.showIcon, isTrue);
      expect(config.enableAutoFit, isTrue);
    });

    test(
        'simple preset disables sort, menu, reorder, icon but keeps resize and autofit',
        () {
      const config = AppGridHeaderConfig.simple();
      expect(config.enableSort, isFalse);
      expect(config.enableMenu, isFalse);
      expect(config.enableReorder, isFalse);
      expect(config.enableResize, isTrue);
      expect(config.showIcon, isFalse);
      expect(config.enableAutoFit, isTrue);
    });

    test('copyWith allows selective overriding', () {
      const simple = AppGridHeaderConfig.simple();
      final custom = simple.copyWith(
        enableSort: true,
        showIcon: true,
      );

      expect(custom.enableSort, isTrue);
      expect(custom.enableMenu, isFalse);
      expect(custom.enableReorder, isFalse);
      expect(custom.enableResize, isTrue);
      expect(custom.showIcon, isTrue);
      expect(custom.enableAutoFit, isTrue);
    });

    test('equality and hashCode contract', () {
      const c1 = AppGridHeaderConfig.simple();
      const c2 = AppGridHeaderConfig(
        enableSort: false,
        enableMenu: false,
        enableReorder: false,
        enableResize: true,
        showIcon: false,
        enableAutoFit: true,
      );
      const c3 = AppGridHeaderConfig();

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });
  });

  group('AppGridHeaderConfig Widget Integration Tests', () {
    testWidgets(
        'grid-level simple header mode hides icons and disables sorting',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        columns: [
          const GridColumn(id: 'name', label: 'Name', initialWidth: 150),
          const GridColumn(id: 'age', label: 'Age', initialWidth: 150),
        ],
        initialData: [
          {'name': 'Alice', 'age': 30},
          {'name': 'Bob', 'age': 25},
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              headerConfig: const AppGridHeaderConfig.simple(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no menu icon (dehaze) is rendered because showIcon is false
      expect(find.byIcon(Icons.dehaze), findsNothing);

      // Tap on 'Name' header - should NOT trigger sorting
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      expect(controller.sortCriteria, isNull);
    });

    testWidgets(
        'per-column headerConfig override allows mixed header configurations',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        columns: [
          // Column 1: Simple mode (no icons, no sort)
          const GridColumn(
            id: 'id',
            label: 'ID',
            initialWidth: 100,
            headerConfig: AppGridHeaderConfig.simple(),
          ),
          // Column 2: Standard mode (default, has icons, can sort)
          const GridColumn(
            id: 'name',
            label: 'Name',
            initialWidth: 150,
          ),
        ],
        initialData: [
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only 1 menu icon should be rendered (for the 'Name' column)
      expect(find.byIcon(Icons.dehaze), findsOneWidget);

      // Tapping 'ID' header does NOT sort
      await tester.tap(find.text('ID'));
      await tester.pumpAndSettle();
      expect(controller.sortCriteria, isNull);

      // Tapping 'Name' header DOES sort
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      expect(controller.sortCriteria?.columnId, equals('name'));
    });

    testWidgets(
        'AppGrid.headerConfig with copyWith selectively enables features',
        (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        columns: [
          const GridColumn(id: 'city', label: 'City', initialWidth: 150),
        ],
        initialData: [
          {'city': 'Tokyo'},
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              headerConfig: const AppGridHeaderConfig.simple().copyWith(
                enableSort: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // showIcon is still false
      expect(find.byIcon(Icons.dehaze), findsNothing);

      // But sorting was selectively enabled via copyWith
      await tester.tap(find.text('City'));
      await tester.pumpAndSettle();
      expect(controller.sortCriteria?.columnId, equals('city'));
    });
  });
}
