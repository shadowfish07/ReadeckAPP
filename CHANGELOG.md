## [0.4.0-beta.3](https://github.com/shadowfish07/ReadeckApp/compare/v0.4.0-beta.2...v0.4.0-beta.3) (2025-06-28)


### ✨ 新功能

* **bookmarks:** 优化书签状态管理和缓存操作，移除乐观更新 ([88b4d84](https://github.com/shadowfish07/ReadeckApp/commit/88b4d8447ae84716ef906beefa4f8b8eeea17f0b))


### 🐛 Bug修复

* **bookmarks:** 标记喜爱后，下拉刷新，过程中喜爱图标会闪烁 ([4460999](https://github.com/shadowfish07/ReadeckApp/commit/446099900e625eab5b861deb204ab786b29b4297)), closes [#44](https://github.com/shadowfish07/ReadeckApp/issues/44)
* 仅一项时，无法触发下拉刷新 ([1ce48cd](https://github.com/shadowfish07/ReadeckApp/commit/1ce48cd482856fddc4f583b04174f8d920dfad31)), closes [#43](https://github.com/shadowfish07/ReadeckApp/issues/43)


### ♻️ 代码重构

* **bookmark:** 为书签仓库添加详细日志记录 ([e98798e](https://github.com/shadowfish07/ReadeckApp/commit/e98798e5394e2d9372b7e976c9f131f18d91df33))
* **readeck_api_client:** 重构HTTP客户端使用并添加资源释放方法 ([2e96849](https://github.com/shadowfish07/ReadeckApp/commit/2e96849136f63a14b9fa489c0dfebb3e3415b2e1))

## [0.4.0-beta.2](https://github.com/shadowfish07/ReadeckApp/compare/v0.4.0-beta.1...v0.4.0-beta.2) (2025-06-27)


### ♻️ 代码重构

* **bookmark:** 重构书签管理逻辑，移除BookmarkUseCases ([85f3547](https://github.com/shadowfish07/ReadeckApp/commit/85f35479385af94f778192120e5d7a72311f232f))
* **标签:** 将标签相关逻辑从用例层迁移到仓库层 ([f061d94](https://github.com/shadowfish07/ReadeckApp/commit/f061d94391026d0a8394be57932de0afd05105f3))

## [0.4.0-beta.1](https://github.com/shadowfish07/ReadeckApp/compare/v0.3.1...v0.4.0-beta.1) (2025-06-27)


### ✨ 新功能

* **ai:** 添加 OpenRouter API 配置功能 ([76c1771](https://github.com/shadowfish07/ReadeckApp/commit/76c177113f8d7bcb14a18577488b04ef1bf76bd8))
* **bookmark:** 实现书签文章缓存 ([725c480](https://github.com/shadowfish07/ReadeckApp/commit/725c480cd6f999ea703038038a3f3a6807733e9d))
* **书签详情:** 书签右上角改为菜单入口，添加更多操作菜单项包括标记喜爱、编辑标签等 ([24a1ede](https://github.com/shadowfish07/ReadeckApp/commit/24a1ede538d187eac7870eae6fb92b195b19fb10))
* 文章页支持AI翻译，支持配置OpenRouter AI key ([51bc98f](https://github.com/shadowfish07/ReadeckApp/commit/51bc98f62c6f554ae93914c83f63b17c79e498af))


### 🐛 Bug修复

* **错误处理:** 添加文章内容为空异常并统一错误页面处理 ([f1454e1](https://github.com/shadowfish07/ReadeckApp/commit/f1454e15bee6c5b43b2091ed470ea82e82585825)), closes [#8](https://github.com/shadowfish07/ReadeckApp/issues/8)


### ♻️ 代码重构

* **viewmodel:** 使用 result_dart 工具函数替换 fold 处理错误 ([3df0e55](https://github.com/shadowfish07/ReadeckApp/commit/3df0e557fdf46e5539f884555914af8b07a23ad5))

## [0.3.1](https://github.com/shadowfish07/ReadeckApp/compare/v0.3.0...v0.3.1) (2025-06-24)


### 🐛 Bug修复

* test ([796fb8c](https://github.com/shadowfish07/ReadeckApp/commit/796fb8ce66f63c3c1517b9595c52a1fb623ac79f))

## [0.3.0](https://github.com/shadowfish07/ReadeckApp/compare/v0.2.1...v0.3.0) (2025-06-23)


### ✨ 新功能

* **日志:** 实现日志轮转功能并添加日志管理工具 ([c7f8993](https://github.com/shadowfish07/ReadeckApp/commit/c7f8993d29a30f7a3095e768db348efe200b42fa))


### ⚡ 性能优化

* **bookmarks:** 增加每页加载书签数量从5到10以提升性能 ([d61bfa2](https://github.com/shadowfish07/ReadeckApp/commit/d61bfa2e37ae03d6967c86984d86631672135f5a))
* **bookmarks:** 将每页加载书签数量从5增加到10以提高效率 ([7fde725](https://github.com/shadowfish07/ReadeckApp/commit/7fde725c08164605e1b076cb33c29bc46c66d111))

# Changelog

所有重要的项目变更都会记录在这个文件中。

这个项目遵循 [Semantic Versioning](https://semver.org/spec/v2.0.0.html)。

## [Unreleased]

### Added
- 集成 semantic-release 自动化版本管理
- 添加 GitHub Actions 自动化构建和发布流程
