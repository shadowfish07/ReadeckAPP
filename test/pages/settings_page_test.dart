import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readeck_app/pages/settings_page.dart';
import 'package:readeck_app/pages/about_page.dart';
import 'package:readeck_app/services/readeck_api_service.dart';

// Mock ReadeckApiService for testing
class MockReadeckApiService extends ReadeckApiService {
  String? _mockBaseUrl;
  String? _mockToken;
  bool _shouldThrowError = false;
  bool _shouldDelay = false;

  @override
  String? get baseUrl => _mockBaseUrl;

  @override
  String? get token => _mockToken;

  @override
  Future<void> initialize() async {
    // Mock initialization
  }

  @override
  Future<void> setConfig(String baseUrl, String token) async {
    if (_shouldDelay) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (_shouldThrowError) {
      throw Exception('保存配置失败');
    }
    _mockBaseUrl = baseUrl;
    _mockToken = token;
  }

  // Test helper methods
  void setMockConfig(String? baseUrl, String? token) {
    _mockBaseUrl = baseUrl;
    _mockToken = token;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  void setShouldDelay(bool shouldDelay) {
    _shouldDelay = shouldDelay;
  }
}

void main() {
  group('SettingsPage Tests', () {
    late MockReadeckApiService mockApiService;
    ThemeMode currentThemeMode = ThemeMode.system;
    bool themeChanged = false;

    void onThemeChanged(ThemeMode mode) {
      currentThemeMode = mode;
      themeChanged = true;
    }

    setUp(() {
      mockApiService = MockReadeckApiService();
      currentThemeMode = ThemeMode.system;
      themeChanged = false;
    });

    testWidgets('应该显示设置页面的基本结构', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            apiService: mockApiService,
            onThemeChanged: onThemeChanged,
            currentThemeMode: currentThemeMode,
          ),
        ),
      );

      // 验证AppBar
      expect(find.text('设置'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // 验证三个主要选项
      expect(find.text('API 配置'), findsOneWidget);
      expect(find.text('主题模式'), findsOneWidget);
      expect(find.text('关于'), findsOneWidget);

      // 验证图标
      expect(find.byIcon(Icons.api), findsOneWidget);
      expect(find.byIcon(Icons.palette), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('应该显示正确的主题模式文本', (WidgetTester tester) async {
      // 测试浅色模式
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            apiService: mockApiService,
            onThemeChanged: onThemeChanged,
            currentThemeMode: ThemeMode.light,
          ),
        ),
      );
      expect(find.text('浅色模式'), findsOneWidget);

      // 测试深色模式
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            apiService: mockApiService,
            onThemeChanged: onThemeChanged,
            currentThemeMode: ThemeMode.dark,
          ),
        ),
      );
      expect(find.text('深色模式'), findsOneWidget);

