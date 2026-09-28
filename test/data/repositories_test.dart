import 'package:beanclick/data/repositories/bean_repository.dart';
import 'package:beanclick/data/repositories/brew_log_repository.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/domain/settings_keys.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

/// 仓储层测试。
///
/// 注意分工：与「批次扣减」直接相关的边界用例在
/// `test/data/design_decisions_test.dart`（那里还覆盖索引、删豆保留历史、
/// 换批次提示等设计决策）。这里放通用的 CRUD、查询与设置项。
void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  // -------------------------------------------------------------------------
  // 豆子
  // -------------------------------------------------------------------------
  group('BeanRepository：豆子的身份', () {
    test('新增后可读回，id 由数据库分配', () async {
      final int id = await harness.beans.save(makeBean(name: '花魁'));

      final CoffeeBean? loaded = await harness.beans.getById(id);
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

      final List<CoffeeBean> list = await harness.beans.watchAll().first;
      expect(list.map((b) => b.name), ['晚', '早']);
    });

    test('编辑后字段更新且 id 不变', () async {
      final int id = await harness.beans.save(makeBean(name: '花魁'));

      await harness.beans.save(
        (await harness.beans.getById(id))!.copyWith(name: '花魁 1.0'),
      );

      final CoffeeBean loaded = (await harness.beans.getById(id))!;
      expect(loaded.name, '花魁 1.0');
      expect(loaded.id, id);
    });

    test('删除后读不到', () async {
      final int id = await harness.beans.save(makeBean());

      await harness.beans.delete(id);

      expect(await harness.beans.getById(id), isNull);
    });

    test('风味标签以 JSON 存取，读回仍是列表', () async {
      final int id = await harness.beans.save(
        makeBean(flavorTags: const ['柑橘', '花香', '蜂蜜']),
      );

      expect((await harness.beans.getById(id))!.flavorTags, ['柑橘', '花香', '蜂蜜']);
    });

    test('收藏可以切换', () async {
      final int id = await harness.beans.save(makeBean(name: '常买'));

      await harness.beans.setFavorite(id, true);
      expect((await harness.beans.getById(id))!.isFavorite, isTrue);
      expect((await harness.beans.getFavorites()).single.name, '常买');

      await harness.beans.setFavorite(id, false);
      expect((await harness.beans.getById(id))!.isFavorite, isFalse);
      expect(await harness.beans.getFavorites(), isEmpty);
    });

    test('search 命中名称、产地与风味标签', () async {
      await harness.beans.save(makeBean(name: '耶加雪菲', origin: '埃塞俄比亚'));
      await harness.beans.save(
        makeBean(name: '花魁', origin: '埃塞俄比亚', flavorTags: const ['草莓']),
      );
      await harness.beans.save(makeBean(name: '曼特宁', origin: '印尼'));

      final List<CoffeeBean> byOrigin = await harness.beans.search('埃塞');
      expect(byOrigin.map((b) => b.name), containsAll(['耶加雪菲', '花魁']));
      expect(byOrigin.length, 2);

      expect((await harness.beans.search('草莓')).single.name, '花魁');
      expect((await harness.beans.search('曼特宁')).single.name, '曼特宁');
    });

    test('search 空关键词返回全部', () async {
      await harness.beans.save(makeBean(name: 'A'));
      await harness.beans.save(makeBean(name: 'B'));

      expect((await harness.beans.search('   ')).length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // 批次
  // -------------------------------------------------------------------------
  group('BeanRepository：批次', () {
    test('一个豆子可以有多个批次（复购）', () async {
      final a = await harness.addBeanWithBatch(
        name: '花魁',
        roastDate: DateTime(2026, 1, 1),
        remainingGrams: 200,
      );
      await harness.beans.saveBatch(
        makeBatch(
          beanId: a.beanId,
          roastDate: DateTime(2026, 3, 1),
          remainingGrams: 250,
        ),
      );

      final List<BeanBatch> batches = await harness.beans.batchesOf(a.beanId);
      expect(batches, hasLength(2));
      // 烘焙日期新的在前
      expect(batches.first.roastDate, DateTime(2026, 3, 1));
    });

    test('batchCount 聚合到豆子上', () async {
      final a = await harness.addBeanWithBatch(name: '花魁');
      await harness.beans.saveBatch(makeBatch(beanId: a.beanId));

      expect((await harness.beans.getById(a.beanId))!.batchCount, 2);
      expect((await harness.beans.getAll()).single.batchCount, 2);
    });

    test('getWithBatches 聚合总余量与最近烘焙日', () async {
      final a = await harness.addBeanWithBatch(
        roastDate: DateTime(2026, 1, 1),
        remainingGrams: 200,
      );
      await harness.beans.saveBatch(
        makeBatch(
          beanId: a.beanId,
          roastDate: DateTime(2026, 3, 1),
          remainingGrams: 50,
        ),
      );

      final BeanWithBatches result = (await harness.beans.getWithBatches(
        a.beanId,
      ))!;
      expect(result.totalRemaining, 250);
      expect(result.latestRoastDate, DateTime(2026, 3, 1));
    });

    test('usableBatches 只返回还有余量的批次', () async {
      final a = await harness.addBeanWithBatch(remainingGrams: 0);
      await harness.beans.saveBatch(
        makeBatch(beanId: a.beanId, remainingGrams: 100),
      );

      final BeanWithBatches result = (await harness.beans.getWithBatches(
        a.beanId,
      ))!;
      expect(result.batches, hasLength(2));
      expect(result.usableBatches, hasLength(1));
      expect(result.usableBatches.single.remainingGrams, 100);
    });

    test('批次可以编辑与删除', () async {
      final a = await harness.addBeanWithBatch(remainingGrams: 200);

      await harness.beans.saveBatch(
        (await harness.beans.getBatch(a.batchId))!
            .copyWith(remainingGrams: 120),
      );
      expect((await harness.beans.getBatch(a.batchId))!.remainingGrams, 120);

      await harness.beans.deleteBatch(a.batchId);
      expect(await harness.beans.getBatch(a.batchId), isNull);
    });

    test('defaultBatchFor 挑余量尚存且烘焙日期最新的批次', () async {
      final a = await harness.addBeanWithBatch(
        roastDate: DateTime(2026, 1, 1),
        remainingGrams: 0,
      );
      await harness.beans.saveBatch(
        makeBatch(
          beanId: a.beanId,
          roastDate: DateTime(2026, 3, 1),
          remainingGrams: 80,
        ),
      );

      final BeanBatch? batch = await harness.beans.defaultBatchFor(a.beanId);
      expect(batch!.roastDate, DateTime(2026, 3, 1));
    });

    test('删除豆子会级联删掉它的批次', () async {
      final a = await harness.addBeanWithBatch();
      await harness.beans.saveBatch(makeBatch(beanId: a.beanId));

      await harness.beans.delete(a.beanId);

      final rows = await harness.db.select(harness.db.beanBatches).get();
      expect(rows, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // 磨豆机
  // -------------------------------------------------------------------------
  group('GrinderRepository', () {
    test('新增、编辑、删除', () async {
      final int id = await harness.grinders.save(makeGrinder());

      final Grinder loaded = (await harness.grinders.getById(id))!;
      expect(loaded.brand, 'Comandante');
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

  // -------------------------------------------------------------------------
  // 冲煮记录：通用读写与查询
  // （扣减细节在 design_decisions_test）
  // -------------------------------------------------------------------------
  group('BrewLogRepository：读写与查询', () {
    test('新增后能读回，并带出豆子用量', () async {
      final a = await harness.addBeanWithBatch(name: '花魁');

      final int logId = (await harness.logs.save(
        makeLog(beanId: a.beanId, batchId: a.batchId, doseGrams: 15),
      )).brewLogId;

      final BrewLog log = (await harness.logs.getById(logId))!;
      expect(log.doseGrams, 15);
      expect(log.beanUsages, hasLength(1));
      expect(log.beanUsages.single.beanName, '花魁');
      expect(log.beanId, a.beanId, reason: '主豆冗余字段应被写入');
    });

    test('getLatest 返回最近一杯（复制上次的数据来源）', () async {
      await harness.logs.save(
        makeLog(rating: 3, brewedAt: DateTime(2026, 1, 1)),
      );
      await harness.logs.save(
        makeLog(rating: 5, brewedAt: DateTime(2026, 3, 1)),
      );

      expect((await harness.logs.getLatest())!.rating, 5);
    });

    test('watchAll 按冲煮时间倒序', () async {
      await harness.logs.save(
        makeLog(rating: 3, brewedAt: DateTime(2026, 1, 1)),
      );
      await harness.logs.save(
        makeLog(rating: 5, brewedAt: DateTime(2026, 3, 1)),
      );

      final List<BrewLog> list = await harness.logs.watchAll().first;
      expect(list.map((l) => l.rating), [5, 3]);
    });

    test('search 按关键词、方法与最低评分过滤', () async {
      await harness.logs.save(
        makeLog(rating: 5, notes: '柑橘明亮', dripper: 'V60'),
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
      final a = await harness.addBeanWithBatch();
      final int grinderId = await harness.grinders.save(makeGrinder());

      for (final (double grind, int rating) in <(double, int)>[
        (24, 3),
        (20, 5),
        (22, 4),
      ]) {
        await harness.logs.save(
          makeLog(
            beanId: a.beanId,
            batchId: a.batchId,
            grinderId: grinderId,
            grindSetting: grind,
            rating: rating,
          ),
        );
      }

      final List<BrewLog> list = await harness.logs
          .watchByBeanAndGrinder(a.beanId, grinderId)
          .first;
      expect(list.map((l) => l.grindSetting), [20, 22, 24]);
      expect(list.map((l) => l.rating), [5, 4, 3]);
    });

    test('删除磨豆机后记录保留，grinderId 置空', () async {
      final int grinderId = await harness.grinders.save(makeGrinder());
      final int logId = (await harness.logs.save(makeLog(grinderId: grinderId)))
          .brewLogId;

      await harness.grinders.delete(grinderId);

      final BrewLog? log = await harness.logs.getById(logId);
      expect(log, isNotNull);
      expect(log!.grinderId, isNull);
    });

    test('分段注水与专业字段能完整往返数据库', () async {
      final int logId = (await harness.logs.save(
        makeLog().copyWith(
          isBest: true,
          tds: 1.35,
          extractionYield: 20.1,
          pourStages: const <PourStage>[
            PourStage(order: 1, waterGrams: 30, atSecond: 0, note: '闷蒸'),
            PourStage(order: 2, waterGrams: 210, atSecond: 30),
          ],
        ),
      )).brewLogId;

      final BrewLog loaded = (await harness.logs.getById(logId))!;
      expect(loaded.isBest, isTrue);
      expect(loaded.tds, 1.35);
      expect(loaded.extractionYield, 20.1);
      expect(loaded.pourStages, hasLength(2));
      expect(loaded.pourStages!.first.note, '闷蒸');
      expect(loaded.pourStages!.last.waterGrams, 210);
    });

    test('没有分段注水时读回 null', () async {
      final int logId = (await harness.logs.save(makeLog())).brewLogId;

      expect((await harness.logs.getById(logId))!.pourStages, isNull);
    });

    test('删除记录会把扣掉的余量回补（测评反馈改的规则）', () async {
      final a = await harness.addBeanWithBatch(remainingGrams: 200);
      final int logId = (await harness.logs.save(
        makeLog(beanId: a.beanId, batchId: a.batchId, doseGrams: 15),
      )).brewLogId;
      expect((await harness.beans.getBatch(a.batchId))!.remainingGrams, 185);

      await harness.logs.delete(logId);

      expect(
        (await harness.beans.getBatch(a.batchId))!.remainingGrams,
        200,
        reason: '删记录要把当时扣的 15g 退回原来那一袋',
      );
      expect(await harness.logs.getById(logId), isNull);
    });

    test('删除拼配记录：两支豆子各自回补', () async {
      final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
      final b = await harness.addBeanWithBatch(
        name: '曼特宁',
        remainingGrams: 100,
      );
      final int logId = (await harness.logs.save(
        makeLog(
          doseGrams: 20,
          beanUsages: <BeanUsage>[
            BeanUsage(
              beanId: a.beanId,
              batchId: a.batchId,
              doseGrams: 14,
              position: 0,
            ),
            BeanUsage(
              beanId: b.beanId,
              batchId: b.batchId,
              doseGrams: 6,
              position: 1,
            ),
          ],
        ),
      )).brewLogId;

      await harness.logs.delete(logId);

      expect((await harness.beans.getBatch(a.batchId))!.remainingGrams, 200);
      expect((await harness.beans.getBatch(b.batchId))!.remainingGrams, 100);
    });

    test('没有关联豆子时不报错', () async {
      final SaveBrewLogResult result = await harness.logs.save(
        makeLog(doseGrams: 15),
      );

      expect(result.stockAdjustments, isEmpty);
      expect(result.brewLogId, greaterThan(0));
    });

    test('收藏与取消收藏：只改标记，不碰余量也不动最佳', () async {
      final a = await harness.addBeanWithBatch(remainingGrams: 200);
      final int logId = (await harness.logs.save(
        makeLog(
          beanId: a.beanId,
          batchId: a.batchId,
          doseGrams: 15,
          isBest: true,
        ),
      )).brewLogId;

      expect((await harness.logs.getById(logId))!.isFavorite, isFalse);

      await harness.logs.setFavorite(logId, true);
      final BrewLog favorited = (await harness.logs.getById(logId))!;
      expect(favorited.isFavorite, isTrue);
      expect(favorited.isBest, isTrue, reason: '收藏不该动「最佳参数」');
      expect((await harness.beans.getBatch(a.batchId))!.remainingGrams, 185);

      await harness.logs.setFavorite(logId, false);
      expect((await harness.logs.getById(logId))!.isFavorite, isFalse);
    });

    test('getFavorites 只返回收藏的，按冲煮时间倒序', () async {
      final int old = (await harness.logs.save(
        makeLog(brewedAt: DateTime(2026, 1, 1, 8), isFavorite: true),
      )).brewLogId;
      await harness.logs.save(
        makeLog(brewedAt: DateTime(2026, 1, 2, 8), isFavorite: false),
      );
      final int newest = (await harness.logs.save(
        makeLog(brewedAt: DateTime(2026, 1, 3, 8), isFavorite: true),
      )).brewLogId;

      final List<BrewLog> favorites = await harness.logs.getFavorites();

      expect(favorites.map((BrewLog log) => log.id).toList(), <int>[
        newest,
        old,
      ]);
    });
  });

  // -------------------------------------------------------------------------
  // 设置项
  // -------------------------------------------------------------------------
  group('SettingsRepository —— 手册 §6.3', () {
    test('建库时写入全部默认值', () async {
      for (final String key in SettingsKeys.all) {
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
      final List<ThemeMode> emissions = <ThemeMode>[];
      final subscription = harness.settings.watchThemeMode().listen(
        emissions.add,
      );

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
