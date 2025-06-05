/// 书签数据模型
///
/// 表示 Readeck 中的一个书签，包含标题、URL、创建时间等信息
class Bookmark {
  /// 书签唯一标识符
  final String id;

  /// 书签标题
  final String title;

  /// 书签URL地址
  final String url;

  /// 网站名称
  final String? siteName;

  /// 书签描述
  final String? description;

  /// 创建时间
  final DateTime created;

  /// 是否已标记为喜爱
  final bool isMarked;

  /// 是否已归档
  final bool isArchived;

  /// 阅读进度（0-100）
  final int readProgress;

  /// 标签列表
  final List<String> labels;

  /// 图片URL
  final String? imageUrl;

  const Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.siteName,
    this.description,
    required this.created,
    required this.isMarked,
    required this.isArchived,
    required this.readProgress,
    required this.labels,
    this.imageUrl,
  });

  /// 从 JSON 创建 Bookmark 实例
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] ?? '',
      title: json['title'] ?? '无标题',
      url: json['url'] ?? '',
      siteName: json['site_name'],
      description: json['description'],
      created:
          DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      isMarked: json['is_marked'] ?? false,
      isArchived: json['is_archived'] ?? false,
      readProgress: _parseIntFromDynamic(json['read_progress']) ?? 0,
      labels: List<String>.from(json['labels'] ?? []),
      imageUrl: json['resources']?['image']?['src'],
    );
  }

  /// 转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'site_name': siteName,
      'description': description,
      'created': created.toIso8601String(),
      'is_marked': isMarked,
      'is_archived': isArchived,
      'read_progress': readProgress,
      'labels': labels,
      'resources': imageUrl != null
          ? {
              'image': {'src': imageUrl}
            }
          : null,
    };
  }

  /// 创建当前实例的副本，可选择性地更新某些字段
  ///
  /// 这个方法支持不可变更新模式，用于状态管理
  Bookmark copyWith({
    String? id,
    String? title,
    String? url,
    String? siteName,
    String? description,
    DateTime? created,
    bool? isMarked,
    bool? isArchived,
    int? readProgress,
    List<String>? labels,
    String? imageUrl,
  }) {
    return Bookmark(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      siteName: siteName ?? this.siteName,
      description: description ?? this.description,
      created: created ?? this.created,
      isMarked: isMarked ?? this.isMarked,
      isArchived: isArchived ?? this.isArchived,
      readProgress: readProgress ?? this.readProgress,
      labels: labels ?? this.labels,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// 判断两个 Bookmark 实例是否相等
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Bookmark) return false;
    return id == other.id;
  }

  /// 获取哈希码
  @override
  int get hashCode => id.hashCode;

  /// 字符串表示
  @override
  String toString() {
    return 'Bookmark(id: $id, title: $title, url: $url, isMarked: $isMarked, isArchived: $isArchived)';
  }

  /// 解析动态类型为整数的辅助方法
  static int? _parseIntFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) {
      return value.toInt();
    }
    return null;
  }
}
