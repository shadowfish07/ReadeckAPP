import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/service/openrouter_api_client.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/domain/use_cases/bookmark_use_cases.dart';
import 'package:readeck_app/domain/use_cases/label_use_cases.dart';
import 'package:readeck_app/main.dart';

class BookmarkDetailViewModel extends ChangeNotifier {
  BookmarkDetailViewModel(
      this._bookmarkRepository,
      this._bookmarkOperationUseCases,
      this._bookmarkUseCases,
      this._labelUseCases,
      this._openRouterApiClient,
      this._bookmark) {
    // 注册标签数据变化监听器
    _labelUseCases.addListener(_onLabelsChanged);
    loadArticleContent = Command.createAsync<void, String>(_loadArticleContent,
        initialValue: '', includeLastResultInCommandResults: true)
      ..execute();

    updateReadProgressCommand = Command.createSync<int, int>((s) => s,
        initialValue: 0)
      ..debounce(const Duration(milliseconds: 500)).listen((readProgress, _) {
        _updateReadProgress(readProgress);
      });

    openUrl = Command.createAsyncNoResult<String>(_openUrl);

    archiveBookmarkCommand =
        Command.createAsyncNoParamNoResult(_archiveBookmark);

    toggleMarkCommand =
        Command.createAsyncNoParamNoResult(_toggleBookmarkMarked);
    deleteBookmarkCommand = Command.createAsyncNoParamNoResult(_deleteBookmark);

    loadLabels = Command.createAsyncNoParam(_loadLabels, initialValue: []);

    translateContentCommand =
        Command.createAsyncNoParamNoResult(_translateContent);
  }

  final BookmarkUseCases _bookmarkUseCases;
  final BookmarkRepository _bookmarkRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final LabelUseCases _labelUseCases;
  final OpenRouterApiClient _openRouterApiClient;
  Bookmark _bookmark;

  // AI翻译相关状态
  bool _isTranslating = false;
  bool _isTranslated = false;
  bool _isTranslateMode = false;
  bool _isTranslateBannerVisible = true;
  String _translatedContent = '';
  String _originalContent = '';

  late Command<void, String> loadArticleContent;
  late Command<int, void> updateReadProgressCommand;
  late Command<String, void> openUrl;
  late Command<void, void> archiveBookmarkCommand;
  late Command<void, void> toggleMarkCommand;
  late Command<void, void> deleteBookmarkCommand;
  late Command<void, List<String>> loadLabels;
  late Command<void, void> translateContentCommand;

  Bookmark get bookmark => _bookmark;
  String get articleHtml =>
      _isTranslateMode ? _translatedContent : loadArticleContent.value;
  bool get isLoading => loadArticleContent.isExecuting.value;
  bool get isTranslating => _isTranslating;
  bool get isTranslated => _isTranslated;
  bool get isTranslateMode => _isTranslateMode;
  bool get isTranslateBannerVisible => _isTranslateBannerVisible;
  bool get canStartTranslate =>
      !_isTranslating && loadArticleContent.value.isNotEmpty && !_isTranslated;

  /// 获取可用的标签名称列表
  List<String> get availableLabels => _labelUseCases.labelNames;
  Exception? get error {
    final commandError = loadArticleContent.errors.value?.error;
    if (commandError is Exception) {
      return commandError;
    } else if (commandError != null) {
      return Exception(commandError.toString());
    }
    return null;
  }

  void _reloadBookmark() {
    final newBookmark = _bookmarkUseCases.getBookmark(bookmark.id);
    if (newBookmark != null) {
      _bookmark = newBookmark;
      notifyListeners();
    }
  }

  Future<String> _loadArticleContent(void _) async {
    try {
      appLogger.i('Loading article content for bookmark: ${bookmark.id}');

      final result = await _bookmarkRepository.getBookmarkArticle(bookmark.id);

      if (result.isSuccess()) {
        final htmlContent = result.getOrThrow();
        appLogger.i(
            'Successfully loaded article content, length: ${htmlContent.length}');
        return htmlContent;
      } else {
        final error = result.exceptionOrNull();
        appLogger.e('Failed to load article content: $error');
        throw error ?? Exception('Unknown error occurred');
      }
    } catch (e) {
      appLogger.e('Exception while loading article content: $e');
      rethrow;
    }
  }

  void retry() {
    loadArticleContent.execute();
  }

  Future<void> _updateReadProgress(int readProgress) async {
    try {
      appLogger.i(
          'Updating read progress for bookmark: ${bookmark.id}, progress: $readProgress');

      final result = await _bookmarkRepository.updateReadProgress(
          bookmark.id, readProgress);
      _bookmarkUseCases.insertOrUpdateBookmark(
          bookmark.copyWith(readProgress: readProgress));

      _reloadBookmark();

      if (result.isSuccess()) {
        appLogger.i('Successfully updated read progress');
      } else {
        final error = result.exceptionOrNull();
        appLogger.e('Failed to update read progress: $error');
        throw error ?? Exception('Failed to update read progress');
      }
    } catch (e) {
      appLogger.e('Exception while updating read progress: $e');
      rethrow;
    }
  }

  Future<void> _openUrl(String url) async {
    final result = await _bookmarkOperationUseCases.openUrl(url);
    if (result.isError()) {
      final error = result.exceptionOrNull();
      appLogger.e('Failed to open URL: $error');
      throw error ?? Exception('Failed to open URL');
    }
  }

