# Mermaid 图集 · 母版库

> 这里放**进度图的母版**，复制到 [`PROGRESS.md`](PROGRESS.md) 或聊天里即可用。
> 读者是 `lead`；人只需要看图，不需要读这一页。
>
> 图的**口径**（状态词、颜色、刷新时机）由
> [`AgentTeams-开发手册.md`](AgentTeams-开发手册.md) §9 定义，本页只给实现。

---

## 0. 语法红线（先看这个，否则图会裂）

进度图有两个消费者：**GitHub 的 Markdown 渲染**和 **Obsidian**。两者的 Mermaid 版本都落后于最新发布版，
所以只用**两边都稳的图型**：

| ✅ 允许 | ❌ 禁止 | 原因 |
|---|---|---|
| `flowchart`（`LR` / `TD`） | `xychart-beta` | GitHub 不支持，图裂 |
| `stateDiagram-v2` | `quadrantChart` | 同上 |
| `sequenceDiagram` | `%%{init}%%` 主题指令 | 两边渲染差异大，可能整段报错 |
| `gantt` | `click` / `linkStyle` | GitHub 出于安全会禁用 |
| `pie` | `journey` | 排版在窄屏不可读 |

另外五条硬规矩：

1. **节点 id 只用 ASCII**（`T01`、`G4`、`M3`），中文一律放**标签**里。
2. **标签一律加英文双引号**：`T01["M3-T01 导出回归"]`。
   不加引号时，标签里的 `(`、`[`、`:`、`；` 会让解析器当场报错。
3. **不要在标签里写 `#`**（它会被当实体编码）。要用序号就写「第 N 步」。
4. **`classDef` / `class` 是唯一的着色方式**，颜色用十六进制。
5. **同一张图里的状态词只能来自手册 §9.5 的七个**：`todo` / `in_progress` / `spec_review` / `code_review` / `blocked` / `done` / `dropped`。

---

## 1. 颜色与状态约定

把这一块**原样复制**到每张 `flowchart` 的末尾（改完节点后照着 `class` 一行）：

```
    classDef todo fill:#eceff1,stroke:#90a4ae,color:#37474f
    classDef doing fill:#e3f2fd,stroke:#1976d2,color:#0d47a1
    classDef review fill:#fff8e1,stroke:#f9a825,color:#795548
    classDef blocked fill:#ffebee,stroke:#c62828,color:#b71c1c
    classDef done fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20
    classDef dropped fill:#e0e0e0,stroke:#757575,color:#424242
```

| 状态 | 颜色 | 含义 |
|---|---|---|
| `todo` | 灰 | 已建卡，未派单 |
| `in_progress` | 蓝 | 子代理正在写 |
| `spec_review` / `code_review` | 琥珀 | 两阶段审查中 |
| `blocked` | 红 | 有阻塞，必须在阻塞表里有条目 |
| `done` | 绿 | 两阶段审查 + 验证命令全过 |
| `dropped` | 深灰 | 明确放弃（要写原因） |

---

## 2. 图 1 · 里程碑总览

**回答**：我们现在在 M 几？
**刷新时机**：迭代收尾；里程碑状态变化时。

```mermaid
flowchart LR
    M0["M0 手册定稿<br/>done"] --> M1["M1 数据模型与外壳<br/>done"]
    M1 --> M2["M2 P0 本地 MVP<br/>done"]
    M2 --> M3["M3 Android 内测<br/>in_progress"]
    M3 --> M4["M4 国内商店上架<br/>dropped 已降级为可选"]
    M3 --> M5["M5 P1 计时器 统计 图片分享 同步<br/>todo"]
    M5 --> M6["M6 P2 智能推荐 社区 设备连接<br/>todo"]
    M4 --> M5

    classDef todo fill:#eceff1,stroke:#90a4ae,color:#37474f
    classDef doing fill:#e3f2fd,stroke:#1976d2,color:#0d47a1
    classDef done fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20
    classDef dropped fill:#e0e0e0,stroke:#757575,color:#424242
    class M0,M1,M2 done
    class M3 doing
    class M4 dropped
    class M5,M6 todo
```

> 里程碑定义见 [`BeanClick-开发手册-v0.2.md`](../BeanClick-开发手册-v0.2.md) §16；
> M4 已降级为可选（[`README.md`](../../README.md) 里程碑小节）。

---

