import 'package:readeck_app/data/service/readeck_api_client.dart';
import 'package:readeck_app/domain/models/bookmark/label_info.dart';
import 'package:readeck_app/main.dart';
import 'package:result_dart/result_dart.dart';

/// 标签数据变化监听器类型定义
typedef LabelChangeListener = void Function();

class LabelRepository {
  LabelRepository(this._readeckApiClient);

  final ReadeckApiClient _readeckApiClient;
  final List<LabelInfo> _labels = [];
  final List<LabelChangeListener> _listeners = [];

  List<LabelInfo> get labels => List.unmodifiable(_labels);

  /// 添加数据变化监听器
  void addListener(LabelChangeListener listener) {
    _listeners.add(listener);
  }

  /// 移除数据变化监听器
  void removeListener(LabelChangeListener listener) {
    _listeners.remove(listener);
  }

  /// 通知所有监听器数据已变化
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void insertOrUpdateLabel(LabelInfo label) {
    final index = _labels.indexWhere((l) => l.name == label.name);
    if (index != -1) {
      _labels[index] = label;
    } else {
      _labels.add(label);
    }
    _notifyListeners();
  }

  void _insertOrUpdateLabels(List<LabelInfo> labels) {
    for (var label in labels) {
      insertOrUpdateLabel(label);
    }
  }

  LabelInfo? getCachedLabel(String name) {
    try {
      return _labels.firstWhere((l) => l.name == name);
    } catch (e) {
      appLogger.w('Label $name not found in cache');
      return null;
    }
  }

  List<LabelInfo> getCachedLabels(List<String> names) {
    return names
        .map((name) => getCachedLabel(name))
        .where((label) => label != null)
        .cast<LabelInfo>()
        .toList();
  }

  AsyncResult<List<LabelInfo>> loadLabels() async {
    final result = await _readeckApiClient.getLabels();
    if (result.isSuccess()) {
      _insertOrUpdateLabels(result.getOrThrow());
      return result;
    }

    return result;
  }

  /// 获取所有标签名称列表
  List<String> get labelNames => _labels.map((l) => l.name).toList();

  /// 释放资源，清空所有监听器
  void dispose() {
    _listeners.clear();
  }
}
