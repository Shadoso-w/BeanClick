import 'package:beanclick/app.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/features/record/brew_log_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

/// M2.10 研磨刻度：`圈 + click` 输入、相对刻度、ⓘ 算式、圈只收正整数。
///
/// 直接以 `existing`/`prefill` 打开表单来带出磨豆机快照，避免在 widget 测试里
/// 操作 `DropdownButtonFormField` 的浮层菜单（那层菜单不好稳定定位）。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  /// 表单要能按 id 查到磨豆机，所以先落一台真磨豆机。
  ///
  /// 记录里的**快照**才是换算依据（老研磨度关联老记录），所以这里让快照值
  /// 可以和磨豆机当前的值不同，用来证明读的是快照。
  Future<int> addGrinder({
    double? zeroPoint = 0,
    int? clicksPerRevolution = 30,
  }) => harness.container
      .read(grinderRepositoryProvider)
      .save(
        Grinder(
          brand: 'Comandante',
          model: 'C40',
          scaleUnit: GrindScaleUnit.click,
          zeroPoint: zeroPoint,
          clicksPerRevolution: clicksPerRevolution,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

  Future<void> pumpForm(
    WidgetTester tester, {
    BrewLog? existing,
    BrewLog? prefill,
  }) async {
    await tester.pumpWidget(
      harness.app(
        MaterialApp(
          home: BrewLogFormPage(existing: existing, prefill: prefill),
        ),
      ),
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// 读回「相对刻度」那一行提示。
  Future<String> grindHelper(WidgetTester tester) async {
    final Finder helper = find.textContaining('相对刻度');
    await tester.scrollTo(helper);
    return tester.widget<Text>(helper).data!;
  }

  testWidgets('圈 + click → 提示行给相对刻度（每圈 30、零点 0）', (tester) async {
    final int grinderId = await addGrinder();
    await pumpForm(
      tester,
      existing: BrewLog(
        method: BrewMethod.pourOver,
        grinderId: grinderId,
        grinderZeroPointSnapshot: 0,
        grinderClicksPerRevolutionSnapshot: 30,
        brewedAt: DateTime(2026, 1, 1, 8),
        createdAt: DateTime(2026, 1, 1, 8),
        updatedAt: DateTime(2026, 1, 1, 8),
      ),
    );

    // 标签统一叫「研磨刻度」，单位写在框里。
    expect(find.text('研磨刻度'), findsOneWidget);
    expect(find.text('圈'), findsOneWidget);
    expect(find.text('click'), findsNWidgets(2));

    await tester.fillField('brew.grindSetting', '1');
    await tester.fillField('brew.grindClicks', '15');
    await tester.pumpAndSettle();

    // 1 × 30 + 15 − 0 = 45
    expect(await grindHelper(tester), '相对刻度 45 click');

    await harness.finish(tester);
  });

  testWidgets('零点不为 0 时是**减**零点（1 × 30 + 5 − 5 = 30）', (tester) async {
    final int grinderId = await addGrinder(zeroPoint: 5);
    await pumpForm(
      tester,
      existing: BrewLog(
        method: BrewMethod.pourOver,
        grinderId: grinderId,
        grinderZeroPointSnapshot: 5,
        grinderClicksPerRevolutionSnapshot: 30,
        brewedAt: DateTime(2026, 1, 1, 8),
        createdAt: DateTime(2026, 1, 1, 8),
        updatedAt: DateTime(2026, 1, 1, 8),
      ),
    );

    await tester.fillField('brew.grindSetting', '1');
    await tester.fillField('brew.grindClicks', '5');
    await tester.pumpAndSettle();

    expect(await grindHelper(tester), '相对刻度 30 click');

    await harness.finish(tester);
  });

  testWidgets('留空 = 0 圈：只填 click 也能算', (tester) async {
    final int grinderId = await addGrinder();
    await pumpForm(
      tester,
      existing: BrewLog(
        method: BrewMethod.pourOver,
        grinderId: grinderId,
        grinderZeroPointSnapshot: 0,
        grinderClicksPerRevolutionSnapshot: 30,
        brewedAt: DateTime(2026, 1, 1, 8),
        createdAt: DateTime(2026, 1, 1, 8),
        updatedAt: DateTime(2026, 1, 1, 8),
      ),
    );

    await tester.fillField('brew.grindClicks', '15');
    await tester.pumpAndSettle();

    expect(find.text('留空'), findsOneWidget, reason: '圈框的 hint');
    expect(await grindHelper(tester), '相对刻度 15 click');

    await harness.finish(tester);
  });

  testWidgets('ⓘ 弹窗给出公式、这台磨豆机的参数与结果', (tester) async {
    final int grinderId = await addGrinder();
    await pumpForm(
      tester,
      existing: BrewLog(
        method: BrewMethod.pourOver,
        grinderId: grinderId,
        grinderZeroPointSnapshot: 0,
        grinderClicksPerRevolutionSnapshot: 30,
        brewedAt: DateTime(2026, 1, 1, 8),
        createdAt: DateTime(2026, 1, 1, 8),
        updatedAt: DateTime(2026, 1, 1, 8),
      ),
    );

    await tester.fillField('brew.grindSetting', '1');
    await tester.fillField('brew.grindClicks', '15');
    await tester.tapKey('brew.grindInfo');

    expect(find.text('研磨刻度怎么算'), findsOneWidget);
    expect(find.text('相对刻度 = 圈 × 每圈 click + click − 零点'), findsOneWidget);
    expect(find.text('这台磨豆机：每圈 30 click · 零点 0'), findsOneWidget);
    expect(find.text('这次填写：1 圈 + 15 click'), findsOneWidget);
    expect(find.text('结果：45 click'), findsOneWidget);

    await tester.tapTextScrolled('知道了');
    await harness.finish(tester);
  });

  testWidgets('圈填 0 时报错并拦住保存', (tester) async {
    final int grinderId = await addGrinder();
    await pumpForm(
      tester,
      existing: BrewLog(
        method: BrewMethod.pourOver,
        grinderId: grinderId,
        grinderZeroPointSnapshot: 0,
        grinderClicksPerRevolutionSnapshot: 30,
        brewedAt: DateTime(2026, 1, 1, 8),
        createdAt: DateTime(2026, 1, 1, 8),
        updatedAt: DateTime(2026, 1, 1, 8),
      ),
    );

    await tester.fillField('brew.grindSetting', '0');
    await tester.tapSaveButton();

    expect(find.textContaining('圈只能是正整数'), findsOneWidget);
    // 没被保存：这个测试用的是内存里的 existing（没落库），落库列表应保持空。
    expect(
      await harness.container.read(brewLogRepositoryProvider).getAll(),
      isEmpty,
      reason: '校验没过就不应该写库',
    );

    await harness.finish(tester);
  });

  testWidgets('旧记录的小数圈数打开时折成「整数圈 + click」', (tester) async {
    final int grinderId = await addGrinder();
    await pumpForm(
      tester,
      existing: BrewLog(
        method: BrewMethod.pourOver,
        grinderId: grinderId,
        grinderZeroPointSnapshot: 0,
        grinderClicksPerRevolutionSnapshot: 30,
        grindSetting: 1.5,
        brewedAt: DateTime(2026, 1, 1, 8),
        createdAt: DateTime(2026, 1, 1, 8),
        updatedAt: DateTime(2026, 1, 1, 8),
      ),
    );

    expect(await tester.readField('brew.grindSetting'), '1');
    expect(await tester.readField('brew.grindClicks'), '15');
    expect(await grindHelper(tester), '相对刻度 45 click');

    await harness.finish(tester);
  });

  testWidgets('每圈 click 缺失的存量旧机器：给提示，不瞎算', (tester) async {
    final int grinderId = await addGrinder(clicksPerRevolution: null);
    await pumpForm(
      tester,
      existing: BrewLog(
        method: BrewMethod.pourOver,
        grinderId: grinderId,
        grinderZeroPointSnapshot: 0,
        grindSetting: 2,
        grindClicks: 2,
        brewedAt: DateTime(2026, 1, 1, 8),
        createdAt: DateTime(2026, 1, 1, 8),
        updatedAt: DateTime(2026, 1, 1, 8),
      ),
    );

    expect(find.textContaining('还没填「每圈几 click」'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('记录卡片第二行只给一个相对刻度值', (tester) async {
    final int grinderId = await addGrinder();
    final a = await harness.addBeanWithBatch(name: '耶菲雪加');
    await harness.addBrewLog(
      beanId: a.beanId,
      batchId: a.batchId,
      grinderId: grinderId,
      doseGrams: 15,
      brewedAt: DateTime(2026, 1, 1, 8),
    );
    // 补上研磨读数（夹具只写粉量）。
    final BrewLog log =
        (await harness.container.read(brewLogRepositoryProvider).getAll())
            .single;
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          log.copyWith(
            grinderZeroPointSnapshot: 0,
            grinderClicksPerRevolutionSnapshot: 30,
            grindSetting: 2,
            grindClicks: 15,
          ),
        );

    // 用完整的 App（带 zh_CN 本地化），记录页就是首页 tab。
    await tester.pumpWidget(harness.app(const BeanClickApp()));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    // 2 × 30 + 15 − 0 = 75，且不再出现「30 click + 15 click」那种两段写法。
    expect(find.textContaining('相对刻度 75 click'), findsOneWidget);
    expect(find.textContaining('click + 15 click'), findsNothing);

    await harness.finish(tester);
  });

  /// M3-T15：相对刻度改用**磨豆机当前的校准**（零点 / 每圈 click），
  /// 磨豆机被删或该字段为空时回落到记录里的快照。
  ///
  /// 两个值各回各的：当前值缺一个不会连带另一个也回落。
  group('M3-T15 相对刻度用当前校准', () {
    /// 整屏 App：记录页就是首页 tab，直接断言卡片第二行的刻度。
    Future<void> pumpApp(WidgetTester tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
    }

    /// 再等几帧 drift 的流查询把新状态推上来（删磨豆机之后用）。
    Future<void> settle(WidgetTester tester) async {
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
    }

    /// 造一条「2 圈 + 15 click」的记录；快照值可以与磨豆机当前值不同。
    Future<void> seedLog({
      required int grinderId,
      required double zeroPointSnapshot,
      required int clicksPerRevolutionSnapshot,
      double turns = 2,
      int clicks = 15,
    }) async {
      final a = await harness.addBeanWithBatch(name: '耶菲雪加');
      final int logId = await harness.addBrewLog(
        beanId: a.beanId,
        batchId: a.batchId,
        grinderId: grinderId,
        doseGrams: 15,
        brewedAt: DateTime(2026, 1, 1, 8),
      );
      final BrewLog log = (await harness.container
          .read(brewLogRepositoryProvider)
          .getById(logId))!;
      await harness.container
          .read(brewLogRepositoryProvider)
          .save(
            log.copyWith(
              grinderZeroPointSnapshot: zeroPointSnapshot,
              grinderClicksPerRevolutionSnapshot: clicksPerRevolutionSnapshot,
              grindSetting: turns,
              grindClicks: clicks,
            ),
          );
    }

    testWidgets('① 改了零点后，旧记录卡片按磨豆机现在的零点显示', (tester) async {
      // 磨豆机现在零点 5；这条记录当时的快照是 0。
      final int grinderId = await addGrinder(zeroPoint: 5);
      await seedLog(
        grinderId: grinderId,
        zeroPointSnapshot: 0,
        clicksPerRevolutionSnapshot: 30,
      );

      await pumpApp(tester);

      // 2 × 30 + 15 − **5**（当前零点）= 70，而不是快照算出的 75。
      expect(find.textContaining('相对刻度 70 click'), findsOneWidget);
      expect(find.textContaining('相对刻度 75 click'), findsNothing);

      await harness.finish(tester);
    });

    testWidgets('② 磨豆机被删时回落记录里的快照', (tester) async {
      final int grinderId = await addGrinder(zeroPoint: 0);
      await seedLog(
        grinderId: grinderId,
        zeroPointSnapshot: 12,
        clicksPerRevolutionSnapshot: 30,
      );

      await pumpApp(tester);
      // 磨豆机还在：用当前零点 0 → 2 × 30 + 15 − 0 = 75。
      expect(find.textContaining('相对刻度 75 click'), findsOneWidget);

      await harness.container.read(grinderRepositoryProvider).delete(grinderId);
      await settle(tester);

      // 磨豆机没了：回落记录里的快照零点 12 → 2 × 30 + 15 − 12 = 63。
      expect(find.textContaining('相对刻度 63 click'), findsOneWidget);
      expect(find.textContaining('相对刻度 75 click'), findsNothing);

      await harness.finish(tester);
    });

    testWidgets('③ 每圈 click 同理：当前值优先，磨豆机被删后回落快照', (tester) async {
      final int grinderId = await addGrinder(
        clicksPerRevolution: 30,
        zeroPoint: 0,
      );
      await seedLog(
        grinderId: grinderId,
        zeroPointSnapshot: 0,
        clicksPerRevolutionSnapshot: 20,
        turns: 2,
        clicks: 5,
      );

      await pumpApp(tester);
      // 当前每圈 30 → 2 × 30 + 5 = 65。
      expect(find.textContaining('相对刻度 65 click'), findsOneWidget);

      await harness.container.read(grinderRepositoryProvider).delete(grinderId);
      await settle(tester);

      // 回落快照的每圈 20 → 2 × 20 + 5 = 45。
      expect(find.textContaining('相对刻度 45 click'), findsOneWidget);
      expect(find.textContaining('相对刻度 65 click'), findsNothing);

      await harness.finish(tester);
    });

    testWidgets('④ 表单提示同样按当前校准（编辑旧记录，快照零点 0 vs 当前 5）', (tester) async {
      final int grinderId = await addGrinder(zeroPoint: 5);
      await pumpForm(
        tester,
        existing: BrewLog(
          method: BrewMethod.pourOver,
          grinderId: grinderId,
          grinderZeroPointSnapshot: 0,
          grinderClicksPerRevolutionSnapshot: 30,
          grindSetting: 2,
          grindClicks: 15,
          brewedAt: DateTime(2026, 1, 1, 8),
          createdAt: DateTime(2026, 1, 1, 8),
          updatedAt: DateTime(2026, 1, 1, 8),
        ),
      );

      // 2 × 30 + 15 − 5（当前零点）= 70。
      expect(await grindHelper(tester), '相对刻度 70 click');

      await harness.finish(tester);
    });

    testWidgets('⑤ 磨豆机已被删除的表单：回落记录里的快照', (tester) async {
      await pumpForm(
        tester,
        existing: BrewLog(
          method: BrewMethod.pourOver,
          // 这台磨豆机已经不在库里了。
          grinderId: 999,
          grinderZeroPointSnapshot: 12,
          grinderClicksPerRevolutionSnapshot: 30,
          grindSetting: 2,
          grindClicks: 15,
          brewedAt: DateTime(2026, 1, 1, 8),
          createdAt: DateTime(2026, 1, 1, 8),
          updatedAt: DateTime(2026, 1, 1, 8),
        ),
      );

      // 2 × 30 + 15 − 12（快照零点）= 63。
      expect(await grindHelper(tester), '相对刻度 63 click');

      await harness.finish(tester);
    });
  });
}
