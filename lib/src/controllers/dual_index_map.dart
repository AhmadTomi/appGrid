import 'dart:typed_data';
import '../models/row_index_info.dart';
import '../models/sort_criteria.dart';

/// Manages bidirectional O(1) index mapping between the raw input dataset
/// ([originalIndex]) and the actively rendered visual sequence ([displayIndex]).
///
/// Uses [Int32List] for ultra-low memory footprint and high cache locality,
/// consuming only 400 KB of RAM for 100,000 rows.
class DualIndexMap {
  Int32List _displayToOriginal;
  Int32List _originalToDisplay;
  int _displayRowCount;
  int _totalOriginalCount;

  DualIndexMap({int totalCount = 0})
      : _totalOriginalCount = totalCount,
        _displayRowCount = totalCount,
        _displayToOriginal = _createIdentityInt32List(totalCount),
        _originalToDisplay = _createIdentityInt32List(totalCount);

  static Int32List _createIdentityInt32List(int count) {
    final list = Int32List(count);
    for (var i = 0; i < count; i++) {
      list[i] = i;
    }
    return list;
  }

  /// Count of visual/display rows currently active (after filter and sort).
  int get displayRowCount => _displayRowCount;

  /// Total count of rows in the underlying dataset.
  int get originalRowCount => _totalOriginalCount;

  /// Retrieves the [originalIndex] for a given [displayIndex].
  int getOriginalIndex(int displayIndex) {
    if (displayIndex < 0 || displayIndex >= _displayRowCount) {
      throw RangeError.index(displayIndex, _displayToOriginal, 'displayIndex', null, _displayRowCount);
    }
    return _displayToOriginal[displayIndex];
  }

  /// Retrieves the [displayIndex] for a given [originalIndex].
  /// Returns -1 if the item is filtered out.
  int getDisplayIndex(int originalIndex) {
    if (originalIndex < 0 || originalIndex >= _originalToDisplay.length) {
      return -1;
    }
    return _originalToDisplay[originalIndex];
  }

  /// Retrieves a [RowIndexInfo] object from a visual [displayIndex].
  RowIndexInfo getInfoForDisplayIndex(int displayIndex) {
    final original = getOriginalIndex(displayIndex);
    return RowIndexInfo(originalIndex: original, displayIndex: displayIndex);
  }

  /// Retrieves a [RowIndexInfo] object from a raw [originalIndex].
  RowIndexInfo? getInfoForOriginalIndex(int originalIndex) {
    final display = getDisplayIndex(originalIndex);
    if (display == -1) return null;
    return RowIndexInfo(originalIndex: originalIndex, displayIndex: display);
  }

  /// Resets mapping to identity (1:1 mapping for [totalCount] rows).
  void reset(int totalCount) {
    _totalOriginalCount = totalCount;
    _displayRowCount = totalCount;
    _displayToOriginal = _createIdentityInt32List(totalCount);
    _originalToDisplay = _createIdentityInt32List(totalCount);
  }

  /// Directly applies pre-sorted indices (e.g. from a background Isolate).
  void setSortedIndices(Int32List displayToOriginal, int totalCount) {
    _totalOriginalCount = totalCount;
    _displayRowCount = displayToOriginal.length;
    _displayToOriginal = displayToOriginal;

    if (_originalToDisplay.length != _totalOriginalCount) {
      _originalToDisplay = Int32List(_totalOriginalCount);
    }
    _originalToDisplay.fillRange(0, _totalOriginalCount, -1);

    for (var displayIdx = 0; displayIdx < _displayRowCount; displayIdx++) {
      final origIdx = _displayToOriginal[displayIdx];
      if (origIdx >= 0 && origIdx < _totalOriginalCount) {
        _originalToDisplay[origIdx] = displayIdx;
      }
    }
  }

  /// Rebuilds mapping based on an optional filter predicate and sort comparator.
  void recompute<T>({
    required List<T> items,
    bool Function(T item)? filter,
    int Function(T a, T b)? comparator,
    SortDirection sortDirection = SortDirection.none,
  }) {
    _totalOriginalCount = items.length;

    // 1. Filter original indices
    final List<int> filteredIndices;
    if (filter != null) {
      filteredIndices = <int>[];
      for (var i = 0; i < items.length; i++) {
        if (filter(items[i])) {
          filteredIndices.add(i);
        }
      }
    } else {
      filteredIndices = List<int>.generate(items.length, (i) => i);
    }

    // 2. Sort if comparator and direction are active
    if (comparator != null && sortDirection != SortDirection.none) {
      final isAsc = sortDirection == SortDirection.ascending;
      filteredIndices.sort((aIndex, bIndex) {
        final cmp = comparator(items[aIndex], items[bIndex]);
        return isAsc ? cmp : -cmp;
      });
    }

    _displayRowCount = filteredIndices.length;
    _displayToOriginal = Int32List(_displayRowCount);
    for (var i = 0; i < _displayRowCount; i++) {
      _displayToOriginal[i] = filteredIndices[i];
    }

    // 3. Rebuild inverse mapping original -> display
    _originalToDisplay = Int32List(_totalOriginalCount);
    _originalToDisplay.fillRange(0, _totalOriginalCount, -1);
    for (var displayIdx = 0; displayIdx < _displayRowCount; displayIdx++) {
      final origIdx = _displayToOriginal[displayIdx];
      _originalToDisplay[origIdx] = displayIdx;
    }
  }
}
