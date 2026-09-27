import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoffeeBean 派生值', () {
    test('ageInDays 按烘焙日期计算', () {
      final bean = CoffeeBean(
        name: '耶加雪菲',
        roastDate: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(bean.ageInDays(now: DateTime(2026, 1, 11)), 10);
    });

    test('没有烘焙日期时 ageInDays 返回 null', () {
      final bean = CoffeeBean(
        name: '耶加雪菲',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(bean.ageInDays(now: DateTime(2026, 1, 11)), isNull);
    });

    test('consumedRatio 用初始克数算消耗比例', () {
      final bean = CoffeeBean(
        name: '耶加雪菲',
        initialGrams: 200,
        remainingGrams: 50,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(bean.consumedRatio(), closeTo(0.75, 1e-9));
    });

    test('缺少初始克数时 consumedRatio 返回 null', () {
      final bean = CoffeeBean(
        name: '耶加雪菲',
        remainingGrams: 50,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(bean.consumedRatio(), isNull);
    });

    test('consumedRatio 不会超过 1', () {
      final bean = CoffeeBean(
        name: '耶加雪菲',
        initialGrams: 200,
        remainingGrams: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(bean.consumedRatio(), 1.0);
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
    test('effectiveRatio 优先取已存值', () {
      final log = BrewLog(
        doseGrams: 15,
        waterGrams: 240,
        ratio: 15,
        brewedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(log.effectiveRatio, 15);
    });

    test('未存 ratio 时按 水量/粉量 推算', () {
      final log = BrewLog(
        doseGrams: 15,
        waterGrams: 240,
        brewedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(log.effectiveRatio, 16);
    });

    test('缺少粉量或水量时 effectiveRatio 返回 null', () {
      final log = BrewLog(
        waterGrams: 240,
        brewedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(log.effectiveRatio, isNull);
    });

    test('formattedTime 输出 m:ss', () {
      final log = BrewLog(
        totalTimeSeconds: 155,
        brewedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(log.formattedTime, '2:35');
    });

    test('formattedTime 对不足 10 秒补零', () {
      final log = BrewLog(
        totalTimeSeconds: 65,
        brewedAt: DateTime(2026, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(log.formattedTime, '1:05');
    });
  });

  group('JSON 往返（导出功能的基础）', () {
    test('CoffeeBean 往返后相等', () {
      final bean = CoffeeBean(
        id: 1,
        name: '耶加雪菲',
        origin: '埃塞俄比亚',
        farm: '科契尔',
        process: ProcessMethod.washed,
        roastLevel: RoastLevel.light,
        roastDate: DateTime(2026, 1, 1),
        flavorTags: const ['柑橘', '花香'],
        remainingGrams: 150.5,
        initialGrams: 200,
        price: 88,
        notes: '手冲首选',
        createdAt: DateTime(2026, 1, 1, 9),
        updatedAt: DateTime(2026, 1, 2, 10),
      );

      expect(CoffeeBean.fromJson(bean.toJson()), bean);
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

    test('BrewLog 往返后相等（含分段注水与专业字段）', () {
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
        pourStages: const [
          PourStage(order: 1, waterGrams: 30, atSecond: 0, note: '闷蒸'),
          PourStage(order: 2, waterGrams: 210, atSecond: 30),
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

  group('枚举', () {
    test('BrewMethod 默认主力只有手冲与摩卡壶', () {
      expect(BrewMethod.primary, [BrewMethod.pourOver, BrewMethod.mokaPot]);
    });

    test('fromName 能解析并容忍未知值', () {
      expect(BrewMethod.fromName('mokaPot'), BrewMethod.mokaPot);
      expect(BrewMethod.fromName('不存在的值'), isNull);
      expect(BrewMethod.fromName(null), isNull);
    });

    test('枚举都有中文标签', () {
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
  });
}
