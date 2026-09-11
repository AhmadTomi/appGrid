/// Mode of data ingestion for [AppGrid].
enum DataFetchMode {
  /// Discrete page navigation with explicit page metadata (page, limit, total).
  pagination,

  /// Continuous lazy-loading triggered when vertical scroll passes a threshold.
  infiniteScroll;
}

/// Metadata payload when using [DataFetchMode.pagination].
class GridPaginationInfo {
  final int page;
  final int limit;
  final int totalCount;

  const GridPaginationInfo({
    required this.page,
    required this.limit,
    required this.totalCount,
  });

  int get totalPages => (totalCount / limit).ceil();
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  GridPaginationInfo copyWith({
    int? page,
    int? limit,
    int? totalCount,
  }) {
    return GridPaginationInfo(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}
