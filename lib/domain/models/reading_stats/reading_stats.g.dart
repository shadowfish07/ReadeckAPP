// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReadingStatsModel _$ReadingStatsModelFromJson(Map<String, dynamic> json) =>
    _ReadingStatsModel(
      id: (json['id'] as num?)?.toInt(),
      bookmarkId: json['bookmarkId'] as String,
      readableCharCount: (json['readableCharCount'] as num).toInt(),
      createdDate: DateTime.parse(json['createdDate'] as String),
    );

Map<String, dynamic> _$ReadingStatsModelToJson(_ReadingStatsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookmarkId': instance.bookmarkId,
      'readableCharCount': instance.readableCharCount,
      'createdDate': instance.createdDate.toIso8601String(),
    };
