import 'package:flutter/foundation.dart';
import '../models/row_index_info.dart';
import '../models/grid_column.dart';
import '../models/sort_criteria.dart';
import '../models/grid_state.dart';
import '../models/data_fetch_mode.dart';
import '../rendering_engine/grid_builders.dart';
import 'dual_index_map.dart';
import 'frame_batch_throttler.dart';
import 'isolate_sorter.dart';

/// Controller coordinating dataset state, dual-index mapping, single-row selection,
/// column sorting, and granular row/cell updates without full-grid rebuilds.
class AppGridController<T> extends ChangeNotifier {
  List<T> _data;
  final DualIndexMap _dualIndexMap = DualIndexMap();
  final Object Function(T item)? rowIdGetter;

  /// Granular notifiers per active row index to update only visible cells.
  final Map<int, ValueNotifier<T>> _rowNotifiers = {};

  /// Throttler for high-frequency streaming updates.
  late final FrameBatchThrottler<MapEntry<int, T>> _streamingThrottler;

  /// Columns definitions managed by this controller.
  final List<GridColumn> _columns;

  /// Modular cell builders per column ID.
  final Map<String, ColumnCellBuilder<T>> _cellBuilders = {};

  /// Modular header builders per column ID.
  final Map<String, ColumnHeaderBuilder> _headerBuilders = {};

  /// Optional global header builder fallback.
  GridHeaderBuilder? _globalHeaderBuilder;

  /// Active column visibility map (columnId -> bool).
  final Map<String, bool> _columnVisibility = {};

  /// Ordered column IDs.
  final List<String> _columnOrder = [];

  SortCriteria? _sortCriteria;
  bool Function(T item)? _activeFilter;

  int? _selectedOriginalIndex;
  ValueChanged<RowIndexInfo>? onRowSelected;

  DataFetchMode fetchMode;
  GridPaginationInfo? paginationInfo;
  VoidCallback? onLoadMore;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSorting = false;
  bool _isReadOnly = false;

  /// Row count threshold above which sorting is automatically offloaded to a background Isolate.
  int isolateSortThreshold;

  AppGridController({
    List<T> initialData = const [],
    List<GridColumn> columns = const [],
    this.rowIdGetter,
    this.onRowSelected,
    this.fetchMode = DataFetchMode.infiniteScroll,
    this.paginationInfo,
    this.onLoadMore,
    this.isolateSortThreshold = 2000,
    bool isLoading = false,
    bool isReadOnly = false,
  })  : _data = List<T>.from(initialData),
        _columns = List<GridColumn>.from(columns),
        _isLoading = isLoading,
        _isReadOnly = isReadOnly {
    _streamingThrottler = FrameBatchThrottler<MapEntry<int, T>>(
      onFlush: _applyFlushedBatch,
    );

    for (final col in _columns) {
      _columnOrder.add(col.id);
      _columnVisibility[col.id] = col.isVisible;
      if (col.cellBuilder != null) {
        _cellBuilders[col.id] ??= (ctx, data, info) => col.cellBuilder!(ctx, data, info);
      }
      if (col.headerBuilder != null) {
        _headerBuilders[col.id] ??= col.headerBuilder!;
      }
    }

    _dualIndexMap.reset(_data.length);
  }

  // ==================== GETTERS ====================

  /// Entire raw dataset.
  List<T> get data => List.unmodifiable(_data);

  /// Number of raw rows in the underlying dataset.
  int get originalRowCount => _data.length;

  /// Number of active visual display rows (after sort and filter).
  int get displayRowCount => _dualIndexMap.displayRowCount;

  /// All columns configuration.
  List<GridColumn> get columns => List.unmodifiable(_columns);

  /// Visible columns ordered by current display sequence.
  List<GridColumn> get visibleColumns {
    final colMap = {for (final col in _columns) col.id: col};
    final result = <GridColumn>[];
    for (final colId in _columnOrder) {
      final col = colMap[colId];
      if (col != null && (_columnVisibility[colId] ?? true)) {
        result.add(col);
      }
    }
    return result;
  }

  SortCriteria? get sortCriteria => _sortCriteria;

  /// Whether the grid is in read-only mode.
  ///
  /// When true, row selection is disabled and any existing selection is cleared.
  bool get isReadOnly => _isReadOnly;

