# 贡献指南 / Contributing

感谢你愿意为豆刻出力。这是一个闲时维护的个人开源项目，
所以流程尽量轻，但下面几条是硬要求。

---

## 开发环境

见 [docs/DEVELOPMENT.md](DEVELOPMENT.md)。注意本项目使用 D 盘便携式工具链，
不要自行改成全局安装后提交路径相关的配置。

## 分支模型

- `main` 受保护，**禁止直接推送**，只能通过 PR 合入。
- 功能分支命名：
  - `feat/xxx` 新功能
  - `fix/xxx` 修 bug
  - `docs/xxx` 文档
  - `refactor/xxx` 重构

## 提交信息

使用约定式提交（Conventional Commits）：

```text
feat(record): 支持复制上次冲煮参数
fix(stock): 修改粉量时按差值补扣余量
docs(manual): 补充余量扣减边界规则
test(export): 补充 CSV 导出单元测试
```

类型：`feat` / `fix` / `docs` / `style` / `refactor` / `test` / `chore`

## PR 要求

提交 PR 前，本地必须通过：

```bash
flutter analyze     # 零警告
flutter test        # 全绿
```

PR 描述里请说明：

1. 改了什么，为什么
2. 关联的 Issue 编号（如有）
3. 如何验证（手动步骤或测试用例）

CI 会在 PR 上自动跑分析与测试，未通过不予合并。

## 测试要求

- 新增 P0 功能 → 必须附带对应测试，且对应开发手册附录 A 的验收清单。
- 修复 bug → 尽量补一个能复现该 bug 的测试。
- 涉及余量扣减、导出格式、统计计算的改动 → **必须有单元测试**。

## 代码风格

- 遵循 `flutter_lints`，不额外引入风格争议。
- 表意优先于简短，中文注释可以，但公共 API 用英文文档注释。
- 不引入任何广告、埋点、崩溃上报类依赖——这是本项目的底线。

## 数据模型变更

改动 Drift 表结构时：

1. 递增数据库 `schemaVersion`
2. 在 `onUpgrade` 里写**逐列迁移**（**不要**删表重建，用户数据只有一份）
3. 重跑 `dart run build_runner build --delete-conflicting-outputs`
4. 重新 dump schema 快照：
   `dart run drift_dev schema dump lib/data/database.dart test/drift/schemas`
   + `dart run drift_dev schema generate test/drift/schemas test/drift/generated`
   （忘了跑，`test/data/schema_snapshot_test.dart` 会红并点名差异）
5. 在 PR 中说明迁移策略与回滚方式

细节见 [docs/DEVELOPMENT.md](DEVELOPMENT.md) §7.4。

## 推送前：信息审核（硬要求）

**任何一次 `git push` / 建 PR / 发 Release 之前，都要先过一遍信息审核**，
确认三件事：

1. **必要性** —— 这个文件别人开发/构建/理解时真的需要吗？（能一条命令重生成的
   产物、一次性脚本、草稿默认不入库）
2. **本机信息** —— 有没有把本机路径、设备型号/序列号、凭据、代理端口、
   私人邮箱、真实个人数据带上去？（本仓库是公开的，推上去就收不回来）
3. **硬编码** —— 每处硬编码是「合理 / 建议提取 / 必须外置」？
   **因机器而异的东西必须外置**（本机字体路径、SDK/JDK 路径、代理端口）。

```powershell
# 一条命令先扫一遍；退出码 1 = 有阻断项，停。
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\check_upload_safety.ps1 -All
```

判定口径、严重度分级、报告格式、图片人工检查、历史遗留处理，
全部见 **[docs/REVIEW-BEFORE-PUSH.md](REVIEW-BEFORE-PUSH.md)**。
脚本有盲区（图片内容、语义判断、git 历史），所以**脚本过了不等于审过了**。

## UI 变更：先出设计稿

**任何 UI 改动都要先给设计稿讨论定稿，再写代码。** 设计稿至少包含：
目标、布局示意（线框图或真实渲染图）、关键尺寸与各种状态、
与现状的差异（含受影响的测试）、以及 2~3 个待确认选项。
细节与两种呈现形式见 [docs/DEVELOPMENT.md](DEVELOPMENT.md) §13.1。

## Issue

提交 Issue 请选用对应模板（Bug / 功能建议）。
标签含义：`P0` `P1` `bug` `feature` `docs`。

## 许可证

你的贡献将以 [MIT](LICENSE) 许可证发布。
