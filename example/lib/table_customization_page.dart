import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_grid/app_grid.dart';

/// Product item model for the customization demo dataset.
class InventoryItem {
  final String sku;
  final String name;
  final String category;
  final int stock;
  final double price;
  final double rating;
  final String status;

  const InventoryItem({
    required this.sku,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    required this.rating,
    required this.status,
  });
}

/// Pre-configured color presets for instant styling showcase.
enum GridThemePreset {
  corporateNavy('Corporate Navy', Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFFE2E8F0), Color(0xFFF8FAFC), Color(0xFFFFFFFF), Color(0xFFBAE6FD)),
  emeraldForest('Emerald Forest', Color(0xFF064E3B), Color(0xFF022C22), Color(0xFFA7F3D0), Color(0xFFF0FDF4), Color(0xFFFFFFFF), Color(0xFF6EE7B7)),
  sunsetAmber('Sunset Amber', Color(0xFF7C2D12), Color(0xFF431407), Color(0xFFFED7AA), Color(0xFFFFFBEB), Color(0xFFFFFFFF), Color(0xFFFDE68A)),
  cyberDark('Cyber Dark', Color(0xFF18181B), Color(0xFF09090B), Color(0xFF27272A), Color(0xFF1F1F23), Color(0xFF141416), Color(0xFF3F3F46)),
  cleanLight('Clean Light', Color(0xFFF1F5F9), Color(0xFFCBD5E1), Color(0xFFE2E8F0), Color(0xFFF8FAFC), Color(0xFFFFFFFF), Color(0xFFE0E7FF)),
  monochromeDark('Monochrome Slate', Color(0xFF334155), Color(0xFF1E293B), Color(0xFF475569), Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF64748B)),
  custom('Custom', null, null, null, null, null, null);

  final String label;
  final Color? headerBg;
  final Color? border;
  final Color? gridLine;
  final Color? oddRow;
  final Color? evenRow;
  final Color? selection;

  const GridThemePreset(
    this.label,
    this.headerBg,
    this.border,
    this.gridLine,
    this.oddRow,
    this.evenRow,
    this.selection,
  );
}

/// A comprehensive interactive page demonstrating how to customize table colors,
/// container/scroll heights, row & header heights, borders, scrollbar styles,
/// and behavior toggles in real time.
class TableCustomizationPage extends StatefulWidget {
  final bool isStandalone;

  const TableCustomizationPage({super.key, this.isStandalone = true});

  @override
  State<TableCustomizationPage> createState() => _TableCustomizationPageState();
}

class _TableCustomizationPageState extends State<TableCustomizationPage> with SingleTickerProviderStateMixin {
  late final AppGridController<InventoryItem> _controller;
  late final TabController _tabController;

  // Active preset
  GridThemePreset _currentPreset = GridThemePreset.corporateNavy;

  // Colors
  late Color _headerBackgroundColor;
  late Color _borderColor;
  late Color _gridLineColor;
  late Color _evenRowColor;
  late Color _oddRowColor;
  late Color _selectedRowColor;
  bool _showHorizontalGridLines = true;
  bool _showVerticalGridLines = false;
  late Color _verticalGridLineColor;
  Color _scrollbarThumbColor = const Color(0xFF64748B);
  Color _scrollbarTrackColor = const Color(0x1A64748B);
  bool _useZebraStripes = true;

  // Heights & Dimensions ("scroll height etc")
  bool _isFixedHeight = false;
  double _tableContainerHeight = 360.0;
  double _rowHeight = 48.0;
  double _headerHeight = 48.0;
  double _footerHeight = 40.0;
  double _scrollbarThickness = 10.0;
  bool _showFooter = true;

  // Scroll & Behavior Toggles
  bool _autoStretch = true;
  bool _enableMouseDragScroll = true;
  AppGridScrollbarVisibility _horizontalScrollbarVisibility = AppGridScrollbarVisibility.onHover;
  AppGridScrollbarVisibility _verticalScrollbarVisibility = AppGridScrollbarVisibility.onHover;
  bool _useBouncingPhysics = false;
  bool _readOnly = false;

