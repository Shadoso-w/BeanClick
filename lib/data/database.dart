/// Drift 数据库定义。
///
/// 表结构对应 `docs/M1-DATA-MODEL.md`，改表时必须同步更新该文档，
/// 并递增 `AppDatabase.schemaVersion`。
///
/// 注意：表定义与枚举/转换器**必须放在同一个 library 内**（本文件 + 它的 part）。
/// 如果拆到别的文件里用相对导入，drift_dev 生成代码时既不会写出 import，
/// 也不会解析到这些符号，`database.g.dart` 会出现大量 `Undefined class`。
library;

import 'dart:convert';
import 'dart:io';

import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/domain/settings_keys.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// 类型转换器
// ---------------------------------------------------------------------------

/// `List<String>` ↔ JSON 字符串（风味标签）。
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) return const [];
    return decoded.map((e) => e.toString()).toList(growable: false);
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// 可空的 `List<PourStage>` ↔ JSON 字符串（分段注水）。
class PourStageListConverter extends TypeConverter<List<PourStage>?, String?> {
  const PourStageListConverter();

  @override
  List<PourStage>? fromSql(String? fromDb) {
    if (fromDb == null || fromDb.isEmpty) return null;
    final decoded = jsonDecode(fromDb);
    if (decoded is! List) return null;
    return decoded
        .map((e) => PourStage.fromJson((e as Map).cast<String, Object?>()))
        .toList(growable: false);
  }

  @override
  String? toSql(List<PourStage>? value) {
    if (value == null) return null;
    return jsonEncode(value.map((e) => e.toJson()).toList(growable: false));
  }
}

/// 任意 JSON（字符串 / 数字 / 布尔 / 列表 / 对象）↔ TEXT。
///
/// 给扩展属性用：一个值可能是 `"埃塞俄比亚"`、`1850`、`true` 或 `["花果","柑橘"]`，
/// 这里统一按 JSON 存，读出来时原样还原类型。
class JsonValueConverter extends TypeConverter<Object?, String?> {
  const JsonValueConverter();

  @override
  Object? fromSql(String? fromDb) {
    if (fromDb == null || fromDb.isEmpty) return null;
    try {
      return jsonDecode(fromDb);
    } on FormatException {
      // 兼容手工写进库的裸字符串（没有引号）。
      return fromDb;
    }
  }

  @override
  String? toSql(Object? value) {
    if (value == null) return null;
    try {
      return jsonEncode(value);
    } on JsonUnsupportedObjectError {
      // 无法编码的对象退化成字符串，总比写失败好。
      return jsonEncode(value.toString());
    }
  }
}

/// 容忍未知值的枚举转换器。
///
/// Drift 自带的 `textEnum<T>()` 用 `values.byName(...)` 解码，
/// **遇到不认识的字符串会抛 `ArgumentError`**。这在前向兼容上是致命的：
/// 将来新版本加了「某种冲煮方法」，旧版本读到那条记录会直接崩。
///
/// ⚠️ **不能写成 `textEnum<T>().map(本转换器)`**——
/// `textEnum<T>()` 内部已经挂了一个 `EnumNameConverter`，
/// 再 `.map()` 只是又包一层，内层那个抛异常的转换器**仍然会先执行**。
/// 必须用裸 `text()` 再接本转换器。
class TolerantEnumConverter<T extends Enum> extends TypeConverter<T?, String?> {
  const TolerantEnumConverter(this.values, {this.fallback});

  final List<T> values;

  /// 认不出时的回退值；为 null 表示回退成 null。
  final T? fallback;

  @override
  T? fromSql(String? fromDb) {
    if (fromDb == null) return fallback;
    for (final value in values) {
      if (value.name == fromDb) return value;
    }
    return fallback;
  }

  @override
  String? toSql(T? value) => value?.name;
}

// ---------------------------------------------------------------------------
// 表定义
// ---------------------------------------------------------------------------

