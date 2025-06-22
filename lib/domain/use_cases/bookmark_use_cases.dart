import 'package:readeck_app/domain/models/bookmark/bookmark.dart';

/// 书签数据变化监听器类型定义
typedef BookmarkChangeListener = void Function();

class BookmarkUseCases {
  BookmarkUseCases();

  final List<Bookmark> _bookmarks = [];
  final List<BookmarkChangeListener> _listeners = [];

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  /// 添加数据变化监听器
  void addListener(BookmarkChangeListener listener) {
    _listeners.add(listener);
  }

  /// 移除数据变化监听器
  void removeListener(BookmarkChangeListener listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器数据已变化
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void insertOrUpdateBookmark(Bookmark bookmark) {
    final index = _bookmarks.indexWhere((b) => b.id == bookmark.id);
    if (index != -1) {
      _bookmarks[index] = bookmark;
    } else {
      _bookmarks.add(bookmark);
    }
    _notifyListeners();
  }

  void insertOrUpdateBookmarks(List<Bookmark> bookmarks) {
    for (var bookmark in bookmarks) {
      insertOrUpdateBookmark(bookmark);
    }
  }

  Bookmark? getBookmark(String id) {
    return _bookmarks.where((b) => b.id == id).firstOrNull;
  }

  List<Bookmark?> getBookmarks(List<String> ids) {
    return ids.map((id) => getBookmark(id)).toList();
  }

  void deleteBookmark(String id) {
    _bookmarks.removeWhere((b) => b.id == id);
    _notifyListeners();
  }

  /// 释放资源，清空所有监听器
  void dispose() {
    _listeners.clear();
  }
}
