import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

typedef Row = Map<String, dynamic>;

AppGridController<Row> _controller(List<Row> data) => AppGridController<Row>(
      initialData: data,
      columns: [
        GridColumn(id: 'code', label: 'Code', valueGetter: (r) => r['code']),
        GridColumn(id: 'price', label: 'Price', valueGetter: (r) => r['price']),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  AppGridController<Row> controller, {
  AppGridStyle style = const AppGridStyle(fillEmptyRows: true, rowHeight: 24),
  Widget? emptyWidget,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: 300,
          child: AppGrid<Row>(
            controller: controller,
            style: style,
            emptyWidget: emptyWidget,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AppGridStyle.fillEmptyRows', () {
    test('defaults to false and is part of equality and copyWith', () {
      const base = AppGridStyle();
      expect(base.fillEmptyRows, isFalse);
      final on = base.copyWith(fillEmptyRows: true);
      expect(on.fillEmptyRows, isTrue);
      expect(on == base, isFalse);
      expect(on.copyWith().fillEmptyRows, isTrue);
    });

    testWidgets('empty grid draws blank rows under the header', (tester) async {
      final controller = _controller([]);
      await _pump(tester, controller);

      expect(find.byType(AppGridEmptyRows), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('off by default: no blank rows', (tester) async {
      final controller = _controller([]);
      await _pump(tester, controller, style: const AppGridStyle());

      expect(find.byType(AppGridEmptyRows), findsNothing);
      controller.dispose();
    });

    testWidgets('emptyWidget wins over fillEmptyRows', (tester) async {
      final controller = _controller([]);
      await _pump(tester, controller, emptyWidget: const Text('Nothing here'));

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byType(AppGridEmptyRows), findsNothing);
      controller.dispose();
    });

    testWidgets('grid with data fills the space below the last row', (tester) async {
      final controller = _controller([
        {'code': 'BBRI', 'price': 2530},
      ]);
      await _pump(tester, controller);

      expect(find.text('BBRI'), findsOneWidget);
      // Blank rows sit behind the data rows and show below them.
      final filler = find.byType(AppGridEmptyRows);
      expect(filler, findsOneWidget);
      final rowTop = tester.getTopLeft(find.text('BBRI')).dy;
      expect(tester.getTopLeft(filler).dy, lessThanOrEqualTo(rowTop));
      controller.dispose();
    });

    testWidgets('grid with data and the option off has no filler', (tester) async {
      final controller = _controller([
        {'code': 'BBRI', 'price': 2530},
      ]);
      await _pump(tester, controller, style: const AppGridStyle(rowHeight: 24));

      expect(find.byType(AppGridEmptyRows), findsNothing);
      controller.dispose();
    });

    testWidgets('blank rows appear when data is cleared', (tester) async {
      final controller = _controller([
        {'code': 'BBRI', 'price': 2530},
      ]);
      await _pump(tester, controller);
      controller.setData([]);
      await tester.pumpAndSettle();

      expect(find.byType(AppGridEmptyRows), findsOneWidget);
      controller.dispose();
    });
  });
}
