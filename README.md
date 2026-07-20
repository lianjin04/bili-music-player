# 🎵 B站收藏夹音乐播放器

> 将你的 B站 个人收藏夹变成私人歌单，跨平台音乐播放器

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.22+-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Android-green" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-orange" alt="License">
</p>

---

## 📖 项目简介

本项目是一个基于 **Flutter** 开发的跨平台音乐播放器，核心功能是**将B站个人收藏夹当作歌单来听歌**。

### ✨ 核心特性

| 特性 | 说明 |
|:----|:------|
| 🎯 **收藏夹即歌单** | 直接读取B站收藏夹，无需手动添加 |
| 🎧 **纯净音频播放** | 利用B站DASH协议，只获取音频流，省流量 |
| 💾 **本地缓存** | LRU淘汰策略，默认2GB缓存空间，离线也能听 |
| 📝 **歌单管理** | 自建歌单、播放历史、我的喜欢 |
| ⏸ **播放状态持久化** | 退出App后恢复上次播放进度 |
| 🔄 **多种播放模式** | 顺序、随机、单曲循环、列表循环 |
| 🎨 **Material 3** | 现代化的 UI 设计 |

---

## 🖥️ 支持平台

| 平台 | 支持状态 | 说明 |
|:----|:--------:|:-----|
| 🪟 **Windows** | ✅ | 桌面端完整支持 |
| 📱 **Android** | ✅ | 移动端完整支持（含后台播放） |
| 🍎 iOS | ⚠️ 理论上支持 | 需 macOS 编译，未测试 |
| 🐧 Linux | ⚠️ 理论上支持 | 需自行编译 |

---

## 🛠️ 技术栈

```
Flutter (Dart)    跨平台 UI 框架
├── just_audio     音频播放引擎
├── dio            HTTP 网络请求
├── hive           本地 NoSQL 数据库
├── flutter_riverpod  状态管理
├── cached_network_image  封面图片缓存
└── flutter_secure_storage  Cookie安全存储
```

---

## 🚀 快速开始

### 环境要求

| 依赖 | 版本要求 | 获取方式 |
|:----|:--------|:---------|
| Flutter SDK | >= 3.22.0 | [flutter.dev](https://flutter.dev) |
| Dart | >= 3.2.0 | Flutter 自带 |
| Git | - | 任意版本 |

### 安装步骤

#### 第一步：获取源码

```bash
git clone <你的仓库地址>
cd bili-music-player
```

#### 第二步：安装依赖

```bash
flutter pub get
```

#### 第三步：配置 Cookie（可选）

首次打开 App 时在登录页输入 Cookie 即可。
> 也可在 `lib/config/api_config.dart` 中预先配置其他参数。

#### 第四步：运行

```bash
# Windows 桌面端
flutter run -d windows

# Android 设备（需连接手机或启动模拟器）
flutter run -d android

# 列出所有可用设备
flutter devices
```

---

## 📦 构建发布

### Windows 桌面端

```bash
# 构建 MSIX 安装包
flutter build windows

# 输出位置
./build/windows/x64/runner/Release/
```

将 `Release` 文件夹打包即可分发。

### Android APK

```bash
# 构建 APK
flutter build apk --release

# 构建 App Bundle（推荐用于 Google Play）
flutter build appbundle --release

# 输出位置
./build/app/outputs/flutter-apk/app-release.apk
./build/app/outputs/bundle/release/app-release.aab
```

---

## 🔧 项目结构

```
bili-music-player/
├── lib/
│   ├── main.dart                        # 程序入口
│   ├── app.dart                         # 根组件 + 路由配置
│   ├── config/
│   │   └── api_config.dart              # B站 API 配置
│   ├── models/
│   │   ├── favorite_folder.dart         # 收藏夹模型
│   │   ├── audio_item.dart              # 音频条目模型
│   │   └── playlist.dart               # 歌单/播放状态/历史
│   ├── services/
│   │   ├── bilibili_api_service.dart    # B站 API 服务
│   │   ├── audio_player_service.dart    # 音频播放服务
│   │   ├── cache_service.dart           # 缓存管理服务
│   │   └── storage_service.dart         # 本地存储服务
│   ├── pages/
│   │   ├── login_page.dart              # 登录页
│   │   ├── home_page.dart               # 主页（收藏夹列表）
│   │   ├── favorite_detail_page.dart    # 收藏夹详情页
│   │   └── player_page.dart             # 播放器页
│   └── widgets/
│       ├── audio_list_tile.dart         # 音频列表组件
│       └── player_bar.dart              # 底部播放栏组件
├── UI设计说明.md                         # UI 设计文档
├── UI预览.html                           # UI 效果预览（浏览器打开）
├── pubspec.yaml                         # 依赖配置
└── analysis_options.yaml               # 代码分析配置
```

---

## 🔑 获取B站 Cookie

App 需要 Cookie 来访问你的收藏夹，获取方式：

```
1. 在浏览器中打开 bilibili.com 并登录
2. 按 F12 打开开发者工具
3. 切换到 Network（网络）选项卡
4. 刷新页面，点击任意请求
5. 在 Request Headers 中找到 Cookie 字段
6. 复制完整的 Cookie 字符串（包含 SESSDATA=xxx）
```

> ⚠️ **注意**：Cookie 会过期，过期后需要重新登录。Cookie 仅保存在本地设备上。

---

## 📊 核心 API 清单

| 用途 | API 地址 | 认证 |
|:----|:---------|:----:|
| 用户信息 | `GET /x/space/myinfo` | Cookie |
| 收藏夹列表 | `GET /x/v3/fav/folder/list` | Cookie |
| 收藏夹资源 | `GET /x/v3/fav/resource/list` | Cookie |
| 视频信息 | `GET /x/web-interface/view` | 可选 |
| 播放信息（含音频流） | `GET /x/player/wbi/v2` | 可选 |

> 详细接口文档参考：[bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect)

---

## 🗺️ 开发路线图

### ✅ 已实现 (v0.1)
- [x] Flutter 项目骨架搭建
- [x] B站 API 服务（认证、收藏夹、视频、音频流）
- [x] 音频播放服务（just_audio 封装）
- [x] 本地缓存服务（LRU 淘汰）
- [x] 本地存储服务（Hive 持久化）
- [x] 登录页（Cookie 输入）
- [x] 收藏夹列表页
- [x] 收藏夹详情页（失效标记）
- [x] 全屏播放器页
- [x] 底部迷你播放栏

### 🔜 计划中
- [ ] Provider/Riverpod 状态管理接入
- [ ] Android 后台播放 + 通知栏控制
- [ ] 缓存设置页面（查看/清理缓存）
- [ ] 失效视频检测刷新
- [ ] 深色模式支持
- [ ] Windows 全局快捷键
- [ ] Android 锁屏控制
- [ ] 歌单导入/导出

---

## ⚠️ 注意事项

1. **仅供学习使用**，请勿用于商业用途
2. **注意请求频率**，本项目已内置 500ms 请求间隔防 412 风控
3. **Cookie 安全**：请勿将 Cookie 分享给他人
4. **已失效视频**：收藏夹中可能存在被和谐的视频，App 会标记为"已失效"
5. **B站接口变更**：B站 API 可能随时更新，如遇问题请提 Issue

---

## 📄 许可证

本项目基于 MIT 许可证开源。

---

## 🙏 致谢

- [bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect) - B站 API 文档
- [just_audio](https://pub.dev/packages/just_audio) - 优秀的音频播放插件
- [Flutter](https://flutter.dev) - 跨平台 UI 框架
