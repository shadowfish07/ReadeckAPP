// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_read_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DailyReadHistory _$DailyReadHistoryFromJson(Map<String, dynamic> json) =>
    _DailyReadHistory(
      id: (json['id'] as num).toInt(),
      createdDate: _dateTimeFromJson(json['created_date'] as String),
      bookmarkIds: _bookmarkIdsFromJson(json['bookmark_ids'] as String),
    );

Map<String, dynamic> _$DailyReadHistoryToJson(_DailyReadHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created_date': _dateTimeToJson(instance.createdDate),
      'bookmark_ids': _bookmarkIdsToJson(instance.bookmarkIds),
    };
