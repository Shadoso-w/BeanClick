import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

/// 数据层 7 条设计决策的验证。
///
/// 对应 `docs/M2.5-数据层设计评审.md` §5 的拍板结果：索引、删除豆子保留历史、
/// 0.1g 归一、烘焙快照、豆子与批次的关系、多豆按各自粉量扣减、
/// 指定批次缺失时显式告知。
///
/// 原文件名 `schema_v3_test.dart` 是 v3 时代的叫法，表结构已经到 v4，
/// 名字和内容对不上，因此改名。
void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  // -------------------------------------------------------------------------
  // 决策 1：加外键索引
  // -------------------------------------------------------------------------
  group('决策 1：外键索引', () {
    test('schemaVersion 为 6', () {
      // v4 = 批次 + 多豆 + 扩展属性；v5 = 记录收藏；v6 = 自定义方法 + 辅料。
      expect(harness.db.schemaVersion, 6);
    });

    test('4 个索引都建上了', () async {
      final rows = await harness.db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name LIKE 'idx_%'",
          )
          .get();
      final names = rows.map((r) => r.read<String>('name')).toSet();

      expect(
        names,
        containsAll(<String>[
          'idx_bean_batches_bean_id',
          'idx_brew_log_beans_brew_log_id',
          'idx_brew_log_beans_bean_id',
          'idx_brew_logs_brewed_at',
        ]),
      );
    });

    test('按豆查批次走索引（EXPLAIN 里出现索引名）', () async {
      final plan = await harness.db
          .customSelect(
            'EXPLAIN QUERY PLAN '
            'SELECT * FROM bean_batches WHERE bean_id = 1',
          )
          .get();
      final detail = plan.map((r) => r.data.values.join(' ')).join(' ');
      expect(detail, contains('idx_bean_batches_bean_id'));
    });
  });

  // -------------------------------------------------------------------------
  // 决策 2：删除豆子时保留记录历史
  // -------------------------------------------------------------------------
  group('决策 2：删除豆子不破坏拼配记录', () {
    test('删除豆子后，用量行保留且 beanId 置空、快照名还在', () async {
      final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 100);
      final b = await harness.addBeanWithBatch(
        name: '曼特宁',
        remainingGrams: 100,
      );

      final logId = (await harness.logs.save(
        makeLog(
          beanId: a.beanId,
          doseGrams: 20,
          beanUsages: <BeanUsage>[
            BeanUsage(beanId: a.beanId, batchId: a.batchId, doseGrams: 14),
            BeanUsage(beanId: b.beanId, batchId: b.batchId, doseGrams: 6),
          ],
        ),
      )).brewLogId;

      // 删掉其中一支豆子
      await harness.beans.delete(b.beanId);

      final log = await harness.logs.getById(logId);
      expect(log, isNotNull);
      expect(log!.beanUsages, hasLength(2), reason: '拼配记录的两支豆子都要保留');

      final deleted = log.beanUsages.firstWhere((u) => u.beanName == '曼特宁');
      expect(deleted.beanId, isNull, reason: '豆子已删，外键应为 SET NULL');
      expect(deleted.beanName, '曼特宁', reason: '靠快照名仍能显示');

      // 记录整体仍可读
      expect(log.beanLabel, '花魁 + 曼特宁');
      expect(log.isBlend, isTrue);
    });

    test('自增主键让同一记录能有两个已删豆子的用量行', () async {
      final a = await harness.addBeanWithBatch(name: 'A');
      final b = await harness.addBeanWithBatch(name: 'B');
      final logId = (await harness.logs.save(
        makeLog(
          beanId: a.beanId,
          doseGrams: 20,
          beanUsages: <BeanUsage>[
            BeanUsage(beanId: a.beanId, batchId: a.batchId, doseGrams: 10),
            BeanUsage(beanId: b.beanId, batchId: b.batchId, doseGrams: 10),
          ],
        ),
      )).brewLogId;

      await harness.beans.delete(a.beanId);
      await harness.beans.delete(b.beanId);

      final log = await harness.logs.getById(logId);
      expect(
        log!.beanUsages,
        hasLength(2),
        reason: '复合主键 (brewLogId, beanId) 在 beanId 置空后会冲突，自增主键才不会',
      );
      expect(log.beanUsages.every((u) => u.beanId == null), isTrue);
      expect(log.beanLabel, 'A + B');
    });

    test('删除记录时用量行一并级联删除', () async {
      final a = await harness.addBeanWithBatch();
      final logId = (await harness.logs.save(
        makeLog(beanId: a.beanId, batchId: a.batchId, doseGrams: 15),
      )).brewLogId;

      await harness.logs.delete(logId);

      final rows = await harness.db.select(harness.db.brewLogBeans).get();
      expect(rows, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // 决策 3：0.1g 精度
  // -------------------------------------------------------------------------
  group('决策 3：克数按 0.1g 归一', () {
    test('roundGrams 归一到 0.1', () {
      expect(roundGrams(15.04), closeTo(15.0, 1e-9));
      expect(roundGrams(15.06), closeTo(15.1, 1e-9));
      expect(roundGrams(184.99999999999997), closeTo(185.0, 1e-9));
      expect(roundGrams(0.05), closeTo(0.1, 1e-9));
    });

    test('反复扣减 0.1g 不累积浮点误差', () async {
      final a = await harness.addBeanWithBatch(remainingGrams: 10);

      // 30 × 0.1g = 3g，应从 10 精确落到 7，而不是 6.999999… 或 7.000001…
      for (var i = 0; i < 30; i++) {
        await harness.beans.adjustStock(a.beanId, 0.1, batchId: a.batchId);
      }

      final batch = await harness.beans.getBatch(a.batchId);
      expect(batch!.remainingGrams, 7.0);
      expect(batch.remainingGrams.toString(), '7.0');
    });

    test('扣满 100 次 0.1g 后精确归零', () async {
      final a = await harness.addBeanWithBatch(remainingGrams: 10);

      for (var i = 0; i < 100; i++) {
        await harness.beans.adjustStock(a.beanId, 0.1, batchId: a.batchId);
      }

      final batch = await harness.beans.getBatch(a.batchId);
      expect(batch!.remainingGrams, 0, reason: '反复扣减应能精确落到 0');
    });

    test('回补也保持 0.1 精度', () async {
      final a = await harness.addBeanWithBatch(remainingGrams: 10);

      await harness.beans.adjustStock(a.beanId, 0.3, batchId: a.batchId);
      await harness.beans.adjustStock(a.beanId, -0.2, batchId: a.batchId);

      final batch = await harness.beans.getBatch(a.batchId);
      expect(batch!.remainingGrams, 9.9);
      expect(batch.remainingGrams.toString(), '9.9');
    });

    test('扣减 0.3 x 3 后余量是规整值', () async {
      final a = await harness.addBeanWithBatch(remainingGrams: 10);

      for (var i = 0; i < 3; i++) {
        await harness.beans.adjustStock(a.beanId, 0.3, batchId: a.batchId);
      }

      final batch = await harness.beans.getBatch(a.batchId);
      expect(batch!.remainingGrams, closeTo(9.1, 1e-9));
      // 不能出现 9.100000000000001 这种
      expect(batch.remainingGrams.toString(), '9.1');
    });
  });

  // -------------------------------------------------------------------------
  // 决策 5：新增豆子强制首个批次
  // -------------------------------------------------------------------------
  group('决策 5：豆子与批次的关系', () {
    test('新豆子可以带首个批次一起建', () async {
      final a = await harness.addBeanWithBatch(
        name: '花魁',
        roastDate: DateTime(2026, 1, 1),
        remainingGrams: 200,
      );

      final withBatches = await harness.beans.getWithBatches(a.beanId);
      expect(withBatches!.batches, hasLength(1));
      expect(withBatches.batches.single.remainingGrams, 200);
      expect(withBatches.batches.single.roastDate, DateTime(2026, 1, 1));
    });

    test('批次数量会聚合到豆子上', () async {
      final a = await harness.addBeanWithBatch(name: '花魁');
      await harness.beans.saveBatch(
        makeBatch(beanId: a.beanId, remainingGrams: 100),
      );

      final bean = await harness.beans.getById(a.beanId);
      expect(bean!.batchCount, 2);

      final list = await harness.beans.getAll();
      expect(list.single.batchCount, 2);
    });

    test('删除豆子级联删除它的批次', () async {
      final a = await harness.addBeanWithBatch();
      await harness.beans.saveBatch(makeBatch(beanId: a.beanId));

      await harness.beans.delete(a.beanId);

      final rows = await harness.db.select(harness.db.beanBatches).get();
      expect(rows, isEmpty);
    });

    test('复购：给同一支豆子加第二个批次', () async {
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

      final withBatches = await harness.beans.getWithBatches(a.beanId);
      expect(withBatches!.batches, hasLength(2));
      expect(withBatches.totalRemaining, 450);
      expect(withBatches.latestRoastDate, DateTime(2026, 3, 1));
      expect(withBatches.bean.batchCount, 2, reason: '豆库里仍是一款豆子，不是两支重复的');
    });
  });

  // -------------------------------------------------------------------------
  // 决策 7：换批次扣减要显式提示
  // -------------------------------------------------------------------------
  group('决策 7：指定批次不存在时显式告知', () {
    test('批次存在时不报 fallback', () async {
      final a = await harness.addBeanWithBatch(remainingGrams: 100);

      final result = await harness.beans.adjustStock(
        a.beanId,
        15,
        batchId: a.batchId,
      );

      expect(result.batchFound, isTrue);
      expect(result.usedFallbackBatch, isFalse);
      expect(result.fallbackFromBatchId, isNull);
      expect(result.after, 85);
    });

    test('指定批次已被删除 → 扣到别的批次，并标记来源', () async {
      // 一个只有余量、没有烘焙日期的批次；再建一个更新的批次。
      final a = await harness.addBeanWithBatch(
        remainingGrams: 50,
        roastDate: null,
      );
      final newerBatchId = await harness.beans.saveBatch(
        makeBatch(beanId: a.beanId, remainingGrams: 80, roastDate: null),
      );

      // 请求一个不存在的批次
      final result = await harness.beans.adjustStock(
        a.beanId,
        10,
        batchId: 99999,
      );

      expect(result.usedFallbackBatch, isTrue, reason: '必须让 UI 能提示用户');
      expect(result.fallbackFromBatchId, 99999);
      expect(
        result.batchId,
        newerBatchId,
        reason: '两个批次烘焙日期都为空时，应按创建时间取更新的那一袋',
      );
      expect(result.after, 70);
    });

    test('拼配时被删除的豆子不再参与扣减，其余豆子正常扣', () async {
      final a = await harness.addBeanWithBatch(name: 'A', remainingGrams: 100);
      final b = await harness.addBeanWithBatch(name: 'B', remainingGrams: 100);

      // 建一条 A + B 的拼配记录，然后删掉 B
      final logId = (await harness.logs.save(
        makeLog(
          beanId: a.beanId,
          doseGrams: 20,
          beanUsages: <BeanUsage>[
            BeanUsage(beanId: a.beanId, batchId: a.batchId, doseGrams: 14),
            BeanUsage(beanId: b.beanId, batchId: b.batchId, doseGrams: 6),
          ],
        ),
      )).brewLogId;
      await harness.beans.delete(b.beanId);
      expect((await harness.beans.getBatch(a.batchId))!.remainingGrams, 86);

      // 把 A 的粉量改成 20：只应补扣 A 的差值 6g
      final saved = await harness.logs.getById(logId);
      final result = await harness.logs.save(
        saved!.copyWith(
          beanUsages: <BeanUsage>[
            BeanUsage(beanId: a.beanId, batchId: a.batchId, doseGrams: 20),
          ],
        ),
      );

      expect(result.hasBatchFallback, isFalse, reason: '已删除的豆子不进扣减流程，所以不该报换批次');
      expect((await harness.beans.getBatch(a.batchId))!.remainingGrams, 80);
    });

    test('豆子一个批次都没有时不报 fallback（只是没扣成）', () async {
      final beanId = await harness.beans.save(makeBean(name: '无批次豆'));

      final result = await harness.beans.adjustStock(beanId, 15);

      expect(result.batchFound, isFalse);
      expect(result.usedFallbackBatch, isFalse, reason: '本来就没指定批次');
      expect(result.applied, 0);
    });
  });

  // -------------------------------------------------------------------------
  // 决策 4：保留烘焙快照
  // -------------------------------------------------------------------------
  group('决策 4：烘焙快照', () {
    test('记录里存的烘焙日期是写入时的值', () async {
      final a = await harness.addBeanWithBatch(
        roastDate: DateTime(2026, 1, 10),
        roastLevel: RoastLevel.light,
      );

      final logId = (await harness.logs.save(
        makeLog(beanId: a.beanId, batchId: a.batchId, doseGrams: 15),
      )).brewLogId;

      final log = await harness.logs.getById(logId);
      expect(log!.beanUsages.single.roastDate, DateTime(2026, 1, 10));
    });

    test('批次烘焙日期之后被改，历史记录的快照不变', () async {
      final a = await harness.addBeanWithBatch(
        roastDate: DateTime(2026, 1, 10),
      );
      final logId = (await harness.logs.save(
        makeLog(beanId: a.beanId, batchId: a.batchId, doseGrams: 15),
      )).brewLogId;

      // 改批次烘焙日期
      final batch = await harness.beans.getBatch(a.batchId);
      await harness.beans.saveBatch(
        batch!.copyWith(roastDate: DateTime(2026, 2, 20)),
      );

      final log = await harness.logs.getById(logId);
      expect(
        log!.beanUsages.single.roastDate,
        DateTime(2026, 1, 10),
        reason: '历史应记录当时的值',
      );
    });
  });

  // -------------------------------------------------------------------------
  // 多豆冲煮的扣减
  // -------------------------------------------------------------------------
  group('多豆冲煮：按各自粉量扣减', () {
    test('拼配时两支豆子分别扣自己的粉量', () async {
      final a = await harness.addBeanWithBatch(name: 'A', remainingGrams: 100);
      final b = await harness.addBeanWithBatch(name: 'B', remainingGrams: 100);

      await harness.logs.save(
        makeLog(
          beanId: a.beanId,
          doseGrams: 20,
          beanUsages: <BeanUsage>[
            BeanUsage(beanId: a.beanId, batchId: a.batchId, doseGrams: 14),
            BeanUsage(beanId: b.beanId, batchId: b.batchId, doseGrams: 6),
          ],
        ),
      );

      expect((await harness.beans.getBatch(a.batchId))!.remainingGrams, 86);
      expect((await harness.beans.getBatch(b.batchId))!.remainingGrams, 94);
    });

    test('编辑拼配比例时按差值补扣', () async {
      final a = await harness.addBeanWithBatch(name: 'A', remainingGrams: 100);
      final b = await harness.addBeanWithBatch(name: 'B', remainingGrams: 100);
      final logId = (await harness.logs.save(
        makeLog(
          beanId: a.beanId,
          doseGrams: 20,
          beanUsages: <BeanUsage>[
            BeanUsage(beanId: a.beanId, batchId: a.batchId, doseGrams: 14),
            BeanUsage(beanId: b.beanId, batchId: b.batchId, doseGrams: 6),
          ],
        ),
      )).brewLogId;

      // 改成 A 10g + B 10g
      final saved = await harness.logs.getById(logId);
      await harness.logs.save(
        saved!.copyWith(
          beanUsages: <BeanUsage>[
            BeanUsage(beanId: a.beanId, batchId: a.batchId, doseGrams: 10),
            BeanUsage(beanId: b.beanId, batchId: b.batchId, doseGrams: 10),
          ],
        ),
      );

      // A: 100-14=86，回到 10 → 回补 4 → 90
      // B: 100-6=94，增到 10 → 再扣 4 → 90
      expect((await harness.beans.getBatch(a.batchId))!.remainingGrams, 90);
      expect((await harness.beans.getBatch(b.batchId))!.remainingGrams, 90);
    });

    test('去掉一支豆子时它被回补', () async {
      final a = await harness.addBeanWithBatch(name: 'A', remainingGrams: 100);
      final b = await harness.addBeanWithBatch(name: 'B', remainingGrams: 100);
      final logId = (await harness.logs.save(
        makeLog(
          beanId: a.beanId,
          doseGrams: 20,
          beanUsages: <BeanUsage>[
            BeanUsage(beanId: a.beanId, batchId: a.batchId, doseGrams: 14),
            BeanUsage(beanId: b.beanId, batchId: b.batchId, doseGrams: 6),
          ],
        ),
      )).brewLogId;

      // 只留 A
      final saved = await harness.logs.getById(logId);
      await harness.logs.save(
        saved!.copyWith(
          beanId: a.beanId,
          beanUsages: <BeanUsage>[
            BeanUsage(beanId: a.beanId, batchId: a.batchId, doseGrams: 14),
          ],
        ),
      );

      expect((await harness.beans.getBatch(a.batchId))!.remainingGrams, 86);
      expect(
        (await harness.beans.getBatch(b.batchId))!.remainingGrams,
        100,
        reason: '被移除的豆子应回补',
      );
    });

    test('关闭自动扣减时拼配也不扣', () async {
      final a = await harness.addBeanWithBatch(name: 'A', remainingGrams: 100);

      await harness.logs.save(
        makeLog(beanId: a.beanId, batchId: a.batchId, doseGrams: 15),
        autoDeductStock: false,
      );

      expect((await harness.beans.getBatch(a.batchId))!.remainingGrams, 100);
    });
  });

  // -------------------------------------------------------------------------
  // 收藏（决策 5 的配套，用于复购时快速找到常买的豆子）
  // -------------------------------------------------------------------------
  group('收藏与筛选', () {
    test('可以切换收藏并只列收藏', () async {
      final a = await harness.addBeanWithBatch(name: '常买');
      await harness.addBeanWithBatch(name: '偶尔买');

      await harness.beans.setFavorite(a.beanId, true);

      final favorites = await harness.beans.getFavorites();
      expect(favorites, hasLength(1));
      expect(favorites.single.name, '常买');
      expect(favorites.single.isFavorite, isTrue);
    });
  });
}
