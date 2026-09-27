# M1 数据模型设计稿

依据：`docs/BeanClick-开发手册-v0.2.md` §6 数据模型、§6.2 余量扣减、§6.3 设置项、§7 字段规范
目标：M1 阶段可被 Drift + SQLite 一对一落地，字段名即代码里的 Dart 属性名。

---

## 0. 总体约定

| 约定 | 决定 | 理由 |
|---|---|---|
| 主键 | `int autoIncrement` | 单机应用，无需分布式 ID；Drift 原生支持 |
| 时间存储 | `DateTime`，Drift 默认存 Unix 秒 | 排序与范围查询成本最低 |
| 枚举存储 | `TEXT` + Dart `enum` 映射 | 可读、可手工修数据、跨版本稳定 |
| 风味标签 | `TEXT` 存 JSON 数组 | 标签数量不定，MVP 不需要按标签建索引查询；P1 若需筛选再拆关联表 |
| 照片 | `TEXT` 存相对路径 | 图片文件另存应用私有目录，DB 只存路径，避免库体积膨胀 |
| 删除策略 | 软删除不采用，直接硬删 + 外键 `SET NULL` / `CASCADE` | 本地单机备份由 JSON 导出负责 |
| 同步字段 | v1 **不加** | WebDAV 属 P1，预留 `updatedAt` 便于将来做冲突判定 |

### 枚举定义

```dart
enum BrewMethod { pourOver, mokaPot, frenchPress, aeropress, espresso, other }
enum RoastLevel { light, mediumLight, medium, mediumDark, dark }
enum ProcessMethod { washed, natural, honey, anaerobic, wetHulled, other }
enum GrindScaleUnit { click, step, number, micron }   // click=C40类, number=1-10标度
```

> `BrewMethod` 增加了法压壶 / 爱乐压 / 意式浓缩。手册 §7 只写了「手冲 / 摩卡壶」，
> 但枚举留扩展位不会增加 UI 成本（默认只展示前两项），加字段比改 schema 便宜。

---

## 1. CoffeeBean（咖啡豆）

| 列 | Dart 类型 | 可空 | 默认 | 说明 |
|---|---|---|---|---|
| `id` | int | 否 | auto | 主键 |
| `name` | String | 否 | — | 豆子名称，必填 |
| `origin` | String? | 是 | — | 产地 |
| `farm` | String? | 是 | — | 庄园 |
| `process` | ProcessMethod? | 是 | — | 处理法 |
| `roastLevel` | RoastLevel? | 是 | — | 烘焙度 |
| `roastDate` | DateTime? | 是 | — | 烘焙日期（用于算养豆期） |
| `flavorTags` | List&lt;String&gt; | 否 | `[]` | JSON 编码存储 |
| `remainingGrams` | double | 否 | `0` | 余量，**下限 0** |
| `initialGrams` | double? | 否 | — | 购入总重，用于算消耗百分比 |
| `price` | double? | 是 | — | 价格 |
| `photoPath` | String? | 是 | — | 照片相对路径 |
| `notes` | String? | 是 | — | 备注 |
| `createdAt` | DateTime | 否 | now | |
| `updatedAt` | DateTime | 否 | now | 每次写入刷新 |

**索引**：`name`（搜索）、`roastDate`（按新鲜度排序）

**派生值（不落库，查询时计算）**：
- 养豆天数 = `now - roastDate`
- 消耗比例 = `(initialGrams - remainingGrams) / initialGrams`

---

## 2. Grinder（磨豆机）

| 列 | Dart 类型 | 可空 | 默认 | 说明 |
|---|---|---|---|---|
| `id` | int | 否 | auto | 主键 |
| `brand` | String | 否 | — | 品牌，必填 |
| `model` | String | 否 | — | 型号，必填 |
| `burrType` | String? | 是 | — | 刀盘类型（锥刀/平刀/鬼齿） |
| `scaleUnit` | GrindScaleUnit | 否 | `click` | 刻度单位 |
| `zeroPoint` | double? | 是 | `0` | 零点 |
| `clicksPerRevolution` | int? | 是 | — | 每圈 click 数 |
| `calibrationNote` | String? | 是 | — | 校准说明 |
| `notes` | String? | 是 | — | 备注 |
| `createdAt` | DateTime | 否 | now | |
| `updatedAt` | DateTime | 否 | now | |

