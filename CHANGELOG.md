# 📋 更新日志

## v0.1.1 (2026-07-20) — API 实测迭代

### 🔬 测试验证
- 对 B站 公开 API 进行了完整连通性测试 ✅
- 测试用户 `L_怜锦` (uid: `424571864`) 的公开收藏夹
- 「音乐」收藏夹 (media_id: `789827364`) 217个视频全部可公开访问

### 🐛 Bug 修复
| Bug | 原因 | 修复方式 |
|:----|:-----|:---------|
| 收藏夹视频 UP主显示"未知" | API返回字段为 `upper` 而非 `owner` | 修改 `_parseMediaToAudioItem` 优先读取 `upper.name` |
| 获取不到音频流地址 | `wbi/v2` 接口需要WBI签名 | 改用 `playurl` + `fnval=4048` 获取 DASH 音频流 |

### 🔧 代码变更
- `lib/config/api_config.dart` — 新增 `videoPlayUrl` 端点
- `lib/services/bilibili_api_service.dart` — 修复字段解析 + 音频流接口
- `test_bili_api.py` — 新增 API 连通性测试脚本

### 📁 文件变更统计
```
 4 files changed, 438 insertions(+), 105 deletions(-)
```

---

## v0.1.0 (2026-07-18) — 初版发布

### ✨ 新功能
- **双模式设计**：公开收藏夹免登录 / 私密收藏夹走Cookie
- **B站 API 服务**：收藏夹列表、视频列表、音频流获取
- **音频播放服务**：just_audio 封装，顺序/随机/单曲循环/列表循环
- **缓存服务**：LRU 淘汰策略，默认 2GB，自动管理
- **本地存储服务**：Hive 持久化（歌单、播放历史、播放状态、我的喜欢）
- **4个页面**：登录页、主页（UID搜索）、收藏夹详情、全屏播放器
- **2个组件**：音频列表项、底部迷你播放栏

### 📄 文档
- README.md — 完整部署文档
- UI设计说明.md — 页面布局和交互说明
- UI预览.html — 浏览器可查看的 UI 模拟效果
- CHANGELOG.md — 本文件