// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookmarkArticle _$BookmarkArticleFromJson(Map<String, dynamic> json) =>
    _BookmarkArticle(
      id: (json['id'] as num?)?.toInt(),
      bookmarkId: json['bookmark_id'] as String,
      article: json['article'] as String,
      translate: json['translate'] as String?,
      createdDate: DateTime.parse(json['created_date'] as String),
    );

Map<String, dynamic> _$BookmarkArticleToJson(_BookmarkArticle instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookmark_id': instance.bookmarkId,
      'article': instance.article,
      'translate': instance.translate,
      'created_date': instance.createdDate.toIso8601String(),
    };