/// 咖啡豆（设计稿 §1）。
///
/// 「一支豆子」代表**一款买过的咖啡**（名称 + 产地 + 处理法 + 风味）。
/// 具体的烘焙日期、烘焙度与余量挂在 [BeanBatches] 上——
/// 复购同一款豆子只需再加一个批次，而不是新建一支重复的豆子。
@DataClassName('CoffeeBeanRow')
class CoffeeBeans extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  TextColumn get origin => text().nullable()();

  TextColumn get farm => text().nullable()();

  /// 处理法，存枚举 name。
  TextColumn get process => text()
      .map(const TolerantEnumConverter<ProcessMethod>(ProcessMethod.values))
      .nullable()();

  /// 风味标签，JSON 数组。属于「这款豆子」而不是某个批次。
  TextColumn get flavorTags => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();

  /// 收藏标记：豆库可只看收藏，复购时也先从这里挑。
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  TextColumn get photoPath => text().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 咖啡豆批次（复购产生的每一袋）。
///
/// 余量、购入总重、烘焙日期、价格、烘焙度都挂在批次上——
/// 这些是「这一袋」的属性，不是「这款豆子」的属性。
@DataClassName('BeanBatchRow')
@TableIndex(name: 'idx_bean_batches_bean_id', columns: {#beanId})
class BeanBatches extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get beanId =>
      integer().references(CoffeeBeans, #id, onDelete: KeyAction.cascade)();

  /// 烘焙日期。
  DateTimeColumn get roastDate => dateTime().nullable()();

  /// 这一袋的烘焙度（同款豆子不同批次可能不同）。
  TextColumn get roastLevel => text()
      .map(const TolerantEnumConverter<RoastLevel>(RoastLevel.values))
      .nullable()();

  /// 剩余克数（g），下限 0，由 Repository 保证。
  RealColumn get remainingGrams => real().withDefault(const Constant(0.0))();

  /// 购入总重（g），用于算消耗比例。
  RealColumn get initialGrams => real().nullable()();

  RealColumn get price => real().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 磨豆机（设计稿 §2）。
@DataClassName('GrinderRow')
class Grinders extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get brand => text().withLength(min: 1, max: 60)();

  TextColumn get model => text().withLength(min: 1, max: 60)();

  /// 刀盘类型：锥刀 / 平刀 / 鬼齿。
  TextColumn get burrType => text().nullable()();

  TextColumn get scaleUnit => text()
      .map(const TolerantEnumConverter<GrindScaleUnit>(GrindScaleUnit.values))
      .withDefault(const Constant('click'))();

  RealColumn get zeroPoint =>
      real().nullable().withDefault(const Constant(0.0))();

  IntColumn get clicksPerRevolution => integer().nullable()();

  TextColumn get calibrationNote => text().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 冲煮记录（设计稿 §3）。
///
/// 豆子关联**不在**本表：一条记录可以用多支豆子（拼配），
/// 每支豆子与各自粉量存在 [BrewLogBeans] 里。
/// 本表的 `beanId` 只是「主豆」冗余字段，便于列表展示与按豆筛选。
@DataClassName('BrewLogRow')
@TableIndex(name: 'idx_brew_logs_brewed_at', columns: {#brewedAt})
class BrewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 主豆（冗余，便于快速查询）。
  IntColumn get beanId => integer().nullable().references(
    CoffeeBeans,
    #id,
    onDelete: KeyAction.setNull,
  )();

  IntColumn get grinderId => integer().nullable().references(
    Grinders,
    #id,
    onDelete: KeyAction.setNull,
  )();

  IntColumn get recipeId => integer().nullable().references(
    Recipes,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get method => text()
      .map(const TolerantEnumConverter<BrewMethod>(BrewMethod.values))
      .withDefault(const Constant('pourOver'))();

  /// 自定义冲煮方法的原文（如「拿铁」）；为空表示用内置的 [method]。
  ///
  /// 单独一列而不是把自定义名字塞进 [method]：[method] 挂着容忍枚举转换器，
  /// 认不出的字符串会被回退掉，等于**丢掉方法**。
  TextColumn get methodLabel => text().nullable()();

  // --- 核心参数 ---
  RealColumn get grindSetting => real().nullable()();

  IntColumn get grindClicks => integer().nullable()();

  /// 总粉量（拼配时是各支豆子之和）。
  RealColumn get doseGrams => real().nullable()();

  RealColumn get waterGrams => real().nullable()();

  /// 粉水比中「1 : N」的 N。
  RealColumn get ratio => real().nullable()();

  RealColumn get waterTemp => real().nullable()();

  IntColumn get totalTimeSeconds => integer().nullable()();

  TextColumn get dripper => text().nullable()();

  /// 评分 1–5。
  IntColumn get rating => integer().nullable()();

  TextColumn get flavorTags => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();

  TextColumn get notes => text().nullable()();

  TextColumn get photoPath => text().nullable()();

  DateTimeColumn get brewedAt => dateTime().withDefault(currentDateAndTime)();

  /// 「标记最佳参数」。
  BoolColumn get isBest => boolean().withDefault(const Constant(false))();

  /// 收藏这条参数（方便以后一键复制出来）。
  ///
  /// 与 [isBest] 的区别：`isBest` 是「这一杯是这套参数的最好结果」，
  /// 收藏是「把这套参数存起来，以后还要照着冲」——
  /// 「新增一杯」右上角复制按钮长按后列出的就是收藏过的这些。
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  // --- 专业字段（UI 折叠） ---
  RealColumn get tds => real().nullable()();

  RealColumn get extractionYield => real().nullable()();

  IntColumn get waterPpm => integer().nullable()();

  RealColumn get ambientTemp => real().nullable()();

  RealColumn get ambientHumidity => real().nullable()();

  RealColumn get beanTemp => real().nullable()();

  RealColumn get pressure => real().nullable()();

  /// 分段注水，JSON 数组，可为空。
  TextColumn get pourStages =>
      text().map(const PourStageListConverter()).nullable()();

  // --- 豆子的烘焙信息（随记录快照，豆子信息被改也不影响历史） ---
  /// 烘焙日期。
  DateTimeColumn get beanRoastDate => dateTime().nullable()();

  /// 烘焙度。
  TextColumn get beanRoastLevel => text()
      .map(const TolerantEnumConverter<RoastLevel>(RoastLevel.values))
      .nullable()();

  // --- 摩卡壶专属 ---
  TextColumn get heatLevel => text().nullable()();

  RealColumn get yieldGrams => real().nullable()();

  BoolColumn get preheatUpperChamber => boolean().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 一条冲煮记录用到的豆子（多行 = 拼配）。
///
/// 行类命名为 `BeanUsageRow`，避免与领域实体 `BeanUsage` 同名冲突。
///
/// 用**自增主键**而不是 `(brewLogId, beanId)` 复合主键：
/// 复合主键要求 `beanId` 非空，导致豆子被删时只能级联删掉整行用量，
/// 拼配记录的历史就断了。换成自增主键后 `beanId` 可以是 `SET NULL`，
/// 再配合 [beanNameSnapshot] 保存当时的豆子名，历史永远可读。
@DataClassName('BeanUsageRow')
@TableIndex(name: 'idx_brew_log_beans_brew_log_id', columns: {#brewLogId})
@TableIndex(name: 'idx_brew_log_beans_bean_id', columns: {#beanId})
class BrewLogBeans extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get brewLogId =>
      integer().references(BrewLogs, #id, onDelete: KeyAction.cascade)();

  /// 豆子被删除时置空——用量行本身要保留。
  IntColumn get beanId => integer().nullable().references(
    CoffeeBeans,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// 消费的批次。批次被删时置空，历史记录仍保留。
  IntColumn get batchId => integer().nullable().references(
    BeanBatches,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// 当时的豆子名快照：豆子被删或改名后，记录仍能显示用的什么豆。
  TextColumn get beanNameSnapshot => text().nullable()();

  /// 当时的烘焙日期快照。
  DateTimeColumn get roastDateSnapshot => dateTime().nullable()();

  /// 这一支豆子用了多少克。
  RealColumn get doseGrams => real().withDefault(const Constant(0.0))();

  /// 顺序，0 是主豆。
  IntColumn get position => integer().withDefault(const Constant(0))();
}

/// 一条记录里加的一种辅料（牛奶、榛果糖浆…）。多行 = 加了多种。
///
/// 与 [BrewLogBeans] 同构：记录删了跟着删（级联），
/// 名字**直接存文本**不建名字表 —— 历史项靠聚合已有记录得到，
/// 用户不需要维护一份辅料清单；名字写进记录后也不会被改名影响。
///
/// 类名刻意写成 `Addins`（不是 `AddIns`）：drift 按驼峰拆词，
/// `BrewLogAddIns` 会变成 `brew_log_add_ins`，而 `BrewLogAddins` 才是
/// 干净的 `brew_log_addins`。
@DataClassName('BrewLogAddInRow')
@TableIndex(name: 'idx_brew_log_addins_brew_log_id', columns: {#brewLogId})
class BrewLogAddins extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get brewLogId =>
      integer().references(BrewLogs, #id, onDelete: KeyAction.cascade)();

  /// 辅料名快照，如「牛奶」。
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// 数量；可空 = 只记「加了什么」没量。
  RealColumn get amount => real().nullable()();

  /// 单位，存枚举 name（`ml` / `gram` / `pump` / `serving`）。
  TextColumn get unit => text()
      .map(
        const TolerantEnumConverter<AddInUnit>(
          AddInUnit.values,
          fallback: AddInUnit.ml,
        ),
      )
      .withDefault(const Constant('ml'))();

  /// 顺序。
  IntColumn get position => integer().withDefault(const Constant(0))();
}

/// 配方（设计稿 §4）。
@DataClassName('RecipeRow')
class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  TextColumn get method => text()
      .map(const TolerantEnumConverter<BrewMethod>(BrewMethod.values))
      .withDefault(const Constant('pourOver'))();

  RealColumn get doseGrams => real().nullable()();

  RealColumn get waterGrams => real().nullable()();

  RealColumn get ratio => real().nullable()();

  RealColumn get waterTemp => real().nullable()();

  IntColumn get totalTimeSeconds => integer().nullable()();

  TextColumn get pourStages =>
      text().map(const PourStageListConverter()).nullable()();

  /// 研磨建议（文字描述，不绑定具体磨豆机）。
  TextColumn get grindSuggestion => text().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 设置项（key-value 单例表，设计稿 §5）。
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text().withLength(min: 1, max: 60)();

  TextColumn get value => text()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// 扩展属性：给豆子 / 磨豆机挂**任意**附加信息。
///
/// ## 用途与边界
///
/// 用于「只记录、只展示」，**不参与筛选/排序/统计**的属性，
/// 例如购买渠道、海拔、包装规格、设备序列号……
/// 这类属性加一个只需改一行字，不用动表结构、不用迁移、不用改测试。
///
/// **不要**把需要查询的字段塞进这张表：
/// key-value 一旦要参与 `WHERE` / `ORDER BY` / 聚合，
/// 就会退化成「全表扫描 + 逐行解析 JSON」，
/// `adjustStock`、按豆筛选、调磨对比都会被拖慢。
///
/// 需要查询的属性应当**晋升为一等列**，步骤见
/// `docs/添加新属性指南.md`。
///
/// ## 设计取舍
///
/// - **复合主键 `(ownerType, ownerId, key)`**：天然保证同一对象同一 key 唯一，
///   写入用 upsert，不需要额外的唯一索引。
/// - **`value` 存 JSON**：一个字段就能承载字符串/数字/布尔/数组，
///   读出来时类型还原，避免为每种类型开一列。
/// - **`valueType` 冗余类型名**：让 UI 知道该用什么控件渲染、怎么排序展示，
///   也让导出文件对人可读。
/// - **`isBuiltin`**：标记「这个 key 是 App 内置的」。
///   用户自己加的 key 可以随意删；内置 key 只能改值，删了会导致功能缺字段。
@DataClassName('ExtraAttributeRow')
@TableIndex(name: 'idx_extra_owner', columns: {#ownerType, #ownerId})
class ExtraAttributes extends Table {
  /// 归属对象的类型：`bean` / `grinder`（见 `ExtraOwnerType`）。
  TextColumn get ownerType => text().withLength(min: 1, max: 32)();

  /// 归属对象的 id。
  IntColumn get ownerId => integer()();

  /// 属性名（稳定标识，不随界面文案变化）。
  TextColumn get key => text().withLength(min: 1, max: 64)();

  /// 属性值，JSON 编码。
  TextColumn get value => text().map(const JsonValueConverter()).nullable()();

  /// 值类型名（`ExtraValueType`），便于 UI 决定控件与展示。
  TextColumn get valueType => text().withLength(min: 1, max: 16)();

  /// 展示名。留空时 UI 直接用 [key]。
  TextColumn get label => text().nullable()();

  /// 是否是 App 内置属性（内置的不可删除）。
  BoolColumn get isBuiltin => boolean().withDefault(const Constant(false))();

  /// 展示顺序。
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {ownerType, ownerId, key};
}

// ---------------------------------------------------------------------------
// 数据库
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [
    CoffeeBeans,
    BeanBatches,
    Grinders,
    BrewLogs,
    BrewLogBeans,
    BrewLogAddins,
    Recipes,
    AppSettings,
    ExtraAttributes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// 内存数据库，仅用于测试。
  AppDatabase.memory() : super(NativeDatabase.memory());

  /// 打开指定文件的数据库。
  AppDatabase.file(File file) : super(NativeDatabase(file));

  /// v6：`brew_logs.methodLabel`（自定义冲煮方法）+ `brew_log_addins`（辅料）。
  ///
  /// 版本历史（**真实情况**，代码里出现过的版本号）：
  /// - v1：M1 的 5 张表，烘焙日期/烘焙度/余量/购入总重/价格都在 `coffee_beans` 上
  /// - v4：批次 + 多豆 + 扩展属性，烘焙信息与余量下移到批次
  /// - v5：`brew_logs.is_favorite`
  /// - v6：`brew_logs.methodLabel`、`brew_log_addins`
  ///
  /// ⚠️ v2 / v3 从未出现过（`git log -L` 里 schemaVersion 是 1 → 4 → 5 → 6）。
  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
      await _seedDefaultSettings();
    },
    onUpgrade: (m, from, to) async {
      if (from < 4) {
        await _upgradeToV4(m);
      }
      if (from < 5) {
        await _upgradeToV5(m);
      }
      if (from < 6) {
        await _upgradeToV6(m);
      }
      // 索引与默认设置都是幂等的，迁移后统一兜一次：
      // 旧库没有索引（v1 一个都没建），而少了索引会让查批次、拉时间线全表扫描。
      await _createIndexes();
      await _seedDefaultSettings();
    },
    beforeOpen: (details) async {
      // SQLite 默认不启用外键，必须显式开启。
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// v5 → v6：加「自定义方法原文」列，并建辅料表。
  ///
  /// 两句都是**纯新增**：新列可空（旧记录自动为 NULL = 用内置方法），
  /// 新表建出来就是空的，都不需要搬数据。
  Future<void> _upgradeToV6(Migrator m) async {
    await m.addColumn(brewLogs, brewLogs.methodLabel);
    await m.createTable(brewLogAddins);
  }

  /// v4 → v5：给冲煮记录加「收藏」。
  ///
  /// 可空列之外的加列都是安全的（`withDefault` 让老记录自动得到 `false`），
  /// 不需要搬迁数据，所以这里只有一句 `addColumn`。
  Future<void> _upgradeToV5(Migrator m) async {
    await m.addColumn(brewLogs, brewLogs.isFavorite);
  }

  /// v1 → v4 的**逐列迁移**（保住用户已经记下的数据）。
  ///
  /// 顺序不能变，每一步都有原因：
  ///
  /// 1. 先建三张新表（批次 / 豆子用量 / 扩展属性）；
  /// 2. **先**把 `coffee_beans` 上的烘焙日期、烘焙度、余量、购入总重、价格
  ///    原样搬成每支豆子的第一个批次；
  /// 3. **先**用 `brew_logs.bean_id` 回填 `brew_log_beans` 用量行，并把当时的
  ///    豆名与烘焙日期存成快照；记录上的 `bean_roast_*` 快照列也在这时填上；
  /// 4. **最后**才改 `coffee_beans` 的形状：加 `is_favorite`、删掉搬走的 5 列。
  ///
  /// 2、3 必须排在 4 前面——那几列一旦删掉，数据就没有第二个来源了。
  ///
  /// 为什么用 `dropColumn` 而不是 `alterTable` 重建表：重建要 DROP 掉
  /// `coffee_beans`，而它被 `bean_batches` / `brew_log_beans` / `brew_logs`
  /// 用外键引用着，删父表会连带触发级联删除（把刚搬好的批次一起删掉）。
  /// `ALTER TABLE ... DROP COLUMN` 不动表本身，没有这个风险。
  /// 它要求 SQLite ≥ 3.35，本项目通过 `sqlite3_flutter_libs` 自带较新的
  /// SQLite，Android 端不受系统版本限制。
  Future<void> _upgradeToV4(Migrator m) async {
    await m.createTable(beanBatches);
    await m.createTable(brewLogBeans);
    await m.createTable(extraAttributes);

    // 一支豆子一袋：v1 的余量就是这一袋的余量。
    // 批次的 notes 留空——v1 的 notes 是「这款豆子」的备注，留在豆子上。
    await customStatement('''
      INSERT INTO bean_batches
        (bean_id, roast_date, roast_level, remaining_grams, initial_grams,
         price, created_at, updated_at)
      SELECT id, roast_date, roast_level, remaining_grams, initial_grams,
             price, created_at, updated_at
      FROM coffee_beans
    ''');

    // v1 一条记录只挂一支豆子（brew_logs.bean_id），补成一条 position=0 的用量行。
    // 批次取这支豆子最早的那一袋：v1 的豆子此时正好只有一袋，写 MIN(id) 只是
    // 为了万一将来有人手工插过多余批次时不会一行变多行。
    await customStatement('''
      INSERT INTO brew_log_beans
        (brew_log_id, bean_id, batch_id, bean_name_snapshot,
         roast_date_snapshot, dose_grams, position)
      SELECT l.id,
             l.bean_id,
             (SELECT MIN(b.id) FROM bean_batches b WHERE b.bean_id = l.bean_id),
             (SELECT c.name FROM coffee_beans c WHERE c.id = l.bean_id),
             (SELECT c.roast_date FROM coffee_beans c WHERE c.id = l.bean_id),
             COALESCE(l.dose_grams, 0),
             0
      FROM brew_logs l
      WHERE l.bean_id IS NOT NULL
    ''');

    // 记录自己的烘焙快照列（v4 新增）：拿当时豆子上的值填，
    // 之后再改豆子/批次也不会影响历史。
    await m.addColumn(brewLogs, brewLogs.beanRoastDate);
    await m.addColumn(brewLogs, brewLogs.beanRoastLevel);
    await customStatement('''
      UPDATE brew_logs SET
        bean_roast_date = (
          SELECT c.roast_date FROM coffee_beans c WHERE c.id = brew_logs.bean_id
        ),
        bean_roast_level = (
          SELECT c.roast_level FROM coffee_beans c WHERE c.id = brew_logs.bean_id
        )
      WHERE bean_id IS NOT NULL
    ''');

    // 最后改 coffee_beans：加收藏标记（默认未收藏），删掉已经搬去批次的列。
    await m.addColumn(coffeeBeans, coffeeBeans.isFavorite);
    for (final String column in const <String>[
      'roast_level',
      'roast_date',
      'remaining_grams',
      'initial_grams',
      'price',
    ]) {
      await m.dropColumn(coffeeBeans, column);
    }
  }

  /// 建索引。
  ///
  /// Drift 的 `@TableIndex` 会随 `createTable` / `createAll` 一起建，
  /// 这里再显式保证一次（`IF NOT EXISTS`，幂等），
  /// 免得**从 v1 升上来的旧库**漏建索引——v1 一个索引都没有。
  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_bean_batches_bean_id '
      'ON bean_batches (bean_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_brew_log_beans_brew_log_id '
      'ON brew_log_beans (brew_log_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_brew_log_beans_bean_id '
      'ON brew_log_beans (bean_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_brew_logs_brewed_at '
      'ON brew_logs (brewed_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_extra_owner '
      'ON extra_attributes (owner_type, owner_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_brew_log_addins_brew_log_id '
      'ON brew_log_addins (brew_log_id)',
    );
  }

  /// 首次建库时写入手册 §6.3 的默认设置值。
  Future<void> _seedDefaultSettings() async {
    final now = DateTime.now();
    for (final key in SettingsKeys.all) {
      await into(appSettings).insert(
        AppSettingsCompanion.insert(
          key: key,
          value: SettingsDefaults.byKey[key]!,
          updatedAt: Value(now),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  /// 供测试与维护使用：把整库清空。
  Future<void> clearAll() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  }
}

/// 默认数据库文件：`<应用文档目录>/beanclick.sqlite`。
Future<File> defaultDatabaseFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File(p.join(dir.path, 'beanclick.sqlite'));
}

/// 打开应用数据库（本地优先，数据只落在设备上）。
Future<AppDatabase> openAppDatabase() async {
  final file = await defaultDatabaseFile();
  return AppDatabase.file(file);
}
