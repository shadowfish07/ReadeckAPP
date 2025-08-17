import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/data/repository/web_content/web_content_repository.dart';
import 'package:readeck_app/data/service/web_content_service.dart';
import 'package:readeck_app/data/repository/ai_tag_recommendation/ai_tag_recommendation_repository.dart';
import 'package:readeck_app/main.dart';

class AddBookmarkViewModel extends ChangeNotifier {
  AddBookmarkViewModel(
    this._bookmarkRepository,
    this._labelRepository,
    SettingsRepository
        settingsRepository, // Not stored as field, only used for DI
    this._webContentRepository,
    this._aiTagRecommendationRepository,
  ) {
    createBookmark = Command.createAsync<CreateBookmarkParams, void>(
      _createBookmark,
      initialValue: null,
    );
    loadLabels = Command.createAsyncNoParam(_loadLabels, initialValue: []);

    // 自动获取网页内容的命令
    autoFetchContentCommand = Command.createAsync<String, void>(
      _autoFetchContent,
      initialValue: null,
    );

    // 自动生成标签推荐的命令
    autoGenerateTagsCommand = Command.createAsync<WebContent, void>(
      _autoGenerateTags,
      initialValue: null,
    );

    // 注册标签数据变化监听器
    _labelRepository.addListener(_onLabelsChanged);

    // 预加载标签
    loadLabels.execute();
  }

  final BookmarkRepository _bookmarkRepository;
  final LabelRepository _labelRepository;
  // SettingsRepository is accessed via _aiTagRecommendationRepository
  final WebContentRepository _webContentRepository;
  final AiTagRecommendationRepository _aiTagRecommendationRepository;

  late Command<CreateBookmarkParams, void> createBookmark;
  late Command<void, List<String>> loadLabels;
  late Command<String, void> autoFetchContentCommand;
  late Command<WebContent, void> autoGenerateTagsCommand;

  String _url = '';
  String _title = '';
  List<String> _selectedLabels = [];
  List<String> _recommendedTags = [];
  bool _isContentFetched = false;
  bool _isTagsGenerated = false;
  bool _hasConsumedRecommendations = false; // 记录推荐标签是否已被消费

  String get url => _url;
  String get title => _title;
  List<String> get selectedLabels => List.unmodifiable(_selectedLabels);
  List<String> get availableLabels => _labelRepository.labelNames;
  List<String> get recommendedTags => List.unmodifiable(_recommendedTags);
  bool get isContentFetched => _isContentFetched;
  bool get isTagsGenerated => _isTagsGenerated;
  bool get hasAiModelConfigured => _aiTagRecommendationRepository.isAvailable;

  /// 检查是否应该显示推荐标签（未被消费且有可显示的标签）
  bool get shouldShowRecommendations =>
      !_hasConsumedRecommendations &&
      _recommendedTags.isNotEmpty &&
      _recommendedTags.any((tag) => !_selectedLabels.contains(tag));

