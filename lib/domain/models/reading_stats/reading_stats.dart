// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_stats.freezed.dart';
part 'reading_stats.g.dart';

/// 阅读统计数据模型
/// 用于存储书签文章的字数统计信息
@freezed
abstract class ReadingStatsModel with _$ReadingStatsModel {
  const factory ReadingStatsModel({
    /// 数据库主键ID
    int? id,

    /// 书签ID
    required String bookmarkId,

    /// 统计数据
    @JsonKey(name: 'character_count') required CharacterCount characterCount,

    /// 创建时间
    required DateTime createdDate,
  }) = _ReadingStatsModel;

  factory ReadingStatsModel.fromJson(Map<String, dynamic> json) =>
      _$ReadingStatsModelFromJson(json);
}

/// 阅读统计详细数据
/// 用于存储各种类型的字符统计信息
@freezed
abstract class CharacterCount with _$CharacterCount {
  const CharacterCount._();

  const factory CharacterCount({
    /// 中文字符数量
    @Default(0) int chineseCharCount,

    /// 英文字符数量
    @Default(0) int englishCharCount,
  }) = _ReadingStatsData;

  factory CharacterCount.fromJson(Map<String, dynamic> json) =>
      _$ReadingStatsDataFromJson(json);

  int get totalCharCount => chineseCharCount + englishCharCount;
}
