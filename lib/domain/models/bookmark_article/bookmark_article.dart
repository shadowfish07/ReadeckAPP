// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'bookmark_article.freezed.dart';
part 'bookmark_article.g.dart';

@freezed
abstract class BookmarkArticle with _$BookmarkArticle {
  const factory BookmarkArticle({
    /// 文章缓存唯一标识符
    int? id,

    /// 关联的书签ID
    @JsonKey(name: 'bookmark_id') required String bookmarkId,

    /// 文章内容
    required String article,

    /// 翻译内容
    String? translate,

    /// 创建时间
    @JsonKey(name: 'created_date') required DateTime createdDate,
  }) = _BookmarkArticle;

  factory BookmarkArticle.fromJson(Map<String, Object?> json) =>
      _$BookmarkArticleFromJson(json);
}
