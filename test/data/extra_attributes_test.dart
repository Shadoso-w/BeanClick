import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/extra_attributes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

/// 扩展属性（schema v4）。
///
/// 目标：以后给豆子/磨豆机加「只记录、只展示」的属性时，
/// 只需往 `ExtraAttributeRegistry` 加一行定义，不用改表结构、迁移或表单代码。
void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  group('schema v4', () {
    test('schemaVersion 为 4，且 extra_attributes 表存在', () async {
      expect(harness.db.schemaVersion, 4);

      final rows = await harness.db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'extra_attributes'",
          )
          .get();
      expect(rows, hasLength(1));
    });

    test('owner 复合索引建上了', () async {
      final rows = await harness.db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name = 'idx_extra_owner'",
          )
          .get();
      expect(rows, hasLength(1));
    });
  });

  group('值的类型往返', () {
    test('文本 / 数字 / 整数 / 布尔 / 日期 / 标签 都能存回', () async {
      final bean = await harness.addBeanWithBatch(name: '花魁');
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: 'M2M',
        ),
        const ExtraAttribute(
          key: 'altitude',
          valueType: ExtraValueType.integer,
          value: 1950,
        ),
        const ExtraAttribute(
          key: 'packageSize',
          valueType: ExtraValueType.number,
          value: 200.5,
        ),
        const ExtraAttribute(
          key: 'isGift',
          valueType: ExtraValueType.boolean,
          value: true,
          label: '是礼物',
        ),
        const ExtraAttribute(
          key: 'boughtOn',
          valueType: ExtraValueType.date,
          value: '2026-01-01T00:00:00.000',
          label: '购买日期',
        ),
        const ExtraAttribute(
          key: 'notes',
          valueType: ExtraValueType.tags,
          value: <String>['花果', '柑橘'],
          label: '风味关键词',
        ),
      ]);

      final all = await repo.getAll(ExtraOwnerType.bean, bean.beanId);
      final byKey = <String, ExtraAttribute>{
        for (final a in all) a.key: a,
      };

      expect(byKey['roaster']!.value, 'M2M');
      expect(byKey['altitude']!.value, 1950);
      expect(byKey['packageSize']!.value, 200.5);
      expect(byKey['isGift']!.value, true);
      expect(byKey['boughtOn']!.value, '2026-01-01T00:00:00.000');
      expect(byKey['notes']!.value, <String>['花果', '柑橘']);
    });

    test('类型能正确还原，展示格式正确', () async {
      final bean = await harness.addBeanWithBatch();
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'isGift',
          valueType: ExtraValueType.boolean,
          value: true,
        ),
        const ExtraAttribute(
          key: 'tags',
          valueType: ExtraValueType.tags,
          value: <String>['a', 'b'],
        ),
      ]);

      final all = await repo.getAll(ExtraOwnerType.bean, bean.beanId);
      final byKey = <String, ExtraAttribute>{for (final a in all) a.key: a};

      expect(byKey['isGift']!.valueType, ExtraValueType.boolean);
      expect(byKey['isGift']!.displayValue, '是');
      expect(byKey['tags']!.valueType, ExtraValueType.tags);
      expect(byKey['tags']!.displayValue, 'a、b');
    });

    test('parse 处理非法输入返回 null', () {
      expect(ExtraValueType.integer.parse('abc'), isNull);
      expect(ExtraValueType.number.parse('1.5'), 1.5);
      expect(ExtraValueType.boolean.parse('是'), isTrue);
      expect(ExtraValueType.boolean.parse('否'), isFalse);
      expect(ExtraValueType.boolean.parse('乱写'), isNull);
      expect(ExtraValueType.tags.parse('a、b, c'), <String>['a', 'b', 'c']);
    });
  });

  group('内置属性总是可见', () {
    test('没填过值时也返回内置定义，value 为 null', () async {
      final bean = await harness.addBeanWithBatch();
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      final all = await repo.getAll(ExtraOwnerType.bean, bean.beanId);

      // 表单需要按这些定义渲染出输入框，所以哪怕库里没有行也要返回。
      expect(all, isNotEmpty);
      expect(all.every((a) => a.isBuiltin), isTrue);
      expect(all.every((a) => a.value == null), isTrue);
      expect(
        all.map((a) => a.key),
        containsAll(<String>['roaster', 'altitude', 'variety']),
      );
    });

    test('磨豆机有自己的一套内置定义', () async {
      final repo = harness.container.read(extraAttributeRepositoryProvider);
      final grinderId = await harness.grinders.save(makeGrinder());

      final all = await repo.getAll(ExtraOwnerType.grinder, grinderId);

      expect(
        all.map((a) => a.key),
        containsAll(<String>['purchasedAt', 'serialNumber']),
      );
    });

    test('豆子的定义不会串到磨豆机上', () async {
      final repo = harness.container.read(extraAttributeRepositoryProvider);
      final grinderId = await harness.grinders.save(makeGrinder());

      final all = await repo.getAll(ExtraOwnerType.grinder, grinderId);

      expect(all.map((a) => a.key), isNot(contains('roaster')));
    });

    test('填写后覆盖内置定义的默认项', () async {
      final bean = await harness.addBeanWithBatch();
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: '啟程拓殖',
        ),
      ]);

      final all = await repo.getAll(ExtraOwnerType.bean, bean.beanId);
      final roaster = all.firstWhere((a) => a.key == 'roaster');

      expect(roaster.value, '啟程拓殖');
      expect(roaster.displayValue, '啟程拓殖');
      expect(roaster.isBuiltin, isTrue, reason: '填了值也还是内置属性');
    });
  });

  group('写入语义', () {
    test('save 只影响传入的 key，别的保留', () async {
      final bean = await harness.addBeanWithBatch();
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: 'M2M',
        ),
      ]);
      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'altitude',
          valueType: ExtraValueType.integer,
          value: 1800,
        ),
      ]);

      final all = await repo.getAll(ExtraOwnerType.bean, bean.beanId);
      final byKey = <String, ExtraAttribute>{for (final a in all) a.key: a};

      expect(byKey['roaster']!.value, 'M2M', reason: '第二次写入不该清掉第一次的');
      expect(byKey['altitude']!.value, 1800);
    });

    test('值为 null 时删除该项', () async {
      final bean = await harness.addBeanWithBatch();
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: 'M2M',
        ),
      ]);
      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(key: 'roaster', valueType: ExtraValueType.text),
      ]);

      final all = await repo.getAll(ExtraOwnerType.bean, bean.beanId);
      final roaster = all.firstWhere((a) => a.key == 'roaster');
      expect(roaster.value, isNull);
      expect(roaster.displayValue, '');
    });

    test('用户自建 key 可以保存与读取', () async {
      final bean = await harness.addBeanWithBatch();
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'myCustomField',
          valueType: ExtraValueType.text,
          value: '自定义值',
          label: '我的字段',
        ),
      ]);

      final all = await repo.getAll(ExtraOwnerType.bean, bean.beanId);
      final custom = all.firstWhere((a) => a.key == 'myCustomField');

      expect(custom.value, '自定义值');
      expect(custom.displayLabel, '我的字段');
      expect(custom.isBuiltin, isFalse);
    });

    test('同一对象同一 key 不会重复（复合主键保证）', () async {
      final bean = await harness.addBeanWithBatch();
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      for (var i = 0; i < 3; i++) {
        await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
          ExtraAttribute(
            key: 'roaster',
            valueType: ExtraValueType.text,
            value: '第 $i 次',
          ),
        ]);
      }

      final all = await repo.getAll(ExtraOwnerType.bean, bean.beanId);
      expect(all.where((a) => a.key == 'roaster'), hasLength(1));
      expect(all.firstWhere((a) => a.key == 'roaster').value, '第 2 次');
    });

    test('不同对象之间互不影响', () async {
      final a = await harness.addBeanWithBatch(name: 'A');
      final b = await harness.addBeanWithBatch(name: 'B');
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      await repo.save(ExtraOwnerType.bean, a.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: 'A 的烘焙商',
        ),
      ]);

      final allB = await repo.getAll(ExtraOwnerType.bean, b.beanId);
      expect(allB.firstWhere((x) => x.key == 'roaster').value, isNull);
    });

    test('豆子与磨豆机即使 id 相同也互不干扰', () async {
      final repo = harness.container.read(extraAttributeRepositoryProvider);
      // 让豆子和磨豆机的 id 都是 1
      final bean = await harness.addBeanWithBatch(name: '豆');
      final grinderId = await harness.grinders.save(makeGrinder());
      expect(bean.beanId, grinderId, reason: '两边都是各表自增，可能撞 id');

      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: '豆子的',
        ),
      ]);

      final grinderAttrs = await repo.getAll(
        ExtraOwnerType.grinder,
        grinderId,
      );
      expect(
        grinderAttrs.every((a) => a.value == null),
        isTrue,
        reason: 'ownerType 必须参与隔离',
      );
    });
  });

  group('批量与删除', () {
    test('getAllFor 一次取回多个对象', () async {
      final a = await harness.addBeanWithBatch(name: 'A');
      final b = await harness.addBeanWithBatch(name: 'B');
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      await repo.save(ExtraOwnerType.bean, a.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: 'M2M',
        ),
      ]);

      final grouped = await repo.getAllFor(ExtraOwnerType.bean, <int>[
        a.beanId,
        b.beanId,
      ]);

      expect(grouped[a.beanId], isNotNull);
      expect(
        grouped[a.beanId]!.firstWhere((x) => x.key == 'roaster').value,
        'M2M',
      );
      // b 没有填过任何值，所以不会出现在结果里
      expect(grouped[b.beanId], isNull);
    });

    test('delete 删掉单项', () async {
      final bean = await harness.addBeanWithBatch();
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
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

      await repo.delete(ExtraOwnerType.bean, bean.beanId, 'roaster');

      final all = await repo.getAll(ExtraOwnerType.bean, bean.beanId);
      expect(all.firstWhere((a) => a.key == 'roaster').value, isNull);
      expect(all.firstWhere((a) => a.key == 'altitude').value, 1800);
    });

    test('deleteAllFor 清掉某对象的全部扩展属性', () async {
      final bean = await harness.addBeanWithBatch();
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: 'M2M',
        ),
      ]);
      await repo.deleteAllFor(ExtraOwnerType.bean, bean.beanId);

      final rows = await harness.db.select(harness.db.extraAttributes).get();
      expect(rows, isEmpty);
    });
  });

  group('watch', () {
    test('写入后能收到更新', () async {
      final bean = await harness.addBeanWithBatch();
      final repo = harness.container.read(extraAttributeRepositoryProvider);

      final stream = repo.watch(ExtraOwnerType.bean, bean.beanId);
      final emissions = <List<ExtraAttribute>>[];
      final sub = stream.listen(emissions.add);

      await repo.save(ExtraOwnerType.bean, bean.beanId, <ExtraAttribute>[
        const ExtraAttribute(
          key: 'roaster',
          valueType: ExtraValueType.text,
          value: 'M2M',
        ),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(emissions, isNotEmpty);
      final last = emissions.last;
      expect(last.firstWhere((a) => a.key == 'roaster').value, 'M2M');
    });
  });

  group('注册表演进：加属性只需加一行', () {
    test('注册表里的每一项都能被表单/导出正确使用', () {
      for (final owner in ExtraOwnerType.values) {
        final definitions = ExtraAttributeRegistry.of(owner);
        expect(definitions, isNotEmpty, reason: '$owner 应当有内置定义');
        for (final definition in definitions) {
          expect(definition.key, isNotEmpty);
          expect(definition.label, isNotEmpty);
          // key 必须是稳定标识，不含空格或中文
          expect(
            RegExp(r'^[a-zA-Z][a-zA-Z0-9]*$').hasMatch(definition.key),
            isTrue,
            reason: '「${definition.key}」不符合 key 命名约定',
          );
        }
      }
    });

    test('同一 owner 内 key 不重复', () {
      for (final owner in ExtraOwnerType.values) {
        final keys = ExtraAttributeRegistry.of(owner).map((d) => d.key).toList();
        expect(keys.toSet(), hasLength(keys.length), reason: '$owner 有重复 key');
      }
    });

    test('fromStorage 容忍未知值', () {
      expect(ExtraOwnerType.fromStorage('bean'), ExtraOwnerType.bean);
      expect(ExtraOwnerType.fromStorage('不存在'), isNull);
      expect(ExtraValueType.fromStorage('number'), ExtraValueType.number);
      expect(
        ExtraValueType.fromStorage('不存在'),
        ExtraValueType.text,
        reason: '未知类型回落到文本，避免旧数据渲染崩溃',
      );
    });
  });
}