  Future<void> _archiveBookmark() async {
    try {
      appLogger.i('Archiving bookmark: ${bookmark.id}');

      final result =
          await _bookmarkOperationUseCases.toggleBookmarkArchived(bookmark);
      _reloadBookmark();

      if (result.isSuccess()) {
        appLogger.i('Successfully archived bookmark');
      } else {
        final error = result.exceptionOrNull();
        appLogger.e('Failed to archive bookmark: $error');
        throw error ?? Exception('Failed to archive bookmark');
      }
    } catch (e) {
      appLogger.e('Exception while archiving bookmark: $e');
      rethrow;
    }
  }

  Future<void> _toggleBookmarkMarked() async {
    try {
      appLogger.i('Toggling bookmark marked: ${bookmark.id}');

      final result =
          await _bookmarkOperationUseCases.toggleBookmarkMarked(bookmark);
      _reloadBookmark();

      if (result.isSuccess()) {
        appLogger.i('Successfully toggled bookmark marked');
      } else {
        final error = result.exceptionOrNull();
        appLogger.e('Failed to toggle bookmark marked: $error');
        throw error ?? Exception('Failed to toggle bookmark marked');
      }
    } catch (e) {
      appLogger.e('Exception while toggling bookmark marked: $e');
      rethrow;
    }
  }

  Future<void> _deleteBookmark() async {
    try {
      appLogger.i('Deleting bookmark: ${bookmark.id}');

      final result =
          await _bookmarkOperationUseCases.deleteBookmark(bookmark.id);

      if (result.isSuccess()) {
        appLogger.i('Successfully deleted bookmark');
      } else {
        final error = result.exceptionOrNull();
        appLogger.e('Failed to delete bookmark: $error');
        throw error ?? Exception('Failed to delete bookmark');
      }
    } catch (e) {
      appLogger.e('Exception while deleting bookmark: $e');
      rethrow;
    }
  }

  Future<void> updateBookmarkLabels(List<String> labels) async {
    try {
      appLogger.i('Updating bookmark labels: ${bookmark.id}');

      final result = await _bookmarkOperationUseCases.updateBookmarkLabels(
          bookmark, labels);
      _reloadBookmark();

      if (result.isSuccess()) {
        appLogger.i('Successfully updated bookmark labels');
      } else {
        final error = result.exceptionOrNull();
        appLogger.e('Failed to update bookmark labels: $error');
        throw error ?? Exception('Failed to update bookmark labels');
      }
    } catch (e) {
      appLogger.e('Exception while updating bookmark labels: $e');
      rethrow;
    }
  }

  Future<List<String>> _loadLabels() async {
    final result = await _bookmarkRepository.getLabels();
    if (result.isSuccess()) {
      _labelUseCases.insertOrUpdateLabels(result.getOrDefault([]));
      return _labelUseCases.labelNames;
    }

    appLogger.e("Failed to load labels", error: result.exceptionOrNull()!);
    throw result.exceptionOrNull()!;
  }

  /// AI翻译内容
  Future<void> _translateContent() async {
    try {
      appLogger.i('开始AI翻译内容');

      _isTranslateMode = true;
      _isTranslating = true;
      notifyListeners();

      // 保存原始内容
      _originalContent = loadArticleContent.value;

      // 构建翻译提示
      final messages = [
        {
          'role': 'system',
          'content':
              '你是一个专业的翻译助手。请将用户提供的HTML内容翻译成中文，保持HTML标签结构不变，只翻译文本内容。请确保翻译准确、流畅、符合中文表达习惯。'
        },
        {'role': 'user', 'content': _originalContent}
      ];

      // 使用流式API进行翻译
      final translationStream = _openRouterApiClient.streamChatCompletion(
        model: 'google/gemini-2.5-flash',
        messages: messages,
        temperature: 0.3,
      );

      _translatedContent = '';

      await for (final result in translationStream) {
        if (result.isSuccess()) {
          final chunk = result.getOrThrow();
          appLogger.d("AI翻译内容 chunk: $chunk");
          _translatedContent += chunk;
          notifyListeners();
        } else {
          final error = result.exceptionOrNull();
          appLogger.e('AI翻译失败: $error');
          throw error ?? Exception('AI翻译失败');
        }
      }

      _isTranslated = true;
      _isTranslating = false;
      notifyListeners();

      appLogger.i('AI翻译完成');
    } catch (e) {
      _isTranslating = false;
      notifyListeners();
      appLogger.e('AI翻译异常: $e');
      rethrow;
    }
  }

  /// 切换显示原文/译文
  void toggleTranslation() {
    _isTranslateMode = !_isTranslateMode;
    notifyListeners();
  }

  /// 隐藏翻译横幅
  void hideTranslateBanner() {
    _isTranslateBannerVisible = false;
    notifyListeners();
  }

  /// 重置翻译状态
  void resetTranslation() {
    _isTranslated = false;
    _isTranslateMode = false;
    _isTranslating = false;
    _isTranslateBannerVisible = true;
    _translatedContent = '';
    _originalContent = '';
    notifyListeners();
  }

  /// 标签数据变化回调
  void _onLabelsChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    // 移除标签数据变化监听器
    _labelUseCases.removeListener(_onLabelsChanged);
    super.dispose();
  }
}
