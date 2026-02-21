class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  static PaginatedResponse<T> fromDecoded<T>(
    dynamic decoded,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (decoded is List) {
      final list = decoded
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      return PaginatedResponse<T>(
        content: list,
        page: 0,
        size: list.length,
        totalElements: list.length,
        totalPages: 1,
        first: true,
        last: true,
      );
    }

    if (decoded is Map) {
      final root = Map<String, dynamic>.from(decoded);
      final source = _resolveContainer(root);
      final rawContent = source['content'];
      final content = rawContent is List
          ? rawContent
                .whereType<Map>()
                .map((e) => fromJson(Map<String, dynamic>.from(e)))
                .toList(growable: false)
          : List<T>.empty(growable: false);

      return PaginatedResponse<T>(
        content: content,
        page: _toInt(source['page'] ?? source['number']),
        size: _toInt(source['size'], defaultValue: content.length),
        totalElements: _toInt(source['totalElements'], defaultValue: content.length),
        totalPages: _toInt(source['totalPages'], defaultValue: 1),
        first: _toBool(source['first'], defaultValue: true),
        last: _toBool(source['last'], defaultValue: true),
      );
    }

    return PaginatedResponse<T>(
      content: List<T>.empty(growable: false),
      page: 0,
      size: 0,
      totalElements: 0,
      totalPages: 1,
      first: true,
      last: true,
    );
  }

  static Map<String, dynamic> _resolveContainer(Map<String, dynamic> root) {
    if (root['content'] is List) return root;
    final data = root['data'];
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['content'] is List) return map;
    }
    return root;
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? defaultValue;
  }

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    final raw = value?.toString().toLowerCase().trim() ?? '';
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return defaultValue;
  }
}
