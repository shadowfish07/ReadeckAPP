// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReadingStatsModel _$ReadingStatsModelFromJson(Map<String, dynamic> json) =>
    _ReadingStatsModel(
      id: (json['id'] as num?)?.toInt(),
      bookmarkId: json['bookmarkId'] as String,
      characterCount: CharacterCount.fromJson(
          json['character_count'] as Map<String, dynamic>),
      createdDate: DateTime.parse(json['createdDate'] as String),
    );

Map<String, dynamic> _$ReadingStatsModelToJson(_ReadingStatsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookmarkId': instance.bookmarkId,
      'character_count': instance.characterCount,
      'createdDate': instance.createdDate.toIso8601String(),
    };

_ReadingStatsData _$ReadingStatsDataFromJson(Map<String, dynamic> json) =>
    _ReadingStatsData(
      chineseCharCount: (json['chineseCharCount'] as num?)?.toInt() ?? 0,
      englishCharCount: (json['englishCharCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ReadingStatsDataToJson(_ReadingStatsData instance) =>
    <String, dynamic>{
      'chineseCharCount': instance.chineseCharCount,
      'englishCharCount': instance.englishCharCount,
    };
