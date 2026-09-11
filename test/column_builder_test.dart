import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

class FruitItem {
  final String name;
  final int total;
  final String? note;

  const FruitItem({required this.name, required this.total, this.note});
}

void main() {
  group('DX Features: Column Builders, GridFooter, Empty States & Header Context Menu', () {
    testWidgets('AppGridController cellBuilders renders modular column cells and EmptyCell for nulls', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<FruitItem>(
        initialData: const [
          FruitItem(name: 'Apple', total: 50, note: 'Fresh'),
          FruitItem(name: 'Banana', total: 20, note: null),
        ],
        columns: [
          const GridColumn(
            id: 'name',
            label: 'Fruit Name',
          ),
          const GridColumn(
            id: 'total',
            label: 'Total',
          ),
          GridColumn(
            id: 'note',
            label: 'Note',
            valueGetter: (f) => f.note,
          ),
        ],
        cellBuilders: {
          'name': (context, fruit, info) => Text('FRUIT: ${fruit.name}'),
          'total': (context, fruit, info) => Text('QTY: ${fruit.total}'),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<FruitItem>(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Modular cellBuilder verification
      expect(find.text('FRUIT: Apple'), findsOneWidget);
      expect(find.text('QTY: 50'), findsOneWidget);
      expect(find.text('Fresh'), findsOneWidget);

      expect(find.text('FRUIT: Banana'), findsOneWidget);
      expect(find.text('QTY: 20'), findsOneWidget);
      // Null note rendered as EmptyCell ('—')
      expect(find.byType(EmptyCell), findsOneWidget);
      expect(find.text('—'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('AppGridController headerBuilders and dynamic builder updates', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<FruitItem>(
        initialData: const [
          FruitItem(name: 'Apple', total: 50),
        ],
        columns: const [
          GridColumn(id: 'name', label: 'Fruit Name'),
          GridColumn(id: 'total', label: 'Total'),
        ],
        headerBuilders: {
          'name': (context, sortDirection, onToggle) => const Text('CUSTOM_NAME_HEADER'),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<FruitItem>(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CUSTOM_NAME_HEADER'), findsOneWidget);

      // Dynamically add a cell builder and update header builder
      controller.setCellBuilder('name', (context, fruit, info) => Text('DYNAMIC: ${fruit.name}'));
      controller.setHeaderBuilder('total', (context, sortDir, onToggle) => const Text('CUSTOM_TOTAL_HEADER'));
      await tester.pumpAndSettle();

      expect(find.text('DYNAMIC: Apple'), findsOneWidget);
      expect(find.text('CUSTOM_TOTAL_HEADER'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('GridFooter.sum renders declarative column sum in footer', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<FruitItem>(
        initialData: const [
          FruitItem(name: 'Apple', total: 50),
          FruitItem(name: 'Banana', total: 20),
          FruitItem(name: 'Orange', total: 30),
        ],
        columns: [
          GridColumn(
            id: 'name',
            label: 'Name',
            valueGetter: (f) => f.name,
            footerBuilder: GridFooter.count(prefix: 'Items: '),
          ),
          GridColumn(
            id: 'total',
            label: 'Total',
            valueGetter: (f) => f.total,
            footerBuilder: GridFooter.sum<FruitItem>((f) => f.total, prefix: 'Sum: ', suffix: ' pcs'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<FruitItem>(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Footer summary assertions
      expect(find.text('Items: 3'), findsOneWidget);
      expect(find.text('Sum: 100 pcs'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('emptyWidget is displayed when dataset has zero rows', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<FruitItem>(
        initialData: const [],
        columns: [
          GridColumn(id: 'name', label: 'Name', valueGetter: (f) => f.name),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<FruitItem>(
              controller: controller,
              emptyWidget: const AppGridEmptyWidget(message: 'No fruits found!'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppGridEmptyWidget), findsOneWidget);
      expect(find.text('No fruits found!'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Right-click on column header shows context menu to freeze column', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<FruitItem>(
        initialData: const [
          FruitItem(name: 'Apple', total: 50),
        ],
        columns: [
          GridColumn(id: 'name', label: 'Name', valueGetter: (f) => f.name, pin: GridColumnPin.none),
          GridColumn(id: 'total', label: 'Total', valueGetter: (f) => f.total, pin: GridColumnPin.none),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<FruitItem>(
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Perform secondary tap (right click) on 'Name' header
      final headerFinder = find.text('Name');
      await tester.tap(headerFinder, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      // Verify Context Menu options
      expect(find.text('Pin to Left'), findsOneWidget);
      expect(find.text('Pin to Right'), findsOneWidget);
      expect(find.text('Unpin (Scrollable)'), findsOneWidget);

      // Tap 'Pin to Left'
      await tester.tap(find.text('Pin to Left'));
      await tester.pumpAndSettle();

      // Verify column pin status was updated
      expect(controller.columns.firstWhere((c) => c.id == 'name').pin, equals(GridColumnPin.left));

      controller.dispose();
    });

    testWidgets('AppGrid with showPaginationBar integrates pagination toolbar seamlessly', (tester) async {
      tester.view.physicalSize = const Size(1024, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? pageChangedTarget;

      final controller = AppGridController<FruitItem>(
        fetchMode: DataFetchMode.pagination,
        paginationInfo: const GridPaginationInfo(page: 1, limit: 10, totalCount: 50),
        initialData: const [
          FruitItem(name: 'Apple', total: 50),
        ],
        columns: [
          GridColumn(id: 'name', label: 'Name', valueGetter: (f) => f.name),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<FruitItem>(
              controller: controller,
              showPaginationBar: true,
              onPageChanged: (page, limit) {
                pageChangedTarget = page;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppGridPaginationBar<FruitItem>), findsOneWidget);
      expect(find.text('Showing 1–10 of 50'), findsOneWidget);
      expect(find.text('Page 1 of 5'), findsOneWidget);

      // Tap Next Page on the built-in pagination bar
      await tester.ensureVisible(find.byTooltip('Next Page'));
      await tester.tap(find.byTooltip('Next Page'));
      await tester.pumpAndSettle();

      expect(pageChangedTarget, equals(2));

      controller.dispose();
    });
  });
}
