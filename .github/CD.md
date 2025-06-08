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

### 1. 创建标签

```bash
# 创建正式版本标签
git tag v1.0.0
git push origin v1.0.0

# 创建预发布版本标签
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

### 2. 自动构建

推送标签后，GitHub Actions 将自动：

1. **更新版本号**：

   - 自动更新 `pubspec.yaml` 中的版本号
   - 自动更新 About 页面中显示的版本号

2. **构建多平台应用**：

   - Android APK
   - Android App Bundle (AAB)
   - Web 版本
   - Linux 版本

3. **创建 GitHub Release**：
   - 正式版本：创建正式发布
   - Beta 版本：创建预发布版本
   - 自动上传所有构建产物

## 📦 构建产物

每次发布将包含以下文件：

- `readeck-app-{version}.apk` - Android 安装包
- `readeck-app-{version}.aab` - Android App Bundle
- `readeck-app-web-{version}.tar.gz` - Web 版本压缩包
- `readeck-app-linux-{version}.tar.gz` - Linux 版本压缩包

## 🔧 工作流配置

工作流文件位于 `.github/workflows/release.yml`，主要特性：

- **触发条件**：推送以 `v` 开头的标签
- **多平台构建**：支持 Android、Web、Linux
- **版本自动更新**：从标签提取版本号并更新代码
- **智能发布**：根据版本号判断是否为预发布版本

## 📋 使用注意事项

1. **标签命名**：必须以 `v` 开头，如 `v1.0.0`
2. **版本号格式**：遵循语义化版本控制规范
3. **Beta 版本**：包含 `beta` 关键字的版本将标记为预发布
4. **权限要求**：需要 `GITHUB_TOKEN` 权限（自动提供）

## 🛠️ 本地测试

在推送标签前，建议本地测试构建：

```bash
# 获取依赖
flutter pub get

# 测试构建
flutter build apk --release
flutter build web --release

# 运行测试
flutter test
```

## 📝 版本发布检查清单

- [ ] 代码已提交并推送到主分支
- [ ] 更新了 CHANGELOG.md（如果有）
- [ ] 本地测试通过
- [ ] 确认版本号符合语义化版本控制
- [ ] 创建并推送标签
- [ ] 检查 GitHub Actions 构建状态
- [ ] 验证 Release 页面的构建产物
