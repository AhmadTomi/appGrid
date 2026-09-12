/// AppGrid: Flutter High-Performance Virtualized DataGrid Engine
///
/// Features:
/// - 2D Virtualization (100,000+ rows x 50+ columns @ 60 FPS)
/// - High-frequency streaming updates throttled to frame rate
/// - Granular isolated cell updates with zero root rebuilds
/// - Direct row update helper APIs (`updateRow`, `patchRow`, `updateRowById`, `batchUpdateRows`)
/// - Left & Right Column Freezing (Pinning)
/// - Interactive Column Reordering, Resizing & Double-Click Auto-Fit
/// - Auto-Stretch with zero empty canvas
/// - Dual-Index Mapping (`originalIndex` & `displayIndex`)
/// - Single-Row Selection with Keyboard Navigation (Arrow, Home, End, PageUp/Down)
/// - Selective State Persistence (Strictly excludes column widths)
/// - CSV & JSON Exporters
library app_grid;

export 'src/models/grid_column.dart';
export 'src/models/row_index_info.dart';
export 'src/models/sort_criteria.dart';
export 'src/models/grid_state.dart';
export 'src/models/data_fetch_mode.dart';

export 'src/controllers/app_grid_controller.dart';
export 'src/controllers/dual_index_map.dart';
export 'src/controllers/frame_batch_throttler.dart';
export 'src/controllers/isolate_sorter.dart';

export 'src/column_layout/auto_stretch_calculator.dart';
export 'src/column_layout/column_layout_manager.dart';

export 'src/rendering_engine/grid_builders.dart';
export 'src/rendering_engine/virtualized_grid_layout.dart';
export 'src/rendering_engine/app_grid_viewport.dart';
export 'src/rendering_engine/cell_widget.dart';
export 'src/rendering_engine/row_widget.dart';

export 'src/keyboard_interaction/grid_keyboard_handler.dart';

export 'src/export_utils/data_grid_exporter.dart';

export 'src/widgets/app_grid.dart';
export 'src/widgets/app_grid_header.dart';
export 'src/widgets/app_grid_column_dialog.dart';
export 'src/widgets/app_grid_footer.dart';
export 'src/widgets/grid_footer_summary.dart';
export 'src/widgets/empty_cell.dart';
export 'src/widgets/app_grid_empty_widget.dart';
export 'src/widgets/app_grid_pagination_bar.dart';
export 'src/widgets/app_grid_scrollbar.dart';
export 'src/widgets/app_grid_loading_overlay.dart';
export 'src/widgets/app_grid_button.dart';
