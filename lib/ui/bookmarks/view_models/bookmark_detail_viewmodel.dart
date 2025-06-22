import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:logger/logger.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/domain/models/bookmark/bookmark.dart';
import 'package:readeck_app/domain/use_cases/bookmark_operation_use_cases.dart';
import 'package:readeck_app/domain/use_cases/bookmark_use_cases.dart';
import 'package:readeck_app/domain/use_cases/label_use_cases.dart';

class BookmarkDetailViewModel extends ChangeNotifier {
  BookmarkDetailViewModel(
      this._bookmarkRepository,
      this._bookmarkOperationUseCases,
      this._bookmarkUseCases,
      this._labelUseCases,
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
  }

  final _log = Logger();
  final BookmarkUseCases _bookmarkUseCases;
  final BookmarkRepository _bookmarkRepository;
  final BookmarkOperationUseCases _bookmarkOperationUseCases;
  final LabelUseCases _labelUseCases;
  Bookmark _bookmark;

  late Command<void, String> loadArticleContent;
  late Command<int, void> updateReadProgressCommand;
  late Command<String, void> openUrl;
  late Command<void, void> archiveBookmarkCommand;
  late Command<void, void> toggleMarkCommand;
  late Command<void, void> deleteBookmarkCommand;
  late Command<void, List<String>> loadLabels;

  Bookmark get bookmark => _bookmark;
  String get articleHtml => loadArticleContent.value;
  bool get isLoading => loadArticleContent.isExecuting.value;

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
    _bookmark = _bookmarkUseCases.getBookmark(bookmark.id);
    notifyListeners();
  }

  Future<String> _loadArticleContent(void _) async {
    try {
      _log.d('Loading article content for bookmark: ${bookmark.id}');

      final result = await _bookmarkRepository.getBookmarkArticle(bookmark.id);

      if (result.isSuccess()) {
        final htmlContent = result.getOrThrow();
        _log.d(
            'Successfully loaded article content, length: ${htmlContent.length}');
        return htmlContent;
      } else {
        final error = result.exceptionOrNull();
        _log.e('Failed to load article content: $error');
        throw error ?? Exception('Unknown error occurred');
      }
    } catch (e) {
      _log.e('Exception while loading article content: $e');
      rethrow;
    }
  }

  void retry() {
    loadArticleContent.execute();
  }

  Future<void> _updateReadProgress(int readProgress) async {
    try {
      _log.d(
          'Updating read progress for bookmark: ${bookmark.id}, progress: $readProgress');

      final result = await _bookmarkRepository.updateReadProgress(
          bookmark.id, readProgress);

      _reloadBookmark();

      if (result.isSuccess()) {
        _log.d('Successfully updated read progress');
      } else {
        final error = result.exceptionOrNull();
        _log.e('Failed to update read progress: $error');
        throw error ?? Exception('Failed to update read progress');
      }
    } catch (e) {
      _log.e('Exception while updating read progress: $e');
      rethrow;
    }
  }

  Future<void> _openUrl(String url) async {
    final result = await _bookmarkOperationUseCases.openUrl(url);
    if (result.isError()) {
      final error = result.exceptionOrNull();
      _log.e('Failed to open URL: $error');
      throw error ?? Exception('Failed to open URL');
    }
  }

  Future<void> _archiveBookmark() async {
    try {
      _log.d('Archiving bookmark: ${bookmark.id}');

      final result =
          await _bookmarkOperationUseCases.toggleBookmarkArchived(bookmark);
      _reloadBookmark();

      if (result.isSuccess()) {
        _log.d('Successfully archived bookmark');
      } else {
        final error = result.exceptionOrNull();
        _log.e('Failed to archive bookmark: $error');
        throw error ?? Exception('Failed to archive bookmark');
      }
    } catch (e) {
      _log.e('Exception while archiving bookmark: $e');
      rethrow;
    }
  }

  Future<void> _toggleBookmarkMarked() async {
    try {
      _log.d('Toggling bookmark marked: ${bookmark.id}');

      final result =
          await _bookmarkOperationUseCases.toggleBookmarkMarked(bookmark);
      _reloadBookmark();

      if (result.isSuccess()) {
        _log.d('Successfully toggled bookmark marked');
      } else {
        final error = result.exceptionOrNull();
        _log.e('Failed to toggle bookmark marked: $error');
        throw error ?? Exception('Failed to toggle bookmark marked');
      }
    } catch (e) {
      _log.e('Exception while toggling bookmark marked: $e');
      rethrow;
    }
  }

  Future<void> _deleteBookmark() async {
    try {
      _log.d('Deleting bookmark: ${bookmark.id}');

      final result =
          await _bookmarkOperationUseCases.deleteBookmark(bookmark.id);

      if (result.isSuccess()) {
        _log.d('Successfully deleted bookmark');
      } else {
        final error = result.exceptionOrNull();
        _log.e('Failed to delete bookmark: $error');
        throw error ?? Exception('Failed to delete bookmark');
      }
    } catch (e) {
      _log.e('Exception while deleting bookmark: $e');
      rethrow;
    }
  }

  Future<void> updateBookmarkLabels(List<String> labels) async {
    try {
      _log.d('Updating bookmark labels: ${bookmark.id}');

      final result = await _bookmarkOperationUseCases.updateBookmarkLabels(
          bookmark, labels);
      _reloadBookmark();

      if (result.isSuccess()) {
        _log.d('Successfully updated bookmark labels');
      } else {
        final error = result.exceptionOrNull();
        _log.e('Failed to update bookmark labels: $error');
        throw error ?? Exception('Failed to update bookmark labels');
      }
    } catch (e) {
      _log.e('Exception while updating bookmark labels: $e');
      rethrow;
    }
  }

  Future<List<String>> _loadLabels() async {
    final result = await _bookmarkRepository.getLabels();
    if (result.isSuccess()) {
      _labelUseCases.insertOrUpdateLabels(result.getOrDefault([]));
      return _labelUseCases.labelNames;
    }

    _log.e("Failed to load labels", error: result.exceptionOrNull()!);
    throw result.exceptionOrNull()!;
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
