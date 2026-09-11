import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_grid/app_grid.dart';

class Employee {
  final int id;
  final String name;
  final String department;

  const Employee({required this.id, required this.name, required this.department});
}

void main() {
  group('DataGridExporter Tests (REQ-DATA-02)', () {
    late AppGridController<Employee> controller;

    setUp(() {
      controller = AppGridController<Employee>(
        initialData: const [
          Employee(id: 1, name: 'John Doe', department: 'Engineering'),
          Employee(id: 2, name: 'Jane, "Admin"', department: 'HR & Operations'),
        ],
        columns: [
          GridColumn(id: 'id', label: 'ID', valueGetter: (r) => (r as Employee).id),
          GridColumn(id: 'name', label: 'Name', valueGetter: (r) => (r as Employee).name),
          GridColumn(id: 'department', label: 'Dept', valueGetter: (r) => (r as Employee).department),
        ],
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('toCsv generates RFC 4180 compliant CSV escaping quotes and commas', () {
      final csv = DataGridExporter.toCsv(controller: controller);
      final lines = csv.trim().split('\n').map((l) => l.trim()).toList();

      expect(lines.length, equals(3)); // header + 2 rows
      expect(lines[0], equals('ID,Name,Dept'));
      expect(lines[1], equals('1,John Doe,Engineering'));
      expect(lines[2], equals('2,"Jane, ""Admin""",HR & Operations'));
    });

    test('toJson generates structured JSON array of records', () {
      final jsonStr = DataGridExporter.toJson(controller: controller);
      final list = jsonDecode(jsonStr) as List<dynamic>;

      expect(list.length, equals(2));
      expect(list[0]['id'], equals(1));
      expect(list[0]['name'], equals('John Doe'));
      expect(list[1]['id'], equals(2));
      expect(list[1]['name'], equals('Jane, "Admin"'));
    });
  });
}