  set isReadOnly(bool value) {
    if (_isReadOnly != value) {
      _isReadOnly = value;
      if (value && _selectedOriginalIndex != null) {
        _selectedOriginalIndex = null;
      }
      notifyListeners();
    }
  }

  int? get selectedOriginalIndex => _isReadOnly ? null : _selectedOriginalIndex;

  int? get selectedDisplayIndex => (!_isReadOnly && _selectedOriginalIndex != null)
      ? _dualIndexMap.getDisplayIndex(_selectedOriginalIndex!)
      : null;

  RowIndexInfo? get selectedRowInfo => (!_isReadOnly && _selectedOriginalIndex != null)
      ? _dualIndexMap.getInfoForOriginalIndex(_selectedOriginalIndex!)
      : null;

  /// Whether the table is actively loading initial or async data.
  bool get isLoading => _isLoading;

  bool get isLoadingMore => _isLoadingMore;

  /// Whether a background sorting operation is currently running.
  bool get isSorting => _isSorting;

  // ==================== BUILDERS API ====================

  /// Modular cell builders registered per column ID.
  Map<String, ColumnCellBuilder<T>> get cellBuilders =>
      Map.unmodifiable(_cellBuilders);

  /// Modular header builders registered per column ID.
  Map<String, ColumnHeaderBuilder> get headerBuilders =>
      Map.unmodifiable(_headerBuilders);

  /// Global header builder fallback.
  GridHeaderBuilder? get globalHeaderBuilder => _globalHeaderBuilder;

  /// Sets or updates the modular cell builder for a specific [columnId].
  void setCellBuilder(String columnId, ColumnCellBuilder<T> builder) {
    _cellBuilders[columnId] = builder;
    notifyListeners();
  }

  /// Removes the modular cell builder for a specific [columnId].
  void removeCellBuilder(String columnId) {
    if (_cellBuilders.remove(columnId) != null) {
      notifyListeners();
    }
  }

  /// Returns the registered cell builder for [columnId], if any.
  ColumnCellBuilder<T>? getCellBuilder(String columnId) => _cellBuilders[columnId];

  /// Sets or updates the modular header builder for a specific [columnId].
  void setHeaderBuilder(String columnId, ColumnHeaderBuilder builder) {
    _headerBuilders[columnId] = builder;
    notifyListeners();
  }

  /// Removes the modular header builder for a specific [columnId].
  void removeHeaderBuilder(String columnId) {
    if (_headerBuilders.remove(columnId) != null) {
      notifyListeners();
    }
  }

  /// Returns the registered header builder for [columnId], if any.
  ColumnHeaderBuilder? getHeaderBuilder(String columnId) => _headerBuilders[columnId];

  /// Sets or updates the global header builder fallback.
  void setGlobalHeaderBuilder(GridHeaderBuilder? builder) {
    _globalHeaderBuilder = builder;
    notifyListeners();
  }

  // ==================== DATA ACCESS ====================

  /// Retrieves row data by its raw [originalIndex].
  T getRowByOriginalIndex(int originalIndex) {
    return _data[originalIndex];
  }

  /// Retrieves row data by its visual [displayIndex].
  T getRowByDisplayIndex(int displayIndex) {
    final originalIndex = _dualIndexMap.getOriginalIndex(displayIndex);
    return _data[originalIndex];
  }

  /// Retrieves [RowIndexInfo] for a given visual [displayIndex].
  RowIndexInfo getRowIndexInfo(int displayIndex) {
    return _dualIndexMap.getInfoForDisplayIndex(displayIndex);
  }

  /// Retrieves or lazily attaches a granular [ValueNotifier] for row at [originalIndex].
  ValueNotifier<T> getRowNotifier(int originalIndex) {
    return _rowNotifiers.putIfAbsent(
      originalIndex,
      () => ValueNotifier<T>(_data[originalIndex]),
    );
  }

  // ==================== ROW & CELL MUTATION HELPERS ====================

  /// Direct 1-Row Update by raw dataset [originalIndex].
  ///
  /// Updates the internal dataset and immediately notifies the granular row
  /// notifier (if on screen). The root grid widget does NOT rebuild.
  void updateRow(int originalIndex, T updatedData) {
    if (originalIndex < 0 || originalIndex >= _data.length) return;
    _data[originalIndex] = updatedData;

    final notifier = _rowNotifiers[originalIndex];
    if (notifier != null) {
      notifier.value = updatedData;
    }
  }

