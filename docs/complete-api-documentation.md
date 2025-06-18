# Readeck API 文档

## 简介

Readeck API 提供 REST 端点，可用于任何目的，无论是移动应用程序、脚本等。

## API 端点

您可以在 `__BASE_URI__` 上访问此 API。

大多数请求和响应都使用 JSON 作为交换格式。

## 认证

要使用 API，您首先需要[创建认证令牌](../profile/tokens)。然后您可以使用 `Bearer` HTTP 授权方案使用新令牌。

例如，您的第一个请求将如下所示：

```sh
curl -H "Authorization: Bearer <TOKEN>" __BASE_URI__/bookmarks
```

或者，在 NodeJS 中：

```js
fetch("__BASE_URI__/bookmarks", {
  headers: {
    Authorization: "Bearer <TOKEN>",
  },
});
```

## 首次认证

虽然您可以从 Readeck 创建认证令牌，但您也可以直接从 API 获取令牌。这提供了一种机制来请求用户凭据并仅为您的应用程序获取令牌。

请参考 [POST /auth](#post-/auth) 获取更多信息。

## 测试 API

在此文档中，您可以测试每个路由。

如果您在[认证](#auth)中不提供 API 令牌，您仍然可以测试所有路由，但请注意，给定的 curl 示例仅适用于 API 令牌。

---

# API 路由

## 认证相关

### POST /auth - 用户认证

此路由使用用户名和密码执行认证，并返回可用于所有 API 请求的令牌。

您不需要每次使用 API 时都向此路由发出请求，只需执行一次并以某种方式保留令牌。您可以使用此路由在移动应用程序或您可能构建的任何 API 客户端中提供首次认证，并仅存储生成的令牌。

您必须提供应用程序名称。

**请求体：**

```json
{
  "username": "alice",
  "password": "1234",
  "application": "api doc",
  "roles": ["string"] // 可选：限制新令牌访问的角色列表
}
```

**响应：**

- 201: 认证成功
- 403: 认证失败

### GET /profile - 用户配置

此路由返回当前用户的配置信息。这包括用户信息和首选项，以及具有其权限的认证提供程序。

**响应：**

- 200: 配置信息

---

## 书签管理

### GET /bookmarks - 书签列表

此路由返回分页的书签列表。

**查询参数：**

- `search`: 全文搜索字符串
- `title`: 书签标题
- `author`: 作者姓名
- `site`: 书签站点名称或域名
- `type`: 书签类型 (article, photo, video)
- `labels`: 一个或多个标签
- `is_loaded`: 按加载状态过滤
- `has_errors`: 过滤有或没有错误的书签
- `has_labels`: 过滤有或没有标签的书签
- `is_marked`: 按标记（收藏）状态过滤
- `is_archived`: 按归档状态过滤
- `range_start`: 开始日期
- `range_end`: 结束日期
- `read_status`: 阅读进度状态 (unread, reading, read)
- `updated_since`: 检索在此日期之后创建的书签
- `id`: 一个或多个书签 ID。多个 id 的格式：?id=1&id=2&id=3
- `collection`: 集合 ID
- `sort`: 排序参数 (created, -created, domain, -domain, duration, -duration, published, -published, site, -site, title, -title)
- `limit`: 每页项目数
- `offset`: 分页偏移量

**响应：**

- 200: 书签项目列表

### POST /bookmarks - 创建书签

创建新书签。

**请求体：**

```json
{
  "url": "string", // 必需：要获取的 URL
  "title": "string", // 可选：书签标题
  "labels": ["string"] // 可选：要设置给书签的标签列表
}
```

**响应：**

- 202: 已接受，返回书签 ID

### GET /bookmarks/{id} - 书签详情

检索保存的书签。

**响应：**

- 200: 书签详情

### PATCH /bookmarks/{id} - 更新书签

此路由更新书签的某些属性。每个输入值都是可选的。成功后，它返回更改值的映射。

**请求体：**

```json
{
  "title": "string", // 新书签标题
  "is_marked": true, // 收藏状态
  "is_archived": true, // 归档状态
  "is_deleted": true, // 如果为 true，安排书签删除
  "read_progress": 50, // 阅读进度百分比 (0-100)
  "read_anchor": "string", // 最后看到元素的 CSS 选择器
  "labels": ["string"], // 替换书签的标签
  "add_labels": ["string"], // 向书签添加给定标签
  "remove_labels": ["string"] // 从书签中删除给定标签
}
```

**响应：**

- 200: 书签已更新

### DELETE /bookmarks/{id} - 删除书签

删除保存的书签。

**响应：**

- 204: 书签已成功删除

---

## 书签导出

### GET /bookmarks/{id}/article - 书签文章

此路由返回书签的文章（如果存在）。

**响应：**

- 200: 包含文章正文的 `text/html` 响应

### GET /bookmarks/{id}/article.{format} - 书签导出

此路由将书签导出为另一种格式。

**路径参数：**

- `format`: 导出格式 (epub, md)

**响应：**

- 200: 导出的文件

---

## 书签分享

### GET /bookmarks/{id}/share/link - 链接分享

此路由生成可公开访问的链接来分享书签。

**响应：**

- 200: 公共链接信息

### POST /bookmarks/{id}/share/email - 邮件分享

此路由将书签发送到电子邮件地址。

**请求体：**

```json
{
  "email": "alice@localhost",
  "format": "html" // html 或 epub
}
```

**响应：**

- 200: 消息已发送

---

## 书签标签

### GET /bookmarks/labels - 标签列表

此路由返回当前用户与书签关联的所有标签。

**响应：**

- 200: 标签列表

### GET /bookmarks/labels/{name} - 标签信息

此路由返回给定书签标签的信息。

**响应：**

- 200: 标签信息

### PATCH /bookmarks/labels/{name} - 更新标签

此路由重命名标签。

**请求体：**

```json
{
  "name": "string" // 新标签名
}
```

**响应：**

- 200: 标签已重命名

### DELETE /bookmarks/labels/{name} - 删除标签

此路由从所有关联的书签中删除标签。

请注意，它不会删除书签本身。

**响应：**

- 204: 标签已删除

---

## 书签高亮

### GET /bookmarks/annotations - 高亮列表

此路由返回当前用户创建的所有高亮。

**响应：**

- 200: 高亮列表

### GET /bookmarks/{id}/annotations - 书签高亮

此路由返回给定书签的高亮。

**响应：**

- 200: 高亮列表

### POST /bookmarks/{id}/annotations - 创建高亮

此路由在给定书签上创建新高亮。

高亮格式类似于 [Range API](https://developer.mozilla.org/en-US/docs/Web/API/Range)，但有一些差异：

- 范围的开始和结束选择器是 XPath 选择器，必须针对元素。
- 偏移量是从选择器开始的文本长度，无论遍历的潜在子元素如何。

**请求体：**

```json
{
  "start_selector": "string", // 开始元素的 XPath 选择器
  "start_offset": 0, // 开始元素的文本偏移量
  "end_selector": "string", // 结束元素的 XPath 选择器
  "end_offset": 0, // 结束元素的文本偏移量
  "color": "string" // 注释颜色
}
```

**响应：**

- 201: 高亮已创建

### PATCH /bookmarks/{id}/annotations/{annotation_id} - 更新高亮

此路由更新给定书签中的给定高亮。

**请求体：**

```json
{
  "color": "string" // 注释颜色
}
```

**响应：**

- 200: 更新结果

### DELETE /bookmarks/{id}/annotations/{annotation_id} - 删除高亮

此路由删除给定书签中的给定高亮。

**响应：**

- 204: 高亮已删除

---

## 书签集合

### GET /bookmarks/collections - 集合列表

此路由返回当前用户的所有集合。

**响应：**

- 200: 集合列表

### POST /bookmarks/collections - 创建集合

此路由创建新集合。

**请求体：**

```json
{
  "name": "string", // 集合名称
  "is_pinned": true, // 集合是否置顶
  "is_deleted": false, // 集合是否安排删除
  "search": "string", // 搜索字符串
  "title": "string", // 标题过滤器
  "author": "string", // 作者过滤器
  "site": "string", // 站点过滤器
  "type": ["article", "photo", "video"], // 类型过滤器
  "labels": "string", // 标签过滤器
  "read_status": ["unread", "reading", "read"], // 阅读进度状态
  "is_marked": true, // 收藏过滤器
  "is_archived": false, // 归档过滤器
  "range_start": "string", // 开始日期过滤器
  "range_end": "string" // 结束日期过滤器
}
```

**响应：**

- 201: 集合已创建

### GET /bookmarks/collections/{id} - 集合详情

此路由返回给定集合信息。

**响应：**

- 200: 集合信息

### PATCH /bookmarks/collections/{id} - 更新集合

此路由更新给定集合。它返回更新字段的映射。

**请求体：** 与创建集合相同的结构

**响应：**

- 200: 更新的字段

### DELETE /bookmarks/collections/{id} - 删除集合

此路由删除给定集合。

**响应：**

- 204: 集合已删除

---

## 书签导入

### POST /bookmarks/import/text - 导入文本文件

此路由从包含每行一个 URL 的文本文件创建书签。

**请求体：** 文本文件内容或 multipart/form-data

**响应：**

- 202: 已接受

### POST /bookmarks/import/browser - 导入浏览器书签

此路由从浏览器书签导出生成的 HTML 文件创建书签。

**请求体：** HTML 文件内容或 multipart/form-data

**响应：**

- 202: 已接受

### POST /bookmarks/import/pocket-file - 导入 Pocket 保存

此路由从 Pocket 导出工具生成的 HTML 文件创建书签。
访问 [https://getpocket.com/export](https://getpocket.com/export) 生成此类文件。

**请求体：** HTML 文件内容或 multipart/form-data

**响应：**

- 202: 已接受

### POST /bookmarks/import/wallabag - 导入 Wallabag 文章

此路由使用其 API 从 Wallabag 导入文章。

您必须在 Wallabag 中创建 API 客户端，并在此路由的负载中使用其"客户端 ID"和"客户端密钥"。

**请求体：**

```json
{
  "url": "string", // 您的 Wallabag 实例的 URL
  "username": "string", // 您的 Wallabag 用户名
  "password": "string", // 您的 Wallabag 密码
  "client_id": "string", // API 客户端 ID
  "client_secret": "string" // API 客户端密钥
}
```

**响应：**

- 202: 已接受

---

## 开发工具

### GET /cookbook/extract - 提取链接

**注意：仅适用于管理员组中的用户。**

此路由提取链接并返回提取结果。

您可以向请求传递 `Accept` 标头，具有以下值之一：

- `application/json`（默认）返回 JSON 响应
- `text/html` 返回 HTML 响应，所有媒体都包含为 base64 编码的 URL。

**查询参数：**

- `url`: 要提取的 URL（必需）

**响应：**

- 200: 提取结果

---

# 数据类型定义

## 基础类型

### message

消息对象，包含状态码和消息文本。

```json
{
  "status": 200, // HTTP 状态码
  "message": "string" // 信息或错误消息
}
```

## 认证类型

### authenticationForm

认证表单数据。

```json
{
  "username": "string", // 用户名（必需）
  "password": "string", // 密码（必需）
  "application": "string", // 应用程序名称（必需）
  "roles": ["string"] // 角色列表（可选）
}
```

### authenticationResult

认证结果。

```json
{
  "id": "string", // 令牌 ID
  "token": "string" // 认证令牌
}
```

### userProfile

用户配置信息。

```json
{
  "provider": {
    "id": "string", // 认证提供程序 ID
    "name": "string", // 提供程序名称
    "application": "string", // 注册的应用程序名称
    "roles": ["string"], // 此会话授予的角色
    "permissions": ["string"] // 此会话授予的权限
  },
  "user": {
    "username": "string", // 用户名
    "email": "string", // 用户邮箱
    "created": "2023-08-27T13:32:11.704606963Z", // 创建日期
    "updated": "2023-12-17T09:08:31.909723372Z", // 最后更新日期
    "settings": {
      "debug_info": false, // 启用调试信息
      "reader_settings": {
        "font": "serif", // 字体
        "font_size": 3, // 字体大小
        "line_height": 3 // 行高
      }
    }
  }
}
```

## 书签类型

### bookmarkSummary

书签摘要信息。

```json
{
  "id": "string", // 书签 ID
  "href": "string", // 书签信息链接
  "created": "2023-08-27T13:32:11Z", // 创建日期
  "updated": "2023-08-27T13:32:11Z", // 最后更新
  "state": 0, // 书签状态：0=已加载, 1=错误, 2=加载中
  "loaded": true, // 书签是否准备就绪
  "url": "string", // 书签的原始 URL
  "title": "string", // 书签标题
  "site_name": "string", // 书签站点名称
  "site": "string", // 书签站点主机名
  "published": "2023-08-27T13:32:11Z", // 发布日期（可为 null）
  "authors": ["string"], // 作者列表
  "lang": "string", // 语言代码
  "text_direction": "ltr", // 文本方向：rtl 或 ltr
  "document_type": "string", // 文档类型
  "type": "article", // 书签类型：article, photo, video
  "has_article": true, // 是否包含文章
  "description": "string", // 简短描述
  "is_deleted": false, // 是否安排删除
  "is_marked": false, // 是否在收藏夹中
  "is_archived": false, // 是否在归档中
  "read_progress": 50, // 阅读进度百分比 (0-100)
  "labels": ["string"], // 书签标签
  "word_count": 1000, // 文章字数
  "reading_time": 5, // 阅读时间（分钟）
  "resources": {
    "article": { "src": "string" }, // 文章链接
    "icon": { "src": "string", "height": 32, "width": 32 }, // 站点图标
    "image": { "src": "string", "height": 600, "width": 800 }, // 文章图片
    "thumbnail": { "src": "string", "height": 150, "width": 200 }, // 缩略图
    "log": { "src": "string" }, // 提取日志
    "props": { "src": "string" } // 书签额外属性
  }
}
```

### bookmarkInfo

书签详细信息，继承自 bookmarkSummary，并包含额外字段：

```json
{
  // ... bookmarkSummary 的所有字段
  "read_anchor": "string", // 最后看到元素的 CSS 选择器
  "links": [
    // 文章中收集的所有链接列表
    {
      "url": "string", // 链接 URI
      "domain": "string", // 链接域名
      "title": "string", // 链接标题
      "is_page": true, // 目标是否为网页
      "content_type": "string" // 目标的 MIME 类型
    }
  ]
}
```

## 标签类型

### labelInfo

标签信息。

```json
{
  "name": "string", // 标签名称
  "count": 10, // 具有此标签的书签数量
  "href": "string", // 标签信息链接
  "href_bookmarks": "string" // 具有此标签的书签链接
}
```

## 高亮类型

### annotationSummary

高亮摘要。

```json
{
  "id": "string", // 高亮 ID
  "href": "string", // 高亮链接
  "text": "string", // 高亮文本
  "created": "2023-08-27T13:32:11Z", // 高亮创建日期
  "bookmark_id": "string", // 书签 ID
  "bookmark_href": "string", // 书签信息链接
  "bookmark_url": "string", // 原始书签 URL
  "bookmark_title": "string", // 书签标题
  "bookmark_site_name": "string" // 书签站点名称
}
```

### annotationInfo

高亮详细信息。

```json
{
  "id": "string", // 高亮 ID
  "start_selector": "string", // 开始元素的 XPath 选择器
  "start_offset": 0, // 开始元素的文本偏移量
  "end_selector": "string", // 结束元素的 XPath 选择器
  "end_offset": 0, // 结束元素的文本偏移量
  "created": "2023-08-27T13:32:11Z", // 高亮创建日期
  "text": "string" // 高亮文本
}
```

## 集合类型

### collectionInfo

集合信息。

```json
{
  "id": "string", // 集合 ID
  "href": "string", // 集合 URL
  "created": "2023-08-27T13:32:11Z", // 创建日期
  "updated": "2023-08-27T13:32:11Z", // 最后更新日期
  "name": "string", // 集合名称
  "is_pinned": false, // 是否置顶
  "is_deleted": false, // 是否安排删除
  "search": "string", // 搜索字符串
  "title": "string", // 标题过滤器
  "author": "string", // 作者过滤器
  "site": "string", // 站点过滤器
  "type": ["article"], // 类型过滤器
  "labels": "string", // 标签过滤器
  "read_status": ["unread"], // 阅读进度状态
  "is_marked": false, // 收藏过滤器
  "is_archived": false, // 归档过滤器
  "range_start": "string", // 开始日期过滤器
  "range_end": "string" // 结束日期过滤器
}
```

---

# 通用特性

## 认证特性

所有需要认证的端点都会返回以下错误响应：

- **401 Unauthorized**: 在 Authorization 标头中找到的请求令牌无效
- **403 Forbidden**: 用户没有权限获取指定的用户，但具有其他帐户权限

## 分页特性

支持分页的端点接受以下查询参数：

- `limit`: 每页项目数
- `offset`: 分页偏移量

分页响应包含以下标头：

- `Link`: 分页结果中其他页面的链接
- `Current-Page`: 当前页码
- `Total-Count`: 项目总数
- `Total-Pages`: 总页数

## 验证特性

当输入数据无效时，API 返回 422 状态码，包含检测到的所有错误的对象：

```json
{
  "is_valid": false, // 输入是否有效
  "errors": ["string"], // 全局输入错误列表
  "fields": {
    // 所有字段，有错误和无错误的
    "field_name": {
      "is_null": false, // 输入值是否为 null
      "is_bound": true, // 值是否绑定到表单
      "value": "any", // 项目值；可以是任何类型
      "errors": ["string"] // 此字段的错误列表
    }
  }
}
```

## 排序特性

书签列表支持以下排序参数：

- `created` / `-created`: 按创建时间排序
- `domain` / `-domain`: 按域名排序
- `duration` / `-duration`: 按持续时间排序
- `published` / `-published`: 按发布时间排序
- `site` / `-site`: 按站点排序
- `title` / `-title`: 按标题排序

前缀 `-` 表示降序排序。

---

# 错误处理

API 使用标准 HTTP 状态码：

- **200 OK**: 请求成功
- **201 Created**: 资源已创建
- **202 Accepted**: 请求已接受，正在处理
- **204 No Content**: 请求成功，无内容返回
- **401 Unauthorized**: 未授权
- **403 Forbidden**: 禁止访问
- **422 Unprocessable Entity**: 输入验证失败

错误响应通常包含 `message` 对象，提供状态码和错误描述。

---

_此文档基于 Readeck API OpenAPI 3.0.0 规范生成。_
