# ReadeckApp

[English](./README.md) | [中文](./README_zh.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/github/v/release/shadowfish07/ReadeckApp)]()

基于 [Readeck](https://readeck.org/en/) 的移动端稍后读应用。

## 关于项目

Readeck 是一个非常出色的稍后读项目，但它没有提供移动端支持。ReadeckApp 旨在作为它的移动端伴侣应用，为用户提供一个方便的移动端稍后读工具。同时，ReadeckApp 会基于 Readeck 数据扩展一些功能，如每日阅读、AI 翻译等。

## ✨ 功能特性

- **📱 每日阅读**: 每日随机抽选 5 篇未归档文章，后续可能会进行可视化数据展示
- **🌐 完整 Readeck 支持**: 支持 Readeck 网页端的所有功能（开发中）
- **🔒 完全隐私**: 不会向第三方发送任何数据 - 您的数据完全私有
- **📊 Readeck 优先架构**: 以 Readeck 数据为优先，本地仅做适当缓存，避免数据同步问题
- **🤖 AI 功能**: AI 翻译、AI 打标等功能
- **📱 原生 Android**: 使用 Flutter 构建，提供流畅的 Android 体验

## 📋 前置要求

在使用 ReadeckApp 之前，您需要先部署自己的 Readeck 实例。请按照 [Readeck 官方文档](https://readeck.org/en/docs/) 进行设置。

## 📦 安装

### 下载 APK

1. 访问 [GitHub Releases](https://github.com/shadowfish07/ReadeckApp/releases) 页面
2. 下载最新的 APK 文件
3. 在您的 Android 设备上安装 APK

_Google Play Store 发布计划正在筹备中。_

### 从源码构建

```bash
# 克隆仓库
git clone git@github.com:shadowfish07/ReadeckAPP.git
cd ReadeckApp

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

## 🛠️ 技术栈

- **框架**: Flutter
- **主要库**:
  - `go_router` - 导航
  - `sqflite` - 本地数据库
  - `freezed` - 代码生成
  - `result_dart` - 错误处理
  - `dio_socket_client` - 网络请求
  - `flutter_command` - 命令模式
  - `flutter_html` - HTML 渲染

## 🗺️ 路线图

- [ ] 增强 AI 功能
- [ ] 改进每日推荐和总结功能
- [ ] Google Play Store 发布
- [ ] iOS 支持
- [ ] 阅读分析和可视化功能

## 🐛 已知问题

该项目目前处于早期开发阶段。如果您遇到任何问题，请及时反馈。

## 🤝 贡献

欢迎贡献！请参考 `.trae/rules/project_rules.md` 获取详细的贡献指南。

## 📄 许可证

该项目采用 MIT 许可证 - 详情请查看 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Readeck](https://readeck.org/en/) - 启发本项目的优秀稍后读服务
- Flutter 社区提供的出色框架和包
