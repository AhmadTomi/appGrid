import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

class TestUser {
  final String id;
  final String name;
  final int age;

  const TestUser({required this.id, required this.name, required this.age});

  TestUser copyWith({String? name, int? age}) {
    return TestUser(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestUser && id == other.id && name == other.name && age == other.age;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ age.hashCode;
}

void main() {
  group('Row & Cell Update Helper API Tests', () {
    late AppGridController<TestUser> controller;

    setUp(() {
      controller = AppGridController<TestUser>(
        initialData: [
          const TestUser(id: 'u1', name: 'Alice', age: 25),
          const TestUser(id: 'u2', name: 'Bob', age: 30),
          const TestUser(id: 'u3', name: 'Charlie', age: 35),
        ],
        columns: [
          GridColumn(id: 'id', label: 'ID', valueGetter: (u) => (u as TestUser).id),
          GridColumn(id: 'name', label: 'Name', valueGetter: (u) => (u as TestUser).name),
          GridColumn(id: 'age', label: 'Age', valueGetter: (u) => (u as TestUser).age),
        ],
        rowIdGetter: (user) => user.id,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('updateRow() updates dataset and notifies row listener directly', () {
      final notifier = controller.getRowNotifier(1); // Bob
      var notificationCount = 0;
      notifier.addListener(() => notificationCount++);

      controller.updateRow(1, const TestUser(id: 'u2', name: 'Robert', age: 31));

      expect(controller.getRowByOriginalIndex(1).name, equals('Robert'));
      expect(controller.getRowByOriginalIndex(1).age, equals(31));
      expect(notificationCount, equals(1));
    });

    test('updateRowAtDisplayIndex() updates row by visual sequence post-sort', () {
      // Sort descending by age: Charlie (35), Bob (30), Alice (25)
      controller.sortByColumn('age', direction: SortDirection.descending);
      expect(controller.getRowByDisplayIndex(0).name, equals('Charlie'));

      // Update visual row 0 (Charlie)
      controller.updateRowAtDisplayIndex(
        0,
        const TestUser(id: 'u3', name: 'Charles', age: 36),
      );

      expect(controller.getRowByDisplayIndex(0).name, equals('Charles'));
      expect(controller.getRowByOriginalIndex(2).name, equals('Charles'));
    });

    test('updateRowById() finds item by id and updates without looping cells manually', () {
      controller.updateRowById(
        'u1',
        const TestUser(id: 'u1', name: 'Alicia', age: 26),
      );

      expect(controller.getRowByOriginalIndex(0).name, equals('Alicia'));
      expect(controller.getRowByOriginalIndex(0).age, equals(26));
    });

    test('patchRow() modifies existing state functionally', () {
      controller.patchRow(2, (user) => user.copyWith(age: 40));

      expect(controller.getRowByOriginalIndex(2).name, equals('Charlie'));
      expect(controller.getRowByOriginalIndex(2).age, equals(40));
    });

    test('updateRowWhere() updates rows matching condition', () {
      controller.updateRowWhere(
        (user) => user.age >= 30,
        (user) => user.copyWith(name: '${user.name} (Senior)'),
      );

      expect(controller.getRowByOriginalIndex(0).name, equals('Alice')); // unchanged
      expect(controller.getRowByOriginalIndex(1).name, equals('Bob (Senior)'));
      expect(controller.getRowByOriginalIndex(2).name, equals('Charlie (Senior)'));
    });
  });
}