**展示格式**（手册 §7）：`C40 / 22 click / 零点 0`
→ 由 `brand` + `model` + `grindSetting` + `scaleUnit` + `zeroPoint` 拼装，不是独立字段。

**索引**：`brand`, `model`

---

## 3. BrewLog（冲煮记录）

### 核心字段

| 列 | Dart 类型 | 可空 | 默认 | 说明 |
|---|---|---|---|---|
| `id` | int | 否 | auto | 主键 |
| `beanId` | int? | 是 | — | FK → CoffeeBean，`ON DELETE SET NULL` |
| `grinderId` | int? | 是 | — | FK → Grinder，`ON DELETE SET NULL` |
| `recipeId` | int? | 是 | — | FK → Recipe，`ON DELETE SET NULL` |
| `method` | BrewMethod | 否 | `pourOver` | 冲煮方法 |
| `grindSetting` | double? | 是 | — | 研磨刻度数值 |
| `grindClicks` | int? | 是 | — | 额外 click 数 |
| `doseGrams` | double? | 是 | — | 粉量 g |
| `waterGrams` | double? | 是 | — | 水量 g |
| `ratio` | double? | 是 | — | 粉水比（1:N 的 N） |
| `waterTemp` | double? | 是 | — | 水温 ℃ |
| `totalTimeSeconds` | int? | 是 | — | 总时间（秒，存整数避免精度噪音） |
| `dripper` | String? | 是 | — | 滤杯 |
| `rating` | int? | 是 | — | 评分 1–5 |
| `flavorTags` | List&lt;String&gt; | 否 | `[]` | JSON |
| `notes` | String? | 是 | — | 备注 |
| `photoPath` | String? | 是 | — | 照片 |
| `brewedAt` | DateTime | 否 | now | 冲煮时间（时间线排序依据） |
| `isBest` | bool | 否 | `false` | 「标记最佳参数」（§8 调磨对比） |
| `createdAt` | DateTime | 否 | now | |
| `updatedAt` | DateTime | 否 | now | |

### 专业字段（UI 折叠，DB 平铺）

| 列 | Dart 类型 | 可空 | 说明 |
|---|---|---|---|
| `tds` | double? | 是 | TDS % |
| `extractionYield` | double? | 是 | 萃取率 %，可由 TDS×水量/粉量 反推 |
| `waterPpm` | int? | 是 | 水质 ppm |
| `ambientTemp` | double? | 是 | 环境温度 |
| `ambientHumidity` | double? | 是 | 环境湿度 |
| `beanTemp` | double? | 是 | 豆温 |
| `pressure` | double? | 是 | 压力 bar |
| `pourStages` | List&lt;PourStage&gt;? | 是 | 分段注水，JSON 存储 |

### 摩卡壶专属（`method == mokaPot` 时展示）

| 列 | Dart 类型 | 可空 | 说明 |
|---|---|---|---|
| `heatLevel` | String? | 是 | 火力：小火/中火/大火 |
| `yieldGrams` | double? | 是 | 出液量 g |
| `preheatUpperChamber` | bool? | 是 | 上壶是否预热 |

### 嵌套结构

```dart
class PourStage {
  final int order;          // 第几段
  final double waterGrams;  // 本段注水量
  final int atSecond;       // 开始时间（秒）
  final String? note;       // 备注，如「闷蒸」
}
```

**索引**：`brewedAt`（时间线）、`beanId`、`grinderId`、`method`、`rating`
**复合索引**：`(beanId, grinderId, grindSetting)` —— 直接服务「调磨对比」核心场景

**派生值**：`ratio` 若为空且 `doseGrams`、`waterGrams` 齐全，展示时按 `waterGrams / doseGrams` 计算。

---

## 4. Recipe（配方）

| 列 | Dart 类型 | 可空 | 默认 | 说明 |
|---|---|---|---|---|
| `id` | int | 否 | auto | 主键 |
| `name` | String | 否 | — | 配方名 |
| `method` | BrewMethod | 否 | `pourOver` | |
| `doseGrams` | double? | 是 | — | |
| `waterGrams` | double? | 是 | — | |
| `ratio` | double? | 是 | — | |
| `waterTemp` | double? | 是 | — | |
| `totalTimeSeconds` | int? | 是 | — | |
| `pourStages` | List&lt;PourStage&gt;? | 是 | — | JSON |
| `grindSuggestion` | String? | 是 | — | 研磨建议（文字，不绑定具体磨豆机） |
| `notes` | String? | 是 | — | |
| `createdAt` | DateTime | 否 | now | |
| `updatedAt` | DateTime | 否 | now | |

