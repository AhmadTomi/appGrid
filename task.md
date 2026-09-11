# AppGrid Task Breakdown & Spec-Driven Development (SDD) Plan

## Module 1: `controllers`
- [x] **DualIndexMap** (`src/controllers/dual_index_map.dart`)
  - Bidirectional mapping between `originalIndex` (raw dataset) and `displayIndex` (filtered/sorted visual rows) backed by optimized `Int32List`.
  - High performance lookup: O(1) by displayIndex and O(1) by originalIndex.
  - Generates `RowIndexInfo(originalIndex: int, displayIndex: int)`.
  - Sorting integration with Numeric, Alphabetical, and Custom Comparators (`Ascending`, `Descending`, `None`).
  - Background `IsolateSorter` (`src/controllers/isolate_sorter.dart`) for sorting large datasets (100k rows) in worker isolate.
  - Unit tests in `test/dual_index_map_test.dart` and `test/isolate_sorter_test.dart`.
- [x] **FrameBatchThrottler** (`src/controllers/frame_batch_throttler.dart`)
  - Streaming mutation buffer (handling 50–100+ events/sec).
  - Sync flushes with `SchedulerBinding.instance.scheduleFrameCallback` to avoid frame drops.
  - Unit tests in `test/frame_batch_throttler_test.dart`.
- [x] **AppGridController<T>** (`src/controllers/app_grid_controller.dart`)
  - Manages dataset, selection state, sorting, filtering, streaming cell updates.
  - **Developer-Friendly Row & Cell Update Helpers**:
    - `updateRow(int originalIndex, T updatedData)`: Updates an entire row in one call without manual cell looping.
    - `updateRowAtDisplayIndex(int displayIndex, T updatedData)`: Updates row by visual index.
    - `updateRowById(Object id, T updatedData)`: Updates row matching ID using user-configured `rowIdGetter`.
    - `patchRow(int originalIndex, T Function(T current) updater)`: Functional delta update.
    - `batchUpdateRows(Map<int, T> updates)`: High-volume streaming row updates buffered via `FrameBatchThrottler`.
  - Granular cell/row change notifications (using isolated ValueNotifiers / streams per cell/row).
  - Data ingestion support: `DataFetchMode.pagination` and `DataFetchMode.infiniteScroll` (threshold 80%).
  - Selection management: Single Row Selection (`onRowSelected(RowIndexInfo)`).

## Module 2: `column_layout`
- [x] **GridColumn Configuration** (`src/models/grid_column.dart`)
  - Id, label, minWidth, initialWidth, isVisible, isFrozen (`GridColumnPin.none`, `left`, `right`), sortable, comparator.
- [x] **AutoStretchCalculator & ColumnLayoutManager** (`src/column_layout/`)
  - Enhanced Auto-Stretch Rules:
    - Automatically stretches columns proportionally **only when $\sum \text{minWidth} < \text{ViewportWidth}$**.
    - If $\sum \text{minWidth} \ge \text{ViewportWidth}$, auto-stretch is inhibited, engaging smooth horizontal scrolling.
    - **Auto-stretch is automatically disabled when the user manually resizes any column**.
    - Resetting widths (`resetWidths()`) re-engages auto-stretch.
  - Column reordering (drag-and-drop header support).
  - Column resizing with drag handle on right border.
  - Double-click resize handle to auto-fit to longest content.
  - Column visibility toggle without dropping column definition.
  - Comprehensive unit tests in `test/column_layout_test.dart`.

## Module 3: `rendering_engine`
- [x] **2D Virtualized Grid Layout** (`src/rendering_engine/`)
  - 2D virtualization: strictly renders only visible row range + 1 buffer row, and visible column range for scrollable section (~5–8 visible columns out of 50).
  - Left & Right pinned columns remain static during horizontal scroll while scrolling vertically synchronously with main viewport.
  - Zero element tree allocations for out-of-viewport cells (~150 active DOM cells for 100k x 50 dataset).
  - Granular reactive cell updates: `CellWidget` listens only to its row notifier.
  - NO full-grid rebuilds on data tick updates.
  - Verified with 100,000 rows x 50 columns benchmark.

## Module 4: `keyboard_interaction`
- [x] **GridKeyboardHandler & Focus Manager** (`src/keyboard_interaction/`)
  - Focusable grid viewport with shortcut/key handling:
    - `ArrowUp` / `ArrowDown`: move selection by 1 row.
    - `Home`: jump to first row.
    - `End`: jump to last row.
    - `PageUp` / `PageDown`: jump row selection by current visible row count.
  - Auto-scrolling viewport to keep selected row visible.
  - Unit tests in `test/keyboard_navigation_test.dart`.

## Module 5: `export_utils` & State Persistence
- [x] **DataGridExporter** (`src/export_utils/data_grid_exporter.dart`)
  - `toCsv(...)` with RFC 4180 escaping.
  - `toJson(...)` with structured serialized active display data.
- [x] **GridState Persistence** (`src/models/grid_state.dart`)
  - Selective serialization: `columnOrder`, `sortCriteria`, `columnVisibility`.
  - **STRICT CONSTRAINT VERIFICATION**: No `columnWidth` or `width` key permitted in JSON.
  - Unit tests in `test/grid_state_persistence_test.dart` and `test/export_utils_test.dart`.

## Verification & Acceptance Criteria
- [x] AC-01: 100,000 rows x 50 columns virtualized viewport rendering (visible rows + 1 buffer, visible center columns).
- [x] AC-02: 60 updates/sec cell mutations without root widget rebuild.
- [x] AC-03: Dual index mapping post-sort visual `displayIndex: 0` maps correctly to raw `originalIndex`.
- [x] AC-04: `PageDown` shifts selection by visible row count.
- [x] AC-05: State persistence JSON strictly contains only columnOrder, sortCriteria, columnVisibility (zero width properties).
- [x] AC-06: Column auto-stretch fills empty canvas width when columns minWidth sum < viewport width.
- [x] Verification with `flutter test` (all 24 tests pass) and `flutter analyze` (zero issues).
