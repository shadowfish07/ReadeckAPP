import 'package:flutter_test/flutter_test.dart';
import 'package:readeck_app/domain/models/reading_stats/reading_stats.dart';
import 'package:readeck_app/utils/reading_stats_calculator.dart';

void main() {
  group('ReadingStatsCalculator Tests', () {
    late ReadingStatsCalculator calculator;

    setUp(() {
      calculator = const ReadingStatsCalculator();
    });

    group('calculateReadingStats', () {
      test('should calculate stats for simple text', () {
        // Arrange
        const htmlContent = '<p>Hello world</p>';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(statsForView.readableCharCount, 2); // "Hello" and "world"
        expect(characterCount.englishCharCount, 2);
        expect(characterCount.chineseCharCount, 0);
      });

      test('should calculate stats for Chinese text', () {
        // Arrange
        const htmlContent = '<p>你好世界</p>';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(statsForView.readableCharCount, 4); // 4 Chinese characters
        expect(characterCount.chineseCharCount, 4);
        expect(characterCount.englishCharCount, 0);
      });

      test('should calculate stats for mixed Chinese and English text', () {
        // Arrange
        const htmlContent = '<p>Hello 世界 world 你好</p>';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(statsForView.readableCharCount,
            6); // 2 English words + 4 Chinese chars
        expect(characterCount.englishCharCount, 2);
        expect(characterCount.chineseCharCount, 4);
      });

      test('should handle empty content', () {
        // Arrange
        const htmlContent = '';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(statsForView.readableCharCount, 0);
        expect(characterCount.englishCharCount, 0);
        expect(characterCount.chineseCharCount, 0);
      });

      test('should handle HTML with only tags', () {
        // Arrange
        const htmlContent = '<div><span></span></div>';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(statsForView.readableCharCount, 0);
        expect(characterCount.englishCharCount, 0);
        expect(characterCount.chineseCharCount, 0);
      });

      test('should remove script and style tags', () {
        // Arrange
        const htmlContent = '''
          <div>
            <script>console.log('test');</script>
            <style>body { color: red; }</style>
            <p>Hello world</p>
          </div>
        ''';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(statsForView.readableCharCount, 2); // Only "Hello" and "world"
        expect(characterCount.englishCharCount, 2);
        expect(characterCount.chineseCharCount, 0);
      });

      test('should decode HTML entities', () {
        // Arrange
        const htmlContent = '<p>&quot;Hello&quot; &amp; &lt;world&gt;</p>';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(statsForView.readableCharCount, 2); // "Hello" and "world"
        expect(characterCount.englishCharCount, 2);
        expect(characterCount.chineseCharCount, 0);
      });

      test('should handle complex HTML structure', () {
        // Arrange
        const htmlContent = '''
          <html>
            <head><title>Test</title></head>
            <body>
              <div class="content">
                <h1>标题 Title</h1>
                <p>这是一段中文内容。This is English content.</p>
                <ul>
                  <li>列表项 Item 1</li>
                  <li>列表项 Item 2</li>
                </ul>
              </div>
            </body>
          </html>
        ''';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        // Chinese: 标题(2) + 这是一段中文内容(7) + 。(1) + 列表项(3) + 列表项(3) + 。(1) = 17
        // English: Test(1) + Title(1) + This(1) + is(1) + English(1) + content(1) + Item(1) + 1(1) + Item(1) + 2(1) = 10
        expect(characterCount.chineseCharCount, 17);
        expect(characterCount.englishCharCount, 10);
        expect(statsForView.readableCharCount, 27);
      });

      test('should calculate correct reading time', () {
        // Arrange
        const htmlContent = '<p>你好世界</p>'; // 4 Chinese characters

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, _) = result.getOrNull()!;
        // 4 Chinese chars / 400 chars per minute = 0.01 minutes
        expect(statsForView.estimatedReadingTimeMinutes, closeTo(0.01, 0.001));
      });

      test('should handle malformed HTML gracefully', () {
        // Arrange
        const htmlContent = '<p>Hello <b>world</p>'; // Missing closing tag

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(statsForView.readableCharCount, 2);
        expect(characterCount.englishCharCount, 2);
        expect(characterCount.chineseCharCount, 0);
      });
    });

    group('calculateCharacterCount', () {
      test('should count Chinese characters correctly', () {
        // Arrange
        const text = '你好世界测试';

        // Act
        final result = calculator.calculateCharacterCount(text);

        // Assert
        expect(result.chineseCharCount, 6);
        expect(result.englishCharCount, 0);
      });

      test('should count English words correctly', () {
        // Arrange
        const text = 'Hello world test';

        // Act
        final result = calculator.calculateCharacterCount(text);

        // Assert
        expect(result.englishCharCount, 3);
        expect(result.chineseCharCount, 0);
      });

      test('should count mixed text correctly', () {
        // Arrange
        const text = 'Hello 你好 world 世界';

        // Act
        final result = calculator.calculateCharacterCount(text);

        // Assert
        expect(result.englishCharCount, 2); // "Hello", "world"
        expect(result.chineseCharCount, 4); // "你", "好", "世", "界"
      });

      test('should handle numbers as English words', () {
        // Arrange
        const text = 'Test 123 hello 456';

        // Act
        final result = calculator.calculateCharacterCount(text);

        // Assert
        expect(result.englishCharCount, 4); // "Test", "123", "hello", "456"
        expect(result.chineseCharCount, 0);
      });

      test('should handle punctuation correctly', () {
        // Arrange
        const text = 'Hello, world! 你好，世界！';

        // Act
        final result = calculator.calculateCharacterCount(text);

        // Assert
        expect(result.englishCharCount, 2); // "Hello", "world"
        expect(result.chineseCharCount, 6); // "你", "好", "，", "世", "界", "！"
      });

      test('should handle empty string', () {
        // Arrange
        const text = '';

        // Act
        final result = calculator.calculateCharacterCount(text);

        // Assert
        expect(result.englishCharCount, 0);
        expect(result.chineseCharCount, 0);
      });

      test('should handle whitespace only', () {
        // Arrange
        const text = '   \n\t  ';

        // Act
        final result = calculator.calculateCharacterCount(text);

        // Assert
        expect(result.englishCharCount, 0);
        expect(result.chineseCharCount, 0);
      });
    });

    group('calculateReadingTime', () {
      test('should calculate reading time for Chinese text', () {
        // Arrange
        const characterCount =
            CharacterCount(chineseCharCount: 400, englishCharCount: 0);

        // Act
        final result = calculator.calculateReadingTime(characterCount);

        // Assert
        expect(result, 1.0); // 400 chars / 400 chars per minute = 1 minute
      });

      test('should calculate reading time for English text', () {
        // Arrange
        const characterCount =
            CharacterCount(chineseCharCount: 0, englishCharCount: 250);

        // Act
        final result = calculator.calculateReadingTime(characterCount);

        // Assert
        expect(result, 1.0); // 250 words / 250 words per minute = 1 minute
      });

      test('should calculate reading time for mixed text', () {
        // Arrange
        const characterCount =
            CharacterCount(chineseCharCount: 200, englishCharCount: 125);

        // Act
        final result = calculator.calculateReadingTime(characterCount);

        // Assert
        // 200/400 + 125/250 = 0.5 + 0.5 = 1.0 minute
        expect(result, 1.0);
      });

      test('should handle zero characters', () {
        // Arrange
        const characterCount =
            CharacterCount(chineseCharCount: 0, englishCharCount: 0);

        // Act
        final result = calculator.calculateReadingTime(characterCount);

        // Assert
        expect(result, 0.0);
      });
    });

    group('Edge Cases', () {
      test('should handle very long text', () {
        // Arrange
        final longText = 'Hello ' * 1000; // 1000 "Hello" words
        final htmlContent = '<p>$longText</p>';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(characterCount.englishCharCount, 1000);
        expect(statsForView.readableCharCount, 1000);
      });

      test('should handle special Unicode characters', () {
        // Arrange
        const htmlContent = '<p>Hello 🌍 世界 emoji test</p>';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(characterCount.englishCharCount, 3); // "Hello", "emoji", "test"
        expect(characterCount.chineseCharCount, 2); // "世", "界"
        expect(statsForView.readableCharCount, 5);
      });

      test('should handle nested HTML tags', () {
        // Arrange
        const htmlContent = '''
          <div>
            <p><strong><em>Hello</em></strong> <span>world</span></p>
            <p>你好<b>世界</b></p>
          </div>
        ''';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(characterCount.englishCharCount, 2); // "Hello", "world"
        expect(characterCount.chineseCharCount, 4); // "你", "好", "世", "界"
        expect(statsForView.readableCharCount, 6);
      });

      test('should handle HTML with attributes', () {
        // Arrange
        const htmlContent = '''
          <div class="content" id="main">
            <p style="color: red;">Hello world</p>
            <a href="https://example.com" target="_blank">Link text</a>
          </div>
        ''';

        // Act
        final result = calculator.calculateReadingStats(htmlContent);

        // Assert
        expect(result.isSuccess(), true);
        final (statsForView, characterCount) = result.getOrNull()!;
        expect(characterCount.englishCharCount,
            4); // "Hello", "world", "Link", "text"
        expect(characterCount.chineseCharCount, 0);
        expect(statsForView.readableCharCount, 4);
      });
    });
  });
}
