import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/domain/settings_keys.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

/// M2.8 第二批的数据层：B1 自定义方法、B3 辅料。
void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  group('B1 自定义冲煮方法', () {
    test('methodLabel 能存能读，且不影响内置 method', () async {
      final int id = (await harness.logs.save(
        makeLog(method: BrewMethod.espresso, methodLabel: '拿铁'),
      )).brewLogId;

      final BrewLog log = (await harness.logs.getById(id))!;
      expect(log.method, BrewMethod.espresso, reason: '做法还在');
      expect(log.methodLabel, '拿铁');
      expect(log.methodDisplay, '拿铁', reason: '显示取原文');
    });

    test('没有 methodLabel 时显示内置标签', () async {
      final int id = (await harness.logs.save(
        makeLog(method: BrewMethod.mokaPot),
      )).brewLogId;

      final BrewLog log = (await harness.logs.getById(id))!;
      expect(log.methodLabel, isNull);
      expect(log.methodDisplay, '摩卡壶');
    });

    test('自定义方法库存在设置表里，能增删改并推送变化', () async {
      final settings = harness.settings;
      expect(await settings.getCustomBrewMethods(), isEmpty);

      await settings.setCustomBrewMethods(<String>['拿铁', '榛果摩卡']);
      expect(await settings.getCustomBrewMethods(), <String>['拿铁', '榛果摩卡']);

      // 删掉第一个、改第二个。
      await settings.setCustomBrewMethods(<String>['摩卡']);
      expect(await settings.getCustomBrewMethods(), <String>['摩卡']);

      final List<String> pushed = await settings.watchCustomBrewMethods().first;
      expect(pushed, <String>['摩卡']);
    });

    test('方法库内容坏掉时当作空列表，不抛异常', () async {
      await harness.settings.set(SettingsKeys.customBrewMethods, '{不是数组');
      expect(await harness.settings.getCustomBrewMethods(), isEmpty);
    });
  });

  group('B3 辅料', () {
    test('JSON 往返带上辅料与自定义方法（导出/导入用的就是这套）', () {
      final BrewLog log = makeLog(
        methodLabel: '拿铁',
        addIns: const <BrewLogAddIn>[
          BrewLogAddIn(name: '牛奶', amount: 150, unit: AddInUnit.ml),
          BrewLogAddIn(name: '冰块'),
        ],
      );

      final BrewLog restored = BrewLog.fromJson(log.toJson());

      expect(restored.methodLabel, '拿铁');
      expect(restored.methodDisplay, '拿铁');
      expect(restored.addIns, hasLength(2));
      expect(restored.addIns[0].name, '牛奶');
      expect(restored.addIns[0].amount, 150);
      expect(restored.addIns[0].unit, AddInUnit.ml);
      expect(restored.addIns[1].name, '冰块');
      expect(restored.addIns[1].amount, isNull);
      expect(restored, log, reason: '往返后整体相等');
    });
    test('辅料随记录一起存，按 position 顺序读回', () async {
      final int id = (await harness.logs.save(
        makeLog(
          addIns: const <BrewLogAddIn>[
            BrewLogAddIn(name: '牛奶', amount: 150, unit: AddInUnit.ml),
            BrewLogAddIn(name: '榛果糖浆', amount: 1, unit: AddInUnit.pump),
          ],
        ),
      )).brewLogId;

      final BrewLog log = (await harness.logs.getById(id))!;
      expect(log.addIns, hasLength(2));
      expect(log.addIns[0].name, '牛奶');
      expect(log.addIns[0].amount, 150);
      expect(log.addIns[0].unit, AddInUnit.ml);
      expect(log.addIns[1].name, '榛果糖浆');
      expect(log.addIns[1].unit, AddInUnit.pump);
    });

    test('数量可以留空（只记加了什么）', () async {
      final int id = (await harness.logs.save(
        makeLog(addIns: const <BrewLogAddIn>[BrewLogAddIn(name: '冰块')]),
      )).brewLogId;

      final BrewLog log = (await harness.logs.getById(id))!;
      expect(log.addIns.single.name, '冰块');
      expect(log.addIns.single.amount, isNull);
      expect(log.addIns.single.unit, AddInUnit.ml, reason: '默认单位 ml');
    });

    test('编辑记录时辅料整组替换，不残留旧的', () async {
      final int id = (await harness.logs.save(
        makeLog(
          addIns: const <BrewLogAddIn>[BrewLogAddIn(name: '牛奶', amount: 150)],
        ),
      )).brewLogId;

      final BrewLog log = (await harness.logs.getById(id))!;
      await harness.logs.save(
        log.copyWith(
          addIns: const <BrewLogAddIn>[
            BrewLogAddIn(name: '燕麦奶', amount: 200),
            BrewLogAddIn(name: '香草糖浆', amount: 1, unit: AddInUnit.pump),
          ],
        ),
      );

      final BrewLog updated = (await harness.logs.getById(id))!;
      expect(updated.addIns.map((BrewLogAddIn a) => a.name), <String>[
        '燕麦奶',
        '香草糖浆',
      ]);
      expect(updated.addIns[0].position, 0);
      expect(updated.addIns[1].position, 1);
    });

    test('删掉记录时辅料跟着级联删除', () async {
      final int id = (await harness.logs.save(
        makeLog(addIns: const <BrewLogAddIn>[BrewLogAddIn(name: '牛奶')]),
      )).brewLogId;

      await harness.logs.delete(id);

      final rows = await harness.db.select(harness.db.brewLogAddins).get();
      expect(rows, isEmpty);
    });

    test('getRecentAddInNames 按最近使用去重倒序', () async {
      // 先牛奶、再糖浆、最后又加了一次牛奶 → 牛奶最近用过。
      await harness.logs.save(
        makeLog(
          brewedAt: DateTime(2026, 1, 1, 8),
          addIns: const <BrewLogAddIn>[BrewLogAddIn(name: '牛奶')],
        ),
      );
      await harness.logs.save(
        makeLog(
          brewedAt: DateTime(2026, 1, 2, 8),
          addIns: const <BrewLogAddIn>[BrewLogAddIn(name: '榛果糖浆')],
        ),
      );
      await harness.logs.save(
        makeLog(
          brewedAt: DateTime(2026, 1, 3, 8),
          addIns: const <BrewLogAddIn>[BrewLogAddIn(name: '牛奶')],
        ),
      );

      final List<String> recent = await harness.logs.getRecentAddInNames();
      expect(recent.first, '牛奶', reason: '最近一次用到的是牛奶');
      expect(recent, contains('榛果糖浆'));
      expect(recent, hasLength(2), reason: '同名的只出现一次');
    });
  });
}
