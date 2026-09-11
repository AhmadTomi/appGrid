import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  group('AppGrid Loading Overlay Tests', () {
    testWidgets('Header stays visible and loading overlay renders when isLoading is true on empty dataset', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: const [],
        columns: [
          GridColumn(id: 'name', label: 'Item Name', initialWidth: 200, valueGetter: (r) => r['name']),
          GridColumn(id: 'price', label: 'Price', initialWidth: 150, valueGetter: (r) => r['price']),
        ],
        isLoading: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              emptyWidget: const Text('No records found'),
            ),
          ),
        ),
      );

      await tester.pump();

      // Headers must be visible!
      expect(find.text('Item Name'), findsOneWidget);
      expect(find.text('Price'), findsOneWidget);

      // Loading overlay should be visible
      expect(find.byType(AppGridLoadingOverlay), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // emptyWidget must NOT be rendered while actively loading
      expect(find.text('No records found'), findsNothing);

      // When async data arrives and setData() is called:
      controller.setData([
        {'name': 'Apple', 'price': 10},
        {'name': 'Orange', 'price': 15},
      ]);
      await tester.pumpAndSettle();

      // Loading overlay disappears and rows are visible
      expect(controller.isLoading, isFalse);
      expect(find.byType(AppGridLoadingOverlay), findsNothing);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Orange'), findsOneWidget);
    });

    testWidgets('Direct isLoading property on AppGrid toggles loading overlay on top of existing data', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: const [
          {'name': 'Banana', 'price': 5},
        ],
        columns: [
          GridColumn(id: 'name', label: 'Item Name', initialWidth: 200, valueGetter: (r) => r['name']),
          GridColumn(id: 'price', label: 'Price', initialWidth: 150, valueGetter: (r) => r['price']),
        ],
      );

      bool isLoadingState = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => isLoadingState = !isLoadingState),
                      child: const Text('Toggle Loading'),
                    ),
                    Expanded(
                      child: AppGrid<Map<String, dynamic>>(
                        controller: controller,
                        isLoading: isLoadingState,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Initially not loading, row is visible
      expect(find.byType(AppGridLoadingOverlay), findsNothing);
      expect(find.text('Banana'), findsOneWidget);

      // Toggle loading to true
      await tester.tap(find.text('Toggle Loading'));
      await tester.pump();

      // Both Banana (underneath) and LoadingOverlay (on top) are present
      expect(find.byType(AppGridLoadingOverlay), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      // Toggle loading back to false
      await tester.tap(find.text('Toggle Loading'));
      await tester.pumpAndSettle();

      expect(find.byType(AppGridLoadingOverlay), findsNothing);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('Custom loadingWidget is rendered when provided', (tester) async {
      final controller = AppGridController<Map<String, dynamic>>(
        initialData: const [],
        columns: const [
          GridColumn(id: 'col1', label: 'Col 1', initialWidth: 200),
        ],
        isLoading: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppGrid<Map<String, dynamic>>(
              controller: controller,
              loadingWidget: const Center(
                child: Text('Custom Loading Skeleton...'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Custom Loading Skeleton...'), findsOneWidget);
      expect(find.byType(AppGridLoadingOverlay), findsNothing);
    });
  });
}
