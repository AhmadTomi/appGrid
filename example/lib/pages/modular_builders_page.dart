import 'package:flutter/material.dart';
import 'package:app_grid/app_grid.dart';
import '../widgets/demo_header.dart';

class FruitData {
  final String name;
  final String category;
  final int total;
  final double price;
  final String? note;

  const FruitData({
    required this.name,
    required this.category,
    required this.total,
    required this.price,
    this.note,
  });
}

class ModularBuildersPage extends StatefulWidget {
  const ModularBuildersPage({super.key});

  @override
  State<ModularBuildersPage> createState() => _ModularBuildersPageState();
}

typedef ModularBuildersDemo = ModularBuildersPage;

class _ModularBuildersPageState extends State<ModularBuildersPage> {
  static const List<FruitData> _sampleFruits = [
    FruitData(name: 'Honeycrisp Apple', category: 'Orchard', total: 140, price: 2.99, note: 'Fresh Harvest'),
    FruitData(name: 'Cavendish Banana', category: 'Tropical', total: 250, price: 0.69, note: 'Fair Trade'),
    FruitData(name: 'Valencia Orange', category: 'Citrus', total: 180, price: 1.49, note: 'High Vitamin C'),
    FruitData(name: 'Alphonso Mango', category: 'Tropical', total: 75, price: 3.50, note: 'Seasonal Premium'),
    FruitData(name: 'Sweet Strawberry', category: 'Berry', total: 95, price: 4.20, note: null),
    FruitData(name: 'Wild Blueberry', category: 'Berry', total: 110, price: 4.99, note: 'Antioxidant Rich'),
    FruitData(name: 'Crimson Watermelon', category: 'Melon', total: 40, price: 5.99, note: null),
    FruitData(name: 'Golden Pineapple', category: 'Tropical', total: 60, price: 3.29, note: 'Extra Sweet'),
    FruitData(name: 'Hass Avocado', category: 'Specialty', total: 130, price: 1.89, note: 'Ripe & Ready'),
    FruitData(name: 'White Peach', category: 'Stone Fruit', total: 85, price: 2.79, note: null),
    FruitData(name: 'Autumn Crisp Grape', category: 'Berry', total: 120, price: 3.89, note: 'Seedless'),
    FruitData(name: 'Golden Kiwi', category: 'Exotic', total: 90, price: 1.25, note: 'New Zealand'),
  ];

