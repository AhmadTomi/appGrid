import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

class Product {
  final String id;
  final String title;
  final double price;

  const Product({required this.id, required this.title, required this.price});

  Product copyWith({String? title, double? price}) {
    return Product(
      id: id,
      title: title ?? this.title,
      price: price ?? this.price,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && id == other.id && title == other.title && price == other.price;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ price.hashCode;
}

void main() {
  group('Automatic Virtualized Diffing Tests (updateData)', () {
    late AppGridController<Product> controller;

    setUp(() {
      controller = AppGridController<Product>(
        initialData: [
          const Product(id: 'p1', title: 'Laptop', price: 999.0),
          const Product(id: 'p2', title: 'Mouse', price: 29.0),
          const Product(id: 'p3', title: 'Keyboard', price: 79.0),
        ],
        columns: [
          GridColumn(id: 'id', label: 'ID', valueGetter: (p) => (p as Product).id),
          GridColumn(id: 'title', label: 'Title', valueGetter: (p) => (p as Product).title),
          GridColumn(id: 'price', label: 'Price', valueGetter: (p) => (p as Product).price),
        ],
        rowIdGetter: (p) => p.id,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Content update: updates row notifier directly WITHOUT notifying controller listeners', () {
      final notifier = controller.getRowNotifier(1); // Mouse
      var notifierFired = 0;
      notifier.addListener(() => notifierFired++);

      var controllerFired = 0;
      controller.addListener(() => controllerFired++);

      // Update Mouse price from 29 to 35
      final updatedList = [
        const Product(id: 'p1', title: 'Laptop', price: 999.0),
        const Product(id: 'p2', title: 'Mouse', price: 35.0),
        const Product(id: 'p3', title: 'Keyboard', price: 79.0),
      ];

      controller.updateData(updatedList);

      // Verify row notifier fired
      expect(notifierFired, equals(1));
      expect(controller.getRowByOriginalIndex(1).price, equals(35.0));

      // CRITICAL: Controller did NOT call notifyListeners (no full-grid rebuild, 60 FPS maintained!)
      expect(controllerFired, equals(0));
    });

    test('Content update: unchanged rows do NOT trigger their notifiers', () {
      final p1Notifier = controller.getRowNotifier(0);
      final p2Notifier = controller.getRowNotifier(1);
      var p1Fired = 0;
      var p2Fired = 0;
      p1Notifier.addListener(() => p1Fired++);
      p2Notifier.addListener(() => p2Fired++);

      // Only change p2
      final updatedList = [
        const Product(id: 'p1', title: 'Laptop', price: 999.0),
        const Product(id: 'p2', title: 'Mouse', price: 40.0),
        const Product(id: 'p3', title: 'Keyboard', price: 79.0),
      ];

      controller.updateData(updatedList);

      expect(p1Fired, equals(0)); // p1 was not changed!
      expect(p2Fired, equals(1)); // only p2 changed!
    });

    test('Structural addition: handles different length and triggers controller notification', () {
      var controllerFired = 0;
      controller.addListener(() => controllerFired++);

      final updatedList = [
        const Product(id: 'p1', title: 'Laptop', price: 999.0),
        const Product(id: 'p2', title: 'Mouse', price: 29.0),
        const Product(id: 'p3', title: 'Keyboard', price: 79.0),
        const Product(id: 'p4', title: 'Monitor', price: 299.0),
      ];

      controller.updateData(updatedList);

      expect(controller.originalRowCount, equals(4));
      expect(controller.displayRowCount, equals(4));
      expect(controller.getRowByOriginalIndex(3).title, equals('Monitor'));
      expect(controllerFired, equals(1));
    });

    test('Structural deletion: handles shorter length and prunes out-of-bound notifiers', () {
      final p3Notifier = controller.getRowNotifier(2); // index 2
      expect(p3Notifier.value.title, equals('Keyboard'));

      var controllerFired = 0;
      controller.addListener(() => controllerFired++);

      // Delete item 2
      final updatedList = [
        const Product(id: 'p1', title: 'Laptop', price: 999.0),
        const Product(id: 'p2', title: 'Mouse', price: 29.0),
      ];

      controller.updateData(updatedList);

      expect(controller.originalRowCount, equals(2));
      expect(controller.displayRowCount, equals(2));
      expect(controllerFired, equals(1));
    });

    test('Selection preservation: keeps selection on the same item ID when list is shifted', () {
      // Select index 1 (Mouse: 'p2')
      controller.selectRow(1);
      expect(controller.selectedRowInfo?.originalIndex, equals(1));
      expect(controller.getRowByOriginalIndex(controller.selectedOriginalIndex!).id, equals('p2'));

      // Insert new item at index 0 (shifts 'p2' to index 2)
      final shiftedList = [
        const Product(id: 'p0', title: 'Desk Pad', price: 15.0),
        const Product(id: 'p1', title: 'Laptop', price: 999.0),
        const Product(id: 'p2', title: 'Mouse', price: 29.0),
        const Product(id: 'p3', title: 'Keyboard', price: 79.0),
      ];

      controller.updateData(shiftedList);

      // Selected original index should now track 'p2' at index 2!
      expect(controller.selectedOriginalIndex, equals(2));
      expect(controller.getRowByOriginalIndex(controller.selectedOriginalIndex!).id, equals('p2'));
    });

    test('Custom rowEquality predicate forces or overrides equality check', () {
      final notifier = controller.getRowNotifier(0);
      var fired = 0;
      notifier.addListener(() => fired++);

      // Even if objects are equal, custom equality returning false forces update
      final sameList = [
        const Product(id: 'p1', title: 'Laptop', price: 999.0),
        const Product(id: 'p2', title: 'Mouse', price: 29.0),
        const Product(id: 'p3', title: 'Keyboard', price: 79.0),
      ];

      controller.updateData(sameList, rowEquality: (a, b) => false);

      expect(fired, equals(1));
    });
  });

  group('Declarative AppGrid(data: ...) Widget Tests', () {
    testWidgets('AppGrid automatically updates and renders when new data list is provided', (tester) async {
      final controller = AppGridController<Product>(
        columns: [
          GridColumn(id: 'title', label: 'Title', valueGetter: (p) => (p as Product).title),
          GridColumn(id: 'price', label: 'Price', valueGetter: (p) => '\$${(p as Product).price}'),
        ],
        rowIdGetter: (p) => p.id,
      );

      final initialList = [
        const Product(id: 'p1', title: 'Laptop', price: 999.0),
        const Product(id: 'p2', title: 'Mouse', price: 25.0),
      ];

      Widget buildHost(List<Product> items) {
        return MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 400,
              child: AppGrid<Product>(
                controller: controller,
                data: items,
              ),
            ),
          ),
        );
      }

      // Initial build
      await tester.pumpWidget(buildHost(initialList));
      await tester.pumpAndSettle();

      expect(find.text('Laptop'), findsOneWidget);
      expect(find.text('\$25.0'), findsOneWidget);

      // Rebuild with updated price
      final updatedList = [
        const Product(id: 'p1', title: 'Laptop', price: 999.0),
        const Product(id: 'p2', title: 'Mouse', price: 30.0),
      ];

      await tester.pumpWidget(buildHost(updatedList));
      await tester.pump();

      expect(find.text('\$30.0'), findsOneWidget);
      expect(find.text('\$25.0'), findsNothing);

      // Rebuild with structural row addition
      final extendedList = [
        const Product(id: 'p1', title: 'Laptop', price: 999.0),
        const Product(id: 'p2', title: 'Mouse', price: 30.0),
        const Product(id: 'p3', title: 'Keyboard', price: 80.0),
      ];

      await tester.pumpWidget(buildHost(extendedList));
      await tester.pumpAndSettle();

      expect(find.text('Keyboard'), findsOneWidget);
      expect(find.text('\$80.0'), findsOneWidget);

      controller.dispose();
    });
  });
}
