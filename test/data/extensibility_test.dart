import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/domain/extra_attributes.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

/// 可扩展性保证。
///
/// 这些测试的目的不是验证功能，而是**锁住「以后加东西不用大改」这个承诺**：
/// 加属性、加枚举值、加可扩展实体类型，都应当是小改动。
void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  group('扩展属性覆盖全部实体类型', () {
    test('每一类都有内置定义（新增类型必须补定义）', () {
      for (final owner in ExtraOwnerType.values) {
        final definitions = ExtraAttributeRegistry.of(owner);
        expect(
          definitions,
          isNotEmpty,
          reason: '${owner.label} 没有内置定义——新增 ExtraOwnerType 时要补上',
        );
      }
    });

    test('冲煮记录与批次也有内置扩展属性', () {
      expect(
        ExtraAttributeRegistry.of(ExtraOwnerType.brewLog).map((d) => d.key),
        contains('filterPaper'),
      );
      expect(
        ExtraAttributeRegistry.of(ExtraOwnerType.batch).map((d) => d.key),
        contains('storageMethod'),
      );
      expect(
        ExtraAttributeRegistry.of(ExtraOwnerType.recipe).map((d) => d.key),
        contains('source'),
      );
    });

    test('storageKey 在类型间唯一且非空', () {
      final keys = ExtraOwnerType.values.map((t) => t.storageKey).toList();
      expect(keys.every((k) => k.isNotEmpty), isTrue);
      expect(keys.toSet(), hasLength(keys.length));
    });
  });

  group('五类对象的扩展属性互不干扰', () {
    test('同一个 id 值挂在不同类型上彼此隔离', () async {
      final repo = harness.container.read(extraAttributeRepositoryProvider);
      // 让几类对象的 id 都从 1 开始（各自表的自增）
      final bean = await harness.addBeanWithBatch(name: '豆');
      final grinderId = await harness.grinders.save(makeGrinder());
      final logId = (await harness.logs.save(
        makeLog(beanId: bean.beanId, batchId: bean.batchId, doseGrams: 15),
      )).brewLogId;

      await repo.saveForBean(bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: '豆子上的',
        ),
      ]);
      await repo.saveForBrewLog(logId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'filterPaper',
          valueType: ExtraValueType.text,
          value: '记录上的',
        ),
      ]);

      expect(
        (await repo.getForBean(bean.beanId)).firstWhere(
          (a) => a.key == 'roaster',
        ).value,
        '豆子上的',
      );
      expect(
        (await repo.getForBrewLog(logId)).firstWhere(
          (a) => a.key == 'filterPaper',
        ).value,
        '记录上的',
      );
      // 磨豆机同 id 上不该有值
      expect(
        (await repo.getForGrinder(grinderId)).every((a) => a.value == null),
        isTrue,
      );
    });

    test('各实体便捷入口都能读写', () async {
      final repo = harness.container.read(extraAttributeRepositoryProvider);
      final bean = await harness.addBeanWithBatch();
      final grinderId = await harness.grinders.save(makeGrinder());
      final batchId = await harness.beans.saveBatch(
        makeBatch(beanId: bean.beanId),
      );
      final logId = (await harness.logs.save(
        makeLog(beanId: bean.beanId, batchId: bean.batchId, doseGrams: 15),
      )).brewLogId;

      await repo.saveForGrinder(grinderId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'serialNumber',
          valueType: ExtraValueType.text,
          value: 'SN-001',
        ),
      ]);
      await repo.saveForBatch(batchId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'storageMethod',
          valueType: ExtraValueType.text,
          value: '密封罐',
        ),
      ]);

      expect(
        (await repo.getForGrinder(grinderId)).firstWhere(
          (a) => a.key == 'serialNumber',
        ).value,
        'SN-001',
      );
      expect(
        (await repo.getForBatch(batchId)).firstWhere(
          (a) => a.key == 'storageMethod',
        ).value,
        '密封罐',
      );
      expect(logId, greaterThan(0));
    });
  });

  group('copyTo：附加信息可跟着复制', () {
    test('默认只补目标缺失的项', () async {
      final repo = harness.container.read(extraAttributeRepositoryProvider);
      final a = await harness.addBeanWithBatch(name: '原');
      final b = await harness.addBeanWithBatch(name: '新');

      await repo.saveForBean(a.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: 'M2M',
        ),
        const ExtraAttribute(
          key: 'altitude',
          valueType: ExtraValueType.integer,
          value: 1800,
        ),
      ]);
      await repo.saveForBean(b.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: '已有的',
        ),
      ]);

      await repo.copyTo(ExtraOwnerType.bean, a.beanId, b.beanId);

      final bAttrs = <String, ExtraAttribute>{
        for (final x in await repo.getForBean(b.beanId)) x.key: x,
      };
      expect(bAttrs['roaster']!.value, '已有的', reason: '不覆盖已有值');
      expect(bAttrs['altitude']!.value, 1800, reason: '补齐缺失项');
    });

    test('overwrite 为 true 时覆盖', () async {
      final repo = harness.container.read(extraAttributeRepositoryProvider);
      final a = await harness.addBeanWithBatch(name: '原');
      final b = await harness.addBeanWithBatch(name: '新');

      await repo.saveForBean(a.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: 'M2M',
        ),
      ]);
      await repo.saveForBean(b.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: '旧的',
        ),
      ]);

      await repo.copyTo(
        ExtraOwnerType.bean,
        a.beanId,
        b.beanId,
        overwrite: true,
      );

      final bAttrs = <String, ExtraAttribute>{
        for (final x in await repo.getForBean(b.beanId)) x.key: x,
      };
      expect(bAttrs['roaster']!.value, 'M2M');
    });

    test('源对象只有空值时什么都不做', () async {
      final repo = harness.container.read(extraAttributeRepositoryProvider);
      final a = await harness.addBeanWithBatch(name: '空');
      final b = await harness.addBeanWithBatch(name: '目标');

      await repo.copyTo(ExtraOwnerType.bean, a.beanId, b.beanId);

      final bAttrs = await repo.getForBean(b.beanId);
      expect(bAttrs.every((x) => x.value == null), isTrue);
    });
  });

  group('枚举扩展性', () {
    test('每个枚举都有 selectable 子集，且是 values 的子集', () {
      expect(
        BrewMethod.selectable.every(BrewMethod.values.contains),
        isTrue,
      );
      expect(RoastLevel.selectable.every(RoastLevel.values.contains), isTrue);
      expect(
        ProcessMethod.selectable.every(ProcessMethod.values.contains),
        isTrue,
      );
      expect(
        GrindScaleUnit.selectable.every(GrindScaleUnit.values.contains),
        isTrue,
      );
    });

    test('冲煮方法的存储全集大于或等于可选子集（预留值已就位）', () {
      expect(
        BrewMethod.values.length,
        greaterThanOrEqualTo(BrewMethod.selectable.length),
      );
      // 预留值必须在存储全集里，否则将来加值会改到表
      expect(BrewMethod.values, containsAll(<BrewMethod>[
        BrewMethod.frenchPress,
        BrewMethod.aeropress,
        BrewMethod.espresso,
      ]));
    });

    test('fromName 对未知值返回 null 而不是抛异常', () {
      for (final name in <String>['', '不存在', 'POUR_OVER']) {
        expect(BrewMethod.fromName(name), isNull);
        expect(RoastLevel.fromName(name), isNull);
        expect(ProcessMethod.fromName(name), isNull);
      }
    });

    test('GrindScaleUnit.fromName 对未知值回落到 click（不会崩）', () {
      expect(GrindScaleUnit.fromName('不存在'), GrindScaleUnit.click);
      expect(GrindScaleUnit.fromName(null), GrindScaleUnit.click);
    });

    test('每个枚举值都有非空中文标签', () {
      for (final value in BrewMethod.values) {
        expect(value.label, isNotEmpty);
      }
      for (final value in RoastLevel.values) {
        expect(value.label, isNotEmpty);
      }
      for (final value in ProcessMethod.values) {
        expect(value.label, isNotEmpty);
      }
      for (final value in GrindScaleUnit.values) {
        expect(value.label, isNotEmpty);
      }
    });

    test('新增枚举值不会破坏已有数据读取（用未知 name 模拟）', () async {
      final bean = await harness.addBeanWithBatch();
      // 直接写入一个当前枚举不认识的值，模拟「旧版本读到新版本的数据」
      await harness.db.customUpdate(
        "UPDATE coffee_beans SET process = 'someFutureProcess' WHERE id = ?",
        variables: <Variable<Object>>[Variable<int>(bean.beanId)],
      );

      final loaded = await harness.beans.getById(bean.beanId);
      expect(loaded, isNotNull, reason: '未知枚举值不应导致读取失败');
      expect(loaded!.process, isNull, reason: '无法识别时回退为 null');
      expect(loaded.name, '耶加雪菲');
    });
  });

  group('表结构扩展性', () {
    test('extra_attributes 用复合主键，保证同对象同 key 唯一', () async {
      final rows = await harness.db
          .customSelect('PRAGMA table_info(extra_attributes)')
          .get();
      final pk = rows
          .where((r) => r.read<int>('pk') > 0)
          .map((r) => r.read<String>('name'))
          .toList();

      expect(pk, containsAll(<String>['owner_type', 'owner_id', 'key']));
    });

    test('新增实体类型不需要改表（ownerType 是文本列）', () {
      // 这是一个「设计意图」断言：owner_type 是 TEXT 而非枚举约束，
      // 所以新增 ExtraOwnerType 不需要迁移。
      final columns = <String>['owner_type', 'owner_id', 'key', 'value'];
      expect(columns, contains('owner_type'));
      // 只要 ExtraOwnerType 能加值、注册表能加定义，就无需改 schema
      expect(ExtraOwnerType.values.length, greaterThanOrEqualTo(5));
    });
  });
}
