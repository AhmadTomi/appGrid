import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('AppGrid Read-Only Mode Tests', () {
    testWidgets('Clicking row in readOnly mode does not select and does not trigger onRowSelected', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      RowIndexInfo? selectedInfo;
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': '1', 'name': 'Alpha'},
          {'id': '2', 'name': 'Beta'},
          {'id': '3', 'name': 'Gamma'},
        ],
        columns: [
          GridColumn(
            id: 'id',
            label: 'ID',
            initialWidth: 100,
            valueGetter: (row) => row['id'],
          ),
          GridColumn(
            id: 'name',
            label: 'Name',
            initialWidth: 200,
            valueGetter: (row) => row['name'],
          ),
        ],
        onRowSelected: (info) => selectedInfo = info,
      );

      const selectedColor = Color(0xFF00FF00);
      const evenColor = Color(0xFFFFFFFF);
      const oddColor = Color(0xFFF5F5F5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              readOnly: true,
              selectedRowColor: selectedColor,
              evenRowColor: evenColor,
              oddRowColor: oddColor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on row 0
      final row0TextFinder = find.text('Alpha');
      expect(row0TextFinder, findsOneWidget);
      await tester.tap(row0TextFinder);
      await tester.pumpAndSettle();

      // Verification: Row should NOT be selected
      expect(controller.selectedOriginalIndex, isNull);
      expect(controller.selectedDisplayIndex, isNull);
      expect(controller.selectedRowInfo, isNull);
      expect(selectedInfo, isNull);

      // Verify row decoration does NOT have selectedColor
      final rowWidgets = tester.widgetList<RowWidget<Map<String, dynamic>>>(
        find.byType(RowWidget<Map<String, dynamic>>),
      ).toList();
      final row0 = rowWidgets.firstWhere((r) => r.indexInfo.displayIndex == 0);
      expect(row0.isSelected, isFalse);

      final containerFinder = find.descendant(
        of: find.byWidget(row0),
        matching: find.byType(Container),
      );
      final container0 = tester.widget<Container>(containerFinder.first);
      final boxDec0 = container0.decoration as BoxDecoration;
      expect(boxDec0.color, equals(evenColor));
      expect(boxDec0.color, isNot(equals(selectedColor)));
    });

    testWidgets('Keyboard navigation does not select rows in readOnly mode', (tester) async {
      final items = List.generate(20, (i) => 'Item $i');
      RowIndexInfo? selectedInfo;

      final controller = AppGridController<String>(
        initialData: items,
        columns: const [
          GridColumn(id: 'col', label: 'Items', initialWidth: 300),
        ],
        onRowSelected: (info) => selectedInfo = info,
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
                readOnly: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      focusNode.requestFocus();
      await tester.pump();

      // Attempt ArrowDown navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(controller.selectedDisplayIndex, isNull);
      expect(selectedInfo, isNull);

      // Attempt PageDown navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(controller.selectedDisplayIndex, isNull);
      expect(selectedInfo, isNull);

      // Attempt Home & End navigation
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(controller.selectedDisplayIndex, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(controller.selectedDisplayIndex, isNull);
    });

    test('AppGridController isReadOnly disables selectRow and selectRowByOriginalIndex', () {
      final controller = AppGridController<String>(
        initialData: ['A', 'B', 'C'],
        columns: const [GridColumn(id: 'c', label: 'C')],
        isReadOnly: true,
      );

      expect(controller.isReadOnly, isTrue);

      controller.selectRow(0);
      expect(controller.selectedDisplayIndex, isNull);
      expect(controller.selectedOriginalIndex, isNull);
      expect(controller.selectedRowInfo, isNull);

      controller.selectRowByOriginalIndex(1);
      expect(controller.selectedDisplayIndex, isNull);
      expect(controller.selectedOriginalIndex, isNull);
      expect(controller.selectedRowInfo, isNull);
    });

    testWidgets('Toggling controller.isReadOnly dynamically clears active selection and updates UI', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<String>(
        initialData: ['Row 0', 'Row 1', 'Row 2'],
        columns: [
          GridColumn(
            id: 'col',
            label: 'Label',
            initialWidth: 200,
            cellBuilder: (context, item, info) => Text('$item'),
          ),
        ],
      );

      const selectedColor = Color(0xFFFF0000);
      const evenColor = Color(0xFFFFFFFF);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<String>(
              controller: controller,
              selectedRowColor: selectedColor,
              evenRowColor: evenColor,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initially select row 0
      controller.selectRow(0);
      await tester.pumpAndSettle();
      expect(controller.selectedDisplayIndex, equals(0));

      // Verify row 0 has selectedColor
      var rowWidgets = tester.widgetList<RowWidget<String>>(
        find.byType(RowWidget<String>),
      ).toList();
      var row0 = rowWidgets.firstWhere((r) => r.indexInfo.displayIndex == 0);
      expect(row0.isSelected, isTrue);

      var containerFinder = find.descendant(
        of: find.byWidget(row0),
        matching: find.byType(Container),
      );
      var boxDec0 = tester.widget<Container>(containerFinder.first).decoration as BoxDecoration;
      expect(boxDec0.color, equals(selectedColor));

      // 2. Enable isReadOnly on controller
      controller.isReadOnly = true;
      await tester.pumpAndSettle();

      // Selection must be cleared
      expect(controller.selectedDisplayIndex, isNull);
      expect(controller.selectedOriginalIndex, isNull);

      // Verify row 0 no longer has selectedColor
      rowWidgets = tester.widgetList<RowWidget<String>>(
        find.byType(RowWidget<String>),
      ).toList();
      row0 = rowWidgets.firstWhere((r) => r.indexInfo.displayIndex == 0);
      expect(row0.isSelected, isFalse);

      containerFinder = find.descendant(
        of: find.byWidget(row0),
        matching: find.byType(Container),
      );
      boxDec0 = tester.widget<Container>(containerFinder.first).decoration as BoxDecoration;
      expect(boxDec0.color, equals(evenColor));
      expect(boxDec0.color, isNot(equals(selectedColor)));

      // 3. Disable isReadOnly on controller -> selection can be made again
      controller.isReadOnly = false;
      await tester.pumpAndSettle();

      await tester.tap(find.text('Row 1'));
      await tester.pumpAndSettle();
      expect(controller.selectedDisplayIndex, equals(1));
    });

    testWidgets('Toggling AppGrid(readOnly: true) via widget update clears selection and disables interactions', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<String>(
        initialData: ['Alpha', 'Beta'],
        columns: [
          GridColumn(
            id: 'c',
            label: 'C',
            initialWidth: 200,
            cellBuilder: (context, item, info) => Text('$item'),
          ),
        ],
      );

      const selectedColor = Color(0xFF123456);

      bool isReadOnly = false;
      late void Function(bool readOnly) updateReadOnly;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateReadOnly = (v) => setState(() => isReadOnly = v);
                return AppGrid<String>(
                  controller: controller,
                  readOnly: isReadOnly,
                  selectedRowColor: selectedColor,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select row 0
      controller.selectRow(0);
      await tester.pumpAndSettle();
      expect(controller.selectedDisplayIndex, equals(0));

      // Switch to readOnly: true
      updateReadOnly(true);
      await tester.pumpAndSettle();

      expect(controller.selectedDisplayIndex, isNull);
      expect(controller.selectedOriginalIndex, isNull);

      // Attempt tapping row 1
      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      expect(controller.selectedDisplayIndex, isNull);
    });

    testWidgets('Pinned freeze columns do not select row when readOnly is true', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'pinned': 'PIN_1', 'center': 'CENTER_1'},
        ],
        columns: [
          GridColumn(id: 'pinned', label: 'Pinned', initialWidth: 120, pin: GridColumnPin.left, valueGetter: (row) => row['pinned']),
          GridColumn(id: 'center', label: 'Center', initialWidth: 250, valueGetter: (row) => row['center']),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              readOnly: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the pinned column cell
      await tester.tap(find.text('PIN_1'));
      await tester.pumpAndSettle();

      expect(controller.selectedDisplayIndex, isNull);
      expect(controller.selectedOriginalIndex, isNull);
    });
  });
}
