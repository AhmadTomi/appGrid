import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class ExportUtilsPage extends StatefulWidget {
  const ExportUtilsPage({super.key});

  @override
  State<ExportUtilsPage> createState() => _ExportUtilsPageState();
}

typedef ExportUtilsDemo = ExportUtilsPage;

class _ExportUtilsPageState extends State<ExportUtilsPage> {
  late final AppGridController<Map<String, dynamic>> _controller;
  String _exportPreview = '';

  @override
  void initState() {
    super.initState();
    _controller = AppGridController<Map<String, dynamic>>(
      initialData: [
        {'id': 1, 'name': 'Acme, "Widgets" Inc.', 'country': 'USA'},
        {'id': 2, 'name': 'Globex Corporation', 'country': 'Canada'},
        {'id': 3, 'name': 'Soylent, Corp', 'country': 'UK'},
      ],
      columns: [
        GridColumn(id: 'id', label: 'ID', valueGetter: (r) => r['id']),
        GridColumn(id: 'name', label: 'Company Name', valueGetter: (r) => r['name']),
        GridColumn(id: 'country', label: 'Country', valueGetter: (r) => r['country']),
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
            title: 'CSV & JSON Data Exporters (REQ-DATA-02)',
            subtitle: 'Built-in RFC 4180 CSV escaping and formatted JSON exports for active display data.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {
                  final csv = DataGridExporter.toCsv(controller: _controller);
                  setState(() => _exportPreview = csv);
                },
                icon: const Icon(Icons.table_view, size: 16),
                label: const Text('Export to CSV (RFC 4180)'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final jsonStr = DataGridExporter.toJson(controller: _controller, pretty: true);
                  setState(() => _exportPreview = jsonStr);
                },
                icon: const Icon(Icons.code, size: 16),
                label: const Text('Export to JSON'),
              ),
            ],
          ),
          if (_exportPreview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _exportPreview,
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

const String exportUtilsSnippet = '''// REQ-DATA-02: CSV & JSON Exporters

// 1. Export active sorted/filtered display data to CSV (RFC 4180)
final String csv = DataGridExporter.toCsv(
  controller: controller,
  includeHeaders: true,
  delimiter: ',',
);

// 2. Export active display data to JSON
final String jsonString = DataGridExporter.toJson(
  controller: controller,
  pretty: true,
);''';