  /// Direct 1-Row Update by active visual [displayIndex].
  void updateRowAtDisplayIndex(int displayIndex, T updatedData) {
    final originalIndex = _dualIndexMap.getOriginalIndex(displayIndex);
    updateRow(originalIndex, updatedData);
  }

  /// Updates a row matching [id] using [rowIdGetter].
  void updateRowById(Object id, T updatedData) {
    assert(rowIdGetter != null, 'rowIdGetter must be configured to use updateRowById');
    final index = _data.indexWhere((item) => rowIdGetter!(item) == id);
    if (index != -1) {
      updateRow(index, updatedData);
    }
  }

  /// Modifies an existing row functionally via [updater].
  void patchRow(int originalIndex, T Function(T current) updater) {
    if (originalIndex < 0 || originalIndex >= _data.length) return;
    final current = _data[originalIndex];
    final updated = updater(current);
    updateRow(originalIndex, updated);
  }

  /// Functional patch of a row by [id].
  void patchRowById(Object id, T Function(T current) updater) {
    assert(rowIdGetter != null, 'rowIdGetter must be configured to use patchRowById');
    final index = _data.indexWhere((item) => rowIdGetter!(item) == id);
    if (index != -1) {
      patchRow(index, updater);
    }
  }

  /// Updates rows matching the [predicate].
  void updateRowWhere(bool Function(T item) predicate, T Function(T current) updater) {
    for (var i = 0; i < _data.length; i++) {
      if (predicate(_data[i])) {
        patchRow(i, updater);
      }
    }
  }

  /// Granular update for a single cell.
  void updateCell(int originalIndex, String columnId, dynamic newValue) {
    // If user provided a patchable model, they use patchRow.
    // updateCell ensures the row notifier fires.
    if (originalIndex < 0 || originalIndex >= _data.length) return;
    final notifier = _rowNotifiers[originalIndex];
    if (notifier != null) {
      // Re-trigger listener
      notifier.value = _data[originalIndex];
    }
  }

  /// High-volume streaming updates queued and synchronized to frame rate.
  ///
  /// Buffers entries and dispatches them via [SchedulerBinding.scheduleFrameCallback].
  void batchUpdateRows(Map<int, T> updates) {
    _streamingThrottler.queueAll(updates.entries);
  }

  /// High-volume streaming updates queued by row ID.
  void batchUpdateRowsById(Map<Object, T> updatesById) {
    assert(rowIdGetter != null, 'rowIdGetter must be configured to use batchUpdateRowsById');
    final Map<int, T> updatesByIndex = {};
    for (var i = 0; i < _data.length; i++) {
      final id = rowIdGetter!(_data[i]);
      if (updatesById.containsKey(id)) {
        updatesByIndex[i] = updatesById[id] as T;
      }
    }
    batchUpdateRows(updatesByIndex);
  }

  void _applyFlushedBatch(List<MapEntry<int, T>> batch) {
    for (final entry in batch) {
      final index = entry.key;
      final value = entry.value;
      if (index >= 0 && index < _data.length) {
        _data[index] = value;
        final notifier = _rowNotifiers[index];
        if (notifier != null) {
          notifier.value = value;
        }
      }
    }
  }

  /// Updates whether the table is in loading state and notifies listeners.
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // ==================== DATASET LIFECYCLE ====================

  /// Replaces the dataset entirely (alias to [setRows]).
  void setData(List<T> newData) => setRows(newData);

  /// Replaces the dataset entirely (e.g. initial load or discrete page switch).
  void setRows(List<T> newRows) {
    _data = List<T>.from(newRows);
    _selectedOriginalIndex = null;
    _isLoading = false;
    _recomputeIndices();
    _syncRowNotifiers();
    notifyListeners();
  }

  /// Replaces the dataset and updates the [paginationInfo] metadata in a single notification.
  void setPageData({
    required List<T> rows,
    required GridPaginationInfo pagination,
  }) {
    paginationInfo = pagination;
    _data = List<T>.from(rows);
    _selectedOriginalIndex = null;
    _isLoading = false;
    _recomputeIndices();
    _syncRowNotifiers();
    notifyListeners();
  }

  /// Appends rows to the dataset (e.g. infinite scroll fetch).
  void appendRows(List<T> additionalRows) {
    if (additionalRows.isEmpty) return;
    _data.addAll(additionalRows);
    _recomputeIndices();
    _isLoadingMore = false;
    notifyListeners();
  }

