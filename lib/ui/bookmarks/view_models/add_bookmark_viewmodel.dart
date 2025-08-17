import 'package:flutter/foundation.dart';
import 'package:flutter_command/flutter_command.dart';
import 'package:readeck_app/data/repository/bookmark/bookmark_repository.dart';
import 'package:readeck_app/data/repository/label/label_repository.dart';
import 'package:readeck_app/main.dart';

class AddBookmarkViewModel extends ChangeNotifier {
  AddBookmarkViewModel(this._bookmarkRepository, this._labelRepository) {
    createBookmark = Command.createAsync<CreateBookmarkParams, void>(
      _createBookmark,
      initialValue: null,
    );
    loadLabels = Command.createAsyncNoParam(_loadLabels, initialValue: []);

    // 注册标签数据变化监听器
    _labelRepository.addListener(_onLabelsChanged);

    // 预加载标签
    loadLabels.execute();
  }

  final BookmarkRepository _bookmarkRepository;
  final LabelRepository _labelRepository;

  late Command<CreateBookmarkParams, void> createBookmark;
  late Command<void, List<String>> loadLabels;

  String _url = '';
  String _title = '';
  List<String> _selectedLabels = [];

  String get url => _url;
  String get title => _title;
  List<String> get selectedLabels => List.unmodifiable(_selectedLabels);
  List<String> get availableLabels => _labelRepository.labelNames;

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
      notifyListeners();
    }
  }

  void clearForm() {
    _url = '';
    _title = '';
    _selectedLabels.clear();
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
