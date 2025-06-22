import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';

class SharedPreferencesService {
  static const String _kThemeMode = 'themeMode';
  static const String _kReadeckApiHost = 'readeckApiHost';
  static const String _kReadeckApiToken = 'readeckApiToken';
  static const String _kReadingStatsPrefix = 'readingStats_';

  AsyncResult<void> setThemeMode(int value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setInt(_kThemeMode, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<int> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getInt(_kThemeMode) ?? ThemeMode.system.index;
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<void> setReadeckApiHost(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kReadeckApiHost, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<String> getReadeckApiHost() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kReadeckApiHost) ?? '';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<void> setReadeckApiToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_kReadeckApiToken, value);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  AsyncResult<String> getReadeckApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = prefs.getString(_kReadeckApiToken) ?? '';
      return Success(value);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 保存书签的阅读统计数据
  AsyncResult<void> setReadingStats(
      String bookmarkId, ReadingStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final statsJson = json.encode({
        'readableCharCount': stats.readableCharCount,
        'estimatedReadingTimeMinutes': stats.estimatedReadingTimeMinutes,
      });
      await prefs.setString('$_kReadingStatsPrefix$bookmarkId', statsJson);
      return const Success(unit);
    } on Exception catch (e) {
      return Failure(e);
    }
  }

  /// 获取书签的阅读统计数据
  AsyncResult<ReadingStats> getReadingStats(String bookmarkId) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final statsJson = prefs.getString('$_kReadingStatsPrefix$bookmarkId');
      if (statsJson == null) {
        return Failure(Exception('未找到书签的阅读统计数据'));
      }

      final statsMap = json.decode(statsJson) as Map<String, dynamic>;
      final stats = ReadingStats(
        readableCharCount: statsMap['readableCharCount'] as int,
        estimatedReadingTimeMinutes:
            (statsMap['estimatedReadingTimeMinutes'] as num).toDouble(),
      );
      return Success(stats);
    } on Exception catch (e) {
      return Failure(e);
    }
  }
}
