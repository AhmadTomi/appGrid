import 'package:flutter/material.dart';
import '../pages/pages.dart';

/// Supported features and showcases in the example application.
enum GridFeature {
  quickstart('Quickstart & Overview', Icons.rocket_launch, 'Basic table setup with models and builders.'),
  customization('Customization Studio', Icons.palette_outlined, 'Change colors, row/header heights, scroll container height, and scrollbar styling.'),
  modularBuilders('Modular Column Builders & DX', Icons.dashboard_customize, 'Modular cellBuilder, GridFooter summaries, Empty states, and Header Right-Click Pinning.'),
  largeDataset('100,000 Rows x 50 Cols', Icons.speed, '2D Virtualization benchmark maintaining 60 FPS.'),
  realtimeStreaming('Realtime Streaming Ticks', Icons.bolt, 'High-frequency 60 updates/sec with 0 root rebuilds.'),
  rowHelpers('Row Mutation Helpers', Icons.edit_note, 'Easy 1-row updates, patchRow, and batch updates.'),
  columnFreezing('Column Freezing', Icons.push_pin, 'Static left & right pinned panes with scrollable center.'),
  columnManipulation('Reorder, Resize & Auto-Fit', Icons.tune, 'Interactive header drag reorder, resize, and double-click fit.'),
  autoStretch('Auto-Stretch Layout', Icons.aspect_ratio, 'Proportional column expansion to fill 100% canvas width.'),
  selectionAndKeyboard('Selection & Keyboard', Icons.keyboard, 'Single-row selection with Arrow, Home, End, PageUp/Down.'),
  statePersistence('Selective State Persistence', Icons.save, 'Export & import JSON layout strictly without column widths.'),
  pagination('Discrete Pagination', Icons.pages, 'Discrete page navigation with page, limit, and total count metadata.'),
  infiniteScroll('Infinite Scroll', Icons.all_inclusive, 'Continuous lazy-loading triggered automatically at 80% scroll extent.'),
  exportUtils('CSV & JSON Exporters', Icons.file_download, 'Built-in RFC 4180 CSV and JSON data export utility.');

  final String title;
  final IconData icon;
  final String description;

  const GridFeature(this.title, this.icon, this.description);

  Widget get demoWidget {
    switch (this) {
      case GridFeature.quickstart:
        return const QuickstartPage();
      case GridFeature.customization:
        return const CustomizationPage();
      case GridFeature.modularBuilders:
        return const ModularBuildersPage();
      case GridFeature.largeDataset:
        return const LargeDatasetPage();
      case GridFeature.realtimeStreaming:
        return const RealtimeStreamingPage();
      case GridFeature.rowHelpers:
        return const RowHelpersPage();
      case GridFeature.columnFreezing:
        return const ColumnFreezingPage();
      case GridFeature.columnManipulation:
        return const ColumnManipulationPage();
      case GridFeature.autoStretch:
        return const AutoStretchPage();
      case GridFeature.selectionAndKeyboard:
        return const SelectionKeyboardPage();
      case GridFeature.statePersistence:
        return const StatePersistencePage();
      case GridFeature.pagination:
        return const PaginationPage();
      case GridFeature.infiniteScroll:
        return const InfiniteScrollPage();
      case GridFeature.exportUtils:
        return const ExportUtilsPage();
    }
  }

  String get codeSnippet {
    switch (this) {
      case GridFeature.quickstart:
        return quickstartSnippet;
      case GridFeature.customization:
        return customizationSnippet;
      case GridFeature.modularBuilders:
        return modularBuildersSnippet;
      case GridFeature.largeDataset:
        return largeDatasetSnippet;
      case GridFeature.realtimeStreaming:
        return realtimeStreamingSnippet;
      case GridFeature.rowHelpers:
        return rowHelpersSnippet;
      case GridFeature.columnFreezing:
        return columnFreezingSnippet;
      case GridFeature.columnManipulation:
        return columnManipulationSnippet;
      case GridFeature.autoStretch:
        return autoStretchSnippet;
      case GridFeature.selectionAndKeyboard:
        return selectionAndKeyboardSnippet;
      case GridFeature.statePersistence:
        return statePersistenceSnippet;
      case GridFeature.pagination:
        return paginationSnippet;
      case GridFeature.infiniteScroll:
        return infiniteScrollSnippet;
      case GridFeature.exportUtils:
        return exportUtilsSnippet;
    }
  }
}
