import 'package:result_dart/result_dart.dart';

/// 阅读统计结果
class ReadingStats {
  const ReadingStats({
    required this.readableCharCount,
    required this.estimatedReadingTimeMinutes,
  });

  /// 可阅读字符数量
  final int readableCharCount;

  /// 预计阅读时间（分钟）
  final double estimatedReadingTimeMinutes;
}

/// 阅读统计计算器
/// 负责HTML内容解析和阅读时间计算
class ReadingStatsCalculator {
  const ReadingStatsCalculator();

  /// 计算HTML内容的可阅读字符数量和预计阅读时间
  ///
  /// [htmlContent] HTML内容字符串
  /// 返回包含可阅读字符数量和预计阅读时间的结果
  Result<ReadingStats> calculateReadingStats(String htmlContent) {
    try {
      // 移除HTML标签，保留文本内容
      final cleanText = _removeHtmlTags(htmlContent);

      // 计算可阅读字符数量
      final readableCharCount = _countReadableCharacters(cleanText);

      // 计算预计阅读时间
      final estimatedTime = _calculateReadingTime(cleanText);

      return Success(ReadingStats(
        readableCharCount: readableCharCount,
        estimatedReadingTimeMinutes: estimatedTime,
      ));
    } catch (e) {
      return Failure(Exception("计算阅读统计时发生错误: $e"));
    }
  }

  /// 移除HTML标签，保留纯文本内容
  String _removeHtmlTags(String htmlContent) {
    // 移除script和style标签及其内容
    String cleanContent = htmlContent.replaceAll(
      RegExp(r'<(script|style)[^>]*>[\s\S]*?</\1>', caseSensitive: false),
      '',
    );

    // 移除所有HTML标签
    cleanContent = cleanContent.replaceAll(RegExp(r'<[^>]*>'), '');

    // 解码HTML实体
    cleanContent = _decodeHtmlEntities(cleanContent);

    // 规范化空白字符
    cleanContent = cleanContent.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleanContent;
  }

  /// 解码常见的HTML实体
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '…');
  }

  /// 计算可阅读字符数量
  /// 对中文字符和英文单词进行不同的计数方式
  int _countReadableCharacters(String text) {
    if (text.isEmpty) return 0;

    int count = 0;

    // 分别处理中文字符和英文单词
    final runes = text.runes.toList();

    for (int i = 0; i < runes.length; i++) {
      final char = String.fromCharCode(runes[i]);

      // 判断是否为中文字符（包括中文标点）
      if (_isChineseCharacter(char)) {
        count++;
      } else if (_isAlphanumeric(char)) {
        // 对于英文字符，按单词计数
        // 跳过当前单词的其余字符
        while (i + 1 < runes.length &&
            _isAlphanumeric(String.fromCharCode(runes[i + 1]))) {
          i++;
        }
        count++; // 一个英文单词计为一个单位
      }
      // 忽略其他字符（空格、标点等）
    }

    return count;
  }

  /// 计算预计阅读时间（分钟）
  /// 中文：平均每分钟300-500字，取400字
  /// 英文：平均每分钟200-300词，取250词
  double _calculateReadingTime(String text) {
    if (text.isEmpty) return 0.0;

    int chineseCharCount = 0;
    int englishWordCount = 0;

    final runes = text.runes.toList();

    for (int i = 0; i < runes.length; i++) {
      final char = String.fromCharCode(runes[i]);

      if (_isChineseCharacter(char)) {
        chineseCharCount++;
      } else if (_isAlphanumeric(char)) {
        // 计算英文单词
        while (i + 1 < runes.length &&
            _isAlphanumeric(String.fromCharCode(runes[i + 1]))) {
          i++;
        }
        englishWordCount++;
      }
    }

    // 中文阅读速度：400字/分钟
    // 英文阅读速度：250词/分钟
    final chineseReadingTime = chineseCharCount / 400.0;
    final englishReadingTime = englishWordCount / 250.0;

    return chineseReadingTime + englishReadingTime;
  }

  /// 判断是否为中文字符
  bool _isChineseCharacter(String char) {
    final codeUnit = char.codeUnitAt(0);
    return (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) || // 中日韩统一表意文字
        (codeUnit >= 0x3400 && codeUnit <= 0x4DBF) || // 中日韩统一表意文字扩展A
        (codeUnit >= 0x20000 && codeUnit <= 0x2A6DF) || // 中日韩统一表意文字扩展B
        (codeUnit >= 0x2A700 && codeUnit <= 0x2B73F) || // 中日韩统一表意文字扩展C
        (codeUnit >= 0x2B740 && codeUnit <= 0x2B81F) || // 中日韩统一表意文字扩展D
        (codeUnit >= 0x3000 && codeUnit <= 0x303F) || // 中日韩符号和标点
        (codeUnit >= 0xFF00 && codeUnit <= 0xFFEF); // 全角ASCII、全角标点
  }

  /// 判断是否为字母或数字
  bool _isAlphanumeric(String char) {
    final codeUnit = char.codeUnitAt(0);
    return (codeUnit >= 0x30 && codeUnit <= 0x39) || // 数字 0-9
        (codeUnit >= 0x41 && codeUnit <= 0x5A) || // 大写字母 A-Z
        (codeUnit >= 0x61 && codeUnit <= 0x7A); // 小写字母 a-z
  }
}
