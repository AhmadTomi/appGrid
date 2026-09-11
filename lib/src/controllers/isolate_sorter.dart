import 'dart:isolate';
import 'dart:typed_data';

/// Background Isolate worker offloading O(N log N) sorting for massive datasets
/// (e.g. 100,000+ rows) to preserve a flawless 60 FPS UI frame rate.
class IsolateSorter {
  const IsolateSorter._();

  /// Sorts row indices in a background Isolate based on extracted primitive/Comparable [keys].
  ///
  /// Returns an [Int32List] of sorted original indices.
  static Future<Int32List> sortKeysAsync({
    required List<dynamic> keys,
    required bool isAscending,
    Int32List? activeIndices,
  }) async {
    return Isolate.run<Int32List>(() {
      final int count = activeIndices != null ? activeIndices.length : keys.length;
      final List<int> indices = activeIndices != null
          ? List<int>.from(activeIndices)
          : List<int>.generate(count, (i) => i);

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

        // Fallback toString comparison
        final strA = valA.toString();
        final strB = valB.toString();
        final cmp = strA.compareTo(strB);
        return isAscending ? cmp : -cmp;
      });

      final result = Int32List(indices.length);
      for (var i = 0; i < indices.length; i++) {
        result[i] = indices[i];
      }
      return result;
    });
  }
}
