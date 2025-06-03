开发一个 flutter APP，基于 Material Design 2 设计。需要遵循其最佳实践。

这个 APP 可以连接 Readeck 的数据，作为其手机端程序。

- 确保设置页里所有设置都是持久化的。

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