> MVP 阶段 Recipe 可以先只建表不开放 UI；「复制上次」走的是直接复制 `BrewLog`，
> 不依赖 Recipe。表中存在是为了避免 M1 之后再改 schema。

---

## 5. AppSetting（设置单例）

手册 §6 写的是 `Settings(key, value)`。落地为 key-value 表：

| 列 | Dart 类型 | 可空 | 说明 |
|---|---|---|---|
| `key` | String | 否 | 主键 |
| `value` | String | 否 | 统一以字符串存储，读取时按类型解析 |
| `updatedAt` | DateTime | 否 | |

键与默认值见手册 §6.3，共 7 项：
`themeMode=system`、`autoDeductStock=true`、`defaultMethod=pourOver`、
`unitWeight=g`、`unitTemp=℃`、`exportFormat=json`、`firstLaunchDone=false`

---

## 6. 余量扣减逻辑（手册 §6.2 落地）

放在 **Repository 层的事务（transaction）** 内，不用 SQLite 触发器：

- 理由：扣减规则含业务判断（差值补扣、下限 0、开关判断），触发器难测试、难读。

```text
saveBrewLog(log):
  begin transaction
    if log.id == null:                      # 新建
      insert log
      if setting.autoDeductStock:
         deduct(beanId, log.doseGrams)      # 余量 = max(0, 余量 - 粉量)
    else:                                   # 编辑
      old = selectById(log.id)
      update log
      if setting.autoDeductStock:
         deduct(beanId, log.doseGrams - old.doseGrams)   # 按差值补扣
    commit

deleteBrewLog(id):
  硬删除，不回补余量（手册 §6.2 明确）
```

**待定细节（M2 前需确认）**：编辑记录时若更换了豆子（`beanId` 变了），
差值应「旧豆回补 + 新豆扣减」还是「只在同一支豆内做差值」。
我倾向后者更简单，但前者更符合直觉——需要你拍板。

---

## 7. schemaVersion 与迁移

- v1 = 上述全部表，`schemaVersion = 1`。
- 迁移策略：M1 阶段仅实现 `onCreate` 建表；`onUpgrade` 从 v2 起按版本号逐个补 `Migration`。
- 每次改表必须：递增 `schemaVersion` → 补迁移 → 重跑 `build_runner` → 更新本文档。
- 建库时会在 `onCreate` 里种入手册 §6.3 的 7 项默认设置。

---

## 8. 落地约定（实现时踩过的坑）

### 8.1 表定义必须和自定义类型在同一 library

`textEnum<ProcessMethod>()` 与 `.map(const StringListConverter())` 要求生成器能在
`part` 文件内解析到这些类型，而 **drift_dev 不会把相对导入写进 `*.g.dart`**。
把表拆到 `tables.dart`、枚举拆到 `enums.dart` 再用相对导入互相引用，
会让 `database.g.dart` 出现上百条 `Undefined class`。

**所以：类型转换器 + 表定义 + `AppDatabase` 全部放在 `lib/data/database.dart`。**
跨文件引用一律用 `package:beanclick/...`。

### 8.2 查询必须用数据库实例上的表访问器

```dart
_db.select(_db.brewLogs);   // 对
_db.select(BrewLogs());     // 错：表对象被当成 HasResultSet
```

生成器访问器名 = 表类名首字母小写：`CoffeeBeans` → `_db.coffeeBeans`。

### 8.3 `AdjustStockResult.applied` 的符号约定

`requested` 与 `applied` 都是**扣减为正、回补为负**。

两者只在被 0 下限裁剪时不同：

| 场景 | requested | applied | before → after |
|---|---|---|---|
| 正常扣 15g | `+15` | `+15` | 200 → 185 |
| 库存 10g 却要扣 15g | `+15` | `+10` | 10 → 0（`clamped = true`） |
| 回补 5g | `-5` | `-5` | 185 → 190 |

`applied` 刻意用 `before - after` 反推而非直接用 `deltaGrams`，
这样裁剪场景下它仍然表示**真实生效量**。