  void setLoadMoreLoading(bool loading) {
    if (_isLoadingMore != loading) {
      _isLoadingMore = loading;
      notifyListeners();
    }
  }

  // ==================== SELECTION ====================

  /// Selects a row by active visual [displayIndex].
  void selectRow(int displayIndex) {
    if (_isReadOnly) return;
    if (displayIndex < 0 || displayIndex >= _dualIndexMap.displayRowCount) {
      return;
    }
    final info = _dualIndexMap.getInfoForDisplayIndex(displayIndex);
    _selectedOriginalIndex = info.originalIndex;
    onRowSelected?.call(info);
    notifyListeners();
  }

  /// Selects a row by raw [originalIndex].
  void selectRowByOriginalIndex(int originalIndex) {
    if (_isReadOnly) return;
    if (originalIndex < 0 || originalIndex >= _data.length) return;
    final info = _dualIndexMap.getInfoForOriginalIndex(originalIndex);
    if (info != null) {
      _selectedOriginalIndex = originalIndex;
      onRowSelected?.call(info);
      notifyListeners();
    }
  }

  /// Clears active row selection.
  void clearSelection() {
    if (_selectedOriginalIndex != null) {
      _selectedOriginalIndex = null;
      notifyListeners();
    }
  }

  // ==================== SORTING & FILTERING ====================

  /// Sorts by column [columnId].
  ///
  /// For large datasets (>= [isolateSortThreshold]), sorting is automatically
  /// offloaded to a background [Isolate] to maintain 60 FPS without UI jank.
  Future<void> sortByColumn(String columnId, {SortDirection? direction}) async {
    if (_isSorting) return;

    final col = _columns.firstWhere(
      (c) => c.id == columnId,
      orElse: () => throw ArgumentError('Column not found: $columnId'),
    );

    if (!col.isSortable) return;

    final targetDirection = direction ??
        (_sortCriteria?.columnId == columnId
            ? _sortCriteria!.direction.next
            : SortDirection.ascending);

    if (targetDirection == SortDirection.none) {
      _sortCriteria = null;
      _recomputeIndices();
      notifyListeners();
      return;
    }

    _sortCriteria = SortCriteria(columnId: columnId, direction: targetDirection);

    // Offload heavy sorting to a background Isolate for large datasets (native platforms only)
    if (!kIsWeb && _data.length >= isolateSortThreshold && col.valueGetter != null && col.comparator == null) {
      _isSorting = true;
      notifyListeners();
      try {
        final keys = List<dynamic>.generate(_data.length, (i) => col.valueGetter!(_data[i]));
        final sortedIndices = await IsolateSorter.sortKeysAsync(
          keys: keys,
          isAscending: targetDirection == SortDirection.ascending,
        );
        _dualIndexMap.setSortedIndices(sortedIndices, _data.length);
        return;
      } catch (_) {
        // Fallback to fast in-memory sort if Isolate execution fails or is cancelled
        _fastSortWithKeys(col, targetDirection == SortDirection.ascending);
        return;
      } finally {
        _isSorting = false;
        notifyListeners();
      }
    }

    // High-performance pre-extracted keys sort (completes 100k rows in ~15-20ms)
    if (col.valueGetter != null && col.comparator == null) {
      _fastSortWithKeys(col, targetDirection == SortDirection.ascending);
      notifyListeners();
      return;
    }

    _recomputeIndices();
    notifyListeners();
  }

  void _fastSortWithKeys(GridColumn col, bool isAscending) {
    final count = _data.length;
    final keys = List<dynamic>.generate(count, (i) => col.valueGetter!(_data[i]));
    final indices = List<int>.generate(count, (i) => i);

    indices.sort((a, b) {
      final valA = keys[a];
      final valB = keys[b];
      if (valA == null && valB == null) return 0;
      if (valA == null) return isAscending ? -1 : 1;
      if (valB == null) return isAscending ? 1 : -1;
      if (valA is Comparable && valB is Comparable) {
        final cmp = valA.compareTo(valB);
        return isAscending ? cmp : -cmp;
      }
      final cmp = valA.toString().compareTo(valB.toString());
      return isAscending ? cmp : -cmp;
    });

    final result = Int32List(count);
    for (var i = 0; i < count; i++) {
      result[i] = indices[i];
    }
    _dualIndexMap.setSortedIndices(result, count);
  }

