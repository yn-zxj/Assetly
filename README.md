# Assetly - 家庭物品管家

<p align="center">
  <img src="src-tauri/icons/128x128.png" alt="Assetly Logo" width="96">
</p>

<p align="center">
  <b>Assetly</b> 是一款跨平台的家庭物品管理应用，帮助你记录、分类、追踪家中的所有资产。
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Tauri-2.0-24C8D8?logo=tauri" alt="Tauri">
  <img src="https://img.shields.io/badge/React-19-61DAFB?logo=react" alt="React">
  <img src="https://img.shields.io/badge/TypeScript-5.8-3178C6?logo=typescript" alt="TypeScript">
  <img src="https://img.shields.io/badge/Tailwind-4-06B6D4?logo=tailwindcss" alt="Tailwind">
  <img src="https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite" alt="SQLite">
</p>

---

## 功能特性

### 物品管理

- **物品录入** - 记录物品名称、自定义 Emoji 图标、分类、存放位置、购买日期、价格、数量、状态
- **状态追踪** - 支持"服役中"、"已闲置"、"已处置"三种状态
- **智能搜索** - 按名称快速搜索物品
- **多维筛选** - 按分类标签、状态筛选物品列表
- **日均成本** - 自动计算每件物品及总资产的日均使用成本

### 分类管理

- 8 个默认分类（电子产品、家具、厨房、衣物鞋包、图书文具、药品保健、工具器材、其他）
- 支持自定义分类，可设置图标和主题色
- 分类图标自动映射为 Emoji，未设置物品图标时作为默认展示

### 位置管理

- 无限层级树形结构（如：家 > 卧室 > 衣柜）
- 自动生成分类完整路径
- 支持添加子位置、重命名、删除

### 药箱管理

- 独立的药品管理模块
- 药品类型：内服、外用、急救
- **过期预警** - 自动检测 30 天内过期的药品并高亮提醒
- 记录用法用量、剩余数量、生产厂家等信息
- **用药提醒** - 支持设置用药时间，到时间自动推送通知
  - 支持每日提醒、每隔 N 天提醒、每周特定日期提醒
  - 可设置多个用药时间段
  - 可设置用药起止日期

### 数据统计

- **资产分布** - 环形图展示各类别资产占比
- **消费趋势** - 平滑曲线图展示近 6 个月消费走势
- **资产总览** - 总资产价值、物品总数、药品数量、过期预警数

### 数据安全

- **本地存储** - 所有数据保存在本地 SQLite 数据库，无需联网
- **数据导出** - 支持 JSON 格式导出（完整备份）
  - 桌面端：直接下载到浏览器下载目录
  - 移动端：弹出系统分享面板，可选择保存到文件或发送给他人
- **数据导入** - 通过 JSON 文件恢复数据，支持跨设备迁移
- **隐私保护** - 不上传任何数据到云端

### 个性化

- **主题色** - 5 种预设主题色（绿、蓝、橙、紫、粉）
- **货币符号** - 支持 ¥、$、€、£、₩ 等多种货币

### 系统工具

- **运行日志** - 实时查看应用运行日志，便于排查问题
  - 支持按日志级别筛选（TRACE / DEBUG / INFO / WARN / ERROR）
  - 自动刷新，最多保留最近 500 条内存日志
  - 完整日志文件保存在应用日志目录
- **通知系统** - 用药提醒等通知功能
  - Android 原生通知渠道，支持高优先级推送
  - 支持锁屏通知、震动提醒

---

## 技术栈

| 层级     | 技术                      | 版本         |
| -------- | ------------------------- | ------------ |
| 桌面框架 | Tauri                     | 2.x          |
| 前端框架 | React                     | 19.1         |
| 语言     | TypeScript                | 5.8          |
| 构建工具 | Vite                      | 7.0          |
| 样式     | Tailwind CSS              | 4.2          |
| 状态管理 | Zustand                   | 5.0          |
| 路由     | React Router DOM          | 7.14         |
| 图表     | Recharts                  | 3.8          |
| 图标     | Lucide React              | 1.8          |
| 日期处理 | Day.js                    | 1.11         |
| 数据库   | SQLite (Tauri SQL Plugin) | 2.4          |
| 后端     | Rust                      | 2021 Edition |
| 日志     | tauri-plugin-log          | 2.8          |
| 通知     | tauri-plugin-notification | 2.3          |
| 文件系统 | tauri-plugin-fs           | 2.5          |

---

## 快速开始

### 环境要求

