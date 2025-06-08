// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_read_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyReadHistory _$DailyReadHistoryFromJson(Map<String, dynamic> json) =>
    _DailyReadHistory(
      id: json['id'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      bookmarkIds: (json['bookmarkIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$DailyReadHistoryToJson(_DailyReadHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdDate': instance.createdDate.toIso8601String(),
      'bookmarkIds': instance.bookmarkIds,
    };
