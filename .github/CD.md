# GitHub Actions 自动化构建和发布

本项目配置了 GitHub Actions 工作流，用于在推送标签时自动构建应用并创建 GitHub Release。

## 🏷️ 版本标签规范

### 语义化版本控制

本项目遵循 [语义化版本控制](https://semver.org/lang/zh-CN/) 规范：

- **主版本号**：当你做了不兼容的 API 修改
- **次版本号**：当你做了向下兼容的功能性新增
- **修订号**：当你做了向下兼容的问题修正

### 标签格式

- **正式版本**：`v1.0.0`、`v1.2.3`、`v2.0.0`
- **预发布版本**：`v1.0.0-beta.1`、`v1.2.0-beta.2`、`v2.0.0-beta.1`

## 🚀 发布流程

### 1. 自动化发布流程

推送到主分支（main 或 beta）后，GitHub Actions 将自动执行以下流程：

#### 🔄 新的智能发布流程
```
代码推送 → 测试 → Dry Run 检查 → 人工确认 → 发布
```

1. **测试阶段**：
   - 运行所有单元测试
   - 代码质量检查

2. **Dry Run 检查阶段**：
   - 使用 semantic-release 的 dry-run 模式检查是否需要发布
   - 如果没有符合发布条件的提交，流程会在此处停止
   - 如果检测到需要发布，会提取版本号和发布说明

3. **人工确认阶段**（仅在需要发布时触发）：
   - 显示即将发布的版本信息
   - 显示发布说明预览
   - 等待手动确认部署

4. **发布阶段**：
   - 自动更新 `pubspec.yaml` 中的版本号
   - 构建 Android APK 和 AAB
   - 创建 GitHub Release
   - 上传构建产物

### 2. 手动发布（跳过确认）

如果需要跳过人工确认步骤，可以使用工作流派发：

```bash
# 在 GitHub Actions 页面手动触发工作流
# 勾选 "跳过手动确认步骤" 选项
```

### 3. 发布条件

只有包含以下类型的提交才会触发发布：
- **feat**: 新功能（minor 版本）
- **fix**: 错误修复（patch 版本）
- **BREAKING CHANGE**: 破坏性更改（major 版本）

以下提交类型不会触发发布：
- **chore**: 杂项任务
- **docs**: 文档更新
- **style**: 代码格式化
- **refactor**: 代码重构（无功能变更）
- **test**: 测试相关

## 📦 构建产物

每次发布将包含以下文件：

- `readeck-app-{version}.apk` - Android 安装包
- `readeck-app-{version}.aab` - Android App Bundle
- `readeck-app-web-{version}.tar.gz` - Web 版本压缩包
- `readeck-app-linux-{version}.tar.gz` - Linux 版本压缩包

## 🔧 工作流配置

工作流文件位于 `.github/workflows/release.yml`，主要特性：

- **触发条件**：推送到 main 或 beta 分支
- **智能检查**：Dry Run 模式预先检查是否需要发布
- **条件性执行**：只有在确实需要发布时才会触发人工确认
- **版本自动更新**：从 semantic-release 获取版本号并更新代码
- **多平台构建**：支持 Android APK 和 AAB
- **人工确认**：生产环境部署前的安全检查点

## 📋 使用注意事项

1. **提交格式**：遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范
2. **分支发布**：main 分支发布正式版本，beta 分支发布预发布版本
3. **智能触发**：只有符合发布条件的提交才会进入发布流程
4. **人工确认**：生产发布前需要手动确认，确保发布安全
5. **权限要求**：需要 `GITHUB_TOKEN` 权限（自动提供）

## 🛠️ 本地测试

在推送代码前，建议本地测试构建：

```bash
# 获取依赖
flutter pub get

# 测试构建
flutter build apk --release

# 运行测试
flutter test

# 检查代码质量
flutter analyze
```

## 📝 版本发布检查清单

- [ ] 代码已提交并推送到对应分支（main 或 beta）
- [ ] 提交信息遵循 Conventional Commits 规范
- [ ] 本地测试通过
- [ ] 确认提交类型符合发布条件（feat/fix/BREAKING CHANGE）
- [ ] 检查 GitHub Actions Dry Run 结果
- [ ] 如需要发布，确认人工审批
- [ ] 验证 Release 页面的构建产物

## 🔍 发布流程监控

你可以在 GitHub Actions 页面监控发布流程：

1. **Dry Run 检查**：查看是否检测到需要发布的更改
2. **人工确认**：如果需要发布，在 Environment 页面进行确认
3. **构建状态**：监控 APK 和 AAB 构建进度
4. **发布结果**：检查 Release 页面的最终产物
