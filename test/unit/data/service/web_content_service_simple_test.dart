import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:readeck_app/data/service/web_content_service.dart';
import 'package:readeck_app/utils/network_error_exception.dart';

import '../../../helpers/test_logger_helper.dart';
import 'web_content_service_simple_test.mocks.dart';

// Generate Mock classes
@GenerateMocks([http.Client])
void main() {
  setUpAll(() {
    setupTestLogger();
  });

  group('WebContentService', () {
    late MockClient mockHttpClient;
    late WebContentService service;

    setUp(() {
      mockHttpClient = MockClient();
      service = WebContentService(httpClient: mockHttpClient);
    });

    tearDown(() {
      service.dispose();
    });

    group('fetchWebContent', () {
      const testUrl = 'https://example.com/article';
      const validHtml = '''
        <!DOCTYPE html>
        <html>
        <head>
          <title>Test Article Title</title>
          <meta property="og:title" content="OG Title">
        </head>
        <body>
          <h1>Main Heading</h1>
          <article>
            <p>This is the main content of the article.</p>
            <p>It contains multiple paragraphs with useful information.</p>
          </article>
          <script>console.log('script');</script>
          <nav>Navigation content</nav>
        </body>
        </html>
      ''';

      test('should successfully fetch and parse web content', () async {
        when(mockHttpClient.get(
          Uri.parse(testUrl),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(validHtml, 200));

        final result = await service.fetchWebContent(testUrl);

        expect(result.isSuccess(), isTrue);
        final webContent = result.getOrThrow();
        expect(webContent.url, equals(testUrl));
        expect(webContent.title, equals('Test Article Title'));
        expect(webContent.content, contains('This is the main content'));
        expect(webContent.content, isNot(contains('script')));
        expect(webContent.content, isNot(contains('Navigation')));
      });

      test('should extract title from title tag', () async {
        const htmlWithTitle = '''
          <html><head><title>Page Title</title></head><body></body></html>
        ''';

        when(mockHttpClient.get(
          Uri.parse(testUrl),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(htmlWithTitle, 200));

        final result = await service.fetchWebContent(testUrl);

        expect(result.isSuccess(), isTrue);
        expect(result.getOrThrow().title, equals('Page Title'));
      });

      test('should extract title from og:title when title tag is empty',
          () async {
        const htmlWithOgTitle = '''
          <html>
          <head>
            <title></title>
            <meta property="og:title" content="Open Graph Title">
          </head>
          <body></body>
          </html>
        ''';

        when(mockHttpClient.get(
          Uri.parse(testUrl),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(htmlWithOgTitle, 200));

        final result = await service.fetchWebContent(testUrl);

        expect(result.isSuccess(), isTrue);
        expect(result.getOrThrow().title, equals('Open Graph Title'));
      });

      test('should handle invalid URL format', () async {
        const invalidUrl = 'not-a-valid-url';

        final result = await service.fetchWebContent(invalidUrl);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull().toString(), contains('无效的URL格式'));
        verifyNever(mockHttpClient.get(any, headers: anyNamed('headers')));
      });

      test('should handle HTTP error responses', () async {
        when(mockHttpClient.get(
          Uri.parse(testUrl),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('Not Found', 404));

        final result = await service.fetchWebContent(testUrl);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), isA<NetworkErrorException>());
      });

      test('should handle network timeout', () async {
        when(mockHttpClient.get(
          Uri.parse(testUrl),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 20));
          return http.Response('OK', 200);
        });

        final result = await service.fetchWebContent(
          testUrl,
          timeout: const Duration(seconds: 1),
        );

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull(), isA<TimeoutException>());
      });

      test('should handle network exceptions', () async {
        when(mockHttpClient.get(
          Uri.parse(testUrl),
          headers: anyNamed('headers'),
        )).thenThrow(const SocketException('Network unreachable'));

        final result = await service.fetchWebContent(testUrl);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull().toString(), contains('获取网页内容失败'));
      });

      test('should use proper headers for requests', () async {
        when(mockHttpClient.get(
          Uri.parse(testUrl),
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response('<html></html>', 200));

        await service.fetchWebContent(testUrl);

        verify(mockHttpClient.get(
          Uri.parse(testUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (compatible; ReadeckApp/1.0)',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
          },
        )).called(1);
      });

      test('should reject URLs without scheme', () async {
        const noSchemeUrl = 'example.com';

        final result = await service.fetchWebContent(noSchemeUrl);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull().toString(), contains('无效的URL格式'));
      });

      test('should reject non-HTTP schemes', () async {
        const ftpUrl = 'ftp://example.com';

        final result = await service.fetchWebContent(ftpUrl);

        expect(result.isError(), isTrue);
        expect(result.exceptionOrNull().toString(), contains('无效的URL格式'));
      });
    });

    group('WebContent model', () {
      test('should create WebContent with all fields', () {
        const webContent = WebContent(
          url: 'https://example.com',
          title: 'Test Title',
          content: 'Test content',
        );

        expect(webContent.url, equals('https://example.com'));
        expect(webContent.title, equals('Test Title'));
        expect(webContent.content, equals('Test content'));
      });

      test('should provide meaningful toString representation', () {
        const webContent = WebContent(
          url: 'https://example.com',
          title: 'Test Title',
          content: 'Test content',
        );

        final string = webContent.toString();
        expect(string, contains('https://example.com'));
        expect(string, contains('Test Title'));
        expect(string, contains('contentLength: 12'));
      });
    });
  });
}
