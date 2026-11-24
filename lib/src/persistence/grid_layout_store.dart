import '../models/grid_column_layout.dart';

/// Synchronous storage for [GridColumnLayout]s keyed by a grid's
/// persistence key.
///
/// Reads must be synchronous so a grid can apply its stored layout before
/// its first frame; implementations backed by async storage should preload
/// into memory and persist in the background.
abstract interface class GridLayoutStore {
  /// Returns the stored layout for [key], or null when none is stored.
  GridColumnLayout? read(String key);

  /// Stores [layout] under [key], replacing any previous value.
  void write(String key, GridColumnLayout layout);

  /// Removes the layout stored under [key].
  void remove(String key);
}

/// [GridLayoutStore] that keeps layouts in memory only.
class InMemoryGridLayoutStore implements GridLayoutStore {
  final Map<String, GridColumnLayout> _layouts = {};

  @override
  GridColumnLayout? read(String key) => _layouts[key];

  @override
  void write(String key, GridColumnLayout layout) => _layouts[key] = layout;

  @override
  void remove(String key) => _layouts.remove(key);
}
