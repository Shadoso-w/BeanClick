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

    test('getRecentAddIns 按最近使用去重倒序', () async {
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

      final List<RecentAddIn> recent = await harness.logs.getRecentAddIns();
      expect(recent.first.name, '牛奶', reason: '最近一次用到的是牛奶');
      expect(recent.map((RecentAddIn addIn) => addIn.name), contains('榛果糖浆'));
      expect(recent, hasLength(2), reason: '同名的只出现一次');
    });
  });

  // -------------------------------------------------------------------------
  // v8（T37）：辅料「牌子」
  // -------------------------------------------------------------------------
  group('v8 辅料牌子', () {
    test('brand 往返：写进去读得回来；没填牌子读回 null', () async {
      final int id = (await harness.logs.save(
        makeLog(
          addIns: const <BrewLogAddIn>[
            BrewLogAddIn(name: '牛奶', brand: 'Oatly', amount: 150),
            BrewLogAddIn(name: '冰块'),
          ],
        ),
      )).brewLogId;

      final BrewLog log = (await harness.logs.getById(id))!;
      expect(log.addIns[0].name, '牛奶');
      expect(log.addIns[0].brand, 'Oatly');
      expect(log.addIns[1].brand, isNull, reason: '没填牌子是 null，不是空串');
    });

    test('brand 参与 JSON 往返', () {
      final BrewLog log = makeLog(
        addIns: const <BrewLogAddIn>[
          BrewLogAddIn(name: '牛奶', brand: 'Oatly', amount: 150),
        ],
      );

      final BrewLog restored = BrewLog.fromJson(log.toJson());

      expect(restored.addIns.single.brand, 'Oatly');
      expect(restored, log, reason: '往返后整体相等');
    });

    test('空串/纯空白归一：传进去不抛，读回来是 null', () async {
      // `brand` 是 `withLength(min: 1)`，而 drift 的 `withLength` **不生成 SQL 约束**、
      // 只在 Dart 侧校验 → 写入 `Value('')` 会抛 InvalidDataException。
      // 所以写入路径必须把「空 」归一成 null：这正是下面这条用例钉住的东西。
      final int id = (await harness.logs.save(
        makeLog(
          addIns: const <BrewLogAddIn>[
            BrewLogAddIn(name: '牛奶', brand: ''),
            BrewLogAddIn(name: '燕麦奶', brand: '   '),
          ],
        ),
      )).brewLogId;

      final BrewLog log = (await harness.logs.getById(id))!;
      expect(log.addIns[0].brand, isNull, reason: '空串应归一成 null');
      expect(log.addIns[1].brand, isNull, reason: '纯空白也算没填');
    });

    test('编辑成空牌子能存下去（回归：清空牌子再保存不该炸）', () async {
      final int id = (await harness.logs.save(
        makeLog(
          addIns: const <BrewLogAddIn>[
            BrewLogAddIn(name: '牛奶', brand: 'Oatly'),
          ],
        ),
      )).brewLogId;
      expect((await harness.logs.getById(id))!.addIns.single.brand, 'Oatly');

      final BrewLog saved = (await harness.logs.getById(id))!;
      await harness.logs.save(
        saved.copyWith(
          addIns: <BrewLogAddIn>[saved.addIns.single.copyWith(brand: '')],
        ),
      );

      expect((await harness.logs.getById(id))!.addIns.single.brand, isNull);
    });

    test('getRecentAddIns 按 name + brand 去重（同名不同牌是两条）', () async {
      await harness.logs.save(
        makeLog(
          brewedAt: DateTime(2026, 1, 1, 8),
          addIns: const <BrewLogAddIn>[
            BrewLogAddIn(name: '牛奶', brand: 'Oatly'),
          ],
        ),
      );
      await harness.logs.save(
        makeLog(
          brewedAt: DateTime(2026, 1, 2, 8),
          addIns: const <BrewLogAddIn>[
            BrewLogAddIn(name: '牛奶', brand: 'Suntory'),
          ],
        ),
      );
      // 又用了一次 Oatly 牛奶 → 它最近用过；同名同牌仍只算一条。
      await harness.logs.save(
        makeLog(
          brewedAt: DateTime(2026, 1, 3, 8),
          addIns: const <BrewLogAddIn>[
            BrewLogAddIn(name: '牛奶', brand: 'Oatly'),
          ],
        ),
      );

      final List<RecentAddIn> recent = await harness.logs.getRecentAddIns();

      expect(recent, hasLength(2), reason: '同名不同牌两条、同名同牌合并成一条');
      expect(recent.first.name, '牛奶');
      expect(recent.first.brand, 'Oatly', reason: '最近一次用的是 Oatly 牛奶');
      expect(
        recent.map((RecentAddIn addIn) => addIn.brand),
        containsAll(<String?>['Oatly', 'Suntory']),
      );
    });

    test('getRecentAddIns 把「没牌子」与「有牌子」算两条', () async {
      await harness.logs.save(
        makeLog(
          brewedAt: DateTime(2026, 1, 1, 8),
          addIns: const <BrewLogAddIn>[BrewLogAddIn(name: '牛奶')],
        ),
      );
      await harness.logs.save(
        makeLog(
          brewedAt: DateTime(2026, 1, 2, 8),
          addIns: const <BrewLogAddIn>[
            BrewLogAddIn(name: '牛奶', brand: 'Oatly'),
          ],
        ),
      );

      final List<RecentAddIn> recent = await harness.logs.getRecentAddIns();

      expect(recent, hasLength(2));
      expect(recent.first.brand, 'Oatly');
      expect(recent.last.brand, isNull);
    });

    test('getRecentAddIns 的 limit 生效', () async {
      for (int i = 0; i < 4; i++) {
        await harness.logs.save(
          makeLog(
            brewedAt: DateTime(2026, 1, 1 + i, 8),
            addIns: <BrewLogAddIn>[BrewLogAddIn(name: '辅料$i')],
          ),
        );
      }

      expect(await harness.logs.getRecentAddIns(limit: 2), hasLength(2));
    });
  });
}
