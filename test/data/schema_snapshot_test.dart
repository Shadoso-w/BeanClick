import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/repositories/bean_repository.dart';
import 'package:beanclick/domain/enums.dart';
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
  6: const _VersionFixture(
    insert: _insertV6Fixture,
    validate: _validateV6Fixture,
  ),
  7: const _VersionFixture(
    insert: _insertV7Fixture,
    validate: _validateV7Fixture,
  ),
  8: const _VersionFixture(
    insert: _insertV8Fixture,
    validate: _validateV8Fixture,
  ),
};

/// v8 = v7 那份数据 + 一个收藏夹 + 一条「记录进夹」关联行 + 给辅料补上牌子。
///
/// **为什么新表也塞数据**：只建表不写行的话，「升级后数据仍在」这条用例对
/// 两张新表毫无判别力（空表查出来是空，忘了 `createTable` 也是查不出来）。
/// 塞一行进去，`_validateFixture` 里的 `hasLength(1)` + 字段断言才真的在证明
/// 「v8 写下的东西 v8 读得回来」。
void _insertV8Fixture(Batch batch, GeneratedDatabase db) {
  _insertV7Fixture(batch, db);
  const int t = 1767319445; // 与 v4 夹具同一个时间戳（Unix 秒）
  // v8 新增：收藏夹组。
  batch.customStatement(
    'INSERT INTO favorite_groups (id, name, sort_order, created_at) '
    "VALUES (1, '早餐配方', 0, $t)",
  );
  // v8 新增：记录 1 进组 1（双外键都指向已存在的行）。
  batch.customStatement(
    'INSERT INTO brew_log_favorite_groups '
    '(id, brew_log_id, group_id, created_at) VALUES (1, 1, 1, $t)',
  );
  // v8 新增：辅料牌子（v7 及更早的行是 NULL）。
  batch.customStatement(
    "UPDATE brew_log_addins SET brand = 'Oatly' WHERE id = 1",
  );
}

/// v7 = v6 那份数据 + 处理法多选 + 磨豆机微米 + 记录上的磨豆机零点快照。
void _insertV7Fixture(Batch batch, GeneratedDatabase db) {
  _insertV6Fixture(batch, db);
  // v7：处理法可以多选（v6 及更早只存一条裸名字，迁移时会包成数组）。
  batch.customStatement(
    "UPDATE coffee_beans SET process = '[\"washed\",\"anaerobic\"]' WHERE id = 1",
  );
  // v7：磨豆机每 click 位移。
  batch.customStatement(
    'UPDATE grinders SET microns_per_click = 30 WHERE id = 1',
  );
  // v7：记录上的磨豆机零点快照。
  batch.customStatement(
    'UPDATE brew_logs SET grinder_zero_point_snapshot = 0, '
    'grinder_clicks_per_revolution_snapshot = 30 WHERE id = 1',
  );
}

/// v6 的写入 = v5 那份数据 + 自定义方法 + 两条辅料。
///
/// 每次升版本都照这个办法复用上一版的写入函数，只补这次新增的东西，
/// 免得每版都把整套 INSERT 抄一遍（抄错了就是假绿）。
void _insertV6Fixture(Batch batch, GeneratedDatabase db) {
  _insertV5Fixture(batch, db);
  // v6 新增：自定义方法原文（内置方法仍走 method 列）。
  batch.customStatement(
    "UPDATE brew_logs SET method_label = '拿铁' WHERE id = 1",
  );
  // v6 新增：辅料两行（一行有量、一行只有名字）。
  batch.customStatement(
    'INSERT INTO brew_log_addins (id, brew_log_id, name, amount, unit, '
    "position) VALUES (1, 1, '牛奶', 150, 'ml', 0)",
  );
  batch.customStatement(
    'INSERT INTO brew_log_addins (id, brew_log_id, name, amount, unit, '
    "position) VALUES (2, 1, '榛果糖浆', 1, 'pump', 1)",
  );
}

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

/// v6 升上来后：收藏 + 自定义方法 + 辅料都要在。
Future<void> _validateV6Fixture(AppDatabase db) =>
    _validateFixture(db, expectFavorite: true, expectAddIns: true);

/// v7 升上来后：再多校验处理法多选与磨豆机微米/零点快照。
Future<void> _validateV7Fixture(AppDatabase db) =>
    _validateFixture(db, expectFavorite: true, expectAddIns: true);

/// v8 升上来后：v7 的全部内容 + 收藏夹 / 关联行 / 辅料牌子都要在。
///
/// （v8 就是当前版本，这条覆盖的是「v8 写下、v8 读回」的一致性；
/// 「老库升到 v8 后两张新表存在」由 v4–v7 那四条各自保证。）
Future<void> _validateV8Fixture(AppDatabase db) => _validateFixture(
  db,
  expectFavorite: true,
  expectAddIns: true,
  expectFavoriteGroups: true,
  expectAddInBrand: 'Oatly',
);

/// 升到当前版本后逐项校验上面的数据。
Future<void> _validateFixture(
  AppDatabase db, {
  required bool expectFavorite,
  bool expectAddIns = false,
  bool expectFavoriteGroups = false,
  String? expectAddInBrand,
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
  // v6 加的自定义方法：v5 及更早升上来时为空（用内置方法）。
  expect(logs.single.methodLabel, expectAddIns ? '拿铁' : isNull);

  // v6 加的辅料行。
  final List<BrewLogAddInRow> addInRows = await (db.select(
    db.brewLogAddins,
  )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
  if (expectAddIns) {
    expect(addInRows, hasLength(2));
    expect(addInRows[0].name, '牛奶');
    expect(addInRows[0].amount, 150);
    expect(addInRows[0].unit, AddInUnit.ml);
    expect(addInRows[1].name, '榛果糖浆');
    expect(addInRows[1].unit, AddInUnit.pump);
    // v8 加的「牌子」：v6 / v7 的夹具没写过 ⇒ 必须是 NULL；
    // v8 的夹具写了 'Oatly'。这条同时证明 **旧库升级后这一列真的存在**
    // （忘了 `addColumn` 的话，上面那句 select 就会抛 no such column）。
    expect(addInRows[0].brand, expectAddInBrand);
    expect(addInRows[1].brand, isNull);
  } else {
    expect(addInRows, isEmpty);
  }

  // --- v8 的两张新表 ---
  // 对**每个**历史版本都查一次：老库升级上来时若 `_upgradeToV8` 漏了
  // `createTable`，select 会直接抛 "no such table"（比列级差异更早暴露）。
  final List<FavoriteGroupRow> groupRows = await db
      .select(db.favoriteGroups)
      .get();
  expect(groupRows, hasLength(expectFavoriteGroups ? 1 : 0));
  final List<BrewLogFavoriteGroupRow> linkRows = await db
      .select(db.brewLogFavoriteGroups)
      .get();
  expect(linkRows, hasLength(expectFavoriteGroups ? 1 : 0));
  if (expectFavoriteGroups) {
    expect(groupRows.single.name, '早餐配方');
    expect(groupRows.single.sortOrder, 0);
    // 关联行指向的正是那条记录与那个夹（双外键都是 CASCADE）。
    expect(linkRows.single.brewLogId, logs.single.id);
    expect(linkRows.single.groupId, groupRows.single.id);
  }

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
