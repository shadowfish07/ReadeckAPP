// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'label_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LabelInfo _$LabelInfoFromJson(Map<String, dynamic> json) => _LabelInfo(
      name: json['name'] as String,
      count: (json['count'] as num).toInt(),
      href: json['href'] as String,
      hrefBookmarks: json['href_bookmarks'] as String,
    );

Map<String, dynamic> _$LabelInfoToJson(_LabelInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'count': instance.count,
      'href': instance.href,
      'href_bookmarks': instance.hrefBookmarks,
    };
