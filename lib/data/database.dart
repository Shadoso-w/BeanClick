/// Drift 数据库定义。
///
/// 表结构对应 `docs/M1-DATA-MODEL.md`，改表时必须同步更新该文档，
/// 并递增 `AppDatabase.schemaVersion` + 补迁移。
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

// ---------------------------------------------------------------------------
// 表定义
// ---------------------------------------------------------------------------

/// 咖啡豆（设计稿 §1）。
@DataClassName('CoffeeBeanRow')
class CoffeeBeans extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  TextColumn get origin => text().nullable()();

  TextColumn get farm => text().nullable()();

  /// 处理法，存枚举 name。
  TextColumn get process => textEnum<ProcessMethod>().nullable()();

  /// 烘焙度，存枚举 name。
  TextColumn get roastLevel => textEnum<RoastLevel>().nullable()();

  DateTimeColumn get roastDate => dateTime().nullable()();

  /// 风味标签，JSON 数组。
  TextColumn get flavorTags =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();

  /// 余量（g），下限 0，由 Repository 保证。
  RealColumn get remainingGrams => real().withDefault(const Constant(0.0))();

  /// 购入总重（g），用于算消耗比例。
  RealColumn get initialGrams => real().nullable()();

  RealColumn get price => real().nullable()();

  TextColumn get photoPath => text().nullable()();

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

  TextColumn get scaleUnit =>
      textEnum<GrindScaleUnit>().withDefault(const Constant('click'))();

  RealColumn get zeroPoint => real().nullable().withDefault(const Constant(0.0))();

  IntColumn get clicksPerRevolution => integer().nullable()();

  TextColumn get calibrationNote => text().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 冲煮记录（设计稿 §3）。
@DataClassName('BrewLogRow')
class BrewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  // --- 外键：豆子/磨豆机/配方被删除时置空，保留历史记录 ---
  IntColumn get beanId => integer()
      .nullable()
      .references(CoffeeBeans, #id, onDelete: KeyAction.setNull)();

  IntColumn get grinderId => integer()
      .nullable()
      .references(Grinders, #id, onDelete: KeyAction.setNull)();

  IntColumn get recipeId => integer()
      .nullable()
      .references(Recipes, #id, onDelete: KeyAction.setNull)();

  TextColumn get method =>
      textEnum<BrewMethod>().withDefault(const Constant('pourOver'))();

  // --- 核心参数 ---
  RealColumn get grindSetting => real().nullable()();

  IntColumn get grindClicks => integer().nullable()();

  RealColumn get doseGrams => real().nullable()();

  RealColumn get waterGrams => real().nullable()();

  /// 粉水比中「1 : N」的 N。
  RealColumn get ratio => real().nullable()();

  RealColumn get waterTemp => real().nullable()();

  IntColumn get totalTimeSeconds => integer().nullable()();

  TextColumn get dripper => text().nullable()();

  /// 评分 1–5。
  IntColumn get rating => integer().nullable()();

  TextColumn get flavorTags =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();

  TextColumn get notes => text().nullable()();

  TextColumn get photoPath => text().nullable()();

  DateTimeColumn get brewedAt => dateTime().withDefault(currentDateAndTime)();

  /// 「标记最佳参数」。
  BoolColumn get isBest => boolean().withDefault(const Constant(false))();

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

  // --- 摩卡壶专属 ---
  TextColumn get heatLevel => text().nullable()();

  RealColumn get yieldGrams => real().nullable()();

  BoolColumn get preheatUpperChamber => boolean().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 配方（设计稿 §4）。
@DataClassName('RecipeRow')
class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  TextColumn get method =>
      textEnum<BrewMethod>().withDefault(const Constant('pourOver'))();

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

// ---------------------------------------------------------------------------
// 数据库
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [CoffeeBeans, Grinders, BrewLogs, Recipes, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// 内存数据库，仅用于测试。
  AppDatabase.memory() : super(NativeDatabase.memory());

  /// 打开指定文件的数据库。
  AppDatabase.file(File file) : super(NativeDatabase(file));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultSettings();
        },
        onUpgrade: (m, from, to) async {
          // v1 是首个版本，暂无迁移。
          // 将来改表时在这里按 from→to 逐个补 Migration，并递增 schemaVersion。
        },
        beforeOpen: (details) async {
          // SQLite 默认不启用外键，必须显式开启。
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

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
