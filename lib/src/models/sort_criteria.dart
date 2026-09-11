/// Direction for sorting grid columns.
enum SortDirection {
  none,
  ascending,
  descending;

  SortDirection get next {
    switch (this) {
      case SortDirection.none:
        return SortDirection.ascending;
      case SortDirection.ascending:
        return SortDirection.descending;
      case SortDirection.descending:
        return SortDirection.none;
    }
  }

  String toJson() => name;

  static SortDirection fromJson(String value) {
    return SortDirection.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SortDirection.none,
    );
  }
}

/// Active sort criteria specifying the column and direction.
class SortCriteria {
  final String columnId;
  final SortDirection direction;

  const SortCriteria({
    required this.columnId,
    required this.direction,
  });

  Map<String, dynamic> toJson() => {
        'columnId': columnId,
        'direction': direction.toJson(),
      };

  factory SortCriteria.fromJson(Map<String, dynamic> json) => SortCriteria(
        columnId: json['columnId'] as String,
        direction: SortDirection.fromJson(json['direction'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortCriteria &&
          runtimeType == other.runtimeType &&
          columnId == other.columnId &&
          direction == other.direction;

  @override
  int get hashCode => columnId.hashCode ^ direction.hashCode;

  @override
  String toString() => 'SortCriteria(columnId: $columnId, direction: $direction)';
}
