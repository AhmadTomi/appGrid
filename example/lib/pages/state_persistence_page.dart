import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class StatePersistencePage extends StatefulWidget {
  const StatePersistencePage({super.key});

  @override
  State<StatePersistencePage> createState() => _StatePersistencePageState();
}

typedef StatePersistenceDemo = StatePersistencePage;

class _StatePersistencePageState extends State<StatePersistencePage> {
  late final AppGridController<Map<String, dynamic>> _controller;
  String _savedJson = '';

  @override
  void initState() {
    super.initState();
    _controller = AppGridController<Map<String, dynamic>>(
      initialData: [
        {'id': 1, 'name': 'Item 1', 'price': 99},
        {'id': 2, 'name': 'Item 2', 'price': 149},
      ],
      columns: [
        GridColumn(id: 'id', label: 'ID', initialWidth: 100, valueGetter: (r) => r['id']),
        GridColumn(id: 'name', label: 'Name', initialWidth: 180, valueGetter: (r) => r['name']),
        GridColumn(id: 'price', label: 'Price', initialWidth: 140, valueGetter: (r) => r['price']),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildDemoHeader(
            title: 'Selective State Persistence (AC-05)',
            subtitle: 'REQ-STATE-03 Strict Invariant: Serializes columnOrder, sortCriteria, columnVisibility. NO widths allowed.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {
                  final state = _controller.exportState();
                  setState(() => _savedJson = state.toJson());
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export State JSON'),
              ),
              OutlinedButton.icon(
                onPressed: _savedJson.isEmpty
                    ? null
                    : () {
                        final restored = GridState.fromJson(_savedJson);
                        _controller.restoreState(restored);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('State restored successfully!')));
                      },
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('Restore State'),
              ),
            ],
          ),
          if (_savedJson.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _savedJson,
                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<Map<String, dynamic>>(
              controller: _controller,
            ),
          ),
        ],
      ),
    );
  }
}

const String statePersistenceSnippet = '''// REQ-STATE-01, 02, 03 & AC-05: State Persistence
// STRICT INVARIANT: Column widths are NEVER saved to persistence.

// 1. Export state (strictly: columnOrder, sortCriteria, columnVisibility)
final GridState state = controller.exportState();
final String jsonString = state.toJson();
// jsonString contains NO 'width' or 'columnWidth' keys!

// 2. Restore state:
final GridState importedState = GridState.fromJson(jsonString);
controller.restoreState(importedState);''';
