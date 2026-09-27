import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/domain/settings_keys.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  group('BeanRepository', () {
    test('新增后可读回，id 由数据库分配', () async {
      final id = await harness.beans.save(makeBean(name: '花魁'));

      final loaded = await harness.beans.getById(id);
      expect(loaded, isNotNull);
      expect(loaded!.name, '花魁');
      expect(loaded.id, id);
    });

    test('watchAll 按创建时间倒序', () async {
      await harness.beans.save(
        makeBean(name: '早', createdAt: DateTime(2026, 1, 1)),
      );
      await harness.beans.save(
        makeBean(name: '晚', createdAt: DateTime(2026, 2, 1)),
      );

      final list = await harness.beans.watchAll().first;
      expect(list.map((bean) => bean.name), ['晚', '早']);
    });

    test('编辑后字段更新且 id 不变', () async {
      final id = await harness.beans.save(
        makeBean(name: '花魁', remainingGrams: 100),
      );

      await harness.beans.save(
        (await harness.beans.getById(id))!
            .copyWith(name: '花魁 1.0', remainingGrams: 80),
      );

      final loaded = await harness.beans.getById(id);
      expect(loaded!.name, '花魁 1.0');
      expect(loaded.remainingGrams, 80);
    });

    test('删除后读不到', () async {
      final id = await harness.beans.save(makeBean());

      await harness.beans.delete(id);

      expect(await harness.beans.getById(id), isNull);
    });

    test('风味标签以 JSON 存取，读回仍是列表', () async {
      final id = await harness.beans.save(
        makeBean(flavorTags: const ['柑橘', '花香', '蜂蜜']),
      );

      final loaded = await harness.beans.getById(id);
      expect(loaded!.flavorTags, ['柑橘', '花香', '蜂蜜']);
    });

    test('search 命中名称、产地与风味标签', () async {
      await harness.beans.save(makeBean(name: '耶加雪菲', origin: '埃塞俄比亚'));
      await harness.beans.save(
        makeBean(name: '花魁', origin: '埃塞俄比亚', flavorTags: const ['草莓']),
      );
      await harness.beans.save(makeBean(name: '曼特宁', origin: '印尼'));

      final byOrigin = await harness.beans.search('埃塞');
      expect(byOrigin.map((bean) => bean.name), containsAll(['耶加雪菲', '花魁']));
      expect(byOrigin.length, 2);

      final byFlavor = await harness.beans.search('草莓');
      expect(byFlavor.single.name, '花魁');

      final byName = await harness.beans.search('曼特宁');
      expect(byName.single.name, '曼特宁');
    });

    test('search 空关键词返回全部', () async {
      await harness.beans.save(makeBean(name: 'A'));
      await harness.beans.save(makeBean(name: 'B'));

      expect((await harness.beans.search('   ')).length, 2);
    });
  });

  group('BeanRepository.adjustStock —— 手册 §6.2 余量规则', () {
    test('正常扣减', () async {
      final id = await harness.beans.save(makeBean(remainingGrams: 200));

      final result = await harness.beans.adjustStock(id, 15);

      expect(result.before, 200);
      expect(result.after, 185);
      expect(result.applied, 15);
      expect(result.clamped, isFalse);
      expect((await harness.beans.getById(id))!.remainingGrams, 185);
    });

    test('回补（负 delta）', () async {
      final id = await harness.beans.save(makeBean(remainingGrams: 100));

      final result = await harness.beans.adjustStock(id, -10);

      expect(result.after, 110);
      expect((await harness.beans.getById(id))!.remainingGrams, 110);
    });

    test('扣超了只扣到 0，并标记 clamped', () async {
      final id = await harness.beans.save(makeBean(remainingGrams: 10));

      final result = await harness.beans.adjustStock(id, 15);

      expect(result.before, 10);
      expect(result.after, 0);
      expect(result.applied, 10);
      expect(result.clamped, isTrue);
      expect((await harness.beans.getById(id))!.remainingGrams, 0);
    });

    test('余量不会变成负数', () async {
      final id = await harness.beans.save(makeBean(remainingGrams: 0));

      final result = await harness.beans.adjustStock(id, 30);

      expect(result.after, 0);
      expect(result.clamped, isTrue);
      expect((await harness.beans.getById(id))!.remainingGrams, 0);
    });

    test('回补不会越过……不会造成异常，只是加上去', () async {
      final id = await harness.beans.save(makeBean(remainingGrams: 0));

      final result = await harness.beans.adjustStock(id, -5);

      expect(result.after, 5);
      expect(result.clamped, isFalse);
    });

    test('豆子不存在时安全返回', () async {
      final result = await harness.beans.adjustStock(9999, 15);

      expect(result.beanFound, isFalse);
      expect(result.after, 0);
    });
  });

  group('GrinderRepository', () {
    test('新增、编辑、删除', () async {
      final id = await harness.grinders.save(makeGrinder());

      final loaded = await harness.grinders.getById(id);
      expect(loaded!.brand, 'Comandante');
      expect(loaded.scaleUnit, GrindScaleUnit.click);

      await harness.grinders.save(loaded.copyWith(model: 'C40 MK4'));
      expect((await harness.grinders.getById(id))!.model, 'C40 MK4');

      await harness.grinders.delete(id);
      expect(await harness.grinders.getById(id), isNull);
    });

    test('search 命中品牌与型号', () async {
      await harness.grinders.save(
        makeGrinder(brand: 'Comandante', model: 'C40'),
      );
      await harness.grinders.save(
        makeGrinder(brand: '1Zpresso', model: 'JX-Pro'),
      );

      expect((await harness.grinders.search('1Z')).single.brand, '1Zpresso');
      expect((await harness.grinders.search('C40')).single.model, 'C40');
    });
  });

  group('BrewLogRepository —— 余量自动扣减', () {
    test('新建记录按粉量扣减余量', () async {
      final beanId = await harness.beans.save(makeBean(remainingGrams: 200));
      final grinderId = await harness.grinders.save(makeGrinder());

      final result = await harness.logs.save(
        makeLog(beanId: beanId, grinderId: grinderId, doseGrams: 15),
      );

      expect(result.brewLogId, greaterThan(0));
      expect(result.stockAdjustments.single.applied, 15);
      expect(result.hasStockShortage, isFalse);
      expect((await harness.beans.getById(beanId))!.remainingGrams, 185);
    });

    test('关闭自动扣减后余量不变', () async {
      final beanId = await harness.beans.save(makeBean(remainingGrams: 200));

      final result = await harness.logs.save(
        makeLog(beanId: beanId, doseGrams: 15),
        autoDeductStock: false,
      );

      expect(result.stockAdjustments, isEmpty);
      expect((await harness.beans.getById(beanId))!.remainingGrams, 200);
    });

    test('编辑记录按粉量差值补扣，不重算历史', () async {
      final beanId = await harness.beans.save(makeBean(remainingGrams: 200));
      final logId = (await harness.logs.save(
        makeLog(beanId: beanId, doseGrams: 15),
      )).brewLogId;
      expect((await harness.beans.getById(beanId))!.remainingGrams, 185);

      final saved = await harness.logs.getById(logId);
      await harness.logs.save(saved!.copyWith(doseGrams: 20));

      // 只补扣多出来的 5g，而不是再扣 20g。
      expect((await harness.beans.getById(beanId))!.remainingGrams, 180);
    });

    test('编辑时调小粉量会回补余量', () async {
      final beanId = await harness.beans.save(makeBean(remainingGrams: 200));
      final logId = (await harness.logs.save(
        makeLog(beanId: beanId, doseGrams: 15),
      )).brewLogId;

      final saved = await harness.logs.getById(logId);
      await harness.logs.save(saved!.copyWith(doseGrams: 10));

      // 差值 15 - 10 = 5，只回补 5g：185 -> 190（不是回到初始的 200）。
      expect((await harness.beans.getById(beanId))!.remainingGrams, 190);
    });

    test('编辑时更换豆子：旧豆回补、新豆扣减', () async {
      final oldBean = await harness.beans.save(
        makeBean(name: '旧豆', remainingGrams: 200),
      );
      final newBean = await harness.beans.save(
        makeBean(name: '新豆', remainingGrams: 100),
      );
      final logId = (await harness.logs.save(
        makeLog(beanId: oldBean, doseGrams: 15),
      )).brewLogId;
      expect((await harness.beans.getById(oldBean))!.remainingGrams, 185);

      final saved = await harness.logs.getById(logId);
      await harness.logs.save(saved!.copyWith(beanId: newBean));

      expect((await harness.beans.getById(oldBean))!.remainingGrams, 200);
      expect((await harness.beans.getById(newBean))!.remainingGrams, 85);
    });

    test('编辑时关闭自动扣减，差值不生效', () async {
      final beanId = await harness.beans.save(makeBean(remainingGrams: 200));
      final logId = (await harness.logs.save(
        makeLog(beanId: beanId, doseGrams: 15),
      )).brewLogId;

      final saved = await harness.logs.getById(logId);
      await harness.logs.save(
        saved!.copyWith(doseGrams: 25),
        autoDeductStock: false,
      );

      expect((await harness.beans.getById(beanId))!.remainingGrams, 185);
    });

    test('余量不足时扣到 0 并标记短缺', () async {
      final beanId = await harness.beans.save(makeBean(remainingGrams: 10));

      final result = await harness.logs.save(
        makeLog(beanId: beanId, doseGrams: 15),
      );

      expect(result.hasStockShortage, isTrue);
      expect((await harness.beans.getById(beanId))!.remainingGrams, 0);
    });

    test('删除记录不回补余量（手册 §6.2 明确）', () async {
      final beanId = await harness.beans.save(makeBean(remainingGrams: 200));
      final logId = (await harness.logs.save(
        makeLog(beanId: beanId, doseGrams: 15),
      )).brewLogId;

      await harness.logs.delete(logId);

      expect((await harness.beans.getById(beanId))!.remainingGrams, 185);
    });

    test('没有关联豆子时不扣减任何东西', () async {
      final result = await harness.logs.save(makeLog(doseGrams: 15));

      expect(result.stockAdjustments, isEmpty);
      expect(result.brewLogId, greaterThan(0));
    });
  });

  group('BrewLogRepository —— 查询', () {
    test('getLatest 返回最近一杯（复制上次的数据来源）', () async {
      await harness.logs.save(
        makeLog(rating: 3, brewedAt: DateTime(2026, 1, 1)),
      );
      await harness.logs.save(
        makeLog(rating: 5, brewedAt: DateTime(2026, 3, 1)),
      );

      final latest = await harness.logs.getLatest();
      expect(latest!.rating, 5);
    });

    test('watchAll 按冲煮时间倒序', () async {
      await harness.logs.save(
        makeLog(rating: 3, brewedAt: DateTime(2026, 1, 1)),
      );
      await harness.logs.save(
        makeLog(rating: 5, brewedAt: DateTime(2026, 3, 1)),
      );

      final list = await harness.logs.watchAll().first;
      expect(list.map((log) => log.rating), [5, 3]);
    });

    test('search 按关键词、方法与最低评分过滤', () async {
      await harness.logs.save(
        makeLog(rating: 5, notes: '柑橘明亮').copyWith(dripper: 'V60'),
      );
      await harness.logs.save(
        makeLog(method: BrewMethod.mokaPot, rating: 2, notes: '偏苦'),
      );

      expect((await harness.logs.search(query: '柑橘')).length, 1);
      expect((await harness.logs.search(query: 'V60')).length, 1);
      expect((await harness.logs.search(method: BrewMethod.mokaPot)).length, 1);
      expect((await harness.logs.search(minRating: 4)).length, 1);
      expect((await harness.logs.search(minRating: 1)).length, 2);
    });

    test('watchByBeanAndGrinder 按研磨刻度升序（调磨对比）', () async {
      final beanId = await harness.beans.save(makeBean());
      final grinderId = await harness.grinders.save(makeGrinder());
      await harness.logs.save(
        makeLog(
          beanId: beanId,
          grinderId: grinderId,
          grindSetting: 24,
          rating: 3,
        ),
      );
      await harness.logs.save(
        makeLog(
          beanId: beanId,
          grinderId: grinderId,
          grindSetting: 20,
          rating: 5,
        ),
      );
      await harness.logs.save(
        makeLog(
          beanId: beanId,
          grinderId: grinderId,
          grindSetting: 22,
          rating: 4,
        ),
      );

      final list = await harness.logs
          .watchByBeanAndGrinder(beanId, grinderId)
          .first;
      expect(list.map((log) => log.grindSetting), [20, 22, 24]);
      expect(list.map((log) => log.rating), [5, 4, 3]);
    });

    test('删除豆子后记录仍保留，beanId 置空（外键 SET NULL）', () async {
      final beanId = await harness.beans.save(makeBean());
      final logId = (await harness.logs.save(makeLog(beanId: beanId)))
          .brewLogId;

      await harness.beans.delete(beanId);

      final log = await harness.logs.getById(logId);
      expect(log, isNotNull);
      expect(log!.beanId, isNull);
    });

    test('分段注水与专业字段能完整往返数据库', () async {
      final logId = (await harness.logs.save(
        makeLog().copyWith(
          isBest: true,
          tds: 1.35,
          extractionYield: 20.1,
          pourStages: const [
            PourStage(order: 1, waterGrams: 30, atSecond: 0, note: '闷蒸'),
            PourStage(order: 2, waterGrams: 210, atSecond: 30),
          ],
        ),
      )).brewLogId;

      final loaded = await harness.logs.getById(logId);
      expect(loaded!.isBest, isTrue);
      expect(loaded.tds, 1.35);
      expect(loaded.extractionYield, 20.1);
      expect(loaded.pourStages, hasLength(2));
      expect(loaded.pourStages!.first.note, '闷蒸');
      expect(loaded.pourStages!.last.waterGrams, 210);
    });

    test('没有分段注水时读回 null', () async {
      final logId = (await harness.logs.save(makeLog())).brewLogId;

      expect((await harness.logs.getById(logId))!.pourStages, isNull);
    });
  });

  group('SettingsRepository —— 手册 §6.3', () {
    test('建库时写入全部默认值', () async {
      for (final key in SettingsKeys.all) {
        expect(
          await harness.settings.get(key),
          SettingsDefaults.byKey[key],
          reason: 'key=$key 应有默认值',
        );
      }
    });

    test('默认主题为跟随系统，默认自动扣减为开', () async {
      expect(await harness.settings.getThemeMode(), ThemeMode.system);
      expect(await harness.settings.getAutoDeductStock(), isTrue);
    });

    test('写入后能读回，并按类型解析', () async {
      await harness.settings.setThemeMode(ThemeMode.dark);
      await harness.settings.setAutoDeductStock(false);

      expect(await harness.settings.getThemeMode(), ThemeMode.dark);
      expect(await harness.settings.getAutoDeductStock(), isFalse);
    });

    test('watchThemeMode 会推送变更', () async {
      final stream = harness.settings.watchThemeMode();
      final emissions = <ThemeMode>[];

      final subscription = stream.listen(emissions.add);
      await harness.settings.setThemeMode(ThemeMode.light);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(emissions.last, ThemeMode.light);
    });

    test('非法主题值回落到跟随系统', () async {
      await harness.settings.set(SettingsKeys.themeMode, '乱写的值');

      expect(await harness.settings.getThemeMode(), ThemeMode.system);
    });
  });
}