  static const List<InventoryItem> _sampleData = [
    InventoryItem(sku: 'SKU-001', name: 'MacBook Pro 16" M3 Max', category: 'Laptops', stock: 45, price: 3499.00, rating: 4.9, status: 'In Stock'),
    InventoryItem(sku: 'SKU-002', name: 'Dell UltraSharp 32 4K Monitor', category: 'Displays', stock: 18, price: 899.50, rating: 4.7, status: 'In Stock'),
    InventoryItem(sku: 'SKU-003', name: 'Sony WH-1000XM5 Headphones', category: 'Audio', stock: 82, price: 398.00, rating: 4.8, status: 'In Stock'),
    InventoryItem(sku: 'SKU-004', name: 'Logitech MX Master 3S Mouse', category: 'Accessories', stock: 120, price: 99.99, rating: 4.9, status: 'In Stock'),
    InventoryItem(sku: 'SKU-005', name: 'Keychron Q1 Pro Wireless Keyboard', category: 'Accessories', stock: 34, price: 199.00, rating: 4.6, status: 'In Stock'),
    InventoryItem(sku: 'SKU-006', name: 'Apple iPad Pro 13" M4 OLED', category: 'Tablets', stock: 12, price: 1299.00, rating: 4.9, status: 'Low Stock'),
    InventoryItem(sku: 'SKU-007', name: 'Samsung Galaxy Tab S9 Ultra', category: 'Tablets', stock: 8, price: 1199.99, rating: 4.5, status: 'Low Stock'),
    InventoryItem(sku: 'SKU-008', name: 'Elgato Stream Deck MK.2', category: 'Streaming', stock: 55, price: 149.99, rating: 4.7, status: 'In Stock'),
    InventoryItem(sku: 'SKU-009', name: 'Shure SM7B Vocal Microphone', category: 'Audio', stock: 24, price: 399.00, rating: 4.9, status: 'In Stock'),
    InventoryItem(sku: 'SKU-010', name: 'CalDigit TS4 Thunderbolt Dock', category: 'Docks', stock: 5, price: 399.95, rating: 4.8, status: 'Low Stock'),
    InventoryItem(sku: 'SKU-011', name: 'LG 27" UltraGear OLED Gaming Monitor', category: 'Displays', stock: 0, price: 799.00, rating: 4.6, status: 'Out of Stock'),
    InventoryItem(sku: 'SKU-012', name: 'Bose QuietComfort Ultra Earbuds', category: 'Audio', stock: 40, price: 299.00, rating: 4.4, status: 'In Stock'),
    InventoryItem(sku: 'SKU-013', name: 'Anker Prime 27,650mAh Power Bank', category: 'Power', stock: 95, price: 179.99, rating: 4.8, status: 'In Stock'),
    InventoryItem(sku: 'SKU-014', name: 'Razer Blade 16 Gaming Laptop', category: 'Laptops', stock: 6, price: 2999.99, rating: 4.5, status: 'Low Stock'),
    InventoryItem(sku: 'SKU-015', name: 'Herman Miller Embody Gaming Chair', category: 'Furniture', stock: 3, price: 1795.00, rating: 4.9, status: 'Low Stock'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _applyPresetColors(GridThemePreset.corporateNavy);

    _controller = AppGridController<InventoryItem>(
      initialData: _sampleData,
      columns: [
        GridColumn(
          id: 'sku',
          label: 'SKU',
          initialWidth: 100,
          minWidth: 80,
          valueGetter: (item) => (item as InventoryItem).sku,
          footerBuilder: GridFooter.count(prefix: 'Total: ', suffix: ' items'),
        ),
        GridColumn(
          id: 'name',
          label: 'Product Name',
          initialWidth: 230,
          minWidth: 160,
          valueGetter: (item) => (item as InventoryItem).name,
        ),
        GridColumn(
          id: 'category',
          label: 'Category',
          initialWidth: 130,
          minWidth: 100,
          valueGetter: (item) => (item as InventoryItem).category,
        ),
        GridColumn(
          id: 'stock',
          label: 'Stock Qty',
          initialWidth: 110,
          minWidth: 90,
          valueGetter: (item) => (item as InventoryItem).stock,
          footerBuilder: GridFooter.sum<InventoryItem>((item) => item.stock, prefix: 'Sum: '),
        ),
        GridColumn(
          id: 'price',
          label: 'Price (\$)',
          initialWidth: 120,
          minWidth: 90,
          valueGetter: (item) => (item as InventoryItem).price,
          footerBuilder: GridFooter.average<InventoryItem>((item) => item.price, prefix: 'Avg: \$', precision: 2),
          cellBuilder: (context, item, info) {
            final inv = item as InventoryItem;
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '\$${inv.price.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
              ),
            );
          },
        ),
        GridColumn(
          id: 'rating',
          label: 'Rating',
          initialWidth: 100,
          minWidth: 80,
          valueGetter: (item) => (item as InventoryItem).rating,
          cellBuilder: (context, item, info) {
            final inv = item as InventoryItem;
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${inv.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            );
          },
        ),
        GridColumn(
          id: 'status',
          label: 'Inventory Status',
          initialWidth: 140,
          minWidth: 110,
          valueGetter: (item) => (item as InventoryItem).status,
          cellBuilder: (context, item, info) {
            final inv = item as InventoryItem;
            final isOut = inv.status == 'Out of Stock';
            final isLow = inv.status == 'Low Stock';
            final color = isOut ? Colors.red : (isLow ? Colors.amber.shade800 : Colors.teal);
            return Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withAlpha(100), width: 0.8),
                ),
                child: Text(
                  inv.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _applyPresetColors(GridThemePreset preset) {
    setState(() {
      _currentPreset = preset;
      if (preset != GridThemePreset.custom) {
        _headerBackgroundColor = preset.headerBg!;
        _borderColor = preset.border!;
        _gridLineColor = preset.gridLine!;
        _verticalGridLineColor = preset.gridLine!;
        _oddRowColor = preset.oddRow!;
        _evenRowColor = preset.evenRow!;
        _selectedRowColor = preset.selection!;

        // Adjust scrollbar color to match theme
        if (preset == GridThemePreset.cyberDark || preset == GridThemePreset.monochromeDark) {
          _scrollbarThumbColor = const Color(0xFF71717A);
          _scrollbarTrackColor = const Color(0xFF27272A);
        } else if (preset == GridThemePreset.emeraldForest) {
          _scrollbarThumbColor = const Color(0xFF10B981);
          _scrollbarTrackColor = const Color(0xFFD1FAE5);
        } else if (preset == GridThemePreset.sunsetAmber) {
          _scrollbarThumbColor = const Color(0xFFF59E0B);
          _scrollbarTrackColor = const Color(0xFFFEF3C7);
        } else {
          _scrollbarThumbColor = const Color(0xFF64748B);
          _scrollbarTrackColor = const Color(0xFFE2E8F0);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Left: Live Table Preview Area
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPreviewArea(isFlexible: true),
                ),
              ),
              VerticalDivider(width: 1, color: Theme.of(context).dividerColor.withAlpha(60)),
              // 2. Right: Interactive Customization Controls Panel
              Expanded(
                flex: 4,
                child: _buildControlsPanel(),
              ),
            ],
          );
        } else {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreviewArea(isFlexible: false),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                SizedBox(
                  height: 540,
                  child: _buildControlsPanel(),
                ),
              ],
            ),
          );
        }
      },
    );

    if (widget.isStandalone) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Table Customization Studio'),
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Reset to Defaults',
              onPressed: () {
                _applyPresetColors(GridThemePreset.corporateNavy);
                setState(() {
                  _isFixedHeight = false;
                  _tableContainerHeight = 360.0;
                  _rowHeight = 48.0;
                  _headerHeight = 48.0;
                  _footerHeight = 40.0;
                  _scrollbarThickness = 10.0;
                  _showFooter = true;
                  _showHorizontalGridLines = true;
                  _showVerticalGridLines = false;
                  _verticalGridLineColor = const Color(0xFFE2E8F0);
                  _autoStretch = true;
                  _enableMouseDragScroll = true;
                  _horizontalScrollbarVisibility = AppGridScrollbarVisibility.onHover;
                  _verticalScrollbarVisibility = AppGridScrollbarVisibility.onHover;
                  _useBouncingPhysics = false;
                  _readOnly = false;
                });
              },
            ),
          ],
        ),
        body: body,
      );
    }

    return body;
  }

  Widget _buildPreviewArea({bool isFlexible = true}) {
    final theme = Theme.of(context);

    // Build the grid widget with all reactive customizations
    final gridWidget = AppGrid<InventoryItem>(
      controller: _controller,
      headerHeight: _headerHeight,
      rowHeight: _rowHeight,
      footerHeight: _showFooter ? _footerHeight : null,
      headerBackgroundColor: _headerBackgroundColor,
      borderColor: _borderColor,
      gridLineColor: _gridLineColor,
      showHorizontalGridLines: _showHorizontalGridLines,
      showVerticalGridLines: _showVerticalGridLines,
      verticalGridLineColor: _verticalGridLineColor,
      evenRowColor: _evenRowColor,
      oddRowColor: _useZebraStripes ? _oddRowColor : _evenRowColor,
      selectedRowColor: _selectedRowColor,
      readOnly: _readOnly,

      scrollbarThickness: _scrollbarThickness,
      scrollbarThumbColor: _scrollbarThumbColor,
      scrollbarTrackColor: _scrollbarTrackColor,
      horizontalScrollbarVisibility: _horizontalScrollbarVisibility,
      verticalScrollbarVisibility: _verticalScrollbarVisibility,
      autoStretch: _autoStretch,
      enableMouseDragScroll: _enableMouseDragScroll,
      physics: _useBouncingPhysics ? const BouncingScrollPhysics() : const ClampingScrollPhysics(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preset theme selection bar
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Theme Presets:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                for (final preset in GridThemePreset.values)
                  ChoiceChip(
                    label: Text(preset.label, style: const TextStyle(fontSize: 12)),
                    selected: _currentPreset == preset,
                    onSelected: (selected) {
                      if (selected) _applyPresetColors(preset);
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Live grid viewport: either fixed container scroll height or expanded
        if (_isFixedHeight || !isFlexible) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.height, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scroll Container Height: ${_tableContainerHeight.toInt()} px (Fixed Bounded Viewport)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _tableContainerHeight,
            child: gridWidget,
          ),
        ] else ...[
          Expanded(
            child: gridWidget,
          ),
        ],
      ],
    );
  }

  Widget _buildControlsPanel() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.palette_outlined, size: 18), text: 'Colors'),
            Tab(icon: Icon(Icons.straighten, size: 18), text: 'Heights & Sizing'),
            Tab(icon: Icon(Icons.touch_app_outlined, size: 18), text: 'Scroll & Toggles'),
            Tab(icon: Icon(Icons.code, size: 18), text: 'Code Snippet'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildColorsTab(),
              _buildDimensionsTab(),
              _buildScrollTogglesTab(),
              _buildCodeSnippetTab(),
            ],
          ),
        ),
      ],
    );
  }

  // 1. Colors Customization Tab
  Widget _buildColorsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Header & Borders'),
        _buildColorTile(
          title: 'Header Background',
          color: _headerBackgroundColor,
          onColorChanged: (c) => setState(() {
            _currentPreset = GridThemePreset.custom;
            _headerBackgroundColor = c;
          }),
        ),
        _buildColorTile(
          title: 'Outer Grid Border',
          color: _borderColor,
          onColorChanged: (c) => setState(() {
            _currentPreset = GridThemePreset.custom;
            _borderColor = c;
          }),
        ),
        SwitchListTile(
          dense: true,
          title: const Text('Show Horizontal Row Dividers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Render horizontal divider lines between rows', style: TextStyle(fontSize: 11)),
          value: _showHorizontalGridLines,
          onChanged: (v) => setState(() => _showHorizontalGridLines = v),
        ),
        if (_showHorizontalGridLines)
          _buildColorTile(
            title: 'Horizontal Row Divider Color',
            color: _gridLineColor,
            onColorChanged: (c) => setState(() {
              _currentPreset = GridThemePreset.custom;
              _gridLineColor = c;
            }),
          ),
        SwitchListTile(
          dense: true,
          title: const Text('Show Vertical Column Dividers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Render vertical divider lines between columns', style: TextStyle(fontSize: 11)),
          value: _showVerticalGridLines,
          onChanged: (v) => setState(() => _showVerticalGridLines = v),
        ),
        if (_showVerticalGridLines)
          _buildColorTile(
            title: 'Vertical Column Divider Color',
            color: _verticalGridLineColor,
            onColorChanged: (c) => setState(() {
              _currentPreset = GridThemePreset.custom;
              _verticalGridLineColor = c;
            }),
          ),
        const Divider(height: 24),
        _buildSectionHeader('Row & Selection Colors'),
        _buildColorTile(
          title: 'Even Row Background',
          color: _evenRowColor,
          onColorChanged: (c) => setState(() {
            _currentPreset = GridThemePreset.custom;
            _evenRowColor = c;
          }),
        ),
        SwitchListTile(
          dense: true,
          title: const Text('Enable Zebra Striping (Odd Rows)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Alternating background color on odd index rows', style: TextStyle(fontSize: 11)),
          value: _useZebraStripes,
          onChanged: (v) => setState(() => _useZebraStripes = v),
        ),
        if (_useZebraStripes)
          _buildColorTile(
            title: 'Odd Row (Zebra) Background',
            color: _oddRowColor,
            onColorChanged: (c) => setState(() {
              _currentPreset = GridThemePreset.custom;
              _oddRowColor = c;
            }),
          ),
        _buildColorTile(
          title: 'Selected Row Highlight',
          color: _selectedRowColor,
          onColorChanged: (c) => setState(() {
            _currentPreset = GridThemePreset.custom;
            _selectedRowColor = c;
          }),
        ),
        const Divider(height: 24),
        _buildSectionHeader('Scrollbar Colors'),
        _buildColorTile(
          title: 'Scrollbar Thumb Color',
          color: _scrollbarThumbColor,
          onColorChanged: (c) => setState(() {
            _currentPreset = GridThemePreset.custom;
            _scrollbarThumbColor = c;
          }),
        ),
        _buildColorTile(
          title: 'Scrollbar Track Color',
          color: _scrollbarTrackColor,
          onColorChanged: (c) => setState(() {
            _currentPreset = GridThemePreset.custom;
            _scrollbarTrackColor = c;
          }),
        ),
      ],
    );
  }

  // 2. Heights & Dimensions Customization Tab ("scroll height etc")
  Widget _buildDimensionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Table Container & Scroll Height'),
        SwitchListTile(
          dense: true,
          title: const Text('Constrain Viewport Height', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: Text(
            _isFixedHeight ? 'Fixed height container (${_tableContainerHeight.toInt()} px)' : 'Expand to fill available space',
            style: const TextStyle(fontSize: 11),
          ),
          value: _isFixedHeight,
          onChanged: (v) => setState(() => _isFixedHeight = v),
        ),
        if (_isFixedHeight) ...[
          _buildSlider(
            label: 'Container Scroll Height: ${_tableContainerHeight.toInt()} px',
            value: _tableContainerHeight,
            min: 200,
            max: 600,
            onChanged: (v) => setState(() => _tableContainerHeight = v),
          ),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(label: const Text('260 px (Compact)'), onPressed: () => setState(() => _tableContainerHeight = 260)),
              ActionChip(label: const Text('380 px (Medium)'), onPressed: () => setState(() => _tableContainerHeight = 380)),
              ActionChip(label: const Text('520 px (Tall)'), onPressed: () => setState(() => _tableContainerHeight = 520)),
            ],
          ),
        ],
        const Divider(height: 24),
        _buildSectionHeader('Row & Header Heights'),
        _buildSlider(
          label: 'Row Height: ${_rowHeight.toInt()} px',
          value: _rowHeight,
          min: 30,
          max: 76,
          onChanged: (v) => setState(() => _rowHeight = v),
        ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(label: const Text('34 px (Dense)'), onPressed: () => setState(() => _rowHeight = 34)),
            ActionChip(label: const Text('48 px (Standard)'), onPressed: () => setState(() => _rowHeight = 48)),
            ActionChip(label: const Text('64 px (Spacious)'), onPressed: () => setState(() => _rowHeight = 64)),
          ],
        ),
        const SizedBox(height: 12),
        _buildSlider(
          label: 'Header Height: ${_headerHeight.toInt()} px',
          value: _headerHeight,
          min: 32,
          max: 72,
          onChanged: (v) => setState(() => _headerHeight = v),
        ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(label: const Text('36 px'), onPressed: () => setState(() => _headerHeight = 36)),
            ActionChip(label: const Text('48 px'), onPressed: () => setState(() => _headerHeight = 48)),
            ActionChip(label: const Text('60 px'), onPressed: () => setState(() => _headerHeight = 60)),
          ],
        ),
        const Divider(height: 24),
        _buildSectionHeader('Footer & Scrollbar Sizing'),
        SwitchListTile(
          dense: true,
          title: const Text('Display Footer Bar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          value: _showFooter,
          onChanged: (v) => setState(() => _showFooter = v),
        ),
        if (_showFooter)
          _buildSlider(
            label: 'Footer Height: ${_footerHeight.toInt()} px',
            value: _footerHeight,
            min: 28,
            max: 60,
            onChanged: (v) => setState(() => _footerHeight = v),
          ),
        _buildSlider(
          label: 'Scrollbar Thickness: ${_scrollbarThickness.toInt()} px',
          value: _scrollbarThickness,
          min: 4,
          max: 18,
          onChanged: (v) => setState(() => _scrollbarThickness = v),
        ),
      ],
    );
  }

  // 3. Scroll & Physics Toggles Tab
  Widget _buildScrollTogglesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Interactive Scrolling Behaviors'),
        SwitchListTile(
          dense: true,
          title: const Text('Auto-Stretch Columns', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Stretches columns proportionally to fill available viewport width with zero empty space', style: TextStyle(fontSize: 11)),
          value: _autoStretch,
          onChanged: (v) => setState(() => _autoStretch = v),
        ),
        SwitchListTile(
          dense: true,
          title: const Text('Enable Mouse Drag Scroll', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Click and drag with mouse pointer anywhere on grid to pan 2D smoothly with ballistic inertia', style: TextStyle(fontSize: 11)),
          value: _enableMouseDragScroll,
          onChanged: (v) => setState(() => _enableMouseDragScroll = v),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Horizontal Scrollbar Visibility', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SegmentedButton<AppGridScrollbarVisibility>(
                segments: const [
                  ButtonSegment(
                    value: AppGridScrollbarVisibility.onHover,
                    label: Text('Hover (Default)', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.mouse_outlined, size: 14),
                  ),
                  ButtonSegment(
                    value: AppGridScrollbarVisibility.always,
                    label: Text('Always', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.visibility_outlined, size: 14),
                  ),
                  ButtonSegment(
                    value: AppGridScrollbarVisibility.hidden,
                    label: Text('Hide', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.visibility_off_outlined, size: 14),
                  ),
                ],
                selected: {_horizontalScrollbarVisibility},
                onSelectionChanged: (set) => setState(() => _horizontalScrollbarVisibility = set.first),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vertical Scrollbar Visibility', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SegmentedButton<AppGridScrollbarVisibility>(
                segments: const [
                  ButtonSegment(
                    value: AppGridScrollbarVisibility.onHover,
                    label: Text('Hover (Default)', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.mouse_outlined, size: 14),
                  ),
                  ButtonSegment(
                    value: AppGridScrollbarVisibility.always,
                    label: Text('Always', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.visibility_outlined, size: 14),
                  ),
                  ButtonSegment(
                    value: AppGridScrollbarVisibility.hidden,
                    label: Text('Hide', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.visibility_off_outlined, size: 14),
                  ),
                ],
                selected: {_verticalScrollbarVisibility},
                onSelectionChanged: (set) => setState(() => _verticalScrollbarVisibility = set.first),
              ),
            ],
          ),
        ),
        SwitchListTile(
          dense: true,
          title: const Text('Use Bouncing Scroll Physics', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('iOS-style bouncy physics vs standard Clamping scroll physics', style: TextStyle(fontSize: 11)),
          value: _useBouncingPhysics,
          onChanged: (v) => setState(() => _useBouncingPhysics = v),
        ),
        SwitchListTile(
          dense: true,
          title: const Text('Read-Only Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Completely disables row selection and hides selected row styling', style: TextStyle(fontSize: 11)),
          value: _readOnly,
          onChanged: (v) => setState(() => _readOnly = v),
        ),
      ],
    );
  }

  // 4. Live Dart Code Snippet Tab
  Widget _buildCodeSnippetTab() {
    final hexHeader = '#${_headerBackgroundColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final hexBorder = '#${_borderColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final hexGridLine = '#${_gridLineColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final hexVertical = '#${_verticalGridLineColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final hexEven = '#${_evenRowColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final hexOdd = '#${_oddRowColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final hexSelected = '#${_selectedRowColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final hexThumb = '#${_scrollbarThumbColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    final hexTrack = '#${_scrollbarTrackColor.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

    final code = '''// AppGrid Custom Styling & Sizing Configuration:
${_isFixedHeight ? '// 1. Bounded container for fixed scroll height:\nSizedBox(\n  height: ${_tableContainerHeight.toInt()}.0,\n  child: ' : ''}AppGrid<InventoryItem>(
  controller: controller,
  // Heights & Sizing:
  rowHeight: ${_rowHeight.toInt()}.0,
  headerHeight: ${_headerHeight.toInt()}.0,
  ${_showFooter ? 'footerHeight: ${_footerHeight.toInt()}.0,' : '// footerHeight: null,'}
  scrollbarThickness: ${_scrollbarThickness.toInt()}.0,

  // Colors & Themes:
  headerBackgroundColor: const Color(0x$hexHeader),
  borderColor: const Color(0x$hexBorder),
  showHorizontalGridLines: $_showHorizontalGridLines,
  ${_showHorizontalGridLines ? 'gridLineColor: const Color(0x$hexGridLine),' : '// gridLineColor: null,'}
  showVerticalGridLines: $_showVerticalGridLines,
  ${_showVerticalGridLines ? 'verticalGridLineColor: const Color(0x$hexVertical),' : '// verticalGridLineColor: null,'}
  evenRowColor: const Color(0x$hexEven),
  ${_useZebraStripes ? 'oddRowColor: const Color(0x$hexOdd),' : '// oddRowColor omitted (no zebra stripes)'}
  selectedRowColor: const Color(0x$hexSelected),
  scrollbarThumbColor: const Color(0x$hexThumb),
  scrollbarTrackColor: const Color(0x$hexTrack),

  // Scroll Behaviors & Physics:
  autoStretch: $_autoStretch,
  enableMouseDragScroll: $_enableMouseDragScroll,
  horizontalScrollbarVisibility: ScrollbarVisibility.${_horizontalScrollbarVisibility.name},
  verticalScrollbarVisibility: ScrollbarVisibility.${_verticalScrollbarVisibility.name},
  physics: ${_useBouncingPhysics ? 'const BouncingScrollPhysics()' : 'const ClampingScrollPhysics()'},
  readOnly: $_readOnly,
)${_isFixedHeight ? ',\n)' : ''};''';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Generated AppGrid Code:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy to Clipboard'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AppGrid customization code copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF18181B)
                    : const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor.withAlpha(60)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  code,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildColorTile({
    required String title,
    required Color color,
    required ValueChanged<Color> onColorChanged,
  }) {
    final commonPalette = [
      const Color(0xFF0F172A),
      const Color(0xFF1E293B),
      const Color(0xFF334155),
      const Color(0xFF64748B),
      const Color(0xFFCBD5E1),
      const Color(0xFFF1F5F9),
      const Color(0xFFFFFFFF),
      const Color(0xFF064E3B),
      const Color(0xFF047857),
      const Color(0xFF10B981),
      const Color(0xFFA7F3D0),
      const Color(0xFF1E3A8A),
      const Color(0xFF2563EB),
      const Color(0xFF60A5FA),
      const Color(0xFFBFDBFE),
      const Color(0xFF7C2D12),
      const Color(0xFFD97706),
      const Color(0xFFFBBF24),
      const Color(0xFFFEF3C7),
      const Color(0xFF831843),
      const Color(0xFFDB2777),
      const Color(0xFFF472B6),
      const Color(0xFFFCE7F3),
    ];

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<Color>(
            tooltip: 'Pick Palette Color',
            icon: const Icon(Icons.colorize, size: 18),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in commonPalette)
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context, c);
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: color == c ? Colors.blue : Colors.grey.shade300,
                                width: color == c ? 2 : 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ];
            },
            onSelected: onColorChanged,
          ),
        ],
      ),
    );
  }
}