- [Node.js](https://nodejs.org/) (LTS 版本)
- [pnpm](https://pnpm.io/) 包管理器
- [Rust](https://rustup.rs/) 工具链
- [Tauri CLI](https://tauri.app/start/prerequisites/)

### 安装依赖

```bash
pnpm install
```

### 开发模式

```bash
# 启动前端开发服务器 + Tauri 桌面应用
pnpm tauri dev
```

### 构建生产版本

**桌面端（macOS / Windows / Linux）：**

```bash
# macOS Universal
pnpm tauri build --target universal-apple-darwin

# Windows
pnpm tauri build --target x86_64-pc-windows-msvc
```

**移动端（Android）：**

```bash
# 构建 APK
pnpm tauri android build --apk
pnpm tauri android build --target aarch64            
```

构建产物位置：

- macOS: `src-tauri/target/universal-apple-darwin/release/bundle/`
- Android: `src-tauri/gen/android/app/build/outputs/apk/universal/release/`

---

## 项目结构

```
assetly/
├── src/                        # 前端源码
│   ├── components/             # 组件
│   │   ├── items/              # 物品相关组件
│   │   ├── layout/             # 布局组件
│   │   ├── medicine/           # 药品相关组件
│   │   └── shared/             # 通用组件
│   ├── routes/                 # 页面路由
│   ├── services/               # 数据服务层
│   ├── stores/                 # Zustand 状态管理
│   ├── types/                  # TypeScript 类型定义
│   └── utils/                  # 工具函数
├── src-tauri/                  # Tauri / Rust 后端
│   ├── src/                    # Rust 源码
│   ├── capabilities/           # 权限配置
│   └── icons/                  # 应用图标
├── package.json                # Node.js 依赖
├── vite.config.ts              # Vite 配置
├── tsconfig.json               # TypeScript 配置
└── README.md                   # 本文档
```

---

## 数据库设计

使用 SQLite 本地数据库，通过 Tauri SQL Plugin 访问。

### 表结构

| 表名            | 说明     | 关键字段                                                                              |
| --------------- | -------- | ------------------------------------------------------------------------------------- |
| `items`       | 物品     | name, icon, category_id, location_id, purchase_date, purchase_price, quantity, status |
| `categories`  | 分类     | name, icon, color, sort_order                                                         |
| `locations`   | 位置     | name, parent_id, full_path, level                                                     |
| `medicines`   | 药品扩展 | item_id, medicine_type, expiry_date, dosage_instructions                              |
| `settings`    | 应用设置 | key, value                                                                            |
| `_migrations` | 迁移记录 | version, applied_at                                                                   |

### 迁移历史

- **v1** - 初始 schema + 默认分类和设置
- **v2** - 物品表新增 `icon` 字段（Emoji 图标）

---

## 开发指南

### 推荐 IDE 配置

- [VS Code](https://code.visualstudio.com/)
- 插件：[Tauri](https://marketplace.visualstudio.com/items?itemName=tauri-apps.tauri-vscode) + [rust-analyzer](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer)

### 常用脚本

```bash
pnpm dev          # 启动 Vite 开发服务器
pnpm build        # TypeScript 检查 + 生产构建
pnpm preview      # 预览生产构建
pnpm tauri        # Tauri CLI
```

### 技术要点

- **响应式设计** - 桌面端侧边栏导航，移动端底部浮动胶囊导航
- **自定义组件** - 底部弹窗选择器、日历选择器、时间选择器、Emoji 选择器、级联位置选择器
- **状态管理** - 按领域拆分 Zustand Store，服务层处理所有数据库操作
- **移动端优化**
  - 全面屏手势适配：完全禁止侧滑返回，避免误触
  - 安全区域适配：自动适配刘海屏、状态栏、底部安全区
  - Touch 滚动优化：TimePicker 防抖动处理
  - 文件分享：移动端使用系统分享面板导出文件

---

## 平台支持

| 平台    | 状态             |
| ------- | ---------------- |
| macOS   | 支持 (Universal) |
| Windows | 支持             |
| Linux   | 支持             |
| Android | 支持             |
| iOS     | 待测试           |

### Android 特殊说明

- **全面屏手势**：已禁用侧滑返回功能，避免与 WebView 导航冲突
- **存储权限**：已声明外部存储读写权限，支持文件导出
- **通知权限**：Android 13+ 需要用户手动授予通知权限
- **后台限制**：用药提醒依赖应用前台运行，建议将应用加入电池优化白名单

---

## 隐私说明

- 所有数据存储在本地 SQLite 数据库中
- 不连接任何云服务或外部 API
- 导出文件通过系统分享或保存在本地，应用不访问外部网络
- 应用完全离线可用
- 日志文件仅保存在本地应用目录，不会上传

---

## License

MIT