  late final AppGridController<FruitData> _controller;
  bool _showEmptyState = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = AppGridController<FruitData>(
      fetchMode: DataFetchMode.pagination,
      paginationInfo: const GridPaginationInfo(page: 1, limit: 6, totalCount: 12),
      initialData: _sampleFruits.take(6).toList(),
      columns: [
        GridColumn(
          id: 'name',
          label: 'Fruit Name',
          initialWidth: 180,
          minWidth: 140,
          footerBuilder: GridFooter.count(prefix: 'Total: ', suffix: ' types'),
          cellBuilder: (context, fruit, info) {
            final f = fruit as FruitData;
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.eco, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        GridColumn(
          id: 'category',
          label: 'Category',
          initialWidth: 130,
          minWidth: 100,
          cellBuilder: (context, fruit, info) {
            final f = fruit as FruitData;
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  f.category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          },
        ),
        GridColumn(
          id: 'total',
          label: 'Stock (pcs)',
          initialWidth: 130,
          minWidth: 100,
          footerBuilder: GridFooter.sum<FruitData>(
            (f) => f.total,
            prefix: 'Sum: ',
            suffix: ' pcs',
          ),
          cellBuilder: (context, fruit, info) {
            final f = fruit as FruitData;
            final isLow = f.total < 80;
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    '${f.total} pcs',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLow ? Colors.orange : null,
                    ),
                  ),
                  if (isLow) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
                  ],
                ],
              ),
            );
          },
        ),
        GridColumn(
          id: 'price',
          label: 'Price',
          initialWidth: 120,
          minWidth: 90,
          footerBuilder: GridFooter.average<FruitData>(
            (f) => f.price,
            prefix: 'Avg: \$',
            precision: 2,
          ),
          cellBuilder: (context, fruit, info) {
            final f = fruit as FruitData;
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '\$${f.price.toStringAsFixed(2)}',
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600),
              ),
            );
          },
        ),
        GridColumn(
          id: 'note',
          label: 'Special Note',
          initialWidth: 150,
          minWidth: 110,
          valueGetter: (f) => (f as FruitData).note,
        ),
      ],
    );
  }

  void _onPageChanged(int page, int pageSize) {
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, _sampleFruits.length);
    final slice = _sampleFruits.sublist(start.clamp(0, _sampleFruits.length), end);

    _controller.setPageData(
      rows: slice,
      pagination: GridPaginationInfo(
        page: page,
        limit: pageSize,
        totalCount: _sampleFruits.length,
      ),
    );
  }

  void _toggleEmptyState() {
    setState(() {
      _showEmptyState = !_showEmptyState;
      if (_showEmptyState) {
        _controller.setPageData(
          rows: [],
          pagination: const GridPaginationInfo(page: 1, limit: 6, totalCount: 0),
        );
      } else {
        _onPageChanged(1, 6);
      }
    });
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
            title: 'Modular Column Builders, Summaries & Header Context Menu',
            subtitle: 'Declare cellBuilder, footer summaries (GridFooter.sum / average / count), and header freeze right on GridColumn.',
          ),
          const SizedBox(height: 12),
          // Interactive Action Toolbar
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _toggleEmptyState,
                icon: Icon(_showEmptyState ? Icons.refresh : Icons.hourglass_empty),
                label: Text(_showEmptyState ? 'Restore Fruit Data' : 'Simulate Empty State'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.withAlpha(100)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.more_vert, size: 16, color: Colors.amber),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Click column sort/menu icon to freeze/unpin or sort',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.withAlpha(100)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pan_tool, size: 16, color: Colors.blue),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Click-drag mouse to pan/scroll table 2D',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AppGrid<FruitData>(
              controller: _controller,
              rowHeight: 44.0,
              headerHeight: 44.0,
              footerHeight: 40.0,
              showPaginationBar: true,
              onPageChanged: _onPageChanged,
              emptyWidget: const AppGridEmptyWidget(
                message: 'No fruit records found. Tap "Restore Fruit Data" to reload catalog.',
                icon: Icons.search_off,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const String modularBuildersSnippet = r'''// Custom Data Model (e.g. List<FruitData>)
class FruitData {
  final String name;
  final String category;
  final int total;
  final double price;
  final String? note;

  const FruitData({
    required this.name,
    required this.category,
    required this.total,
    required this.price,
    this.note,
  });
}

// 1. Controller with Modular Column Builders, Header Builders & Footer Summaries:
final controller = AppGridController<FruitData>(
  initialData: fruits,
  columns: [
    GridColumn(
      id: 'name',
      label: 'Fruit Name',
      // Column-level custom header builder:
      headerBuilder: (context, sortDirection, onToggle) => Row(
        children: [
          const Icon(Icons.eco, size: 16, color: Colors.green),
          const SizedBox(width: 6),
          const Text('Fruit Name', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      // Column-level custom cell builder:
      cellBuilder: (context, fruit, info) => Row(
        children: [
          const Icon(Icons.eco, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(fruit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      // Declarative footer summary:
      footerBuilder: GridFooter.count(prefix: 'Total: ', suffix: ' types'),
    ),
    GridColumn(
      id: 'total',
      label: 'Total Stock',
      cellBuilder: (context, fruit, info) => Text('${fruit.total} pcs'),
      // Declarative 1-line column sum calculation:
      footerBuilder: GridFooter.sum<FruitData>((f) => f.total, prefix: 'Sum: ', suffix: ' pcs'),
    ),
    GridColumn(
      id: 'price',
      label: 'Unit Price',
      // Declarative average calculation:
      footerBuilder: GridFooter.average<FruitData>((f) => f.price, prefix: 'Avg: \$', precision: 2),
    ),
    GridColumn(
      id: 'note',
      label: 'Quality / Note',
      valueGetter: (f) => (f as FruitData).note, // Null values automatically render EmptyCell ('—')
    ),
  ],
);

// 2. High-Performance AppGrid with Built-In Addons:
AppGrid<FruitData>(
  controller: controller,
  showPaginationBar: true, // Integrated production-ready pagination bar
  emptyWidget: const AppGridEmptyWidget(
    message: 'No fruit records found. Try adjusting filters or reload data.',
  ),
  // Tip: Right-click any column header to freeze to left/right or unpin!
);''';
