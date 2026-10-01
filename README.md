# 豆刻 BeanClick

**记录每一杯咖啡豆、手磨刻度和冲煮参数。**

豆刻是一款面向**手冲**与**摩卡壶**用户的轻量咖啡参数记录 App。
本地优先、无账号、无追踪、无广告。

[![Flutter CI](https://github.com/Shadoso-w/BeanClick/actions/workflows/flutter.yml/badge.svg)](https://github.com/Shadoso-w/BeanClick/actions/workflows/flutter.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%207%2B-3DDC84?logo=android)](https://developer.android.com)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

> 当前状态：**0.3.0**（= M0–M2.11 + 用户反馈第二轮修复，schema v7）。`flutter test` 实测 **343 通过**。内测 APK 见 [Releases](https://github.com/Shadoso-w/BeanClick/releases)。

---

## 它解决什么问题

冲咖啡的人最常问自己的一句话是：**「上次那杯是怎么冲的？」**

豆刻不做社区、不做商城、不接广告。它只做一件事：让你用最少的点击，把
豆子、磨豆机刻度、粉水比、水温、时间记下来，然后能查、能比、能导出。

## 核心功能

| 模块 | 说明 |
|---|---|
| 记录 | 时间线列表，FAB 一键记录，**默认复制上次参数** |
| 豆库 | 咖啡豆 + 磨豆机的分段管理，余量、烘焙日期、风味标签 |
| 统计 | 评分趋势 → 参数对比 → 消耗（按此顺序实现） |
| 我的 | 设置、导出/导入、开源许可、关于 |

### 特色

- **手磨刻度友好**：磨豆机 + 刻度 + click + 零点，展示形如 `C40 / 22 click / 零点 0`
- **参数可深可浅**：核心字段直接填，专业字段（TDS、萃取率、水质 ppm、分段注水…）折叠收起
- **调磨对比**：同一支豆 + 同一台磨，按刻度横向比评分与风味
- **余量自动扣减**：保存记录时按粉量扣减库存，可在设置里关闭

## 技术栈

| 项 | 选择 |
|---|---|
| 框架 | Flutter 3.47.5 (Dart 3.13.4) |
| 数据库 | Drift + SQLite |
| 状态管理 | Riverpod |
| 架构 | 本地优先 + Repository 模式 |
| 平台 | Android 8+ 优先 |
| 同步 | 预留 WebDAV，iCloud 后续 |

## 非功能目标

| 项目 | 目标 |
|---|---|
| 启动速度 | < 1.5s |
| 安装包 | < 30MB |
| 离线 | 完整可用 |
| 性能 | 1000 条记录流畅滚动 |
| 隐私 | 无追踪 SDK、无强制登录 |

## 开发

### 环境要求

- **Flutter**（stable）与 **Dart**；`flutter --version` 能跑通即可
- **Android SDK**（只需 compileSdk 对应的 platform + build-tools）与 **JDK 17**
- 建议把工具链装在工程之外的独立目录，用环境变量指向
  （`JAVA_HOME` / `ANDROID_HOME` / `ANDROID_SDK_ROOT` / `GRADLE_USER_HOME`），
  **不要**把本机路径写进仓库

```powershell
flutter pub get
flutter test                              # 全量测试
flutter run                               # 连真机/模拟器运行
flutter build apk --release --split-per-abi
```

发布签名见 `android/app/build.gradle.kts`（口令文件放 `android/key.properties`，
该文件与密钥库都不入库）。

产品与数据模型规范见 [docs/BeanClick-开发手册-v0.2.md](docs/BeanClick-开发手册-v0.2.md)；
版本变更见 [docs/CHANGELOG.md](docs/CHANGELOG.md)。

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

## 里程碑

- [x] **M0** 开发手册确认（v0.2 定稿）
- [x] **M1** 数据模型与应用外壳
- [x] **M2** P0 表单（新增 / 编辑 / 删除 + 复制上次）
- [x] **M2.5** P0 导出（JSON 备份 / CSV 表格）
- [x] **M2.6–M2.9** 批次模型 / 多豆冲煮 / 扩展属性 / 自定义方法与辅料 / 测评反馈
      （schema 升到 v7，见 [CHANGELOG](docs/CHANGELOG.md)）
- [x] **M2.10–M2.11** 研磨刻度「圈 + click」与相对刻度 / 图标尺寸对齐
- [ ] **M3** Android 内测
- [ ] **M5** P1 计时器、统计、图片分享、同步
- [ ] **M6** P2 智能推荐、社区、设备连接

> M4（国内商店上架）已降级为可选阶段，当前仅通过 GitHub Releases 分发。

### M1 已完成的内容

| 层 | 内容 |
|---|---|
| 数据 | Drift schema v1（5 张表）、4 个 Repository、余量扣减事务规则 |
| 领域 | 5 个实体 + 4 个枚举，含 JSON 往返（导出功能的基础） |
| 状态 | Riverpod providers（数据库、仓储、主题、列表、设置） |
| UI | 主题（咖啡棕 / 米白 / 深棕黑）、4 tab 外壳 + 中间 FAB、四页骨架与空状态 |
| 设置 | 主题模式、自动扣减余量 —— 真读写数据库 |

### M2 已完成的内容

| 功能 | 说明 |
|---|---|
| 咖啡豆表单 | 新增 / 编辑 / 删除；名称必填校验；产地、庄园、处理法、烘焙度、烘焙日期、风味标签、余量与购入总重、价格、备注 |
| 磨豆机表单 | 新增 / 编辑 / 删除；品牌与型号必填；刻度单位、零点、每圈 click；实时预览 `C40 / 22 click / 零点 0` |
| 冲煮记录表单 | 新增 / 编辑 / 删除；方法（手冲 / 摩卡壶，可展开更多）、豆子与磨豆机下拉（可就地新增）、刻度/click、粉量水量与自动粉水比、水温、总时间、滤杯、评分、风味、备注 |
| 复制上次 | 记录页 FAB 带上次参数直接进表单；**不继承评分与备注**（这是一杯新的咖啡）；表单内也可手动再复制一次 |
| 摩卡壶专属 | 火力、出液量、上壶预热（选摩卡壶时才出现） |
| 专业字段折叠 | TDS、萃取率、水质 ppm、环境温湿度、豆温、压力 |
| 余量联动 | 保存时按设置自动扣减；改动粉量按差值补扣；换豆回补旧豆；余量不足则扣至 0 并提示 |
| 删除一致性 | 删除豆子 / 磨豆机时历史记录保留、外键置空；删除记录**自动回补**余量（M2.9 改了手册 §6.2 的规则） |

M2 尚未做：**独立搜索页**（记录页已有内存过滤）。导出已在 M2.5 完成。

### M2.6 起的已完成内容

| 版本 | 内容 |
|---|---|
| M2.6 | 批次模型（一支豆子多袋，各记烘焙日期 / 余量）+ 多豆冲煮（拼配）+ 扩展属性；schema v4 |
| M2.7 | dock 改两栏 + 中间固定加号；记录卡片刻度；收藏 / 删除改左滑；schema v5 |
| M2.8 | 日期时间弹窗中文化、时间可选到时分；记录卡片第一行 = 豆名 + 方法 + 评分；自定义冲煮方法；辅料；schema v6 |
| M2.9 | 处理法多选、每 click µm、研磨刻度「圈 + click」、零点快照、删除回补、新增一杯从归零页开始；schema v7 |
| M2.10 | 研磨刻度：圈只收正整数（留空 = 0 圈）、单位进框、提示给**相对刻度**、算式收进 ⓘ、每圈 click 改必填；卡片只显示一个相对刻度值 |
| M2.11 | 传统图标与自适应图标同比例内缩（都在画布 82%），两者视觉等大 |

### M2.5 已完成的内容

| 功能 | 说明 |
|---|---|
| JSON 完整备份 | 4 张表全字段导出，含 `schemaVersion` 与计数；缩进 2 空格，人也能读 |
| CSV 表格 | 4 张表分段拼在一个文件里，中文表头；**带 UTF-8 BOM**，Excel 打开中文不乱码 |
| 二选一入口 | 设置 → 导出数据 → 弹窗选择，**JSON 为默认**；选择会被记住，下次默认选中 |
| 导出后分享 | 文件写入应用文档目录，再唤起系统分享面板让用户保存 / 发送 |
| 防 CSV 注入 | 以 `= + - @` 开头的文本会加单引号前缀，避免表格软件当公式执行 |
| 备份可读回 | `decodeJson` 支持把备份解析回来（为下一步的「导入」预留），并有往返测试守住 |

## 参与

欢迎 Issue 与 PR。提交前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。
提交 PR 前必须通过 `flutter analyze` 与 `flutter test`。

## 许可证

代码以 [MIT](LICENSE) 许可发布。文档建议以 CC BY 4.0 共享。
