import 'package:readeck_app/domain/models/bookmark/label_info.dart';
import 'package:readeck_app/main.dart';

/// 标签数据变化监听器类型定义
typedef LabelChangeListener = void Function();

class LabelUseCases {
  LabelUseCases();

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

  void insertOrUpdateLabels(List<LabelInfo> labels) {
    for (var label in labels) {
      insertOrUpdateLabel(label);
    }
  }

  LabelInfo getLabel(String name) {
    return _labels.firstWhere((l) => l.name == name, orElse: () {
      appLogger.e('Label $name not found');
      throw ArgumentError('Label not found');
    });
  }

  List<LabelInfo> getLabels(List<String> names) {
    return names.map((name) => getLabel(name)).toList();
  }

  /// 获取所有标签名称列表
  List<String> get labelNames => _labels.map((l) => l.name).toList();

  /// 释放资源，清空所有监听器
  void dispose() {
    _listeners.clear();
  }
}
