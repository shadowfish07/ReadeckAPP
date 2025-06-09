// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'daily_read_history.freezed.dart';
part 'daily_read_history.g.dart';

@freezed
abstract class DailyReadHistory with _$DailyReadHistory {
  const factory DailyReadHistory(
      {required int id,
      @JsonKey(
          name: "created_date",
          fromJson: _dateTimeFromJson,
          toJson: _dateTimeToJson)
      required DateTime createdDate,
      @JsonKey(
        name: "bookmark_ids",
        fromJson: _bookmarkIdsFromJson,
        toJson: _bookmarkIdsToJson,
      )
      required List<String> bookmarkIds}) = _DailyReadHistory;

  factory DailyReadHistory.fromJson(Map<String, Object?> json) =>
      _$DailyReadHistoryFromJson(json);
}

DateTime _dateTimeFromJson(String json) {
  return DateTime.parse(json);
}

String _dateTimeToJson(DateTime date) {
  return date.toIso8601String();
}

List<String> _bookmarkIdsFromJson(String json) {
  return List<String>.from(jsonDecode(json).map((item) => item.toString()));
}

String _bookmarkIdsToJson(List<String> bookmarkIds) {
  return jsonEncode(bookmarkIds);
}
