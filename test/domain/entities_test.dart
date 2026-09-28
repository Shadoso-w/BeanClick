import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// 领域实体的派生值与 JSON 往返。
///
/// 模型要点：豆子只有身份信息；烘焙日期、烘焙度、余量、价格都在批次上。
void main() {
  group('CoffeeBean 派生值', () {
    test('originLabel 拼出产地与处理法', () {
      final bean = CoffeeBean(
        name: '耶加雪菲',
        origin: '埃塞俄比亚',
        processes: const <ProcessMethod>[ProcessMethod.washed],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(bean.originLabel, '埃塞俄比亚 · 水洗');
    });

    test('只有产地时 originLabel 只有产地', () {
      final bean = CoffeeBean(
        name: '耶加雪菲',
        origin: '埃塞俄比亚',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(bean.originLabel, '埃塞俄比亚');
    });

    test('都没有时 originLabel 返回 null', () {
      final bean = CoffeeBean(
        name: '耶加雪菲',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(bean.originLabel, isNull);
    });

    test('batchCount 默认 0，可由 copyWith 设置', () {
      final bean = CoffeeBean(
        name: '耶加雪菲',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(bean.batchCount, 0);
      expect(bean.copyWith(batchCount: 3).batchCount, 3);
    });

    test('isFavorite 默认 false', () {
      final bean = CoffeeBean(
        name: '耶加雪菲',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(bean.isFavorite, isFalse);
    });
  });

  group('BeanBatch 派生值', () {
    BeanBatch makeBatch({
      DateTime? roastDate,
      double remainingGrams = 200,
      double? initialGrams = 200,
    }) => BeanBatch(
      beanId: 1,
      roastDate: roastDate,
      remainingGrams: remainingGrams,
      initialGrams: initialGrams,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('ageInDays 按烘焙日期计算', () {
      final batch = makeBatch(roastDate: DateTime(2026, 1, 1));

      expect(batch.ageInDays(now: DateTime(2026, 1, 11)), 10);
    });

    test('没有烘焙日期时 ageInDays 返回 null', () {
      expect(makeBatch().ageInDays(now: DateTime(2026, 1, 11)), isNull);
    });

    test('consumedRatio 用初始克数算消耗比例', () {
      expect(
        makeBatch(remainingGrams: 50).consumedRatio(),
        closeTo(0.75, 1e-9),
      );
    });

    test('缺少初始克数时 consumedRatio 返回 null', () {
      expect(makeBatch(initialGrams: null).consumedRatio(), isNull);
    });

    test('consumedRatio 不会超过 1', () {
      expect(makeBatch(remainingGrams: 0).consumedRatio(), 1.0);
    });

    test('isEmpty 判断是否用完', () {
      expect(makeBatch(remainingGrams: 0).isEmpty, isTrue);
      expect(makeBatch(remainingGrams: 0.1).isEmpty, isFalse);
    });
  });

  group('Grinder 展示格式', () {
    test('手册 §7 的格式：C40 / 22 click / 零点 0', () {
      final grinder = Grinder(
        brand: 'Comandante',
        model: 'C40',
        scaleUnit: GrindScaleUnit.click,
        zeroPoint: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(
        grinder.displayName(grindSetting: 22),
        'Comandante C40 / 22 click / 零点 0',
      );
    });

    test('不传刻度时只展示机型与零点', () {
      final grinder = Grinder(
        brand: 'Comandante',
        model: 'C40',
        zeroPoint: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(grinder.displayName(), 'Comandante C40 / 零点 0');
    });

    test('非整数刻度保留小数', () {
      final grinder = Grinder(
        brand: '1Zpresso',
        model: 'JX-Pro',
        scaleUnit: GrindScaleUnit.number,
        zeroPoint: 1.5,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(
        grinder.displayName(grindSetting: 3.5),
        '1Zpresso JX-Pro / 3.5 刻度 / 零点 1.5',
      );
    });
  });

  group('BrewLog 派生值', () {
    BrewLog makeLog({
      List<BeanUsage> usages = const <BeanUsage>[],
      double? doseGrams = 15,
      double? waterGrams = 240,
      double? ratio,
      int? totalTimeSeconds = 155,
    }) => BrewLog(
      doseGrams: doseGrams,
      waterGrams: waterGrams,
      ratio: ratio,
      totalTimeSeconds: totalTimeSeconds,
      brewedAt: DateTime(2026, 1, 1),
      beanUsages: usages,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('effectiveRatio 优先取已存值', () {
      expect(makeLog(ratio: 15).effectiveRatio, 15);
    });

    test('未存 ratio 时按 水量/粉量 推算', () {
      expect(makeLog().effectiveRatio, 16);
    });

    test('缺少粉量或水量时 effectiveRatio 返回 null', () {
      expect(makeLog(waterGrams: null).effectiveRatio, isNull);
    });

    test('formattedTime 输出 m:ss', () {
      expect(makeLog(totalTimeSeconds: 155).formattedTime, '2:35');
    });

    test('formattedTime 对不足 10 秒补零', () {
      expect(makeLog(totalTimeSeconds: 65).formattedTime, '1:05');
    });

    test('单支豆子时 isBlend 为 false，beanLabel 是豆子名', () {
      final log = makeLog(
        usages: const <BeanUsage>[
          BeanUsage(beanId: 1, doseGrams: 15, beanName: '花魁'),
        ],
      );

      expect(log.isBlend, isFalse);
      expect(log.beanLabel, '花魁');
    });

    test('多支豆子时 isBlend 为 true，beanLabel 用 + 连接', () {
      final log = makeLog(
        usages: const <BeanUsage>[
          BeanUsage(beanId: 1, doseGrams: 11, beanName: '花魁'),
          BeanUsage(beanId: 2, doseGrams: 4, beanName: '曼特宁'),
        ],
      );

      expect(log.isBlend, isTrue);
      expect(log.beanLabel, '花魁 + 曼特宁');
    });

    test('没有用量时 beanLabel 返回 null', () {
      expect(makeLog().beanLabel, isNull);
    });
  });

  group('BeanUsage 的快照与降级（决策 2）', () {
    test('豆子还在时用名称', () {
      const usage = BeanUsage(beanId: 1, doseGrams: 15, beanName: '花魁');

      expect(usage.label, '花魁');
    });

    test('豆子被删除后仍能用快照名显示', () {
      const usage = BeanUsage(beanId: null, doseGrams: 15, beanName: '花魁');

      expect(usage.label, '花魁');
      expect(usage.beanId, isNull);
    });

    test('连快照都没有时才退化成「已删除的豆子」', () {
      const usage = BeanUsage(beanId: null, doseGrams: 15);

      expect(usage.label, '已删除的豆子');
    });

    test('有 id 但没名字时退化成 id', () {
      const usage = BeanUsage(beanId: 7, doseGrams: 15);

      expect(usage.label, '豆子#7');
    });
  });

  group('克数精度：0.1g 归一（决策 3）', () {
    test('roundGrams 归一到 0.1', () {
      expect(roundGrams(15.04), closeTo(15.0, 1e-9));
      expect(roundGrams(15.06), closeTo(15.1, 1e-9));
      expect(roundGrams(0.05), closeTo(0.1, 1e-9));
    });

    test('消除浮点误差累积出的尾数', () {
      expect(roundGrams(184.99999999999997), closeTo(185.0, 1e-9));
      // 这是 (10 - 0.1 - 0.1 - 0.1) 这类运算的典型结果
      expect(roundGrams(9.700000000000001), 9.7);
      expect(roundGrams(9.700000000000001).toString(), '9.7');
    });

    test('不能用乘法实现：97 * 0.1 本身就不是 9.7', () {
      // 记录这个事实，防止将来有人「优化」成 (v/0.1).round()*0.1
      expect(97 * 0.1 == 9.7, isFalse);
      expect(double.parse((97 * 0.1).toStringAsFixed(1)) == 9.7, isTrue);
    });
  });

  group('JSON 往返（导出功能的基础）', () {
    test('CoffeeBean 往返后相等', () {
      final bean = CoffeeBean(
        id: 1,
        name: '耶加雪菲',
        origin: '埃塞俄比亚',
        farm: '科契尔',
        processes: const <ProcessMethod>[ProcessMethod.washed],
        flavorTags: const ['柑橘', '花香'],
        isFavorite: true,
        notes: '手冲首选',
        createdAt: DateTime(2026, 1, 1, 9),
        updatedAt: DateTime(2026, 1, 2, 10),
      );

      expect(CoffeeBean.fromJson(bean.toJson()), bean);
    });

    test('BeanBatch 往返后相等', () {
      final batch = BeanBatch(
        id: 2,
        beanId: 1,
        roastDate: DateTime(2026, 1, 1),
        roastLevel: RoastLevel.light,
        remainingGrams: 150.5,
        initialGrams: 200,
        price: 88,
        createdAt: DateTime(2026, 1, 1, 9),
        updatedAt: DateTime(2026, 1, 1, 9),
      );

      expect(BeanBatch.fromJson(batch.toJson()), batch);
    });

    test('Grinder 往返后相等', () {
      final grinder = Grinder(
        id: 2,
        brand: 'Comandante',
        model: 'C40',
        burrType: '锥刀',
        scaleUnit: GrindScaleUnit.click,
        zeroPoint: 0,
        clicksPerRevolution: 30,
        createdAt: DateTime(2026, 1, 1, 9),
        updatedAt: DateTime(2026, 1, 1, 9),
      );

      expect(Grinder.fromJson(grinder.toJson()), grinder);
    });

    test('BrewLog 往返后相等（含多豆、分段注水与专业字段）', () {
      final log = BrewLog(
        id: 3,
        beanId: 1,
        grinderId: 2,
        method: BrewMethod.pourOver,
        grindSetting: 22,
        grindClicks: 2,
        doseGrams: 15,
        waterGrams: 240,
        waterTemp: 92,
        totalTimeSeconds: 155,
        dripper: 'V60',
        rating: 5,
        flavorTags: const ['柑橘'],
        brewedAt: DateTime(2026, 1, 3, 8, 30),
        isBest: true,
        tds: 1.35,
        extractionYield: 20.1,
        waterPpm: 80,
        ambientTemp: 24,
        ambientHumidity: 55,
        beanTemp: 22,
        pressure: 1.2,
        pourStages: const <PourStage>[
          PourStage(order: 1, waterGrams: 30, atSecond: 0, note: '闷蒸'),
          PourStage(order: 2, waterGrams: 210, atSecond: 30),
        ],
        beanRoastDate: DateTime(2026, 1, 1),
        beanRoastLevel: RoastLevel.light,
        beanUsages: <BeanUsage>[
          BeanUsage(
            beanId: 1,
            batchId: 10,
            doseGrams: 11,
            beanName: '花魁',
            // 用了 DateTime 就不能是 const
            roastDate: DateTime(2026, 1, 1),
          ),
          const BeanUsage(
            beanId: 2,
            batchId: 11,
            doseGrams: 4,
            beanName: '曼特宁',
          ),
        ],
        createdAt: DateTime(2026, 1, 3, 8, 30),
        updatedAt: DateTime(2026, 1, 3, 8, 30),
      );

      expect(BrewLog.fromJson(log.toJson()), log);
    });

    test('Recipe 往返后相等', () {
      final recipe = Recipe(
        id: 4,
        name: 'V60 四六法',
        method: BrewMethod.pourOver,
        doseGrams: 20,
        waterGrams: 300,
        waterTemp: 92,
        totalTimeSeconds: 210,
        grindSuggestion: '中细，白砂糖粗细',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(Recipe.fromJson(recipe.toJson()), recipe);
    });
  });
}
