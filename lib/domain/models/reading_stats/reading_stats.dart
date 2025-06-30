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

    /// 可阅读字符数量
    required int readableCharCount,

    /// 创建时间
    required DateTime createdDate,
  }) = _ReadingStatsModel;

  factory ReadingStatsModel.fromJson(Map<String, dynamic> json) =>
      _$ReadingStatsModelFromJson(json);
}
