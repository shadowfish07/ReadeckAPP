// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'bookmark.freezed.dart';
part 'bookmark.g.dart';

@freezed
abstract class Bookmark with _$Bookmark {
  const factory Bookmark({
    /// 书签唯一标识符
    required String id,

    /// 书签标题
    required String title,

    /// 书签URL地址
    required String url,

    /// 网站名称
    @JsonKey(name: 'site_name') String? siteName,

    /// 书签描述
    String? description,

    /// 创建时间
    required DateTime created,

    /// 是否已标记为喜爱

    @JsonKey(name: 'is_marked') required bool isMarked,

    /// 是否已归档
    @JsonKey(name: 'is_archived') required bool isArchived,

    /// 阅读进度（0-100）
    @JsonKey(name: 'read_progress') required int readProgress,

    /// 标签列表
    required List<String> labels,

    /// 图片URL
    @JsonKey(name: 'image_url') String? imageUrl,
  }) = _Bookmark;

  factory Bookmark.fromJson(Map<String, Object?> json) =>
      _$BookmarkFromJson(json);
}
