import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/repositories/bean_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../drift/generated/schema.dart';
import '../drift/generated/schema_v4.dart' as v4;

/// **M2.6（schema v4）及以后的数据，任何升级都必须保住。**
///
/// 这里用 Drift 官方的 schema 快照 + 校验工具把这件事锁住，
/// 而不是靠「记得写迁移」这种口头约定：
///
/// - `test/drift/schemas/drift_schema_v4.json` 是 v4 的**冻结快照**
///   （`dart run drift_dev schema dump lib/data/database.dart test/drift/schemas` 生成）
/// - `test/drift/generated/` 是配套的校验代码
///   （`dart run drift_dev schema generate test/drift/schemas test/drift/generated`）
///
/// 于是：
///
/// 1. **改表结构却忘了 dump 新快照 → 第一个用例直接失败**（当前代码的表结构
///    必须与快照逐列一致，包括类型、NOT NULL、默认值、外键与索引）。
/// 2. **改了表却没写迁移 → 第二个用例失败**：它拿 v4 快照灌入真实数据，
///    用当前代码打开（会真实跑 `onUpgrade`），再断言数据一条不少、值没变。
///    以后每次升 schemaVersion，这个用例自动变成「v4 → 新版本」的数据保活测试，
///    不需要改代码（`oldVersion` 永远钉在 4）。
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  /// 当前代码的 schemaVersion。用一次性实例读，不打开任何连接。
  int currentVersion() => AppDatabase(NativeDatabase.memory()).schemaVersion;

  test('当前代码的表结构与 v4 快照逐列一致（改表必须重新 dump）', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();

    // 对不上会抛出带列级差异的异常，指出哪张表哪一列不一样。
    await verifier.migrateAndValidate(db, currentVersion());
    await db.close();
  });

  test('v4（M2.6）的库升到当前版本后，数据一条不少', () async {
    await verifier.testWithDataIntegrity<v4.DatabaseAtV4, AppDatabase>(
      oldVersion: 4,
      newVersion: currentVersion(),
      createOld: v4.DatabaseAtV4.new,
      createNew: AppDatabase.new,
      openTestedDatabase: AppDatabase.new,
      createItems: _insertV4Fixture,
      validateItems: (AppDatabase db) async {
        // --- 豆子与批次 ---
        final List<CoffeeBeanRow> beans = await (db.select(
          db.coffeeBeans,
        )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
        expect(beans, hasLength(2));
        expect(beans[0].name, '花魁');
        expect(beans[0].origin, '埃塞俄比亚');
        expect(beans[0].flavorTags, <String>['柑橘', '花香']);
        expect(beans[0].isFavorite, isTrue);

        final BeanRepository repository = BeanRepository(db);
        final BeanWithBatches? withBatches = await repository.getWithBatches(
          beans[0].id,
        );
        expect(withBatches, isNotNull);
        // 复购的两袋都在，总余量是两袋之和。
        expect(withBatches!.batches, hasLength(2));
        expect(withBatches.totalRemaining, 128.5 + 200);

        // --- 拼配记录：两支豆子的用量行都在，快照名也在 ---
        final List<BrewLogRow> logs = await db.select(db.brewLogs).get();
        expect(logs, hasLength(1));
        expect(logs.single.doseGrams, 20);
        expect(logs.single.rating, 5);

        final List<BeanUsageRow> usages = await (db.select(
          db.brewLogBeans,
        )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
        expect(usages, hasLength(2));
        expect(usages[0].beanNameSnapshot, '花魁');
        expect(usages[0].doseGrams, 14);
        expect(usages[1].beanNameSnapshot, '曼特宁');
        expect(usages[1].doseGrams, 6);

        // --- 扩展属性 ---
        final List<ExtraAttributeRow> extras = await db
            .select(db.extraAttributes)
            .get();
        expect(extras, hasLength(1));
        expect(extras.single.key, 'purchaseChannel');
        expect(extras.single.value, '淘宝');
        expect(extras.single.isBuiltin, isFalse);

        // --- 设置项：用户改过的值不能被默认值盖掉 ---
        final Map<String, String> settings = <String, String>{
          for (final AppSettingRow row in await db.select(db.appSettings).get())
            row.key: row.value,
        };
        expect(settings['themeMode'], 'dark');
        expect(settings['autoDeductStock'], 'false');

        // --- 迁移之后余量扣减仍然工作（拿搬过来的那一袋扣） ---
        final AdjustStockResult result = await repository.adjustStock(
          beans[1].id,
          10,
        );
        expect(result.applied, 10);
        expect(result.before, 150);
        expect(result.after, 140);
      },
    );
  });
}

/// 往 **v4 结构的库**里塞一份有代表性的数据。
///
/// 用原生 SQL 而不是 Companion：这里的表来自 dump 出来的 v4 快照
/// （`v4.DatabaseAtV4`），它只有表没有 Companion，写原生 SQL 反而更直白，
/// 也让「列名对不上」这种错立刻暴露。
void _insertV4Fixture(Batch batch, v4.DatabaseAtV4 db) {
  const int t = 1767319445; // Unix 秒（Drift 的 dateTime 存储格式）

  // 花魁：两袋（复购），第一袋只剩 128.5g，第二袋满袋。
  batch.customStatement(
    'INSERT INTO coffee_beans (id, name, origin, farm, process, flavor_tags, '
    'is_favorite, notes, created_at, updated_at) VALUES '
    "(1, '花魁', '埃塞俄比亚', 'Buku Abel', 'washed', '[\"柑橘\",\"花香\"]', "
    "1, '手冲为主', $t, $t)",
  );
  batch.customStatement(
    'INSERT INTO coffee_beans (id, name, origin, flavor_tags, is_favorite, '
    'created_at, updated_at) VALUES '
    "(2, '曼特宁', '印尼', '[]', 0, $t, $t)",
  );
  batch.customStatement(
    'INSERT INTO bean_batches (id, bean_id, roast_date, roast_level, '
    'remaining_grams, initial_grams, price, created_at, updated_at) VALUES '
    "(11, 1, $t, 'light', 128.5, 200, 88.55, $t, $t)",
  );
  batch.customStatement(
    'INSERT INTO bean_batches (id, bean_id, roast_level, remaining_grams, '
    'initial_grams, price, created_at, updated_at) VALUES '
    "(12, 1, 'light', 200, 200, 92, $t, $t)",
  );
  batch.customStatement(
    'INSERT INTO bean_batches (id, bean_id, remaining_grams, initial_grams, '
    'created_at, updated_at) VALUES (13, 2, 150, 250, $t, $t)',
  );

  batch.customStatement(
    "INSERT INTO grinders (id, brand, model, scale_unit, zero_point, "
    "created_at, updated_at) VALUES (1, 'Comandante', 'C40', 'click', 0, $t, $t)",
  );

  // 一条拼配记录（14g + 6g），豆名与烘焙快照都写进去。
  batch.customStatement(
    'INSERT INTO brew_logs (id, bean_id, grinder_id, method, dose_grams, '
    'water_grams, water_temp, rating, notes, is_best, brewed_at, '
    'bean_roast_date, bean_roast_level, created_at, updated_at) VALUES '
    "(1, 1, 1, 'pourOver', 20, 300, 92, 5, '拼配第一杯', 1, $t, $t, 'light', "
    '$t, $t)',
  );
  batch.customStatement(
    'INSERT INTO brew_log_beans (id, brew_log_id, bean_id, batch_id, '
    'bean_name_snapshot, roast_date_snapshot, dose_grams, position) VALUES '
    "(1, 1, 1, 11, '花魁', $t, 14, 0)",
  );
  batch.customStatement(
    'INSERT INTO brew_log_beans (id, brew_log_id, bean_id, batch_id, '
    'bean_name_snapshot, roast_date_snapshot, dose_grams, position) VALUES '
    "(2, 1, 2, 13, '曼特宁', NULL, 6, 1)",
  );

  batch.customStatement(
    'INSERT INTO extra_attributes (owner_type, owner_id, key, value, '
    "value_type, label, is_builtin, sort_order, created_at, updated_at) VALUES "
    "('bean', 1, 'purchaseChannel', '\"淘宝\"', 'text', '购买渠道', 0, 1, $t, $t)",
  );

  // 用户改过的设置项：迁移不能把它盖回默认值。
  batch.customStatement(
    "INSERT INTO app_settings (key, value, updated_at) VALUES "
    "('themeMode', 'dark', $t)",
  );
  batch.customStatement(
    "INSERT INTO app_settings (key, value, updated_at) VALUES "
    "('autoDeductStock', 'false', $t)",
  );
}
