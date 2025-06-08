import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'daily_read_history.freezed.dart';
part 'daily_read_history.g.dart';

@freezed
abstract class DailyReadHistory with _$DailyReadHistory {
  const factory DailyReadHistory(
      {@Converter() required String id,
      required DateTime createdDate,
      required List<String> bookmarkIds}) = _DailyReadHistory;

  factory DailyReadHistory.fromJson(Map<String, Object?> json) =>
      _$DailyReadHistoryFromJson(json);
}

class Converter
    implements JsonConverter<DailyReadHistory, Map<String, Object?>> {
  const Converter();
  @override
  DailyReadHistory fromJson(Map<String, Object?> json) {
    return DailyReadHistory(
      id: json['id'] as String,
      createdDate: DateTime.parse(json['created_date'] as String),
      bookmarkIds: (jsonDecode(json['bookmark_ids'] as String) as List)
          .map((e) => e.toString())
          .toList(),
    );
  }

  @override
  Map<String, Object?> toJson(DailyReadHistory object) {
    return {
      'id': object.id,
      'created_date': object.createdDate.toString(),
      'bookmark_ids': jsonEncode(object.bookmarkIds),
    };
  }
}
