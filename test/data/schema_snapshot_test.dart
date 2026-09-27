import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/repositories/bean_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../drift/generated/schema.dart';

/// **M2.6（schema v4）及以后的数据，任何版本升级都必须保住。**
///
/// 这件事靠工具锁住，不靠「记得写迁移」：
///
/// - `test/drift/schemas/drift_schema_v4.json` 是 v4 的**冻结快照**
/// - `test/drift/generated/` 是配套校验代码
/// - 生成命令见 `docs/DEVELOPMENT.md` §7.4
///
/// 两组守门用例：
///
/// 1. **改表却忘了重新 dump 快照** → 第一个用例红。
///    它把当前代码的表结构与最新快照逐列比对（类型、NOT NULL、DEFAULT、
///    外键、索引都算），失败信息直接点名哪张表多了哪一列。
/// 2. **改了表却没写迁移（或迁移把数据搬丢了）** → 第二组用例红。
///    它对**每一个 dump 过的历史版本**各跑一遍：用那个版本的结构灌入真实数据，
///    再用当前代码打开（**真的跑 `onUpgrade`**），断言数据一条不少、值没变、
///    迁移后余量扣减照常工作。
///
/// 第 2 组是按 `GeneratedHelper.versions` 循环生成的，所以以后每 dump 一个
/// 新版本，**它会自动多出一条「vN → 当前版本」的保活用例**；新版本需要一份
/// 数据夹具（见 [_fixtures]），没补的话那条用例会红并说明原因——
/// 这是故意的，免得新版本悄悄失去覆盖。
void main() {
  late SchemaVerifier verifier;
  late GeneratedHelper helper;

  setUpAll(() {
    helper = GeneratedHelper();
    verifier = SchemaVerifier(helper);
  });

  /// 当前代码的 schemaVersion。用一次性实例读，不打开任何连接。
  int currentVersion() => AppDatabase(NativeDatabase.memory()).schemaVersion;

  test('当前代码的表结构与最新快照逐列一致（改表必须重新 dump）', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();

    // 对不上会抛出带列级差异的异常，指出哪张表哪一列不一样。
    await verifier.migrateAndValidate(db, currentVersion());
    await db.close();
  });

  for (final int version in GeneratedHelper.versions) {
    test('v$version 写下的数据，升到当前版本后一条不少', () async {
      final _VersionFixture? fixture = _fixtures[version];
      expect(
        fixture,
        isNotNull,
        reason:
            'v$version 是新 dump 的快照，但还没给它准备数据夹具。'
            '请在 _fixtures 里补一份（可以复用上一版的写入函数），'
            '否则这个版本写下的数据就没有保活覆盖了。',
      );

      await verifier.testWithDataIntegrity<GeneratedDatabase, AppDatabase>(
        oldVersion: version,
        newVersion: currentVersion(),
        createOld: (QueryExecutor executor) =>
            helper.databaseForVersion(executor, version),
        createNew: AppDatabase.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (Batch batch, GeneratedDatabase old) =>
            fixture!.insert(batch, old),
        validateItems: (AppDatabase db) => fixture!.validate(db),
      );
    });
  }
}

/// 某个版本的「数据夹具」：怎么把数据写进那个版本的库，以及升上来后怎么校验。
class _VersionFixture {
  const _VersionFixture({required this.insert, required this.validate});

  final void Function(Batch batch, GeneratedDatabase db) insert;
  final Future<void> Function(AppDatabase db) validate;
}

/// 历史版本 → 数据夹具。新增版本时在这里加一条（键就是 schemaVersion）。
final Map<int, _VersionFixture> _fixtures = <int, _VersionFixture>{
  4: const _VersionFixture(
    insert: _insertV4Fixture,
    validate: _validateV4Fixture,
  ),
  5: const _VersionFixture(
    insert: _insertV5Fixture,
    validate: _validateV5Fixture,
  ),
};

/// v5 的写入 = v4 那份数据 + 把那条记录标成收藏。
///
/// 每次升版本都照这个办法复用上一版的写入函数，只补这次新增的字段，
/// 免得每版都把整套 INSERT 抄一遍（抄错了就是假绿）。
void _insertV5Fixture(Batch batch, GeneratedDatabase db) {
  _insertV4Fixture(batch, db);
  // v5 新增：收藏这套参数。
  batch.customStatement('UPDATE brew_logs SET is_favorite = 1 WHERE id = 1');
}

/// 往 **v4 结构的库**里塞一份有代表性的数据。
///
/// 用原生 SQL 而不是 Companion：表来自 dump 出来的快照（`v4.DatabaseAtV4`），
/// 它只有表没有 Companion，写原生 SQL 反而更直白，也让「列名对不上」立刻暴露。
void _insertV4Fixture(Batch batch, GeneratedDatabase db) {
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
    'INSERT INTO grinders (id, brand, model, scale_unit, zero_point, '
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
    'value_type, label, is_builtin, sort_order, created_at, updated_at) VALUES '
    "('bean', 1, 'purchaseChannel', '\"淘宝\"', 'text', '购买渠道', 0, 1, $t, $t)",
  );

  // 用户改过的设置项：迁移不能把它盖回默认值。
  batch.customStatement(
    'INSERT INTO app_settings (key, value, updated_at) VALUES '
    "('themeMode', 'dark', $t)",
  );
  batch.customStatement(
    'INSERT INTO app_settings (key, value, updated_at) VALUES '
    "('autoDeductStock', 'false', $t)",
  );
}

/// v4 升上来后：那条记录还没有收藏概念，默认必须是「未收藏」。
Future<void> _validateV4Fixture(AppDatabase db) =>
    _validateFixture(db, expectFavorite: false);

/// v5 升上来后：收藏标记要原样保留。
Future<void> _validateV5Fixture(AppDatabase db) =>
    _validateFixture(db, expectFavorite: true);

/// 升到当前版本后逐项校验上面的数据。
Future<void> _validateFixture(
  AppDatabase db, {
  required bool expectFavorite,
}) async {
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
  // v5 加的收藏标记：v4 的库升上来默认 false，v5 的库要保住写进去的 true。
  expect(logs.single.isFavorite, expectFavorite);

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
}