      // 测试跟随系统
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            apiService: mockApiService,
            onThemeChanged: onThemeChanged,
            currentThemeMode: ThemeMode.system,
          ),
        ),
      );
      expect(find.text('跟随系统'), findsOneWidget);
    });

    testWidgets('点击API配置应该导航到API配置页面', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            apiService: mockApiService,
            onThemeChanged: onThemeChanged,
            currentThemeMode: currentThemeMode,
          ),
        ),
      );

      // 点击API配置
      await tester.tap(find.text('API 配置'));
      await tester.pumpAndSettle();

      // 验证导航到API配置页面
      expect(find.text('Readeck API 配置'), findsOneWidget);
      expect(find.text('服务器地址'), findsOneWidget);
      expect(find.text('API 令牌'), findsOneWidget);
    });

    testWidgets('点击主题模式应该显示主题选择对话框', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            apiService: mockApiService,
            onThemeChanged: onThemeChanged,
            currentThemeMode: currentThemeMode,
          ),
        ),
      );

      // 点击主题模式
      await tester.tap(find.text('主题模式'));
      await tester.pumpAndSettle();

      // 验证对话框显示
      expect(find.text('选择主题模式'), findsOneWidget);
      expect(find.text('浅色模式'), findsOneWidget);
      expect(find.text('深色模式'), findsOneWidget);
      expect(find.text('跟随系统'), findsNWidgets(2)); // 一个在设置页面，一个在对话框中
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('在主题对话框中选择主题应该调用回调函数', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            apiService: mockApiService,
            onThemeChanged: onThemeChanged,
            currentThemeMode: ThemeMode.system,
          ),
        ),
      );

      // 点击主题模式打开对话框
      await tester.tap(find.text('主题模式'));
      await tester.pumpAndSettle();

      // 选择浅色模式
      await tester.tap(find.byType(RadioListTile<ThemeMode>).first);
      await tester.pumpAndSettle();

      // 验证主题已更改
      expect(themeChanged, isTrue);
      expect(currentThemeMode, equals(ThemeMode.light));
    });

    testWidgets('点击取消应该关闭主题对话框', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            apiService: mockApiService,
            onThemeChanged: onThemeChanged,
            currentThemeMode: currentThemeMode,
          ),
        ),
      );

      // 点击主题模式打开对话框
      await tester.tap(find.text('主题模式'));
      await tester.pumpAndSettle();

      // 点击取消
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // 验证对话框已关闭
      expect(find.text('选择主题模式'), findsNothing);
      expect(themeChanged, isFalse);
    });

    testWidgets('点击关于应该导航到关于页面', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(
            apiService: mockApiService,
            onThemeChanged: onThemeChanged,
            currentThemeMode: currentThemeMode,
          ),
        ),
      );

      // 点击关于
      await tester.tap(find.text('关于'));
      await tester.pumpAndSettle();

      // 验证导航到关于页面
      expect(find.byType(AboutPage), findsOneWidget);
    });
  });

  group('ApiConfigPage Tests', () {
    late MockReadeckApiService mockApiService;

    setUp(() {
      mockApiService = MockReadeckApiService();
      // 重置所有状态
      mockApiService.setMockConfig(null, null);
      mockApiService.setShouldThrowError(false);
      mockApiService.setShouldDelay(false);
    });

    testWidgets('未配置时输入框应该为空', (WidgetTester tester) async {
      // 设置为未配置状态
      mockApiService.setMockConfig(null, null);

      await tester.pumpWidget(
        MaterialApp(
          home: ApiConfigPage(apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      // 查找输入框
      final baseUrlField = find.byType(TextFormField).first;
      final tokenField = find.byType(TextFormField).last;

      final baseUrlWidget = tester.widget<TextFormField>(baseUrlField);
      final tokenWidget = tester.widget<TextFormField>(tokenField);

      // 验证输入框为空
      expect(baseUrlWidget.controller?.text ?? '', isEmpty);
      expect(tokenWidget.controller?.text ?? '', isEmpty);
    });

    testWidgets('已配置时应该回填之前的值', (WidgetTester tester) async {
      // 设置已配置状态
      const testBaseUrl = 'https://test.readeck.com';
      const testToken = 'test-token-123';
      mockApiService.setMockConfig(testBaseUrl, testToken);

      await tester.pumpWidget(
        MaterialApp(
          home: ApiConfigPage(apiService: mockApiService),
        ),
      );

      await tester.pumpAndSettle();

      // 查找输入框并验证值
      final baseUrlField = find.byType(TextFormField).first;
      final tokenField = find.byType(TextFormField).last;
      
      final baseUrlWidget = tester.widget<TextFormField>(baseUrlField);
      final tokenWidget = tester.widget<TextFormField>(tokenField);
      
      expect(baseUrlWidget.controller?.text, equals(testBaseUrl));
      expect(tokenWidget.controller?.text, equals(testToken));
    });

    testWidgets('应该显示API配置页面的基本结构', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ApiConfigPage(apiService: mockApiService),
        ),
      );

      // 验证页面标题和元素
      expect(find.text('API 配置'), findsOneWidget);
      expect(find.text('Readeck API 配置'), findsOneWidget);
      expect(find.text('服务器地址'), findsOneWidget);
      expect(find.text('API 令牌'), findsOneWidget);
      expect(find.text('保存配置'), findsOneWidget);
      expect(find.text('使用说明'), findsOneWidget);

      // 验证图标
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.key), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('输入验证应该正常工作', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ApiConfigPage(apiService: mockApiService),
        ),
      );

      // 点击保存配置按钮（不输入任何内容）
      await tester.tap(find.text('保存配置'));
      await tester.pumpAndSettle();

      // 验证显示验证错误
      expect(find.text('请输入服务器地址'), findsOneWidget);
      expect(find.text('请输入API令牌'), findsOneWidget);
    });

    testWidgets('URL格式验证应该正常工作', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ApiConfigPage(apiService: mockApiService),
        ),
      );

      // 输入无效的URL
      await tester.enterText(find.byType(TextFormField).first, 'invalid-url');
      await tester.enterText(find.byType(TextFormField).last, 'test-token');

      // 点击保存配置
      await tester.tap(find.text('保存配置'));
      await tester.pumpAndSettle();

      // 验证URL格式错误提示
      expect(find.text('请输入有效的URL（以http://或https://开头）'), findsOneWidget);
    });

    testWidgets('成功保存配置应该调用API服务', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ApiConfigPage(apiService: mockApiService),
        ),
      );

      // 输入有效的配置
      await tester.enterText(find.byType(TextFormField).first, 'https://test.readeck.com');
      await tester.enterText(find.byType(TextFormField).last, 'test-token');

      // 点击保存配置
      await tester.tap(find.text('保存配置'));
      await tester.pumpAndSettle();

      // 验证配置已保存到mock服务
      expect(mockApiService.baseUrl, equals('https://test.readeck.com'));
      expect(mockApiService.token, equals('test-token'));
    });

    testWidgets('保存配置失败时不应更新配置', (WidgetTester tester) async {
      // 设置API服务抛出错误
      mockApiService.setShouldThrowError(true);
      final originalBaseUrl = mockApiService.baseUrl;
      final originalToken = mockApiService.token;

      await tester.pumpWidget(
        MaterialApp(
          home: ApiConfigPage(apiService: mockApiService),
        ),
      );

      // 输入有效的配置
      await tester.enterText(find.byType(TextFormField).first, 'https://test.readeck.com');
      await tester.enterText(find.byType(TextFormField).last, 'test-token');

      // 点击保存配置
      await tester.tap(find.text('保存配置'));
      await tester.pumpAndSettle();

      // 验证配置没有被更新（因为保存失败）
      expect(mockApiService.baseUrl, equals(originalBaseUrl));
      expect(mockApiService.token, equals(originalToken));
    });

    testWidgets('保存过程中应该显示加载状态', (WidgetTester tester) async {
      // 设置延迟以便观察加载状态
      mockApiService.setShouldDelay(true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: ApiConfigPage(apiService: mockApiService),
        ),
      );

      // 输入有效的配置
      await tester.enterText(find.byType(TextFormField).first, 'https://test.readeck.com');
      await tester.enterText(find.byType(TextFormField).last, 'test-token');

      // 点击保存配置
      await tester.tap(find.text('保存配置'));
      await tester.pump(); // 触发状态更新

      // 验证显示加载指示器
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // 等待异步操作完成
      await tester.pumpAndSettle();
    });
  });
}