  /// Applies a custom row filter predicate.
  void filter(bool Function(T item)? predicate) {
    _activeFilter = predicate;
    _recomputeIndices();
    notifyListeners();
  }

  void _recomputeIndices() {
    int Function(T a, T b)? comparator;
    if (_sortCriteria != null && _sortCriteria!.direction != SortDirection.none) {
      final col = _columns.firstWhere((c) => c.id == _sortCriteria!.columnId);
      if (col.comparator != null) {
        comparator = (a, b) => col.comparator!(a, b);
      } else if (col.valueGetter != null) {
        comparator = (a, b) {
          final valA = col.valueGetter!(a);
          final valB = col.valueGetter!(b);
          if (valA is Comparable && valB is Comparable) {
            return Comparable.compare(valA, valB);
          }
          return 0;
        };
      }
    }

    _dualIndexMap.recompute<T>(
      items: _data,
      filter: _activeFilter,
      comparator: comparator,
      sortDirection: _sortCriteria?.direction ?? SortDirection.none,
    );
  }

  // ==================== COLUMN MANIPULATION ====================

  /// Reorders a column from [oldIndex] to [newIndex] in display sequence.
  void reorderColumn(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _columnOrder.length ||
        newIndex < 0 ||
        newIndex >= _columnOrder.length) {
      return;
    }
    final colId = _columnOrder.removeAt(oldIndex);
    _columnOrder.insert(newIndex, colId);
    notifyListeners();
  }

  /// Sets visibility of a column.
  void setColumnVisibility(String columnId, bool isVisible) {
    if (_columnVisibility[columnId] != isVisible) {
      _columnVisibility[columnId] = isVisible;
      notifyListeners();
    }
  }

  /// Toggles visibility of a column.
  void toggleColumnVisibility(String columnId) {
    final current = _columnVisibility[columnId] ?? true;
    setColumnVisibility(columnId, !current);
  }

  /// Updates the freeze/pin status of a column ([GridColumnPin.none], [left], [right]).
  void setColumnPin(String columnId, GridColumnPin newPin) {
    final index = _columns.indexWhere((c) => c.id == columnId);
    if (index != -1 && _columns[index].pin != newPin) {
      _columns[index] = _columns[index].copyWith(pin: newPin);
      notifyListeners();
    }
  }

  // ==================== STATE PERSISTENCE ====================

  /// Exports table state conforming strictly to REQ-STATE-01, 02, and 03.
  ///
  /// Column widths are STRICTLY excluded.
  GridState exportState() {
    return GridState(
      columnOrder: List<String>.from(_columnOrder),
      sortCriteria: _sortCriteria,
      columnVisibility: Map<String, bool>.from(_columnVisibility),
    );
  }

  /// Restores table state from a [GridState] snapshot.
  ///
  /// Reorders columns, restores sorting, and updates column visibility.
  void restoreState(GridState state) {
    // 1. Column order
    _columnOrder.clear();
    final validIds = _columns.map((c) => c.id).toSet();
    for (final colId in state.columnOrder) {
      if (validIds.contains(colId)) {
        _columnOrder.add(colId);
      }
    }
    // Add any missing columns
    for (final col in _columns) {
      if (!_columnOrder.contains(col.id)) {
        _columnOrder.add(col.id);
      }
    }

    // 2. Visibility
    for (final entry in state.columnVisibility.entries) {
      if (validIds.contains(entry.key)) {
        _columnVisibility[entry.key] = entry.value;
      }
    }

    // 3. Sort criteria
    if (state.sortCriteria != null && validIds.contains(state.sortCriteria!.columnId)) {
      _sortCriteria = state.sortCriteria;
    } else {
      _sortCriteria = null;
    }

    _recomputeIndices();
    notifyListeners();
  }

  void _syncRowNotifiers() {
    final keysToRemove = <int>[];
    for (final entry in _rowNotifiers.entries) {
      if (entry.key < _data.length) {
        entry.value.value = _data[entry.key];
      } else {
        keysToRemove.add(entry.key);
      }
    }
    for (final key in keysToRemove) {
      _rowNotifiers[key]?.dispose();
      _rowNotifiers.remove(key);
    }
  }

  @override
  void dispose() {
    _streamingThrottler.dispose();
    for (final notifier in _rowNotifiers.values) {
      notifier.dispose();
    }
    _rowNotifiers.clear();
    super.dispose();
  }
}
