import 'package:flutter/material.dart';
import '../table_customization_page.dart';

class CustomizationPage extends StatelessWidget {
  const CustomizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withAlpha(40),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withAlpha(60),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Customization Studio',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Text(
                      'Live configuration of colors, compact mode (2-in-1 stacked rows), row/header heights, scroll container height, and scrollbars.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open Full Page'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TableCustomizationPage(isStandalone: true),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const Expanded(
          child: TableCustomizationPage(isStandalone: false),
        ),
      ],
    );
  }
}

typedef CustomizationShowcaseDemo = CustomizationPage;

const String customizationSnippet = '''// AppGrid Custom Styling & Viewport Sizing:
// Wrap AppGrid in a SizedBox to constrain scroll height, or use Expanded.
SizedBox(
  height: 400.0, // Fixed scroll container height
  child: AppGrid<InventoryItem>(
    controller: controller,

    // 1. Dimensions & Sizing:
    rowHeight: 48.0,
    headerHeight: 48.0,
    footerHeight: 40.0,
    scrollbarThickness: 10.0,
    compactMode: false, // Set to true to merge adjacent canCompact columns 2-in-1

    // 2. Custom Color Palette:
    headerBackgroundColor: const Color(0xFF1E293B),
    borderColor: const Color(0xFF0F172A),
    gridLineColor: const Color(0xFFE2E8F0),
    evenRowColor: Colors.white,
    oddRowColor: const Color(0xFFF8FAFC), // Zebra stripes
    selectedRowColor: const Color(0xFFBAE6FD),
    scrollbarThumbColor: const Color(0xFF64748B),
    scrollbarTrackColor: const Color(0x1A64748B),

    // 3. Scroll Behaviors & Physics:
    autoStretch: true,
    enableMouseDragScroll: true,
    showHorizontalScrollbar: true,
    showVerticalScrollbar: true,
    physics: const ClampingScrollPhysics(),
  ),
);''';
