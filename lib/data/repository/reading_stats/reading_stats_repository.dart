import 'package:readeck_app/data/service/database_service.dart';
import 'package:readeck_app/domain/models/reading_stats/reading_stats.dart';
import 'package:readeck_app/main.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';
import 'package:result_dart/result_dart.dart';

/// 阅读统计数据仓库
/// 负责管理书签文章的阅读统计数据
class ReadingStatsRepository {
  final DatabaseService _databaseService;
  final ReadingStatsCalculator _calculator = const ReadingStatsCalculator();

  ReadingStatsRepository(
    this._databaseService,
  );

  /// 计算并保存书签的阅读统计数据
  ///
  /// [bookmarkId] 书签ID
  /// [htmlContent] HTML内容
  /// 返回计算结果和保存状态
  AsyncResult<ReadingStats> calculateAndSaveReadingStats(
    String bookmarkId,
    String htmlContent,
  ) async {
    try {
      appLogger.i('开始计算书签阅读统计数据: $bookmarkId');

      // 计算阅读统计
      final calculateResult = _calculator.calculateReadingStats(htmlContent);
      if (calculateResult.isError()) {
        final error = calculateResult.exceptionOrNull()!;
        appLogger.e('计算阅读统计失败: $bookmarkId', error: error);
        return Failure(error);
      }

      final stats = calculateResult.getOrNull()!;
      appLogger.i('计算完成 - 书签: $bookmarkId, 字数: ${stats.readableCharCount}');

      // 保存到数据库
      final model = ReadingStatsModel(
        bookmarkId: bookmarkId,
        readableCharCount: stats.readableCharCount,
        createdDate: DateTime.now(),
      );

      final saveResult =
          await _databaseService.insertOrUpdateReadingStats(model);
      if (saveResult.isError()) {
        final error = saveResult.exceptionOrNull()!;
        appLogger.e('保存阅读统计失败: $bookmarkId', error: error);
        return Failure(error);
      }

      appLogger.i('成功保存阅读统计数据: $bookmarkId');
      return Success(stats);
    } catch (e) {
      final error = Exception('计算并保存阅读统计时发生错误: $e');
      appLogger.e('计算并保存阅读统计异常: $bookmarkId', error: error);
      return Failure(error);
    }
  }

  /// 获取书签的阅读统计数据
  ///
  /// [bookmarkId] 书签ID
  /// 返回阅读统计数据，如果不存在则返回失败
  AsyncResult<ReadingStats> getReadingStats(String bookmarkId) async {
    try {
      appLogger.i('获取书签阅读统计数据: $bookmarkId');

      final result =
          await _databaseService.getReadingStatsByBookmarkId(bookmarkId);
      if (result.isError()) {
        final error = result.exceptionOrNull()!;
        appLogger.i('未找到书签阅读统计数据: $bookmarkId');
        return Failure(error);
      }

      final model = result.getOrNull()!;

      // 根据字数计算阅读时间
      final estimatedTime =
          _calculateReadingTimeFromCharCount(model.readableCharCount);

      final stats = ReadingStats(
        readableCharCount: model.readableCharCount,
        estimatedReadingTimeMinutes: estimatedTime,
      );

      appLogger.i('成功获取阅读统计数据: $bookmarkId, 字数: ${stats.readableCharCount}');
      return Success(stats);
    } catch (e) {
      final error = Exception('获取阅读统计时发生错误: $e');
      appLogger.e('获取阅读统计异常: $bookmarkId', error: error);
      return Failure(error);
    }
  }

  /// 删除书签的阅读统计数据
  ///
  /// [bookmarkId] 书签ID
  /// 返回删除操作的结果
  AsyncResult<void> deleteReadingStats(String bookmarkId) async {
    try {
      appLogger.i('删除书签阅读统计数据: $bookmarkId');

      final result = await _databaseService.deleteReadingStats(bookmarkId);
      if (result.isError()) {
        final error = result.exceptionOrNull()!;
        appLogger.e('删除阅读统计失败: $bookmarkId', error: error);
        return Failure(error);
      }

      appLogger.i('成功删除阅读统计数据: $bookmarkId');
      return const Success(unit);
    } catch (e) {
      final error = Exception('删除阅读统计时发生错误: $e');
      appLogger.e('删除阅读统计异常: $bookmarkId', error: error);
      return Failure(error);
    }
  }

  /// 根据字符数计算阅读时间
  ///
  /// [charCount] 字符数
  /// 返回预计阅读时间（分钟）
  double _calculateReadingTimeFromCharCount(int charCount) {
    // 使用与ReadingStatsCalculator相同的计算逻辑
    // 假设平均阅读速度为每分钟200-300字符（中文）或每分钟250个单词（英文约1250字符）
    const double averageReadingSpeedCharsPerMinute = 250.0;
    return charCount / averageReadingSpeedCharsPerMinute;
  }
}
