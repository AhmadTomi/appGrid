import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Column Visibility & Header Menu Tests', () {
    testWidgets('Header menu displays Hide Column and Manage Columns options', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Alpha', 'role': 'Admin'},
        ],
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100),
          GridColumn(id: 'name', label: 'Name', initialWidth: 120),
          GridColumn(id: 'role', label: 'Role', initialWidth: 120),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the column menu for 'Name' column (using unfold_more or more_vert icon)
      final menuButtons = find.byIcon(Icons.unfold_more);
      expect(menuButtons, findsWidgets);

      await tester.tap(menuButtons.at(1));
      await tester.pumpAndSettle();

      // Verify "Hide Column" and "Manage Columns..." are present
      expect(find.text('Hide Column'), findsOneWidget);
      expect(find.text('Manage Columns...'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Tapping Hide Column hides the column and updates state persistence', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Alpha', 'role': 'Admin'},
        ],
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100),
          GridColumn(id: 'name', label: 'Name', initialWidth: 120),
          GridColumn(id: 'role', label: 'Role', initialWidth: 120),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.visibleColumns.map((c) => c.id).toList(), equals(['id', 'name', 'role']));

      // Open menu on 'Name' column (at index 1)
      final menuButtons = find.byIcon(Icons.unfold_more);
      await tester.tap(menuButtons.at(1));
      await tester.pumpAndSettle();

      // Tap "Hide Column"
      await tester.tap(find.text('Hide Column'));
      await tester.pumpAndSettle();

      // Verify 'name' is hidden
      expect(controller.visibleColumns.map((c) => c.id).toList(), equals(['id', 'role']));

      // Verify exportState captures visibility
      final state = controller.exportState();
      expect(state.columnVisibility['name'], isFalse);
      expect(state.columnVisibility['id'], isTrue);
      expect(state.columnVisibility['role'], isTrue);

      controller.dispose();
    });

    testWidgets('Manage Columns dialog allows toggling visibility back on', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Alpha', 'role': 'Admin'},
        ],
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100),
          GridColumn(id: 'name', label: 'Name', initialWidth: 120),
          GridColumn(id: 'role', label: 'Role', initialWidth: 120),
        ],
      );

      // Hide 'name' initially
      controller.setColumnVisibility('name', false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.visibleColumns.map((c) => c.id).toList(), equals(['id', 'role']));

      // Open menu on 'ID' column
      final menuButtons = find.byIcon(Icons.unfold_more);
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      // Tap "Manage Columns..."
      await tester.tap(find.text('Manage Columns...'));
      await tester.pumpAndSettle();

      // Verify Dialog is open
      expect(find.text('Manage Columns'), findsOneWidget);
      expect(find.text('2 of 3 visible'), findsOneWidget);

      // Tap checkbox for 'Name' to make it visible again
      final nameCheckbox = find.widgetWithText(CheckboxListTile, 'Name');
      expect(nameCheckbox, findsOneWidget);
      await tester.tap(nameCheckbox);
      await tester.pumpAndSettle();

      // 'name' is now visible
      expect(controller.visibleColumns.map((c) => c.id).toList(), equals(['id', 'name', 'role']));

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Manage Columns'), findsNothing);

      controller.dispose();
    });

    testWidgets('Cannot hide the last remaining visible column', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        columns: const [
          GridColumn(id: 'only_col', label: 'Only Column', initialWidth: 100),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open menu on 'only_col'
      final menuButtons = find.byIcon(Icons.unfold_more);
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      // Verify "Hide Column" is disabled
      final hideItem = tester.widget(
        find.ancestor(
          of: find.text('Hide Column'),
          matching: find.byWidgetPredicate((w) => w is PopupMenuItem),
        ),
      ) as PopupMenuItem;
      expect(hideItem.enabled, isFalse);

      // Dismiss menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      controller.dispose();
    });

    test('State Persistence roundtrip preserves column visibility strictly without width keys', () {
      final controller = AppGridController<Map<String, dynamic>>(
        columns: const [
          GridColumn(id: 'c1', label: 'Col 1'),
          GridColumn(id: 'c2', label: 'Col 2'),
          GridColumn(id: 'c3', label: 'Col 3'),
        ],
      );

      controller.setColumnVisibility('c2', false);

      final state = controller.exportState();
      final jsonStr = state.toJson();

      // Strict REQ-STATE-03: No width keys
      expect(jsonStr.contains('width'), isFalse);

      // Create new controller and restore
      final controller2 = AppGridController<Map<String, dynamic>>(
        columns: const [
          GridColumn(id: 'c1', label: 'Col 1'),
          GridColumn(id: 'c2', label: 'Col 2'),
          GridColumn(id: 'c3', label: 'Col 3'),
        ],
      );

      controller2.restoreState(GridState.fromJson(jsonStr));

      expect(controller2.visibleColumns.map((c) => c.id).toList(), equals(['c1', 'c3']));

      controller.dispose();
      controller2.dispose();
    });

    testWidgets('Manage Columns overlay only blocks the table and does not block external UI', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Alpha'},
        ],
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100),
          GridColumn(id: 'name', label: 'Name', initialWidth: 120),
        ],
      );

      bool externalButtonClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ElevatedButton(
                  onPressed: () => externalButtonClicked = true,
                  child: const Text('External Header Button'),
                ),
                Expanded(
                  child: AppGrid<Map<String, dynamic>>(controller: controller),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Column Chooser
      controller.openColumnChooser();
      await tester.pumpAndSettle();

      // Verify Column Chooser is open inside AppGrid
      expect(find.text('Manage Columns'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppGrid<Map<String, dynamic>>),
          matching: find.byType(AppGridColumnChooserOverlay<Map<String, dynamic>>),
        ),
        findsOneWidget,
      );

      // Verify external button is still interactive and can be clicked
      await tester.tap(find.text('External Header Button'));
      await tester.pumpAndSettle();
      expect(externalButtonClicked, isTrue);

      // Verify clicking the barrier over the table dismisses the overlay
      // Find top-left area inside AppGrid (e.g. over header)
      final gridBox = tester.getRect(find.byType(AppGrid<Map<String, dynamic>>));
      await tester.tapAt(Offset(gridBox.left + 20, gridBox.top + 20));
      await tester.pumpAndSettle();

      expect(find.text('Manage Columns'), findsNothing);
      expect(controller.isColumnChooserOpen, isFalse);

      controller.dispose();
    });

    testWidgets('GridColumn(canHide: false) disables hiding across header menu, dialog, and controller', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: [
          {'id': 1, 'name': 'Alpha', 'role': 'Admin'},
        ],
        columns: const [
          GridColumn(id: 'id', label: 'ID', initialWidth: 100, canHide: false),
          GridColumn(id: 'name', label: 'Name', initialWidth: 120, canHide: true),
          GridColumn(id: 'role', label: 'Role', initialWidth: 120, canHide: true),
        ],
      );

      // 1. Controller rejects programmatic hiding of unhideable column
      controller.setColumnVisibility('id', false);
      expect(controller.visibleColumns.map((c) => c.id).contains('id'), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Map<String, dynamic>>(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 2. Open header menu on 'ID' column (index 0)
      final menuButtons = find.byIcon(Icons.unfold_more);
      await tester.tap(menuButtons.first);
      await tester.pumpAndSettle();

      // "Hide Column" must NOT be in the menu for 'id' column
      expect(find.text('Hide Column'), findsNothing);
      expect(find.text('Manage Columns...'), findsOneWidget);

      // 3. Open Manage Columns dialog
      await tester.tap(find.text('Manage Columns...'));
      await tester.pumpAndSettle();

      expect(find.text('Manage Columns'), findsOneWidget);
      expect(find.text('Required column (cannot be hidden)'), findsOneWidget);

      // Checkbox for 'ID' should be disabled
      final idTileFinder = find.widgetWithText(CheckboxListTile, 'ID');
      final idTile = tester.widget<CheckboxListTile>(idTileFinder);
      expect(idTile.onChanged, isNull);
      expect(idTile.value, isTrue);

      // Dismiss dialog
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // 4. State restoration cannot hide a canHide: false column
      final maliciousState = GridState.fromJson(
        '{"columnOrder":["id","name","role"],"columnVisibility":{"id":false,"name":true,"role":true}}',
      );
      controller.restoreState(maliciousState);
      expect(controller.visibleColumns.map((c) => c.id).contains('id'), isTrue);

      controller.dispose();
    });
  });
}
