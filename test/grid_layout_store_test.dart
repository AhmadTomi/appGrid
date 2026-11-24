import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

void main() {
  const layout = GridColumnLayout(
    columnOrder: ['a', 'b'],
    columnVisibility: {'b': false},
  );

  group('InMemoryGridLayoutStore', () {
    test('read returns what was written and null after remove', () {
      final store = InMemoryGridLayoutStore();
      expect(store.read('orders'), isNull);
      store.write('orders', layout);
      expect(store.read('orders'), layout);
      expect(store.read('other'), isNull);
      store.remove('orders');
      expect(store.read('orders'), isNull);
    });
  });

  group('AppGridLayoutScope', () {
    testWidgets('maybeOf returns the store under a scope and null without one',
        (tester) async {
      final store = InMemoryGridLayoutStore();
      GridLayoutStore? inside;
      GridLayoutStore? outside;

      await tester.pumpWidget(Column(
        textDirection: TextDirection.ltr,
        children: [
          Builder(builder: (context) {
            outside = AppGridLayoutScope.maybeOf(context);
            return const SizedBox();
          }),
          AppGridLayoutScope(
            store: store,
            child: Builder(builder: (context) {
              inside = AppGridLayoutScope.maybeOf(context);
              return const SizedBox();
            }),
          ),
        ],
      ));

      expect(inside, same(store));
      expect(outside, isNull);
    });
  });
}
