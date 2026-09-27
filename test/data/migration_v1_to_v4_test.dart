import 'dart:io';

import 'package:beanclick/data/database.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/domain/settings_keys.dart';
// drift 也导出 isNull / isNotNull（SQL 表达式），会和 matcher 的同名匹配器冲突。
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// v1 → v4 的逐列迁移。
///
/// 这里造的旧库用的是**从 v1 代码里 dump 出来的原样建库语句**
/// （在 `e1f6946` 的工作树上跑 `sqlite_master` 拿到的），
/// 不是手抄的近似结构——手抄很容易漏掉 NOT NULL / DEFAULT，
/// 那样测出来的「迁移通过」是假的。
///
/// 每条断言都对应一个「用户会丢数据」的具体风险点。
void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('beanclick_migrate_test');
    file = File(p.join(dir.path, 'beanclick.sqlite'));
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  /// 把一份 v1 的库写到 [file]。
  ///
  /// 做法：先用当前代码建库（跑一次 onCreate），再把它**改造成 v1 的样子**
  /// ——删掉所有表、按 v1 的语句重建、`user_version` 设回 1。
  /// 这样不需要额外依赖 `package:sqlite3` 就能造出真实的旧库。
  Future<void> createV1Database() async {
    final AppDatabase db = AppDatabase.file(file);
    // 外键先关掉，否则删父表会连带删子表（这里反正是全删，但顺序会报错）。
    await db.customStatement('PRAGMA foreign_keys = OFF');
    for (final TableInfo table in db.allTables) {
      await db.customStatement(
        'DROP TABLE IF EXISTS "${table.actualTableName}"',
      );
    }
    for (final String ddl in _v1Schema) {
      await db.customStatement(ddl);
    }
    for (final String insert in _v1Rows) {
      await db.customStatement(insert);
    }
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();
  }

  /// 打开当前代码的库（触发 onUpgrade）。
  Future<AppDatabase> openUpgraded() async {
    final AppDatabase db = AppDatabase.file(file);
    // 首次查询才会真正打开并跑迁移。
    await db.customSelect('SELECT 1').get();
    return db;
  }

  test('迁移后 v1 的豆子身份信息还在，烘焙/余量搬成了第一个批次', () async {
    await createV1Database();
    final AppDatabase db = await openUpgraded();
    addTearDown(db.close);

    final List<CoffeeBeanRow> beans = await (db.select(
      db.coffeeBeans,
    )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
    expect(beans, hasLength(2));
    expect(beans[0].name, '花魁');
    expect(beans[0].origin, '埃塞俄比亚');
    expect(beans[0].farm, 'Buku Abel');
    expect(beans[0].flavorTags, <String>['柑橘', '花香']);
    expect(beans[0].notes, '手冲为主');
    expect(beans[0].isFavorite, isFalse, reason: 'v1 没有收藏，迁移后默认未收藏');
    expect(beans[1].name, '曼特宁');

    final List<BeanBatchRow> batches = await (db.select(
      db.beanBatches,
    )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
    expect(batches, hasLength(2), reason: '一支豆子一袋，不能多也不能少');
    expect(batches[0].beanId, beans[0].id);
    expect(batches[0].remainingGrams, 128.5);
    expect(batches[0].initialGrams, 200);
    expect(batches[0].price, 88.55);
    expect(batches[0].roastDate, isNotNull);
    expect(
      batches[0].roastDate!.millisecondsSinceEpoch ~/ 1000,
      1767319445,
      reason: 'Drift 的 dateTime 存 Unix 秒，迁移要原样保留',
    );
    expect(batches[0].roastLevel, RoastLevel.light);
    expect(batches[1].beanId, beans[1].id);
    expect(batches[1].remainingGrams, 0);
    expect(batches[1].initialGrams, isNull);
    expect(batches[1].roastDate, isNull);
  });

  test('迁移后冲煮记录还在，并补出了用量行与烘焙快照', () async {
    await createV1Database();
    final AppDatabase db = await openUpgraded();
    addTearDown(db.close);

    final List<BrewLogRow> logs = await (db.select(
      db.brewLogs,
    )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
    expect(logs, hasLength(3), reason: '记录一条都不能丢');
    expect(logs[0].doseGrams, 15);
    expect(logs[0].waterGrams, 240);
    expect(logs[0].waterTemp, 92);
    expect(logs[0].rating, 5);
    expect(logs[0].notes, '第一杯');
    expect(logs[0].flavorTags, <String>['柑橘']);
    expect(logs[0].isBest, isTrue);
    expect(logs[0].beanRoastLevel, RoastLevel.light, reason: '烘焙度快照要补上');

    final List<BeanUsageRow> usages = await (db.select(
      db.brewLogBeans,
    )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
    // 两条挂了豆子的记录各补一条用量行；第三条 v1 里就没选豆子，不该凭空造。
    expect(usages, hasLength(2));
    expect(usages[0].brewLogId, logs[0].id);
    expect(usages[0].beanId, 1);
    expect(usages[0].beanNameSnapshot, '花魁', reason: '豆名快照让历史记录永远可读');
    expect(usages[0].doseGrams, 15);
    expect(usages[0].position, 0);
    expect(usages[0].batchId, isNotNull, reason: '要指到迁移出来的那个批次');
    expect(usages[1].brewLogId, logs[1].id);
    expect(usages[1].beanId, 2);
    expect(usages[1].doseGrams, 18);
    // 第三条：v1 里 bean_id 为空，用量行数为 0。
    final List<BeanUsageRow> third = await (db.select(
      db.brewLogBeans,
    )..where((t) => t.brewLogId.equals(logs[2].id))).get();
    expect(third, isEmpty);
  });

  test('迁移不会覆盖用户已经改过的设置项', () async {
    await createV1Database();
    final AppDatabase db = await openUpgraded();
    addTearDown(db.close);

    final List<AppSettingRow> rows = await db.select(db.appSettings).get();
    final Map<String, String> byKey = <String, String>{
      for (final AppSettingRow row in rows) row.key: row.value,
    };
    // key 用 SettingsKeys 里的真名（camelCase）。写成 snake_case 会
    // 「插进去一条没人读的行、断言又恰好通过」，等于什么都没测。
    expect(byKey[SettingsKeys.themeMode], 'dark', reason: '用户选过深色主题，不能被默认值盖掉');
    expect(byKey[SettingsKeys.autoDeductStock], 'false');
    // v1 库里缺的键要补上默认值。
    expect(byKey[SettingsKeys.unitWeight], SettingsDefaults.unitWeight);
    // 7 个键一个不少。
    expect(byKey.keys.toSet(), SettingsKeys.all.toSet());
  });

  test('迁移后的表结构与全新建库完全一致（含索引）', () async {
    await createV1Database();
    final AppDatabase upgraded = await openUpgraded();

    final File freshFile = File(p.join(dir.path, 'fresh.sqlite'));
    final AppDatabase fresh = AppDatabase.file(freshFile);
    await fresh.customSelect('SELECT 1').get();

    final List<String> upgradedShape = await _shapeOf(upgraded);
    final List<String> freshShape = await _shapeOf(fresh);

    expect(upgradedShape, freshShape);
    // 扩展属性表建出来了，且是空的（v1 没有这个概念）。
    expect(await upgraded.select(upgraded.extraAttributes).get(), isEmpty);

    await upgraded.close();
    await fresh.close();
  });

  test('迁移只跑一次：再打开一次不会重复搬批次', () async {
    await createV1Database();

    final AppDatabase first = await openUpgraded();
    final int version = (await first.customSelect('PRAGMA user_version').get())
        .first
        .read<int>('user_version');
    expect(version, 6, reason: '一次升到当前版本，不会停在中间某个版本');
    await first.close();

    final AppDatabase second = await openUpgraded();
    addTearDown(second.close);
    expect(await second.select(second.beanBatches).get(), hasLength(2));
    expect(await second.select(second.brewLogBeans).get(), hasLength(2));
  });
}

/// 取一张库的「形状」：每张表的列定义、索引、外键，排序后拼成字符串。
///
/// 用来断言「从 v1 升上来的库」和「全新建的库」结构一致——
/// 只对齐列名不够，`NOT NULL` / `DEFAULT` / 索引漏建都要能测出来。
Future<List<String>> _shapeOf(AppDatabase db) async {
  final List<String> out = <String>[];

  final List<QueryRow> tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  for (final QueryRow table in tables) {
    final String name = table.read<String>('name');
    final List<QueryRow> columns = await db
        .customSelect('PRAGMA table_info("$name")')
        .get();
    for (final QueryRow column in columns) {
      out.add(
        'column $name.${column.read<String>('name')} '
        '${column.read<String>('type')} '
        'notnull=${column.read<int>('notnull')} '
        'default=${column.data['dflt_value']} '
        'pk=${column.read<int>('pk')}',
      );
    }
    final List<QueryRow> foreignKeys = await db
        .customSelect('PRAGMA foreign_key_list("$name")')
        .get();
    for (final QueryRow fk in foreignKeys) {
      out.add(
        'fk $name.${fk.read<String>('from')} -> '
        '${fk.read<String>('table')}.${fk.read<String>('to')} '
        'on_delete=${fk.read<String>('on_delete')}',
      );
    }
  }

  final List<QueryRow> indexes = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  for (final QueryRow index in indexes) {
    out.add('index ${index.read<String>('name')}');
  }

  out.sort();
  return out;
}

/// v1（`e1f6946`）的真实建库语句，从 `sqlite_master` dump 出来的。
const List<String> _v1Schema = <String>[
  'CREATE TABLE "app_settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, '
      '"updated_at" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', '
      'CURRENT_TIMESTAMP) AS INTEGER)), PRIMARY KEY ("key"))',
  'CREATE TABLE "brew_logs" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"bean_id" INTEGER NULL REFERENCES coffee_beans (id) ON DELETE SET NULL, '
      '"grinder_id" INTEGER NULL REFERENCES grinders (id) ON DELETE SET NULL, '
      '"recipe_id" INTEGER NULL REFERENCES recipes (id) ON DELETE SET NULL, '
      '"method" TEXT NOT NULL DEFAULT \'pourOver\', "grind_setting" REAL NULL, '
      '"grind_clicks" INTEGER NULL, "dose_grams" REAL NULL, '
      '"water_grams" REAL NULL, "ratio" REAL NULL, "water_temp" REAL NULL, '
      '"total_time_seconds" INTEGER NULL, "dripper" TEXT NULL, '
      '"rating" INTEGER NULL, "flavor_tags" TEXT NOT NULL DEFAULT \'[]\', '
      '"notes" TEXT NULL, "photo_path" TEXT NULL, '
      '"brewed_at" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', '
      'CURRENT_TIMESTAMP) AS INTEGER)), "is_best" INTEGER NOT NULL DEFAULT 0 '
      'CHECK ("is_best" IN (0, 1)), "tds" REAL NULL, '
      '"extraction_yield" REAL NULL, "water_ppm" INTEGER NULL, '
      '"ambient_temp" REAL NULL, "ambient_humidity" REAL NULL, '
      '"bean_temp" REAL NULL, "pressure" REAL NULL, "pour_stages" TEXT NULL, '
      '"heat_level" TEXT NULL, "yield_grams" REAL NULL, '
      '"preheat_upper_chamber" INTEGER NULL CHECK '
      '("preheat_upper_chamber" IN (0, 1)), "created_at" INTEGER NOT NULL '
      'DEFAULT (CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)), '
      '"updated_at" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', '
      'CURRENT_TIMESTAMP) AS INTEGER)))',
  'CREATE TABLE "coffee_beans" ("id" INTEGER NOT NULL PRIMARY KEY '
      'AUTOINCREMENT, "name" TEXT NOT NULL, "origin" TEXT NULL, '
      '"farm" TEXT NULL, "process" TEXT NULL, "roast_level" TEXT NULL, '
      '"roast_date" INTEGER NULL, "flavor_tags" TEXT NOT NULL DEFAULT \'[]\', '
      '"remaining_grams" REAL NOT NULL DEFAULT 0.0, "initial_grams" REAL NULL, '
      '"price" REAL NULL, "photo_path" TEXT NULL, "notes" TEXT NULL, '
      '"created_at" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', '
      'CURRENT_TIMESTAMP) AS INTEGER)), "updated_at" INTEGER NOT NULL '
      'DEFAULT (CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)))',
  'CREATE TABLE "grinders" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"brand" TEXT NOT NULL, "model" TEXT NOT NULL, "burr_type" TEXT NULL, '
      '"scale_unit" TEXT NOT NULL DEFAULT \'click\', "zero_point" REAL NULL '
      'DEFAULT 0.0, "clicks_per_revolution" INTEGER NULL, '
      '"calibration_note" TEXT NULL, "notes" TEXT NULL, '
      '"created_at" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', '
      'CURRENT_TIMESTAMP) AS INTEGER)), "updated_at" INTEGER NOT NULL '
      'DEFAULT (CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)))',
  'CREATE TABLE "recipes" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
      '"name" TEXT NOT NULL, "method" TEXT NOT NULL DEFAULT \'pourOver\', '
      '"dose_grams" REAL NULL, "water_grams" REAL NULL, "ratio" REAL NULL, '
      '"water_temp" REAL NULL, "total_time_seconds" INTEGER NULL, '
      '"pour_stages" TEXT NULL, "grind_suggestion" TEXT NULL, '
      '"notes" TEXT NULL, "created_at" INTEGER NOT NULL DEFAULT '
      '(CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)), '
      '"updated_at" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', '
      'CURRENT_TIMESTAMP) AS INTEGER)))',
];

/// v1 里塞进去的样例数据。时间列是 Unix 秒（Drift 的 dateTime 存储格式）。
final List<String> _v1Rows = <String>[
  "INSERT INTO coffee_beans (id, name, origin, farm, process, roast_level, "
      "roast_date, flavor_tags, remaining_grams, initial_grams, price, notes, "
      "created_at, updated_at) VALUES "
      "(1, '花魁', '埃塞俄比亚', 'Buku Abel', 'washed', 'light', "
      "1767319445, '[\"柑橘\",\"花香\"]', 128.5, 200, 88.55, '手冲为主', "
      "1767319445, 1767319445)",
  "INSERT INTO coffee_beans (id, name, origin, flavor_tags, remaining_grams, "
      "created_at, updated_at) VALUES "
      "(2, '曼特宁', '印尼', '[]', 0, 1767319445, 1767319445)",
  "INSERT INTO grinders (id, brand, model, scale_unit, zero_point, created_at, "
      "updated_at) VALUES (1, 'Comandante', 'C40', 'click', 0, "
      "1767319445, 1767319445)",
  "INSERT INTO recipes (id, name, method, dose_grams, water_grams, created_at, "
      "updated_at) VALUES (1, 'V60 日常', 'pourOver', 15, 240, "
      "1767319445, 1767319445)",
  // 手冲一杯：有豆子、有粉量、有备注与评分。
  "INSERT INTO brew_logs (id, bean_id, grinder_id, recipe_id, method, "
      "dose_grams, water_grams, water_temp, ratio, rating, flavor_tags, notes, "
      "is_best, brewed_at, created_at, updated_at) VALUES "
      "(1, 1, 1, 1, 'pourOver', 15, 240, 92, 16, 5, '[\"柑橘\"]', '第一杯', 1, "
      "1767319445, 1767319445, 1767319445)",
  // 第二杯：另一支豆子，验证多条记录各自的用量行都对。
  "INSERT INTO brew_logs (id, bean_id, method, dose_grams, water_grams, "
      "brewed_at, created_at, updated_at) VALUES "
      "(2, 2, 'pourOver', 18, 288, 1767319445, 1767319445, 1767319445)",
  // 第三杯：v1 里就没选豆子（外键为空），迁移后也不该有用量行。
  "INSERT INTO brew_logs (id, bean_id, method, dose_grams, brewed_at, "
      "created_at, updated_at) VALUES "
      "(3, NULL, 'mokaPot', 16, 1767319445, 1767319445, 1767319445)",
  // 用户改过的设置项：迁移不能把它盖回默认值。
  // 键名必须用 SettingsKeys 里的真名（camelCase），写错了这条测试就是假绿。
  "INSERT INTO app_settings (key, value, updated_at) VALUES "
      "('themeMode', 'dark', 1767319445)",
  "INSERT INTO app_settings (key, value, updated_at) VALUES "
      "('autoDeductStock', 'false', 1767319445)",
];