## 3. 图 2 · 任务 DAG

**回答**：这批要做几张卡、谁挡着谁？
**刷新时机**：每张卡状态迁移；依赖变化时。
**规矩**：`blocked_by` 画成**虚线箭头**，方向 = 依赖方向（A 依赖 B 就画 `B -.-> A`）。

```mermaid
flowchart TD
    T01["M3-T01 导出分享回归基线<br/>done"]
    T02["M3-T02 冷启动耗时采样<br/>in_progress"]
    T03["M3-T03 1000 条记录滚动压测<br/>spec_review"]
    T04["M3-T04 内测反馈清单回流<br/>blocked 等用户反馈"]
    T05["M3-T05 0.3.0 版本号与 CHANGELOG<br/>todo"]
    T06["M3-T06 出包与真机覆盖安装<br/>todo"]

    T01 -.-> T05
    T02 -.-> T06
    T03 -.-> T06
    T04 -.-> T05
    T05 -.-> T06

    classDef todo fill:#eceff1,stroke:#90a4ae,color:#37474f
    classDef doing fill:#e3f2fd,stroke:#1976d2,color:#0d47a1
    classDef review fill:#fff8e1,stroke:#f9a825,color:#795548
    classDef blocked fill:#ffebee,stroke:#c62828,color:#b71c1c
    classDef done fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20
    class T01 done
    class T02 doing
    class T03 review
    class T04 blocked
    class T05,T06 todo
```

---

## 4. 图 3 · 任务状态机

**回答**：单张卡走到哪一步了、下一步是谁？
**刷新时机**：只在**流程本身**改动时改这张图（它是规则图，不是进度图）。

```mermaid
stateDiagram-v2
    [*] --> todo
    todo --> in_progress : lead 派单
    in_progress --> spec_review : 子代理 DONE
    in_progress --> blocked : 子代理 BLOCKED
    in_progress --> in_progress : NEEDS_CONTEXT 补料后继续
    spec_review --> code_review : G4 通过
    spec_review --> in_progress : G4 打回
    code_review --> in_progress : G5 有阻断项
    code_review --> done : G5 通过 + verifier 验收命令全绿
    blocked --> in_progress : 阻塞解除且 lead 重新派单
    todo --> dropped : 明确放弃
    blocked --> dropped : 确认不做
    done --> [*]
    dropped --> [*]
```

---

## 5. 图 4 · 迭代泳道（谁在干什么）

**回答**：并行度如何、有没有人在热点文件上排队？
**刷新时机**：派单 / 收单时。

```mermaid
flowchart LR
    subgraph LEAD["lead"]
        L1["拆卡与派单"]
        L2["落盘 PROGRESS.md"]
        L3["commit 与收尾"]
    end
    subgraph DATA["impl-data 数据层"]
        D1["M3-T07 加一等列<br/>in_progress"]
    end
    subgraph UI["impl-ui 界面层"]
        U1["M3-T08 记录页左滑<br/>spec_review"]
    end
    subgraph GATE["guardian 迁移门"]
        G1["M3-T07 的迁移段<br/>blocked 等 T07 完成"]
    end
    subgraph VER["verifier"]
        V1["G6 全量验证<br/>todo"]
    end

    L1 --> D1
    L1 --> U1
    D1 -.-> G1
    U1 -.-> V1
    G1 -.-> V1
    V1 --> L2
    L2 --> L3

    classDef todo fill:#eceff1,stroke:#90a4ae,color:#37474f
    classDef doing fill:#e3f2fd,stroke:#1976d2,color:#0d47a1
    classDef review fill:#fff8e1,stroke:#f9a825,color:#795548
    classDef blocked fill:#ffebee,stroke:#c62828,color:#b71c1c
    class D1 doing
    class U1 review
    class G1 blocked
    class V1 todo
```

> 泳道**按写作用域分**，不按人分。这样一眼就能看出"两张卡是不是压在同一个热点文件上"。

---

## 6. 图 5 · 门禁与健康度

**回答**：有哪些门没过？测试数和包体有没有退化？
**刷新时机**：每个门禁通过/失败；每天收工。

门禁状态图：

