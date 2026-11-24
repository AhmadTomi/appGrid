import 'package:flutter/widgets.dart';

import 'grid_layout_store.dart';

/// Provides a [GridLayoutStore] to every [AppGrid] below it.
///
/// Grids with a `persistenceKey` read their stored layout from this store
/// when they are attached and write it back whenever the user changes the
/// column order, visibility or sort.
class AppGridLayoutScope extends InheritedWidget {
  /// The store shared by the grids below this scope.
  final GridLayoutStore store;

  const AppGridLayoutScope({
    super.key,
    required this.store,
    required super.child,
  });

  /// The nearest store above [context], or null when there is no scope.
  ///
  /// Does not register a dependency: a grid applies its stored layout only
  /// when it is attached, never live.
  static GridLayoutStore? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<AppGridLayoutScope>()?.store;
  }

  @override
  bool updateShouldNotify(AppGridLayoutScope oldWidget) =>
      store != oldWidget.store;
}
