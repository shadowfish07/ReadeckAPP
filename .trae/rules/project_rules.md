开发一个 flutter APP，基于 Material Design 2 设计。需要遵循其最佳实践。

这个 APP 可以连接 Readeck 的数据，作为其手机端程序。

完成代码变动后，你应当始终执行 `flutter analyze` 命令，进行代码检查和错误修复。

# Material Design 2 常用样式设计规范总结

### 📱 AppBar (应用栏)

- 标题对齐 : 左对齐 ( centerTitle: false )
- 标题字号 : 20sp
- 标题字重 : Medium (500)
- 高度 : 56dp (手机), 64dp (平板)
- 阴影 : 4dp elevation

### 🎨 颜色系统

- 主色调 : Primary color
- 次要色调 : Secondary color
- 表面色 : Surface color
- 背景色 : Background color
- 错误色 : Error color
- 颜色对比度 : 至少 4.5:1 的对比度

### 📝 文字排版

- Headline 1 : 96sp, Light (300)
- Headline 2 : 60sp, Light (300)
- Headline 3 : 48sp, Regular (400)
- Headline 4 : 34sp, Regular (400)
- Headline 5 : 24sp, Regular (400)
- Headline 6 : 20sp, Medium (500)
- Subtitle 1 : 16sp, Regular (400)
- Subtitle 2 : 14sp, Medium (500)
- Body 1 : 16sp, Regular (400)
- Body 2 : 14sp, Regular (400)
- Button : 14sp, Medium (500), 大写
- Caption : 12sp, Regular (400)
- Overline : 10sp, Regular (400), 大写

### 🔘 按钮

- Material Button : 36dp 高度，8dp 圆角
- Floating Action Button : 56dp 直径
- 最小触摸目标 : 48dp × 48dp
- 按钮文字 : 14sp, Medium 字重，大写

### 📦 卡片 (Cards)

- 圆角 : 4dp
- 阴影 : 1dp-8dp elevation
- 内边距 : 16dp
- 间距 : 8dp

### 📋 列表 (Lists)

- 单行列表 : 48dp 高度
- 双行列表 : 64dp 高度
- 三行列表 : 88dp 高度
- 左右内边距 : 16dp
- 图标大小 : 24dp

### 🎯 间距系统

- 基础单位 : 8dp
- 常用间距 : 4dp, 8dp, 16dp, 24dp, 32dp, 48dp, 64dp
- 内容边距 : 16dp
- 组件间距 : 8dp

### 🖼️ 图标

- 系统图标 : 24dp × 24dp
- 应用图标 : 48dp × 48dp
- 最小触摸目标 : 48dp × 48dp

### 📱 响应式断点

- 手机 : 0-599dp
- 平板 : 600-1023dp
- 桌面 : 1024dp+

### 🎭 动画

- 标准缓动 : cubic-bezier(0.4, 0.0, 0.2, 1)
- 进入动画 : cubic-bezier(0.0, 0.0, 0.2, 1)
- 退出动画 : cubic-bezier(0.4, 0.0, 1, 1)
- 持续时间 : 150ms-300ms (短), 300ms-500ms (中), 500ms+ (长)

### ✅ 可访问性

- 颜色对比度 : 最低 4.5:1
- 触摸目标 : 最小 48dp × 48dp
- 焦点指示器 : 清晰可见

# 轻量级 Flutter 架构设计

## 🎯 设计原则

- **简单实用**：避免过度抽象，保持代码清晰易懂
- **渐进式**：可以随着项目发展逐步扩展
- **Material Design 2**：严格遵循设计规范
- **持久化优先**：确保所有设置都能持久保存

## 📁 轻量级目录结构

```
lib/
├── main.dart                    # 应用入口
├── app/
│   ├── app.dart                 # 应用配置
│   ├── routes.dart              # 路由定义
│   └── theme.dart               # 主题配置
├── models/
│   ├── bookmark.dart            # 书签模型
│   ├── user.dart                # 用户模型
│   └── app_settings.dart        # 应用设置模型
├── services/
│   ├── api_service.dart         # API 服务（重构后）
│   ├── storage_service.dart     # 本地存储服务
│   └── theme_service.dart       # 主题服务
├── providers/
│   ├── bookmark_provider.dart   # 书签状态管理
│   ├── settings_provider.dart   # 设置状态管理
│   └── theme_provider.dart      # 主题状态管理
├── pages/
│   ├── home/
│   │   ├── home_page.dart
│   │   └── widgets/
│   │       ├── bookmark_card.dart
│   │       └── daily_summary.dart
│   ├── settings/
│   │   ├── settings_page.dart
│   │   └── api_config_page.dart
│   └── about/
│       └── about_page.dart
├── widgets/
│   ├── common/
│   │   ├── loading_widget.dart
│   │   ├── error_widget.dart
│   │   └── empty_state.dart
│   └── readeck_app_bar.dart
└── utils/
    ├── constants.dart           # 常量定义
    ├── validators.dart          # 验证工具
    └── extensions.dart          # 扩展方法
```

## 🔧 核心架构组件

### 1. 状态管理 - Provider Pattern

- 使用 Provider 进行轻量级状态管理
- 每个功能模块对应一个 Provider
- 支持状态持久化和恢复

### 2. 服务层设计

- **StorageService**: 统一的本地存储管理
- **ApiService**: 简化的 API 调用服务
- **ThemeService**: 主题管理服务

### 3. 数据模型

- 使用简单的 Dart 类作为数据模型
- 支持 JSON 序列化和反序列化
- 包含 copyWith 方法支持不可变更新

### 4. 错误处理

- 统一的异常处理机制
- 优雅的错误提示和降级策略
- 离线模式支持

## 📝 编码规范

### 命名规范

- 文件名：使用 snake_case
- 类名：使用 PascalCase
- 变量和方法：使用 camelCase
- 常量：使用 SCREAMING_SNAKE_CASE

### 代码组织

- 每个文件只包含一个主要的类或功能
- 相关的 Widget 可以放在同一个文件中
- 使用 barrel exports 简化导入

### 注释规范

- 公共 API 必须有文档注释
- 复杂逻辑需要添加行内注释
- 使用中文注释说明业务逻辑
