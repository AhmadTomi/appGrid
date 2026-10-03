import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('AppGridFooterSpanItem unit tests', () {
    test('computes default span items (span = 1)', () {
      final cols = [
        const GridColumn(id: 'c1', label: 'C1', initialWidth: 100),
        const GridColumn(id: 'c2', label: 'C2', initialWidth: 120),
        const GridColumn(id: 'c3', label: 'C3', initialWidth: 80),
      ];
      final groups = CompactColumnGroup.buildGroups(columns: cols, compactMode: false);
      final widths = {'c1': 100.0, 'c2': 120.0, 'c3': 80.0};
      final offsets = {'c1': 0.0, 'c2': 100.0, 'c3': 220.0};

      final items = AppGridFooterSpanItem.computeSpanItems(
        groups: groups,
        widths: widths,
        offsets: offsets,
      );

      expect(items.length, equals(3));
      expect(items[0].column.id, equals('c1'));
      expect(items[0].width, equals(100.0));
      expect(items[0].offset, equals(0.0));
      expect(items[0].spanCount, equals(1));

      expect(items[1].column.id, equals('c2'));
      expect(items[1].width, equals(120.0));
      expect(items[1].offset, equals(100.0));

      expect(items[2].column.id, equals('c3'));
      expect(items[2].width, equals(80.0));
      expect(items[2].offset, equals(220.0));
    });

    test('computes merged span items across multiple columns', () {
      final cols = [
        const GridColumn(id: 'c1', label: 'C1', initialWidth: 100),
        const GridColumn(id: 'c2', label: 'C2', initialWidth: 80, footerSpan: 3),
        const GridColumn(id: 'c3', label: 'C3', initialWidth: 70),
        const GridColumn(id: 'c4', label: 'C4', initialWidth: 90),
        const GridColumn(id: 'c5', label: 'C5', initialWidth: 110),
      ];
      final groups = CompactColumnGroup.buildGroups(columns: cols, compactMode: false);
      final widths = {'c1': 100.0, 'c2': 80.0, 'c3': 70.0, 'c4': 90.0, 'c5': 110.0};
      final offsets = {'c1': 0.0, 'c2': 100.0, 'c3': 180.0, 'c4': 250.0, 'c5': 340.0};

      final items = AppGridFooterSpanItem.computeSpanItems(
        groups: groups,
        widths: widths,
        offsets: offsets,
      );

      // c1 (span 1), c2 (spans c2, c3, c4), c5 (span 1) -> total 3 items
      expect(items.length, equals(3));

      expect(items[0].column.id, equals('c1'));
      expect(items[0].width, equals(100.0));
      expect(items[0].offset, equals(0.0));

      expect(items[1].column.id, equals('c2'));
      expect(items[1].width, equals(80.0 + 70.0 + 90.0)); // 240.0
      expect(items[1].offset, equals(100.0));
      expect(items[1].spanCount, equals(3));

      expect(items[2].column.id, equals('c5'));
      expect(items[2].width, equals(110.0));
      expect(items[2].offset, equals(340.0));
      expect(items[2].spanCount, equals(1));
    });

    test('clamps span that exceeds remaining columns count', () {
      final cols = [
        const GridColumn(id: 'c1', label: 'C1', initialWidth: 100),
        const GridColumn(id: 'c2', label: 'C2', initialWidth: 80, footerSpan: 10),
        const GridColumn(id: 'c3', label: 'C3', initialWidth: 70),
      ];
      final groups = CompactColumnGroup.buildGroups(columns: cols, compactMode: false);
      final widths = {'c1': 100.0, 'c2': 80.0, 'c3': 70.0};
      final offsets = {'c1': 0.0, 'c2': 100.0, 'c3': 180.0};

      final items = AppGridFooterSpanItem.computeSpanItems(
        groups: groups,
        widths: widths,
        offsets: offsets,
      );

      expect(items.length, equals(2));
      expect(items[1].column.id, equals('c2'));
      expect(items[1].width, equals(80.0 + 70.0)); // 150.0
      expect(items[1].spanCount, equals(2));
    });
  });

  group('AppGrid Footer ColSpan & Alignment Widget Tests', () {
    testWidgets('renders financial orderbook style footer with centered span',
        (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'b_vol': 100, 'bid': 500, 'offer': 505, 'o_vol': 120},
          {'b_vol': 200, 'bid': 495, 'offer': 510, 'o_vol': 150},
        ],
        columns: [
          GridColumn(
            id: 'left_action',
            label: '-',
            initialWidth: 60,
            pin: GridColumnPin.left,
            footerBuilder: (context, data) => const Text('0/0'),
          ),
          GridColumn(
            id: 'b_vol',
            label: 'B.vol',
            initialWidth: 100,
            footerSpan: 4,
            footerAlignment: Alignment.center,
            footerBuilder: (context, data) =>
                const Text('Total Speed Order', key: Key('speed_order_footer')),
          ),
          const GridColumn(id: 'bid', label: 'Bid', initialWidth: 100),
          const GridColumn(id: 'offer', label: 'Offer', initialWidth: 100),
          const GridColumn(id: 'o_vol', label: 'O.Vol', initialWidth: 100),
          GridColumn(
            id: 'right_action',
            label: '-',
            initialWidth: 60,
            pin: GridColumnPin.right,
            footerBuilder: (context, data) => const Text('0/0'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              autoStretch: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the spanned footer widget is present
      final speedOrderFinder = find.byKey(const Key('speed_order_footer'));
      expect(speedOrderFinder, findsOneWidget);

      // Verify the parent AppGridFooterCell has width 400 (4 * 100)
      final footerCellFinder = find.ancestor(
        of: speedOrderFinder,
        matching: find.byType(AppGridFooterCell),
      );
      expect(footerCellFinder, findsOneWidget);
      final footerCell = tester.widget<AppGridFooterCell>(footerCellFinder);
      expect(footerCell.width, equals(400.0));
      expect(footerCell.column.footerSpan, equals(4));
      expect(footerCell.column.footerAlignment, equals(Alignment.center));

      // Verify left and right pinned footers
      expect(find.text('0/0'), findsNWidgets(2));

      controller.dispose();
    });

    testWidgets('footerAlignment aligns content correctly (centerRight, center, centerLeft)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'val1': 10, 'val2': 20},
        ],
        columns: [
          GridColumn(
            id: 'val1',
            label: 'Val 1',
            initialWidth: 150,
            footerAlignment: Alignment.centerRight,
            footerBuilder: (context, data) => const Text('Right Aligned', key: Key('right_footer')),
          ),
          GridColumn(
            id: 'val2',
            label: 'Val 2',
            initialWidth: 150,
            footerAlignment: Alignment.centerLeft,
            footerBuilder: (context, data) => const Text('Left Aligned', key: Key('left_footer')),
          ),
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

      expect(find.byKey(const Key('right_footer')), findsOneWidget);
      expect(find.byKey(const Key('left_footer')), findsOneWidget);

      final rightContainerFinder = find.ancestor(
        of: find.byKey(const Key('right_footer')),
        matching: find.byType(Container),
      );
      final leftContainerFinder = find.ancestor(
        of: find.byKey(const Key('left_footer')),
        matching: find.byType(Container),
      );

      final rightContainer = tester.widget<Container>(rightContainerFinder.first);
      final leftContainer = tester.widget<Container>(leftContainerFinder.first);

      expect(rightContainer.alignment, equals(Alignment.centerRight));
      expect(leftContainer.alignment, equals(Alignment.centerLeft));

      controller.dispose();
    });

    testWidgets('spanned footer scrolls horizontally in lockstep with columns',
        (tester) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 8 center columns of 100px each = 800px total in a 400px viewport
      // Columns 2, 3, 4, 5 are spanned by c2 (span: 4, width: 400)
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'c0': 1},
        ],
        columns: [
          const GridColumn(id: 'c0', label: 'C0', initialWidth: 100),
          const GridColumn(id: 'c1', label: 'C1', initialWidth: 100),
          GridColumn(
            id: 'c2',
            label: 'C2',
            initialWidth: 100,
            footerSpan: 4,
            footerBuilder: (context, data) =>
                const Text('Spanned Center', key: Key('spanned_center')),
          ),
          const GridColumn(id: 'c3', label: 'C3', initialWidth: 100),
          const GridColumn(id: 'c4', label: 'C4', initialWidth: 100),
          const GridColumn(id: 'c5', label: 'C5', initialWidth: 100),
          const GridColumn(id: 'c6', label: 'C6', initialWidth: 100),
          const GridColumn(id: 'c7', label: 'C7', initialWidth: 100),
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

      // At hScroll = 0, c2 starts at offset 200, so it's visible in 400px viewport
      expect(find.byKey(const Key('spanned_center')), findsOneWidget);

      // Drag/scroll horizontally to offset 250
      await tester.drag(find.byType(AppGrid<Map<String, dynamic>>), const Offset(-250, 0));
      await tester.pumpAndSettle();

      // Spanned item starts at 200 and ends at 600, at scroll 250 it is still visible
      expect(find.byKey(const Key('spanned_center')), findsOneWidget);

      controller.dispose();
    });

    testWidgets('spanned footer expands dynamically with autoStretch',
        (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Total initial = 60 + 400 + 60 = 520px. Viewport = 800px.
      // AutoStretch expands center columns proportionally.
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'b_vol': 100},
        ],
        columns: [
          GridColumn(
            id: 'left_action',
            label: '-',
            initialWidth: 60,
            pin: GridColumnPin.left,
            footerBuilder: (context, data) => const Text('0/0'),
          ),
          GridColumn(
            id: 'b_vol',
            label: 'B.vol',
            initialWidth: 100,
            footerSpan: 4,
            footerAlignment: Alignment.center,
            footerBuilder: (context, data) =>
                const Text('Dynamic Stretched Footer', key: Key('dynamic_footer')),
          ),
          const GridColumn(id: 'bid', label: 'Bid', initialWidth: 100),
          const GridColumn(id: 'offer', label: 'Offer', initialWidth: 100),
          const GridColumn(id: 'o_vol', label: 'O.Vol', initialWidth: 100),
          GridColumn(
            id: 'right_action',
            label: '-',
            initialWidth: 60,
            pin: GridColumnPin.right,
            footerBuilder: (context, data) => const Text('0/0'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              autoStretch: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dynamicFooterFinder = find.byKey(const Key('dynamic_footer'));
      expect(dynamicFooterFinder, findsOneWidget);

      final footerCellFinder = find.ancestor(
        of: dynamicFooterFinder,
        matching: find.byType(AppGridFooterCell),
      );
      final footerCell = tester.widget<AppGridFooterCell>(footerCellFinder);

      // Total stretched center pane width is ~615.38 (greater than 400.0)
      expect(footerCell.width, greaterThan(400.0));

      controller.dispose();
    });
  });
}
