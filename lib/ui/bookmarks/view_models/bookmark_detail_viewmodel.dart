import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/article/article_repository.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/data/repository/settings/settings_repository.dart';
import 'package:readeck_app/main.dart';

class BookmarkDetailViewModel extends ChangeNotifier {
  BookmarkDetailViewModel(
      this._bookmarkRepository,
      this._articleRepository,
      this._bookmarkOperationUseCases,
      this._labelRepository,
      this._settingsRepository,
      this._bookmark) {
    // 注册标签数据变化监听器
    _labelRepository.addListener(_onLabelsChanged);
    // 注册书签数据变化监听器
    _bookmarkRepository.addListener(_onBookmarksChanged);
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

  final BookmarkRepository _bookmarkRepository;
  final ArticleRepository _articleRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final LabelRepository _labelRepository;
  final SettingsRepository _settingsRepository;
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
  List<String> get availableLabels => _labelRepository.labelNames;
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
    final newBookmark = _bookmarkRepository.getCachedBookmark(bookmark.id);
    if (newBookmark != null) {
      _bookmark = newBookmark;
      notifyListeners();
    }
  }

  Future<String> _loadArticleContent(void _) async {
    try {
      appLogger.i('Loading article content for bookmark: ${bookmark.id}');

      final result = await _articleRepository.getBookmarkArticle(bookmark.id);

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

      final result =
          await _bookmarkRepository.updateReadProgress(bookmark, readProgress);

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

      final result = await _bookmarkRepository.toggleArchived(bookmark);
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

      final result = await _bookmarkRepository.toggleMarked(bookmark);
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
    appLogger.i('Deleting bookmark: ${bookmark.id}');
    _bookmarkRepository.deleteBookmark(bookmark.id);
  }

  Future<void> updateBookmarkLabels(List<String> labels) async {
    try {
      appLogger.i('Updating bookmark labels: ${bookmark.id}');

      final result = await _bookmarkRepository.updateLabels(bookmark, labels);
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
    final result = await _labelRepository.loadLabels();
    if (result.isSuccess()) {
      return _labelRepository.labelNames;
    }

    appLogger.e("Failed to load labels", error: result.exceptionOrNull()!);
    throw result.exceptionOrNull()!;
  }

  /// AI翻译内容（流式处理）
  /// 通过Repository层进行翻译，优先从缓存获取翻译，如果缓存没有则使用AI翻译并写入缓存
  Future<void> _translateContent() async {
    try {
      appLogger.i('开始AI翻译内容');

      // 检查OpenRouter API Key是否已配置
      final apiKeyResult = await _settingsRepository.getOpenRouterApiKey();
      if (apiKeyResult.isError() || apiKeyResult.getOrNull()?.isEmpty == true) {
        appLogger.w('OpenRouter API Key未配置，无法进行AI翻译');
        throw '请先在设置中配置OpenRouter API Key';
      }

      _isTranslateMode = true;
      _isTranslating = true;
      _translatedContent = ''; // 清空之前的翻译内容
      notifyListeners();

      // 保存原始内容
      _originalContent = loadArticleContent.value;

      // 通过Repository进行流式翻译
      final translationStream = _articleRepository
          .translateBookmarkContentStream(_bookmark.id, _originalContent);

      await for (final result in translationStream) {
        if (result.isSuccess()) {
          _translatedContent = result.getOrThrow();
          // 实时更新UI显示翻译进度
          notifyListeners();
          appLogger.d('翻译进度更新: ${_translatedContent.length} 字符');
        } else {
          _isTranslating = false;
          notifyListeners();
          final error = result.exceptionOrNull();
          appLogger.e('翻译失败: ${_bookmark.id}', error: error);
          throw error ?? Exception('翻译失败');
        }
      }

      // 翻译完成
      _isTranslated = true;
      _isTranslating = false;
      notifyListeners();
      appLogger.i('翻译完成: ${_bookmark.id}');
    } catch (e) {
      _isTranslating = false;
      notifyListeners();
      appLogger.e('翻译异常: ${_bookmark.id}', error: e);
      rethrow;
    }
  }

  /// 切换显示原文/译文
  void toggleTranslation() {
    _isTranslateMode = !_isTranslateMode;
    if (_isTranslateMode) {
      _isTranslateBannerVisible = true;
    }
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

  /// 书签数据变化回调
  void _onBookmarksChanged() {
    // 更新当前书签数据
    final updatedBookmark = _bookmarkRepository.getCachedBookmark(_bookmark.id);
    if (updatedBookmark != null) {
      _bookmark = updatedBookmark;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // 移除标签数据变化监听器
    _labelRepository.removeListener(_onLabelsChanged);
    // 移除书签数据变化监听器
    _bookmarkRepository.removeListener(_onBookmarksChanged);
    super.dispose();
  }
}
