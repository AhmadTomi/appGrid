import 'package:flutter/widgets.dart';
import '../models/grid_column.dart';

/// Declarative footer summary utilities providing 1-line summary calculations.
class GridFooter {
  const GridFooter._();

  /// Creates a footer builder that sums the numeric values from [valueSelector].
  static ColumnFooterBuilder sum<T>(
    num Function(T item) valueSelector, {
    String prefix = '',
    String suffix = '',
    int precision = 0,
    TextStyle? style,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return (BuildContext context, List<dynamic> visibleItems) {
      num sum = 0;
      for (final item in visibleItems) {
        sum += valueSelector(item as T);
      }
      final formatted = precision > 0
          ? sum.toStringAsFixed(precision)
          : (sum is int ? sum.toString() : sum.round().toString());

      return Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Text(
          '$prefix$formatted$suffix',
          style: style ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    };
  }

  /// Creates a footer builder that averages the numeric values from [valueSelector].
  static ColumnFooterBuilder average<T>(
    num Function(T item) valueSelector, {
    String prefix = '',
    String suffix = '',
    int precision = 2,
    TextStyle? style,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return (BuildContext context, List<dynamic> visibleItems) {
      if (visibleItems.isEmpty) {
        return Container(
          alignment: alignment,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            '${prefix}0$suffix',
            style: style ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        );
      }
      num sum = 0;
      for (final item in visibleItems) {
        sum += valueSelector(item as T);
      }
      final avg = sum / visibleItems.length;
      final formatted = avg.toStringAsFixed(precision);

      return Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Text(
          '$prefix$formatted$suffix',
          style: style ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    };
  }

  /// Creates a footer builder that displays the total count of currently visible items.
  static ColumnFooterBuilder count({
    String prefix = '',
    String suffix = '',
    TextStyle? style,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return (BuildContext context, List<dynamic> visibleItems) {
      return Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Text(
          '$prefix${visibleItems.length}$suffix',
          style: style ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    };
  }

  /// Creates a footer builder using a custom builder function.
  static ColumnFooterBuilder custom<T>(
    Widget Function(BuildContext context, List<T> visibleItems) builder,
  ) {
    return (BuildContext context, List<dynamic> visibleItems) =>
        builder(context, visibleItems.cast<T>());
  }
}