```mermaid
flowchart LR
    G0["G0 需求澄清<br/>done"] --> G1["G1 设计定稿<br/>done"]
    G1 --> G2["G2 工作区就绪<br/>done"]
    G2 --> G3["G3 计划完备<br/>done"]
    G3 --> G4["G4 规格符合<br/>done"]
    G4 --> G5["G5 代码质量<br/>in_progress"]
    G5 --> G6["G6 集成验证<br/>todo"]
    G6 --> G7["G7 信息审核与收尾<br/>todo"]
    DG["DG 设计稿门<br/>done 已签字"]
    MG["MG 迁移门<br/>todo 本批不涉及"]
    PG["PG 推送门<br/>todo"]

    DG -.-> G3
    MG -.-> G3
    G6 -.-> PG

    classDef todo fill:#eceff1,stroke:#90a4ae,color:#37474f
    classDef doing fill:#e3f2fd,stroke:#1976d2,color:#0d47a1
    classDef done fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20
    class G0,G1,G2,G3,G4,DG done
    class G5 doing
    class G6,G7,MG,PG todo
```

健康度用**表格化的 flowchart 节点**，不要用 `xychart-beta`（GitHub 不支持）：

```mermaid
flowchart LR
    B["基线 <日期> 实测<br/>测试 <n> 通过<br/>arm64 <x> MB"] --> C["当前<br/>测试 <n+Δ> 通过<br/>arm64 <x> MB 持平"]
    C --> J{"判定"}
    J -->|"测试数不低于基线<br/>包体不超 30MB"| OK["健康<br/>green"]
    J -->|"任一退化"| BAD["退化<br/>必须在 PROGRESS 里写解释"]

    classDef done fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20
    classDef blocked fill:#ffebee,stroke:#c62828,color:#b71c1c
    class OK done
    class BAD blocked
```

> 数字必须来自 `verifier` 的原始输出。**容量指标只有三个**：测试通过数、包体（arm64）、
> 启动耗时（M3 起有采样才填）。别自己加指标——指标一多就没人维护。

---

## 7. 图 6 · 单卡生命周期（时序）

**回答**：一张卡从派单到合并经过谁？
**刷新时机**：流程改动时（规则图）。

```mermaid
sequenceDiagram
    autonumber
    participant L as lead
    participant W as impl 子代理
    participant V as verifier
    participant RS as rev-spec
    participant RC as rev-code
    L->>W: 派单（任务卡全文）
    W->>W: RED 写失败测试并确认失败
    W->>W: GREEN 最小实现
    W->>W: REFACTOR 整理后复测
    W-->>L: DONE 或 DONE_WITH_CONCERNS
    L->>V: 跑本卡验收命令
    V-->>L: 验证报告（原始输出 + 通过数 + 退出码）
    L->>RS: G4 规格符合性审查
    alt 有缺项
        RS-->>L: 打回
        L->>W: 补缺项
    else 通过
        RS-->>L: 通过
        L->>RC: G5 代码质量审查
        RC-->>L: 阻断项清单
        L->>W: 修阻断项
    end
    L->>V: G6 全量验证
    V-->>L: analyze/format/test 全绿
    L->>L: commit 并更新 PROGRESS.md
```

---

## 8. 图 7 · 迁移门决策树（MG）

**回答**：这次改动到底要不要动 schema？
**刷新时机**：每次有字段类改动时；这张图常年不变，直接复用。

```mermaid
flowchart TD
    A["要加/改一个字段"] --> B{"会出现在<br/>WHERE / ORDER BY / 聚合里吗"}
    B -->|"不会"| C["走扩展属性<br/>改 extra_attributes.dart<br/>不动表 不迁移"]
    B -->|"会"| D["晋升为一等列<br/>触发 MG 门"]
    D --> E["guardian 独占 database.dart<br/>加列 或 改存储编码"]
    E --> F["schemaVersion 递增<br/>写逐列 onUpgrade"]
    F --> G["build_runner 重新生成"]
    G --> H["schema dump + schema generate"]
    H --> I["补一份旧库升级测试夹具"]
    I --> J{"schema_snapshot_test<br/>两个守门用例通过"}
    J -->|"否"| K["按失败信息点名补漏<br/>不許跳过"]
    J -->|"是"| L["全量 flutter test 绿"]
    L --> M["真机覆盖安装验证<br/>旧数据原样在"]
    M --> N["才允许对外发版"]

    classDef todo fill:#eceff1,stroke:#90a4ae,color:#37474f
    classDef done fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20
    classDef blocked fill:#ffebee,stroke:#c62828,color:#b71c1c
    class C done
    class K blocked
    class N done
    class A,B,D,E,F,G,H,I,J,L,M todo
```

