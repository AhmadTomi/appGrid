import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Keyboard Navigation Tests (REQ-NAV-01 & AC-04)', () {
    testWidgets('ArrowDown, ArrowUp, Home, End, PageDown navigate selection properly', (tester) async {
      // 100 rows, rowHeight: 50, viewportHeight: 500 (10 visible rows per page)
      final items = List.generate(100, (i) => 'Item $i');
      RowIndexInfo? lastSelectedInfo;

      final controller = AppGridController<String>(
        initialData: items,
        columns: const [
          GridColumn(id: 'col', label: 'Items', initialWidth: 300),
        ],
        onRowSelected: (info) => lastSelectedInfo = info,
      );

      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 550, // 50 header + 500 body
              child: AppGrid<String>(
                controller: controller,
                focusNode: focusNode,
                rowHeight: 50.0,
                headerHeight: 50.0,
                cellBuilder: (context, item, info, colId) => Text(item),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      focusNode.requestFocus();
      await tester.pump();

      // 1. Initial selection via ArrowDown -> row 0
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(0));
      expect(lastSelectedInfo?.displayIndex, equals(0));

      // 2. ArrowDown -> row 1
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(1));

      // 3. ArrowUp -> back to row 0
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(0));

      // 4. AC-04: PageDown -> viewportHeight (500) / rowHeight (50) = 10 rows shift
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(10));
      expect(lastSelectedInfo?.displayIndex, equals(10));

      // Another PageDown -> shifts by 10 rows to row 20
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(20));

      // 5. End -> jumps to the very last row (index 99)
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(99));

      // 6. Home -> jumps to the very first row (index 0)
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(0));

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('Tapping on a row or grid automatically requests focus and enables keyboard navigation', (tester) async {
      final items = List.generate(50, (i) => 'Row $i');
      final controller = AppGridController<String>(
        initialData: items,
        columns: const [
          GridColumn(id: 'col', label: 'Items', initialWidth: 300),
        ],
      );
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 500,
              child: AppGrid<String>(
                controller: controller,
                focusNode: focusNode,
                autofocus: false, // verify click-to-focus works even when autofocus is false
                rowHeight: 50.0,
                headerHeight: 50.0,
                cellBuilder: (context, item, info, colId) => Text(item),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isFalse);

      // Tap on Row 2
      await tester.tap(find.text('Row 2'));
      await tester.pump();

      // Verify grid acquired focus and selected row 2
      expect(focusNode.hasFocus, isTrue);
      expect(controller.selectedDisplayIndex, equals(2));

      // Now ArrowDown should immediately navigate to Row 3
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(3));

      // ArrowUp should navigate back to Row 2
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(2));

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('autofocus: true automatically acquires focus on mount', (tester) async {
      final items = List.generate(20, (i) => 'Item $i');
      final controller = AppGridController<String>(
        initialData: items,
        columns: const [
          GridColumn(id: 'col', label: 'Items', initialWidth: 300),
        ],
      );
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 500,
              child: AppGrid<String>(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                rowHeight: 50.0,
                headerHeight: 50.0,
                cellBuilder: (context, item, info, colId) => Text(item),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      // ArrowDown without any click -> selects row 0
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(0));

      // Numpad2 (Down) -> selects row 1
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad2);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(1));

      // Numpad8 (Up) -> back to row 0
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad8);
      await tester.pump();
      expect(controller.selectedDisplayIndex, equals(0));

      controller.dispose();
      focusNode.dispose();
    });
  });
}
