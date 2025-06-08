// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Bookmark _$BookmarkFromJson(Map<String, dynamic> json) => _Bookmark(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      siteName: json['site_name'] as String?,
      description: json['description'] as String?,
      created: DateTime.parse(json['created'] as String),
      isMarked: json['is_marked'] as bool,
      isArchived: json['is_archived'] as bool,
      readProgress: (json['read_progress'] as num).toInt(),
      labels:
          (json['labels'] as List<dynamic>).map((e) => e as String).toList(),
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$BookmarkToJson(_Bookmark instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'url': instance.url,
      'site_name': instance.siteName,
      'description': instance.description,
      'created': instance.created.toIso8601String(),
      'is_marked': instance.isMarked,
      'is_archived': instance.isArchived,
      'read_progress': instance.readProgress,
      'labels': instance.labels,
      'image_url': instance.imageUrl,
    };