---

## 9. 图 8 · 推送门（PG）与分支收尾

```mermaid
flowchart LR
    A["lead 发范围<br/>分支 + git diff --stat + 文件清单"] --> B["info-reviewer 检查<br/>脚本 -All + 人眼看图"]
    B --> C{"结论"}
    C -->|"BLOCK 大于 0"| D["修完 回到第 1 步重审"]
    C -->|"有条件通过"| E["逐条落地后复核"]
    C -->|"可推送"| F["lead 执行 push 或建 PR"]
    E --> F
    F --> G["CI 全绿"]
    G --> H["用户选收尾动作"]

    classDef todo fill:#eceff1,stroke:#90a4ae,color:#37474f
    classDef blocked fill:#ffebee,stroke:#c62828,color:#b71c1c
    classDef done fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20
    class D blocked
    class F,G done
    class A,B,C,E,H todo
```

收尾动作四选一（**问用户，不自己拍板**）：建 PR / 本地合并 / 保留分支 / 丢弃 worktree。

---

## 10. 聊天里的迷你进度条

任何一次状态汇报都可以带这一行图（≤6 个节点，只高亮当前阶段）：

```mermaid
flowchart LR
    P0["G0"] --> P1["G1"] --> P2["G2"] --> P3["G3"] --> P4["G4"] --> P5["G5"] --> P6["G6"] --> P7["G7"]

    classDef done fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20
    classDef doing fill:#e3f2fd,stroke:#1976d2,color:#0d47a1
    classDef todo fill:#eceff1,stroke:#90a4ae,color:#37474f
    class P0,P1,P2,P3,P4 done
    class P5 doing
    class P6,P7 todo
```

纯文本汇报（不渲染图也能看懂，**必须带数字**）：

```text
M3-T02 冷启动采样 → G4 通过，进入 G5
门禁：G4 ✅ | G5 进行中 | DG 已签字 | MG 本批不涉及
测试：<基线 n> → <当前 n+Δ>（+Δ）| 退出码 0
包体：arm64 <x> MB（无变化）
阻塞：M3-T04 等用户内测反馈（解除条件：Releases 收到 issue）
下一动作：rev-code 审 M3-T02 的采样脚本改动
```

---

## 11. 怎么改（三个最高频的编辑场景）

### 11.1 新增一张卡

1. 在**图 2 任务 DAG** 里加一个节点，状态 `todo`，加进对应的 `class` 行。
2. 在 `PROGRESS.md` 的任务表里加一行（ID / 目标 / scope / 依赖 / 状态）。
3. 有依赖就在 DAG 上加一条**虚线**边。
4. 在**图 4 泳道**里放到对应 role 的 `subgraph`。

### 11.2 一张卡被阻塞

1. 改节点标签里的状态为 `blocked`，把 `class` 行挪到 `blocked`。
2. 在 `PROGRESS.md` **阻塞表**里加一行：卡号 / 阻塞原因 / 解除条件 / 谁负责。
3. **不许只在图上标红而不写解除条件** —— 无解除条件的阻塞等于没有阻塞。

### 11.3 迭代收尾

1. 图 1 里程碑总览更新状态。
2. 图 2 的 `done` 节点可以整批删掉，只留未完成的（历史进 `plans/` 归档）。
3. 图 5 健康度更新基线与当前值。
4. 图 4 泳道清空。

---

## 12. 自查清单（提交前过一遍）

- [ ] 没有用 `xychart-beta` / `quadrantChart` / `%%{init}%%` / `click` / `linkStyle`
- [ ] 所有节点 id 都是 ASCII
- [ ] 所有标签都带英文双引号，标签里没有裸的 `(` `[` `:` `#`
- [ ] 用到的状态词都在手册 §9.5 的七个之内
- [ ] `classDef` 块完整，且每个节点都被某个 `class` 覆盖（漏了会显示默认色，一眼能看出）
- [ ] 每个 `blocked` 节点在 `PROGRESS.md` 阻塞表里都有对应行，且有解除条件
- [ ] 数字（测试数 / 包体 / 耗时）来自 `verifier` 的原始输出，不是估计
- [ ] 图里的时间戳与 `PROGRESS.md` 顶部的"最后更新"一致
