# Assetly · 物语

<p align="center">
  <img src="assets/app-icon.png" alt="Assetly 图标" width="112">
</p>

<p align="center">
  Local-first 的家庭物品、收纳空间与家庭药箱管理应用。
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-stable-02569B?logo=flutter" alt="Flutter stable">
  <img src="https://img.shields.io/badge/Android-supported-3DDC84?logo=android" alt="Android supported">
  <img src="https://img.shields.io/badge/data-local--first-10B981" alt="Local-first">
  <a href="https://github.com/yn-zxj/Assetly/actions/workflows/android-release.yml"><img src="https://github.com/yn-zxj/Assetly/actions/workflows/android-release.yml/badge.svg" alt="Android CI and Release"></a>
</p>

Assetly 使用 Flutter 重构，重点改善原 Tauri 客户端在手机端的交互、性能和系统能力适配。界面采用接近 shadcn/ui 的黑白灰层次、细描边、圆角卡片和 Lucide 线性图标。

> 旧版 Tauri + React 工程保存在 `v0.3.3` 和 `legacy-tauri-v0.3.3` 标签中；当前 `main` 分支为 Flutter 版本。

## 功能

### 家庭物品

- 新增、修改、删除、搜索及状态筛选
- 自定义物品 Emoji 图标、分类和存放空间
- 购买日期、价格、条码、质保日期和退役/转售记录
- 资产详情、使用天数和日均成本
- 首页近 6 个月新增资产金额统计及完整月份明细

### 家庭药箱

- 药品详情、新增、修改和删除
- 有效期、药品类型、库存单位、厂商及服用/使用说明
- “正在服用”开关、多个用药时间和服用周期
- 首页快捷打卡、库存扣减、过期和低库存预警
- Android 本地通知与精确提醒

### 收纳空间

- 多层级空间和完整路径
- 新增、重命名、删除及添加子空间
- 自定义空间 Emoji 图标
- 空间资产数量、总值和二维码收纳贴纸

### 智能录入

- 使用设备相机扫描 EAN、UPC、Code 128 和药监码
- OpenAI-compatible 多模态接口拍照识别
- AI 自动判断普通物品或药品，并允许保存前人工切换
- 药品识别可回填名称、有效期、使用说明、厂商、数量、单位和条码

条码扫描只负责读取编码。本项目没有连接商业商品数据库，因此不会根据普通商品条码虚构名称、价格等信息，扫描后仍需用户补充资料。

### 数据与设置

- SQLite 本机存储，首次启动为空库，不写入演示资产
- JSON 完整导入、导出与跨设备迁移
- WebDAV 连接测试及远程备份
- 浅色、深色、跟随系统和多种强调色
- 文本/视觉模型共享配置或独立配置
- API Key 和 WebDAV 密码使用系统安全存储，不写入数据库或备份文件

## 安装

稳定版 APK 可从 [GitHub Releases](https://github.com/yn-zxj/Assetly/releases) 下载：

- `android-universal.apk`：适合不确定设备架构时安装
- `android-arm64-v8a.apk`：适合绝大多数现代 Android 手机，体积更小
- `android-armeabi-v7a.apk`：旧 32 位 ARM 设备
- `android-x86_64.apk`：Android 模拟器

Android 应用标识继续使用旧版的 `com.assetly.home`。使用与旧版相同的正式签名时，可覆盖升级并保留应用沙盒内的兼容数据。

## 本地开发

### 环境

- Flutter stable，Dart `>=3.11.5 <4.0.0`
- Android Studio / Android SDK
- JDK 17

### 运行

```bash
flutter pub get
flutter run
```

### 检查与测试

```bash
flutter analyze --no-pub
flutter test --no-pub
```

### 构建 Android APK

```bash
flutter build apk --release
```

构建产物位于 `build/app/outputs/flutter-apk/app-release.apk`。

## AI 配置

Assetly 不绑定某一家模型厂商，只要求服务兼容 OpenAI Chat Completions 的请求结构。

1. 在“设置 → 大模型配置”中填写 API Endpoint、API Key 和模型名称。
2. Endpoint 通常填写服务商提供的 API 根地址，例如 `https://api.example.com/v1`；应用会自动补全 `/chat/completions`。
3. 如果文字模型不支持图片，打开“双模型分离”，单独填写视觉模型。
4. 使用配置页的测试按钮确认连接。

拍照识别时，只有当前压缩照片会发送至用户配置的模型服务。其他资产、药品和空间数据不会随请求上传。

## 数据与兼容性

- 数据库文件名：`assetly.db`
- 当前 schema：v9
- 支持旧版核心字段及旧版 JSON 中的 `categories`、`locations`、`items`、`medicines`
- Flutter 版本新增条码、退役日期、转售金额及服药流水等字段

升级或导入重要数据前，建议先在设置中导出一份 JSON 备份。

## 项目结构

```text
assetly/
├── lib/
│   ├── main.dart
│   └── src/
│       ├── data/       # SQLite、数据模型和迁移
│       ├── services/   # AI、WebDAV 和通知服务
│       ├── state/      # 应用状态与业务编排
│       ├── theme/      # 主题与视觉规范
│       └── ui/         # 页面和通用组件
├── assets/             # 应用图标等静态资源
├── test/               # 逻辑与界面回归测试
├── android/            # Android 原生工程
├── ios/                # iOS 原生工程
├── macos/ linux/       # 桌面端工程
├── windows/ web/
└── .github/workflows/  # CI 与自动发版
```

## GitHub 自动发版

`.github/workflows/android-release.yml` 会执行以下工作：

- 向 `main` 推送或创建 Pull Request：运行静态检查和自动测试
- 推送 `v*` 标签：检查、测试、构建通用及分架构 APK，并创建 GitHub Release
- 手动运行工作流：可指定标签并选择是否标记为预发布

发布新版本前先更新 `pubspec.yaml` 的版本号，然后创建同名标签：

```bash
git tag -a v1.3.0 -m "Assetly Flutter v1.3.0"
git push origin main --follow-tags
```

### Android 正式签名

仓库 Actions Secrets 支持以下配置，并与旧版流水线名称保持一致：

| Secret | 说明 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | JKS/Keystore 文件的 Base64 内容 |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore 密码 |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key 密码 |

完整配置时流水线使用正式签名；未配置 Keystore 时仍可生成使用调试签名的测试 APK，但不适合作为长期发布版本。

## 技术栈

| 范围 | 技术 |
| --- | --- |
| UI | Flutter、Material 3、自定义 shadcn 风格组件、Lucide Icons |
| 数据 | SQLite / sqflite、JSON 备份、WebDAV |
| 图表 | fl_chart |
| 扫码 | mobile_scanner / ML Kit |
| 通知 | flutter_local_notifications、timezone |
| 安全存储 | flutter_secure_storage |
| 网络与 AI | http、OpenAI-compatible Chat Completions |

## 旧版归档

如需查看或恢复 Tauri 版本：

```bash
git switch --detach legacy-tauri-v0.3.3
```

返回 Flutter 主线：

```bash
git switch main
```
