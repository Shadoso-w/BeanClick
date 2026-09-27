import 'package:beanclick/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

/// 数据库 schema 测试。
///
/// 目的：把 `docs/M1-DATA-MODEL.md` 的表结构固化成可验证的断言，
/// 避免以后改表时悄悄漏掉迁移或漏建索引。
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<Set<String>> tableNames() async {
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  test('建库后包含设计稿 §1–§5 的全部表', () async {
    final tables = await tableNames();

    expect(tables, containsAll(<String>[
      'coffee_beans',
      'grinders',
      'brew_logs',
      'recipes',
      'app_settings',
    ]));
  });

  test('schemaVersion 为 1', () {
    expect(db.schemaVersion, 1);
  });

  test('外键约束已开启（SQLite 默认关闭）', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();

    expect(row.data.values.first, 1);
  });

  test('brew_logs 的三个外键都指向正确的表且为 SET NULL', () async {
    final rows = await db.customSelect('PRAGMA foreign_key_list(brew_logs)').get();

    final byColumn = {
      for (final row in rows)
        row.read<String>('from'): row.read<String>('table'),
    };

    expect(byColumn['bean_id'], 'coffee_beans');
    expect(byColumn['grinder_id'], 'grinders');
    expect(byColumn['recipe_id'], 'recipes');

    for (final row in rows) {
      // KeyAction.setNull 在 PRAGMA 里是 'SET NULL'
      expect(row.read<String>('on_delete').toUpperCase(), 'SET NULL');
    }
  });

  test('app_settings 以 key 为主键', () async {
    final rows = await db.customSelect('PRAGMA table_info(app_settings)').get();

    final primaryKeys = rows
        .where((row) => row.read<int>('pk') > 0)
        .map((row) => row.read<String>('name'))
        .toList();

    expect(primaryKeys, ['key']);
  });

  test('建库时种入 7 项默认设置（手册 §6.3）', () async {
    final rows = await db.customSelect('SELECT key FROM app_settings').get();

    expect(rows.length, 7);
  });

  test('枚举列以 TEXT 存储', () async {
    Future<String> columnType(String table, String column) async {
      final rows = await db.customSelect('PRAGMA table_info($table)').get();
      return rows
          .firstWhere((row) => row.read<String>('name') == column)
          .read<String>('type');
    }

    expect(await columnType('coffee_beans', 'roast_level'), 'TEXT');
    expect(await columnType('coffee_beans', 'process'), 'TEXT');
    expect(await columnType('brew_logs', 'method'), 'TEXT');
    expect(await columnType('grinders', 'scale_unit'), 'TEXT');
  });

  test('专业字段与摩卡壶专属列都存在（手册 §7）', () async {
    Future<Set<String>> columnsOf(String table) async {
      final rows = await db.customSelect('PRAGMA table_info($table)').get();
      return rows.map((row) => row.read<String>('name')).toSet();
    }

    final brewLogColumns = await columnsOf('brew_logs');
    expect(
      brewLogColumns,
      containsAll(<String>[
        // 核心
        'method',
        'grind_setting',
        'grind_clicks',
        'dose_grams',
        'water_grams',
        'ratio',
        'water_temp',
        'total_time_seconds',
        'dripper',
        'rating',
        'flavor_tags',
        'is_best',
        // 专业字段
        'tds',
        'extraction_yield',
        'water_ppm',
        'ambient_temp',
        'ambient_humidity',
        'bean_temp',
        'pressure',
        'pour_stages',
        // 摩卡壶
        'heat_level',
        'yield_grams',
        'preheat_upper_chamber',
      ]),
    );

    final beanColumns = await columnsOf('coffee_beans');
    expect(
      beanColumns,
      containsAll(<String>[
        'name',
        'origin',
        'farm',
        'process',
        'roast_level',
        'roast_date',
        'flavor_tags',
        'remaining_grams',
        'initial_grams',
        'price',
        'photo_path',
        'notes',
      ]),
    );

    final grinderColumns = await columnsOf('grinders');
    expect(
      grinderColumns,
      containsAll(<String>[
        'brand',
        'model',
        'burr_type',
        'scale_unit',
        'zero_point',
        'clicks_per_revolution',
        'calibration_note',
        'notes',
      ]),
    );
  });

  test('clearAll 清空数据但保留表结构', () async {
    await db.customStatement(
      "INSERT INTO app_settings (key, value) VALUES ('x', 'y')",
    );
    expect((await db.customSelect('SELECT * FROM app_settings').get()).length, 8);

    await db.clearAll();

    expect(await tableNames(), contains('app_settings'));
    expect((await db.customSelect('SELECT * FROM app_settings').get()), isEmpty);
  });
}
