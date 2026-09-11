import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('Column Layout & Auto-Stretch Tests (REQ-COL-05 & AC-06)', () {
    test('AC-06: Columns auto-stretch proportionally when sum(minWidth) < ViewportWidth', () {
      const calculator = AutoStretchCalculator();
      const columns = [
        GridColumn(id: 'col1', label: 'C1', minWidth: 100, initialWidth: 100),
        GridColumn(id: 'col2', label: 'C2', minWidth: 200, initialWidth: 200),
        GridColumn(id: 'col3', label: 'C3', minWidth: 200, initialWidth: 200),
      ];

      // Sum of minWidths is 500px, available viewport is 1000px (500 < 1000)
      final widths = calculator.calculateWidths(
        columns: columns,
        availableViewportWidth: 1000.0,
      );

      // Proportion: 100/500 = 20% -> 200px
      // 200/500 = 40% -> 400px
      // 200/500 = 40% -> 400px
      expect(widths['col1'], closeTo(200.0, 0.01));
      expect(widths['col2'], closeTo(400.0, 0.01));
      expect(widths['col3'], closeTo(400.0, 0.01));

      // Sum of all widths MUST exactly equal 1000.0 (no blank canvas!)
      final totalCalculated = widths.values.fold(0.0, (sum, w) => sum + w);
      expect(totalCalculated, closeTo(1000.0, 0.001));
    });

    test('Disables auto-stretch when sum(minWidth) exceeds or equals screen width', () {
      const calculator = AutoStretchCalculator();
      const columns = [
        GridColumn(id: 'col1', label: 'C1', minWidth: 300, initialWidth: 300),
        GridColumn(id: 'col2', label: 'C2', minWidth: 300, initialWidth: 300),
        GridColumn(id: 'col3', label: 'C3', minWidth: 300, initialWidth: 300),
      ];

      // Sum of minWidths is 900px, available screen is 600px (900 >= 600)
      // Must NOT auto-stretch; retain natural base widths for horizontal scroll!
      final widths = calculator.calculateWidths(
        columns: columns,
        availableViewportWidth: 600.0,
      );

      expect(widths['col1'], equals(300.0));
      expect(widths['col2'], equals(300.0));
      expect(widths['col3'], equals(300.0));

      final total = widths.values.fold(0.0, (sum, w) => sum + w);
      expect(total, equals(900.0)); // exceeds 600px -> triggers horizontal scroll!
    });

    test('Disables auto-stretch when user resizes any column manually', () {
      const calculator = AutoStretchCalculator();
      const columns = [
        GridColumn(id: 'col1', label: 'C1', minWidth: 100, initialWidth: 100),
        GridColumn(id: 'col2', label: 'C2', minWidth: 100, initialWidth: 100),
      ];

      // Available screen is 500px.
      // Initially, without manual resize: stretches to fill 500px (250px each).
      final initialWidths = calculator.calculateWidths(
        columns: columns,
        availableViewportWidth: 500.0,
      );
      expect(initialWidths['col1'], equals(250.0));
      expect(initialWidths['col2'], equals(250.0));

      // User manually resizes col1 to 180px:
      final userResizedWidths = {'col1': 180.0};
      final manualWidths = calculator.calculateWidths(
        columns: columns,
        availableViewportWidth: 500.0,
        userResizedWidths: userResizedWidths,
      );

      // Auto-stretch must be DISABLED: col1 stays 180, col2 stays 100 (base width)
      expect(manualWidths['col1'], equals(180.0));
      expect(manualWidths['col2'], equals(100.0));
    });

    test('Clamps column resize to minWidth and maxWidth', () {
      final manager = ColumnLayoutManager();
      const column = GridColumn(
        id: 'col1',
        label: 'C1',
        minWidth: 80.0,
        maxWidth: 300.0,
        initialWidth: 120.0,
      );

      // Attempt to resize below minWidth
      manager.resizeColumn(column: column, newWidth: 40.0);
      expect(manager.getUserResizedWidth('col1'), equals(80.0));

      // Attempt to resize above maxWidth
      manager.resizeColumn(column: column, newWidth: 500.0);
      expect(manager.getUserResizedWidth('col1'), equals(300.0));

      // Valid resize
      manager.resizeColumn(column: column, newWidth: 220.0);
      expect(manager.getUserResizedWidth('col1'), equals(220.0));
      expect(manager.hasManualResize, isTrue);

      // Reset widths clears manual overrides
      manager.resetWidths();
      expect(manager.getUserResizedWidth('col1'), isNull);
      expect(manager.hasManualResize, isFalse);
    });
  });
}
