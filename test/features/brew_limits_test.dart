import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/features/record/brew_log_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

/// M3-T26：核心参数上下限抽成同源常量后的**边界**验收。
///
/// 目的有两个：
/// 1. **两端取值合法**（含刻意的 60 分 = 3600 秒，M3-T22）—— 不飘红；
/// 2. **越界给逐字文案** —— 文案必须与重构前逐字一致（沿用既有 19 处断言的同一批串）。
///
/// 手法与 [batch1_ui_test] 的「核心参数超出上下限时报错并拦下保存」一致：
/// 豆库非空但不选豆 → 保存被「请先选一支豆子」拦下 → **表单不弹走**，
/// 于是可以在同一个表单里连续走完所有边界状态。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      harness.app(const MaterialApp(home: BrewLogFormPage())),
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  Future<List<BrewLog>> logs() =>
      harness.container.read(brewLogRepositoryProvider).getAll();

  /// 填一组核心参数；null = 该框留空。
  Future<void> fillAll(
    WidgetTester tester, {
    String? dose,
    String? water,
    String? waterTemp,
    String? minutes,
    String? seconds,
  }) async {
    await tester.fillField('brew.dose', dose ?? '');
    await tester.fillField('brew.water', water ?? '');
    await tester.fillField('brew.waterTemp', waterTemp ?? '');
    await tester.fillField('brew.totalTimeMin', minutes ?? '');
    await tester.fillField('brew.totalTimeSec', seconds ?? '');
  }

  /// 保存并把「范围类报错」的可见性交回给调用方。
  Future<void> save(WidgetTester tester) async {
    await tester.tapSaveButton();
    await tester.pumpAndSettle();
  }

  testWidgets('核心参数：两端取值的边界与越界文案（M3-T26）', (tester) async {
    // 豆库非空但**不选豆**：保存会被「请先选一支豆子」拦住 → 表单留在原地。
    await harness.addBeanWithBatch(name: '花魁');
    await pumpForm(tester);

    // ── 下端全取合法值：0.1 / 0 / 0 / 0 分 0 秒 ──
    await fillAll(
      tester,
      dose: '0.1',
      water: '0',
      waterTemp: '0',
      minutes: '0',
      seconds: '0',
    );
    await save(tester);
    expect(
      find.textContaining('应在'),
      findsNothing,
      reason: '下端点（0.1 / 0 / 0）必须合法',
    );
    expect(
      find.textContaining('请先选一支豆子'),
      findsOneWidget,
      reason: '范围这层放行了，只剩「没选豆子」拦住',
    );

    // ── 上端全取合法值：100 / 2000 / 100 / 60 分 0 秒（= 3600 秒）──
    // 60 分是刻意的（M3-T22）：60:00 = 3600 秒要合法，否则那条上限校验是死代码。
    await fillAll(
      tester,
      dose: '100',
      water: '2000',
      waterTemp: '100',
      minutes: '60',
      seconds: '0',
    );
    await save(tester);
    expect(
      find.textContaining('应在'),
      findsNothing,
      reason: '上端点（100 / 2000 / 100 / 60 分）必须合法',
    );

    // ── 上端越界：逐字文案（与重构前完全相同）──
    await fillAll(
      tester,
      dose: '100.1',
      water: '2000.1',
      waterTemp: '100.1',
      minutes: '60',
      seconds: '1', // 总分 3601 → 落「总时间」那条
    );
    await save(tester);
    expect(find.text('粉量应在 0.1–100 g 之间'), findsOneWidget);
    expect(find.text('水量应在 0–2000 g 之间'), findsOneWidget);
    expect(find.text('水温应在 0–100 ℃ 之间'), findsOneWidget);
    expect(find.text('总时间应在 0–3600 秒之间'), findsOneWidget);
    expect(
      find.text('总时间应在 0–3600 秒 之间'),
      findsNothing,
      reason: '「秒」是中文单位，文案里不留多余空格',
    );

    // ── 分 / 秒两框各自的上限越界 ──
    await fillAll(tester, minutes: '61', seconds: '60');
    await save(tester);
    expect(find.text('分应在 0–60 之间'), findsOneWidget);
    expect(find.text('秒应在 0–59 之间'), findsOneWidget);

    // ── 下端越界：粉量 0.09（水量/水温的下限是 0，输入框连负号都不收）──
    await fillAll(tester, dose: '0.09');
    await save(tester);
    expect(find.text('粉量应在 0.1–100 g 之间'), findsOneWidget);

    // 全程一条记录都不该落库：每次保存都被拦住了。
    expect(await logs(), isEmpty);

    await harness.finish(tester);
  });
}
