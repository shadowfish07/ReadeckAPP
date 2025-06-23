# Semantic Release 使用指南

本项目使用 [semantic-release](https://semantic-release.gitbook.io/) 进行自动化版本管理和发布。

## 提交信息规范

本项目遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

### 提交格式

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### 提交类型

| 类型 | 说明 | 版本影响 |
|------|------|----------|
| `feat` | 新功能 | minor |
| `fix` | Bug修复 | patch |
| `perf` | 性能优化 | patch |
| `refactor` | 代码重构 | patch |
| `revert` | 回滚 | patch |
| `docs` | 文档更新 | 无 |
| `style` | 代码格式 | 无 |
| `test` | 测试相关 | 无 |
| `chore` | 构建/工具 | 无 |
| `ci` | CI配置 | 无 |
| `build` | 构建系统 | 无 |

### 破坏性变更

在提交信息中包含 `BREAKING CHANGE:` 或在类型后添加 `!` 会触发 major 版本更新：

```
feat!: 重构API接口

BREAKING CHANGE: 移除了旧的API端点
```

### 示例

```bash
# 新功能 (minor版本)
git commit -m "feat: 添加书签搜索功能"

# Bug修复 (patch版本)
git commit -m "fix: 修复登录页面崩溃问题"

# 性能优化 (patch版本)
git commit -m "perf: 优化书签列表加载速度"

# 破坏性变更 (major版本)
git commit -m "feat!: 重构用户认证系统

BREAKING CHANGE: 更改了认证API的响应格式"

# 文档更新 (不影响版本)
git commit -m "docs: 更新API文档"
```

## 发布流程

### 自动发布

1. **主分支发布**: 推送到 `main` 分支会触发正式版本发布
2. **预发布**: 推送到 `beta` 分支会触发预发布版本

### 发布内容

每次发布会自动生成：

- 📦 **Android APK**: `readeck-app.apk`
- 📦 **Android App Bundle**: `readeck-app.aab`
- 🌐 **Web版本**: `readeck-app-web.tar.gz`
- 🐧 **Linux版本**: `readeck-app-linux.tar.gz`
- 📝 **更新日志**: 自动生成的 CHANGELOG.md
- 🏷️ **Git标签**: 语义化版本标签
- 📋 **GitHub Release**: 包含所有构建产物

## 分支策略

- `main`: 主分支，用于正式版本发布
- `beta`: 预发布分支，用于测试版本
- `feature/*`: 功能分支，开发新功能
- `fix/*`: 修复分支，修复Bug

## 配置文件

- `.releaserc.json`: semantic-release 配置
- `package.json`: Node.js 依赖和脚本
- `.github/workflows/release.yml`: GitHub Actions 工作流

## 本地测试

```bash
# 安装依赖
npm install

# 模拟发布（不会实际发布）
npx semantic-release --dry-run
```

## 注意事项

1. **提交信息**: 必须遵循 Conventional Commits 规范
2. **分支保护**: main 分支应设置保护规则
3. **权限配置**: 确保 GitHub Actions 有足够的权限
4. **密钥管理**: Android 签名密钥通过 GitHub Secrets 管理

## 故障排除

### 常见问题

1. **版本没有更新**: 检查提交信息是否符合规范
2. **构建失败**: 检查 Flutter 版本和依赖
3. **发布失败**: 检查 GitHub Token 权限

### 手动发布

如果自动发布失败，可以手动触发：

```bash
# 在本地运行 semantic-release
GITHUB_TOKEN=your_token npx semantic-release
```