  bool get isValidUrl {
    if (_url.isEmpty) return false;
    try {
      final uri = Uri.parse(_url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  bool get canSubmit => isValidUrl;

  void updateUrl(String url) {
    if (_url != url) {
      _url = url;

      // 清除之前的状态
      _title = '';
      _recommendedTags.clear();
      _isContentFetched = false;
      _isTagsGenerated = false;
      _hasConsumedRecommendations = false; // 重置推荐标签消费状态
      autoFetchContentCommand.clearErrors(); // 关键修复：清除旧的错误状态

      // 如果URL有效，自动获取内容
      if (isValidUrl) {
        autoFetchContentCommand.execute(url);
      }

      notifyListeners();
    }
  }

  void updateTitle(String title) {
    if (_title != title) {
      _title = title;
      notifyListeners();
    }
  }

  void updateSelectedLabels(List<String> labels) {
    if (!listEquals(_selectedLabels, labels)) {
      _selectedLabels = List.from(labels);
      notifyListeners();
    }
  }

  void addLabel(String label) {
    if (!_selectedLabels.contains(label)) {
      _selectedLabels.add(label);
      notifyListeners();
    }
  }

  void removeLabel(String label) {
    if (_selectedLabels.remove(label)) {
      // 如果删除的是推荐标签，且推荐已被标记为消费，需要重新检查
      if (_hasConsumedRecommendations && _recommendedTags.contains(label)) {
        // 如果不是所有推荐标签都还在选择列表中，重新启用推荐显示
        if (!_recommendedTags.every(
            (recommendedTag) => _selectedLabels.contains(recommendedTag))) {
          _hasConsumedRecommendations = false;
        }
      }
      notifyListeners();
    }
  }

  void clearForm() {
    _url = '';
    _title = '';
    _selectedLabels.clear();
    _recommendedTags.clear();
    _isContentFetched = false;
    _isTagsGenerated = false;
    _hasConsumedRecommendations = false;
    notifyListeners();
  }

  /// 处理分享的文本，仅提取URL
  void processSharedText(String sharedText) {
    appLogger.i('处理分享的文本: $sharedText');

    // 简单的URL检测和提取
    final urlRegex = RegExp(r'https?://[^\s]+');
    final match = urlRegex.firstMatch(sharedText);

    if (match != null) {
      final extractedUrl = match.group(0)!;
      updateUrl(extractedUrl);
      appLogger.i('解析分享内容 - URL: $extractedUrl');
    } else {
      appLogger.i('未找到URL，保持URL字段为空');
    }

    // 标题字段保持为空，让服务器自动获取
  }

  /// 添加推荐标签到已选标签
  void addRecommendedTag(String tag) {
    if (!_selectedLabels.contains(tag)) {
      _selectedLabels.add(tag);

      // 检查是否所有推荐标签都已被添加
      if (_recommendedTags.every(
          (recommendedTag) => _selectedLabels.contains(recommendedTag))) {
        _hasConsumedRecommendations = true; // 只有当所有推荐标签都被添加时才标记为已消费
      }

      notifyListeners();
    }
  }

  /// 添加所有推荐标签
  void addAllRecommendedTags() {
    bool hasAdded = false;
    for (final tag in _recommendedTags) {
      if (!_selectedLabels.contains(tag)) {
        _selectedLabels.add(tag);
        hasAdded = true;
      }
    }
    if (hasAdded) {
      _hasConsumedRecommendations = true; // 全部添加时直接标记为已消费
    }
    notifyListeners();
  }

  /// 手动重新获取内容和标签推荐
  void retryContentFetch() {
    autoFetchContentCommand.clearErrors();
    if (isValidUrl) {
      autoFetchContentCommand.execute(url);
    }
  }

  Future<void> _createBookmark(CreateBookmarkParams params) async {
    appLogger.i('开始创建书签: ${params.url}');

    final result = await _bookmarkRepository.createBookmark(
      url: params.url,
      title: params.title.isNotEmpty ? params.title : null,
      labels: params.labels.isNotEmpty ? params.labels : null,
    );

    if (result.isSuccess()) {
      appLogger.i('书签创建请求已提交，正在处理: ${params.url}');
      // 清空表单
      clearForm();
    } else {
      appLogger.e('书签创建失败: ${params.url}', error: result.exceptionOrNull());
      throw result.exceptionOrNull()!;
    }
  }

  Future<List<String>> _loadLabels() async {
    appLogger.i('开始加载标签');
    final result = await _labelRepository.loadLabels();
    if (result.isSuccess()) {
      final labelNames =
          result.getOrThrow().map((label) => label.name).toList();
      appLogger.i('成功加载 ${labelNames.length} 个标签');
      return labelNames;
    } else {
      appLogger.e('加载标签失败', error: result.exceptionOrNull());
      throw result.exceptionOrNull()!;
    }
  }

  /// 自动获取网页内容
  Future<void> _autoFetchContent(String url) async {
    appLogger.i('自动获取网页内容: $url');

    try {
      final result = await _webContentRepository.fetchWebContent(url);

      if (result.isSuccess()) {
        final webContent = result.getOrThrow();

        // 更新标题
        if (webContent.title.isNotEmpty) {
          _title = webContent.title;
          _isContentFetched = true;
          appLogger.i('自动填充标题: $_title');
        }

        // 如果配置了AI模型，自动生成标签推荐
        if (hasAiModelConfigured) {
          autoGenerateTagsCommand.execute(webContent);
        }

        notifyListeners();
      } else {
        final error = result.exceptionOrNull()!;
        appLogger.w('获取网页内容失败: $error');
        throw error;
      }
    } catch (e) {
      appLogger.e('自动获取网页内容时发生异常', error: e);
      rethrow;
    }
  }

  /// 自动生成标签推荐
  Future<void> _autoGenerateTags(WebContent webContent) async {
    appLogger.i('自动生成标签推荐');

    try {
      final result =
          await _aiTagRecommendationRepository.generateTagRecommendations(
        webContent,
        availableLabels,
      );

      if (result.isSuccess()) {
        _recommendedTags = result.getOrThrow();
        _isTagsGenerated = true;
        appLogger.i('自动生成标签推荐: $_recommendedTags');
        notifyListeners();
      } else {
        final error = result.exceptionOrNull()!;
        appLogger.w('生成标签推荐失败: $error');
        throw error;
      }
    } catch (e) {
      appLogger.e('自动生成标签推荐时发生异常', error: e);
      rethrow;
    }
  }

  void _onLabelsChanged() {
    appLogger.d('标签数据已变化，通知UI更新');
    notifyListeners();
  }

  @override
  void dispose() {
    // 移除标签数据变化监听器
    _labelRepository.removeListener(_onLabelsChanged);
    super.dispose();
  }
}

class CreateBookmarkParams {
  const CreateBookmarkParams({
    required this.url,
    this.title = '',
    this.labels = const [],
  });

  final String url;
  final String title;
  final List<String> labels;
}
