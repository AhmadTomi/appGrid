import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/pages/realtime_streaming_page.dart';

void main() {
  group('Realtime Streaming with Sortable AppGridButton Column', () {
    testWidgets('RealtimeStreamingPage mounts and renders Trade Action column with AppGridButton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: RealtimeStreamingPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Trade Action header is present
      expect(find.text('Trade Action'), findsOneWidget);

      // Verify AppGridButton widgets are rendered with price
      expect(find.byType(AppGridButton), findsWidgets);
      expect(find.textContaining('Buy \$'), findsWidgets);
    });

    testWidgets('Sorting by Trade Action column sorts rows by realtime price', (tester) async {
      final items = [
        {'symbol': 'SYM1', 'price': 250.0, 'change': 1.2, 'volume': 1000},
        {'symbol': 'SYM2', 'price': 105.0, 'change': -0.8, 'volume': 2000},
        {'symbol': 'SYM3', 'price': 380.0, 'change': 4.5, 'volume': 1500},
      ];

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: items,
        columns: [
          GridColumn(id: 'symbol', label: 'Ticker', valueGetter: (r) => r['symbol']),
          GridColumn(
            id: 'trade',
            label: 'Trade Action',
            valueGetter: (r) => r['price'],
            cellBuilder: (context, item, info) => Center(
              child: AppGridButton(
                text: 'Buy \$${(item['price'] as num).toStringAsFixed(2)}',
                onPressed: () {},
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Sort Ascending by Trade Action (Price)
      await tester.tap(find.text('Trade Action'));
      await tester.pumpAndSettle();

      expect(controller.sortCriteria?.columnId, equals('trade'));
      expect(controller.sortCriteria?.direction, equals(SortDirection.ascending));
      expect(controller.getRowByDisplayIndex(0)['symbol'], equals('SYM2')); // 105.0
      expect(controller.getRowByDisplayIndex(1)['symbol'], equals('SYM1')); // 250.0
      expect(controller.getRowByDisplayIndex(2)['symbol'], equals('SYM3')); // 380.0

      // 2. Sort Descending by Trade Action (Price)
      await tester.tap(find.text('Trade Action'));
      await tester.pumpAndSettle();

      expect(controller.sortCriteria?.direction, equals(SortDirection.descending));
      expect(controller.getRowByDisplayIndex(0)['symbol'], equals('SYM3')); // 380.0
      expect(controller.getRowByDisplayIndex(1)['symbol'], equals('SYM1')); // 250.0
      expect(controller.getRowByDisplayIndex(2)['symbol'], equals('SYM2')); // 105.0

      controller.dispose();
    });

    testWidgets('Realtime tick update updates AppGridButton text with 0 root rebuilds', (tester) async {
      var rootBuilds = 0;

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'symbol': 'AAPL', 'price': 150.0, 'change': 0.0},
        ],
        columns: [
          GridColumn(id: 'symbol', label: 'Symbol', valueGetter: (r) => r['symbol']),
          GridColumn(
            id: 'trade',
            label: 'Trade',
            valueGetter: (r) => r['price'],
            cellBuilder: (context, item, info) => Center(
              child: AppGridButton(
                text: 'Buy \$${(item['price'] as num).toStringAsFixed(2)}',
                onPressed: () {},
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rootBuilds++;
                return SizedBox(
                  width: 400,
                  height: 300,
                  child: AppGrid<Map<String, dynamic>>(
                    controller: controller,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(rootBuilds, equals(1));
      expect(find.text('Buy \$150.00'), findsOneWidget);

      // Simulate streaming tick
      controller.updateRow(0, {'symbol': 'AAPL', 'price': 155.50, 'change': 5.50});
      await tester.pump();

      // Verify button reflects new price
      expect(find.text('Buy \$155.50'), findsOneWidget);
      // Zero root rebuilds!
      expect(rootBuilds, equals(1));

      controller.dispose();
    });
  });
}
