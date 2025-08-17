import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:readeck_app/main.dart';

/// 处理分享Intent接收的服务
class ShareIntentService {
  static final ShareIntentService _instance = ShareIntentService._internal();
  factory ShareIntentService() => _instance;
  ShareIntentService._internal();

  StreamController<String>? _shareTextController;
  StreamSubscription? _intentDataStreamSubscription;

  /// 分享文本数据流
  Stream<String> get shareTextStream =>
      _shareTextController?.stream ?? const Stream.empty();

  /// 初始化分享Intent监听
  void initialize() {
    _shareTextController = StreamController<String>.broadcast();

    appLogger.i('开始初始化分享Intent服务');

    // 监听应用运行时接收到的分享Intent
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        appLogger.i('接收到分享媒体: ${value.length} 个文件');
        for (var file in value) {
          if (file.type == SharedMediaType.text) {
            appLogger.i('接收到分享文本: ${file.path}');
            _shareTextController?.add(file.path);
          } else if (file.type == SharedMediaType.url) {
            appLogger.i('接收到分享URL: ${file.path}');
            _shareTextController?.add(file.path);
          }
        }
      },
      onError: (error) {
        appLogger.e('接收分享Intent时出错', error: error);
      },
    );

    // 处理应用启动时接收到的分享Intent
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        appLogger.i('应用启动时接收到分享媒体: ${value.length} 个文件');
        for (var file in value) {
          if (file.type == SharedMediaType.text) {
            appLogger.i('应用启动时接收到分享文本: ${file.path}');
            _shareTextController?.add(file.path);
          } else if (file.type == SharedMediaType.url) {
            appLogger.i('应用启动时接收到分享URL: ${file.path}');
            _shareTextController?.add(file.path);
          }
        }
      }
      // 重要：处理完成后重置
      ReceiveSharingIntent.instance.reset();
    }).catchError((error) {
      appLogger.e('获取初始分享Intent时出错', error: error);
    });

    appLogger.i('分享Intent服务初始化完成');
  }

  /// 清理资源
  void dispose() {
    appLogger.i('正在清理分享Intent服务');
    _intentDataStreamSubscription?.cancel();
    _shareTextController?.close();
    _shareTextController = null;
    _intentDataStreamSubscription = null;
  }
}
