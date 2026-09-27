import 'package:beanclick/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

/// 数据库 schema 测试。
///
/// 目的：把 `docs/M1-DATA-MODEL.md` 与 `docs/M2.5-数据层设计评审.md` 的结构
/// 固化成可验证的断言，避免以后改表时悄悄漏掉迁移或漏建索引。
///
/// 版本历史：v1 五张表 → v2 批次与多豆 → v3 索引与快照 → v4 扩展属性。
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

  Future<Set<String>> indexNames() async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name LIKE 'idx_%'",
        )
        .get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  Future<Set<String>> columnsOf(String table) async {
    final rows = await db.customSelect('PRAGMA table_info($table)').get();
    return rows.map((row) => row.read<String>('name')).toSet();
  }

  group('表结构', () {
    test('包含全部 8 张表', () async {
      final tables = await tableNames();

      expect(
        tables,
        containsAll(<String>[
          'coffee_beans',
          'bean_batches',
          'grinders',
          'brew_logs',
          'brew_log_beans',
          'recipes',
          'app_settings',
          'extra_attributes',
        ]),
      );
    });

    test('schemaVersion 为 5', () {
      expect(db.schemaVersion, 5);
    });

    test('外键约束已开启（SQLite 默认关闭）', () async {
      final row = await db.customSelect('PRAGMA foreign_keys').getSingle();

      expect(row.data.values.first, 1);
    });

    test('建库时种入 7 项默认设置（手册 §6.3）', () async {
      final rows = await db.customSelect('SELECT key FROM app_settings').get();

      expect(rows.length, 7);
    });

    test('clearAll 清空数据但保留表结构', () async {
      await db.customStatement(
        "INSERT INTO app_settings (key, value) VALUES ('x', 'y')",
      );
      expect(
        (await db.customSelect('SELECT * FROM app_settings').get()).length,
        8,
      );

      await db.clearAll();

      expect(await tableNames(), contains('app_settings'));
      expect(
        (await db.customSelect('SELECT * FROM app_settings').get()),
        isEmpty,
      );
    });
  });

  group('索引（决策 1）', () {
    test('查询索引都建上了', () async {
      final names = await indexNames();

      expect(
        names,
        containsAll(<String>[
          'idx_bean_batches_bean_id',
          'idx_brew_logs_brewed_at',
          'idx_brew_log_beans_brew_log_id',
          'idx_brew_log_beans_bean_id',
          'idx_extra_owner',
        ]),
      );
    });

    test('按豆查批次走索引而不是全表扫描', () async {
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN SELECT * FROM bean_batches WHERE bean_id = 1',
          )
          .get();
      final detail = plan.map((r) => r.data.values.join(' ')).join(' ');
      expect(detail, contains('idx_bean_batches_bean_id'));
    });
  });

  group('咖啡豆与批次的分工', () {
    test('coffee_beans 只留身份信息，批次属性已移出', () async {
      final columns = await columnsOf('coffee_beans');

      expect(
        columns,
        containsAll(<String>[
          'name',
          'origin',
          'farm',
          'process',
          'flavor_tags',
          'is_favorite',
          'photo_path',
          'notes',
        ]),
      );
      // 这些已经移到 bean_batches，不该再出现在豆子上
      expect(columns, isNot(contains('remaining_grams')));
      expect(columns, isNot(contains('initial_grams')));
      expect(columns, isNot(contains('roast_date')));
      expect(columns, isNot(contains('roast_level')));
      expect(columns, isNot(contains('price')));
    });

    test('bean_batches 承载每一次购买的信息', () async {
      final columns = await columnsOf('bean_batches');

      expect(
        columns,
        containsAll(<String>[
          'id',
          'bean_id',
          'roast_date',
          'roast_level',
          'remaining_grams',
          'initial_grams',
          'price',
          'notes',
        ]),
      );
    });
  });

  group('磨豆机', () {
    test('字段齐全（手册 §7）', () async {
      final columns = await columnsOf('grinders');

      expect(
        columns,
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
  });

  group('冲煮记录', () {
    test('核心参数、专业字段与摩卡壶专属列都在（手册 §7）', () async {
      final columns = await columnsOf('brew_logs');

      expect(
        columns,
        containsAll(<String>[
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
          'tds',
          'extraction_yield',
          'water_ppm',
          'ambient_temp',
          'ambient_humidity',
          'bean_temp',
          'pressure',
          'pour_stages',
          'bean_roast_date',
          'bean_roast_level',
          'heat_level',
          'yield_grams',
          'preheat_upper_chamber',
        ]),
      );
    });

    test('多豆用量表用自增主键并带快照列（决策 2）', () async {
      final columns = await columnsOf('brew_log_beans');

      expect(
        columns,
        containsAll(<String>[
          'id',
          'brew_log_id',
          'bean_id',
          'batch_id',
          'bean_name_snapshot',
          'roast_date_snapshot',
          'dose_grams',
          'position',
        ]),
      );

      // 主键必须只有 id 一个：复合主键会让 beanId 置空后冲突
      final info = await db
          .customSelect('PRAGMA table_info(brew_log_beans)')
          .get();
      final pk = info
          .where((r) => r.read<int>('pk') > 0)
          .map((r) => r.read<String>('name'))
          .toList();
      expect(pk, <String>['id']);
    });
  });

  group('枚举列以 TEXT 存储', () {
    Future<String> columnType(String table, String column) async {
      final rows = await db.customSelect('PRAGMA table_info($table)').get();
      return rows
          .firstWhere((row) => row.read<String>('name') == column)
          .read<String>('type');
    }

    test('豆子与批次的枚举列都是 TEXT', () async {
      expect(await columnType('coffee_beans', 'process'), 'TEXT');
      expect(await columnType('bean_batches', 'roast_level'), 'TEXT');
    });

    test('记录与磨豆机的枚举列也是 TEXT', () async {
      expect(await columnType('brew_logs', 'method'), 'TEXT');
      expect(await columnType('brew_logs', 'bean_roast_level'), 'TEXT');
      expect(await columnType('grinders', 'scale_unit'), 'TEXT');
    });
  });

  group('外键删除行为', () {
    test('brew_logs 的三个外键指向正确的表且为 SET NULL', () async {
      final rows = await db
          .customSelect('PRAGMA foreign_key_list(brew_logs)')
          .get();

      final byColumn = <String, String>{
        for (final row in rows)
          row.read<String>('from'): row.read<String>('table'),
      };

      expect(byColumn['bean_id'], 'coffee_beans');
      expect(byColumn['grinder_id'], 'grinders');
      expect(byColumn['recipe_id'], 'recipes');

      for (final row in rows) {
        expect(row.read<String>('on_delete').toUpperCase(), 'SET NULL');
      }
    });

    test('豆子 -> 批次 是级联删除', () async {
      final rows = await db
          .customSelect('PRAGMA foreign_key_list(bean_batches)')
          .get();
      final beanFk = rows.firstWhere(
        (row) => row.read<String>('from') == 'bean_id',
      );

      expect(beanFk.read<String>('table'), 'coffee_beans');
      expect(beanFk.read<String>('on_delete').toUpperCase(), 'CASCADE');
    });

    test('豆子 -> 用量是 SET NULL（决策 2：保留历史）', () async {
      final rows = await db
          .customSelect('PRAGMA foreign_key_list(brew_log_beans)')
          .get();
      final beanFk = rows.firstWhere(
        (row) => row.read<String>('from') == 'bean_id',
      );

      expect(beanFk.read<String>('table'), 'coffee_beans');
      expect(
        beanFk.read<String>('on_delete').toUpperCase(),
        'SET NULL',
        reason: '删豆子不能删掉用量行，否则拼配记录的历史就断了',
      );
    });

    test('记录 -> 用量是级联删除', () async {
      final rows = await db
          .customSelect('PRAGMA foreign_key_list(brew_log_beans)')
          .get();
      final logFk = rows.firstWhere(
        (row) => row.read<String>('from') == 'brew_log_id',
      );

      expect(logFk.read<String>('table'), 'brew_logs');
      expect(logFk.read<String>('on_delete').toUpperCase(), 'CASCADE');
    });
  });

  group('设置表与扩展属性表', () {
    test('app_settings 以 key 为主键', () async {
      final rows = await db
          .customSelect('PRAGMA table_info(app_settings)')
          .get();

      final primaryKeys = rows
          .where((row) => row.read<int>('pk') > 0)
          .map((row) => row.read<String>('name'))
          .toList();

      expect(primaryKeys, ['key']);
    });

    test('extra_attributes 以 (ownerType, ownerId, key) 为复合主键', () async {
      final rows = await db
          .customSelect('PRAGMA table_info(extra_attributes)')
          .get();

      final primaryKeys = rows
          .where((row) => row.read<int>('pk') > 0)
          .map((row) => row.read<String>('name'))
          .toList();

      expect(
        primaryKeys,
        containsAll(<String>['owner_type', 'owner_id', 'key']),
      );
    });
  });
}
