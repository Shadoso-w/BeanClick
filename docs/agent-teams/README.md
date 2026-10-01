# Agent Teams 开发文档 · 总览

> 这套文档把 Superpowers 的「七阶段 + 子代理驱动开发」落到**豆刻 BeanClick**这台具体项目上。
> 它不替代项目现有规范，只补现有规范没有的那一层：**谁来做、按什么顺序做、什么叫做完了、进度怎么看**。

---

## 30 秒上手

| 你的角色 | 从这里开始 |
|---|---|
| **人（项目所有者）** | 看 [`PROGRESS.md`](PROGRESS.md) 的 5 张图 → 需要细节再看 [`AgentTeams-开发手册.md`](AgentTeams-开发手册.md) §5 |
| **Lead（带队的 AI 或人）** | [`AgentTeams-开发手册.md`](AgentTeams-开发手册.md) 全文，然后做 §11.1 的开工清单 |
| **subagent（被派单的代理）** | 只读你收到的那张任务卡 + 对应的 [`skills/`](skills/) 技能卡；**不要通读全套** |

---

## 文件清单

| 文件 | 给谁 | 作用 |
|---|---|---|
| [`AgentTeams-开发手册.md`](AgentTeams-开发手册.md) | Lead | **主手册**：团队编制、写作用域冲突地图、七阶段八门禁、任务卡规范、迁移门、返回协议、反模式 |
| [`PROGRESS.md`](PROGRESS.md) | 人 + Lead | **进度看板（唯一真相源）**：5 张 mermaid 图 + 任务表 + 阻塞表 + 门禁健康度 |
| [`Mermaid-图集.md`](Mermaid-图集.md) | Lead | 全部图的**母版**，复制即用；含语法约定与 GitHub/Obsidian 兼容性红线 |
| [`任务卡模板.md`](任务卡模板.md) | Lead | 任务卡的九个字段 + 3 张填好的样例（M3 真实任务） |
| [`审查报告模板.md`](审查报告模板.md) | rev-spec / rev-code / info-reviewer | 规格审查 / 质量审查 / 信息审核 三份可粘贴模板 |
| [`skills/`](skills/) | subagent | **8 张技能卡**，SKILL.md 格式，直接喂给 subagent |

### 8 张技能卡

| 技能卡 | 角色 | 什么时候加载 |
|---|---|---|
| [beanclick-lead-orchestration](skills/beanclick-lead-orchestration/SKILL.md) | `lead` | 组队、拆卡、派单、收单 |
| [beanclick-subagent-task-loop](skills/beanclick-subagent-task-loop/SKILL.md) | `impl-*` | 拿到一张任务卡开工前 |
| [beanclick-two-stage-review](skills/beanclick-two-stage-review/SKILL.md) | `rev-spec` / `rev-code` | 审查任何实现产出前 |
| [beanclick-drift-migration-guard](skills/beanclick-drift-migration-guard/SKILL.md) | `guardian` | 要碰 `schemaVersion` 或表结构时 |
| [beanclick-ui-design-gate](skills/beanclick-ui-design-gate/SKILL.md) | `impl-ui` / `lead` | 任何 UI 改动**之前** |
| [beanclick-verify-before-done](skills/beanclick-verify-before-done/SKILL.md) | `verifier` | 宣称"做完了"之前 |
| [beanclick-progress-board](skills/beanclick-progress-board/SKILL.md) | `lead` | 任何状态迁移 / 门禁变化 / 收工时 |
| [beanclick-pre-push-info-review](skills/beanclick-pre-push-info-review/SKILL.md) | `info-reviewer` | 任何 `git push` / 建 PR / 发 Release 之前 |

> 技能卡的 `description` 只写"什么时候用"，**不概括工作流**——
> 一旦概括了，subagent 会照着 description 干，不再读卡片正文
> （这是 Superpowers 源码里的明确设计，见参考指南 §6.2）。

---

## 这套文档的边界

**它管**：团队编制与写作用域、阶段与门禁、任务卡、审查、进度可见性、以及豆刻特有的三个高风险特区（
设计稿 / 数据迁移 / 公开推送）。

**它不管**（一律指向现有文档，避免两份规范打架）：

| 主题 | 权威文档 |
|---|---|
| 环境搭建、工具链、Drift 约定、排障 | [`docs/DEVELOPMENT.md`](../DEVELOPMENT.md) |
| 产品范围、数据模型、验收清单 | [`docs/BeanClick-开发手册-v0.2.md`](../BeanClick-开发手册-v0.2.md) |
| 加字段 / 加枚举 / 加可扩展对象 | [`docs/添加新属性指南.md`](../添加新属性指南.md) |
| 推送前信息审核的判定口径 | [`docs/REVIEW-BEFORE-PUSH.md`](../REVIEW-BEFORE-PUSH.md) |
| 分支模型、提交信息、PR 要求 | [`CONTRIBUTING.md`](../../CONTRIBUTING.md) |
| 出包与真机安装 | [`RELEASING.md`](../../RELEASING.md) |

---

## 三条最容易被忽视的规则

1. **写作用域是文件级的，不是模块级的。** 两张卡的文件集合相交，就必须串行——
   这一点在 `lib/data/database.dart` 上尤其致命（迁移段互相覆盖会悄悄少一步）。
2. **依赖只表达顺序，不会唤醒任何人。** 前置卡完成后，必须由 Lead 显式派下一张。
3. **进度不在 `PROGRESS.md` 里就等于不存在。** 只有 Lead 能写它；"测试全过"必须附通过数与退出码。

---

## 维护这套文档

* 手册改的是**流程**，改完要同步 `PROGRESS.md` 的图例与 `Mermaid-图集.md` 的母版。
* 技能卡的 `description` **只写"什么时候用"**，不要概括工作流——
  一旦概括了，subagent 会照着 description 干，不再读卡片正文（这是 Superpowers 源码里的明确设计）。
* 本目录所有文件在**公开仓库**里，描述本机特征一律用占位符
  （[`REVIEW-BEFORE-PUSH.md`](../REVIEW-BEFORE-PUSH.md) §9）；推送前照 §5.7 走 PG 门。
* 新写的 mermaid 图先过 [`Mermaid-图集.md`](Mermaid-图集.md) §0 的语法红线，再进 `PROGRESS.md`。
