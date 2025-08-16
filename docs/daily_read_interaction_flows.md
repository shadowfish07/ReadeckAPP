# 每日阅读交互流程图

## 🔄 核心交互流程

### 1. 数据加载流程
```mermaid
flowchart TD
    A[用户打开页面] --> B[显示Loading状态]
    B --> C{检查今日历史}
    C -->|存在| D[加载历史书签]
    C -->|不存在| E[获取随机书签]
    E --> F[保存今日历史]
    F --> G[显示书签列表]
    D --> G
    G --> H{用户操作}
    H --> I[书签归档]
    H --> J[书签标记]
    H --> K[打开URL]
    H --> L[编辑标签]
    I --> M{是否完成全部}
    M -->|是| N[显示庆祝页面]
    M -->|否| G
    J --> G
    K --> O[打开浏览器]
    L --> G
    N --> P[用户点击再来一组]
    P --> E
```

### 2. UI状态切换流程
```mermaid
stateDiagram-v2
    [*] --> Loading
    Loading --> BookmarkList: 加载成功且有书签
    Loading --> Celebration: 加载成功但无未归档书签
    Loading --> ErrorPage: 加载失败
    BookmarkList --> Celebration: 最后一个书签归档
    BookmarkList --> BookmarkList: 书签操作
    Celebration --> Loading: 点击再来一组
    ErrorPage --> Loading: 用户重试
```

### 3. Command执行流程
```mermaid
sequenceDiagram
    participant U as User
    participant V as ViewModel
    participant R as Repository
    participant A as API
    participant UI as UI Layer

    U->>V: 触发操作
    V->>V: Command.execute()
    V->>R: 调用Repository方法
    R->>A: API请求
    A-->>R: 返回结果
    R-->>V: Result<T>
    alt 成功
        V->>V: 更新状态
        V->>UI: notifyListeners()
        UI->>UI: 重新渲染
    else 失败
        V->>V: 抛出异常
        UI->>UI: 显示错误页面
    end
```

## 📱 用户交互路径

### 路径A: 首次使用
```
开始 → Loading → 随机书签列表 → 操作书签 → 完成庆祝 → 再来一组
```

### 路径B: 继续阅读
```
开始 → Loading → 历史书签列表 → 继续操作 → 完成庆祝
```

### 路径C: 错误恢复
```
开始 → Loading → 错误页面 → 重试 → 正常流程
```

## 🎮 操作映射表

| 用户操作 | UI组件 | ViewModel方法 | Repository方法 | 结果反馈 |
|---------|-------|---------------|----------------|----------|
| 打开页面 | DailyReadScreen | load.execute() | loadRandomUnarchivedBookmarks() | 显示书签列表 |
| 归档书签 | BookmarkCard | toggleBookmarkArchived | toggleArchived() | UI刷新+可能触发庆祝 |
| 标记书签 | BookmarkCard | toggleBookmarkMarked | toggleMarked() | UI刷新 |
| 打开URL | BookmarkCard | openUrl | openUrl() | 打开浏览器 |
| 编辑标签 | BookmarkCard | updateBookmarkLabels | updateLabels() | UI刷新 |
| 点击卡片 | BookmarkCard | - | - | 导航到详情页 |
| 再来一组 | CelebrationOverlay | load.execute(true) | loadRandomUnarchivedBookmarks() | 重新加载 |
| 刷新 | ErrorPage | load.execute(false) | loadRandomUnarchivedBookmarks() | 重试加载 |

## 🔧 状态管理详解

### ViewModel状态属性
```dart
// 私有状态
List<BookmarkDisplayModel> _todayBookmarks  // 今日推荐书签
bool _isNoMore                              // 是否没有更多书签

// 计算属性 (getter)
List<BookmarkDisplayModel> bookmarks        // 过滤后的书签列表
List<BookmarkDisplayModel> unArchivedBookmarks  // 未归档书签列表
List<String> availableLabels               // 可用标签列表
bool isNoMore                              // 是否没有更多书签
```

### 命令对象
```dart
Command<bool, List<BookmarkDisplayModel>> load           // 加载书签
Command<String, void> openUrl                           // 打开URL
Command<Bookmark, void> toggleBookmarkArchived          // 切换归档状态
Command<Bookmark, void> toggleBookmarkMarked            // 切换标记状态
Command<void, List<String>> loadLabels                  // 加载标签
```

### 监听器机制
```dart
// Repository数据变化监听
_bookmarkRepository.addListener(_onBookmarksChanged);
_labelRepository.addListener(_onLabelsChanged);

// 书签归档完成回调
VoidCallback? _onBookmarkArchivedCallback;
```

## 🎨 UI渲染逻辑

### render()方法决策树
```
render()
├── unArchivedBookmarks.isEmpty?
│   ├── 是 → Stack(ConfettiWidget + CelebrationOverlay)
│   └── 否 → isNoMore?
│       ├── 是 → Center(无更多书签提示)
│       └── 否 → ListView.builder(书签列表)
```

### CommandBuilder状态处理
```
CommandBuilder
├── whileExecuting → Loading组件 (if lastValue.isEmpty)
├── onError → ErrorPage (NetworkError | UnknownError)
└── onData → render()
```

## 📊 数据流图

### 完整数据流
```mermaid
graph TD
    A[用户操作] --> B[Command执行]
    B --> C[Repository调用]
    C --> D[API请求/本地存储]
    D --> E[Result返回]
    E --> F{操作结果}
    F -->|成功| G[更新ViewModel状态]
    F -->|失败| H[抛出异常]
    G --> I[notifyListeners]
    I --> J[UI重新构建]
    H --> K[ErrorPage显示]
    
    L[Repository数据变化] --> M[监听器触发]
    M --> N[ViewModel刷新]
    N --> I
```

### 历史记录管理
```mermaid
graph LR
    A[首次访问] --> B[生成随机推荐]
    B --> C[保存DailyReadHistory]
    C --> D[显示书签列表]
    
    E[重复访问] --> F[查询今日历史]
    F --> G[加载历史书签]
    G --> D
    
    D --> H[用户操作]
    H --> I[状态更新]
    I --> D
```

## 🔄 生命周期管理

### 页面生命周期
```dart
initState() {
  // 初始化礼花控制器
  _confettiController = ConfettiController(duration: Duration(seconds: 3));
  // 设置归档回调
  widget.viewModel.setOnBookmarkArchivedCallback(_onBookmarkArchived);
}

didChangeDependencies() {
  // 设置Command错误监听
  widget.viewModel.load.errors.listen(...);
  widget.viewModel.toggleBookmarkArchived.errors.listen(...);
  widget.viewModel.toggleBookmarkMarked.errors.listen(...);
}

dispose() {
  // 清理动画控制器
  _confettiController.dispose();
  // 清除回调
  widget.viewModel.setOnBookmarkArchivedCallback(null);
  super.dispose();
}
```

### ViewModel生命周期
```dart
构造函数() {
  // 初始化Commands
  load = Command.createAsync<bool, List<BookmarkDisplayModel>>(_load, ...);
  // 注册监听器
  _bookmarkRepository.addListener(_onBookmarksChanged);
  _labelRepository.addListener(_onLabelsChanged);
  // 自动加载
  load.execute(false);
}

dispose() {
  // 移除监听器
  _bookmarkRepository.removeListener(_onBookmarksChanged);
  _labelRepository.removeListener(_onLabelsChanged);
  super.dispose();
}
```

---

*此文档描述了每日阅读功能的完整交互流程和业务逻辑*  
*版本: v1.0 | 更新时间: 2025-08-15*