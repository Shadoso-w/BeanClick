import 'package:beanclick/core/icons.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/features/record/brew_log_form_page.dart';
import 'package:beanclick/features/record/record_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

/// 拼配（多豆）表单。
///
/// 一条记录只存总粉量（`brew_logs.doseGrams`）和每支豆子的粉量
/// （`brew_log_beans.doseGrams`）。M3-T15 起界面改成：**每支直接填克数**
/// （`brew.beanGrams.$i`），「占比」（`brew.share.$i`，只读文字）与「总粉量」
/// （`brew.dose`，拼配时是只读展示）都是按各支克数算出来的。
/// 各支克数之和就是总粉量，余量按各支克数扣。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  /// 直接打开记录表单（不用走外壳导航）。
  Future<void> pumpForm(WidgetTester tester, {BrewLog? existing}) async {
    await tester.pumpWidget(
      harness.app(MaterialApp(home: BrewLogFormPage(existing: existing))),
    );
    await tester.pumpAndSettle();
  }

  /// 某一行豆子下拉里可选的豆子 id（含「未指定」的 null）。
  List<int?> optionsOf(WidgetTester tester, int index) {
    final Finder button = find.descendant(
      of: find.byKey(Key('brew.bean.$index')),
      matching: find.byType(DropdownButton<int?>),
    );
    return tester
        .widget<DropdownButton<int?>>(button)
        .items!
        .map((DropdownMenuItem<int?> item) => item.value)
        .toList();
  }

  /// 选中某一行下拉里的豆子。
  Future<void> pickBean(WidgetTester tester, int index, String name) async {
    await tester.tapKey('brew.bean.$index');
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<BeanBatch> batchOf(int batchId) async =>
      (await harness.container.read(beanRepositoryProvider).getBatch(batchId))!;

  Future<List<BrewLog>> logs() =>
      harness.container.read(brewLogRepositoryProvider).getAll();

  /// 拼配时「占比」是**只读文字**（`brew.share.$i` 挂在 `Text` 上，不是输入框）。
  Future<String> shareText(WidgetTester tester, int index) async {
    final Finder finder = find.byKey(Key('brew.share.$index'));
    await tester.scrollTo(finder);
    return tester.widget<Text>(finder).data!;
  }

  /// 拼配时「总粉量」也是只读展示（`InputDecorator` 里的那行文字，如 `20 g`）。
  Future<String> totalDoseText(WidgetTester tester) async {
    final Finder field = find.byKey(const Key('brew.dose'));
    await tester.scrollTo(field);
    return tester
        .widgetList<Text>(
          find.descendant(of: field, matching: find.byType(Text)),
        )
        .map((Text text) => text.data ?? '')
        .firstWhere((String value) => value.endsWith('g'), orElse: () => '');
  }

  /// 行内校验的直接探针：`validate()` 为 true 就等于「行内 validator 不飘红」。
  /// 顺手 pump 一帧，让可能出现的错误文案真的渲染出来。
  Future<bool> formValidates(WidgetTester tester) async {
    final bool ok = tester.state<FormState>(find.byType(Form)).validate();
    await tester.pump();
    return ok;
  }

  /// 视口放宽，保证豆子那两行都真的在册（在册才谈得上「行内 validator 放行」）。
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(2400, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// 造一条「花魁 14g + 曼特宁 6g」的拼配记录。
  Future<({int logId, int aBatch, int bBatch, int aBean, int bBean})>
  seedBlend() async {
    final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
    final b = await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 100);
    final DateTime at = DateTime(2026, 1, 1, 8);
    final int logId =
        (await harness.container
                .read(brewLogRepositoryProvider)
                .save(
                  BrewLog(
                    method: BrewMethod.pourOver,
                    doseGrams: 20,
                    brewedAt: at,
                    createdAt: at,
                    updatedAt: at,
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
                ))
            .brewLogId;
    return (
      logId: logId,
      aBatch: a.batchId,
      bBatch: b.batchId,
      aBean: a.beanId,
      bBean: b.beanId,
    );
  }

  /// 造一条「各支克数由调用方给」的拼配记录。
  ///
  /// 用来复现**加限之前**记下的越界拼配（M3-T25 / F2）：120 g（60 + 60，
  /// 单支都合法、总分越界）与 500 g（250 + 250，单支本身就越界）。
  /// 余量给得很足，免得保存时撞上「余量不足」的提示。
  Future<({int logId, int aBatch, int bBatch, int aBean, int bBean})>
  seedBlendGrams(List<double> grams) async {
    final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 5000);
    final b = await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 5000);
    final DateTime at = DateTime(2026, 1, 1, 8);
    final int logId =
        (await harness.container
                .read(brewLogRepositoryProvider)
                .save(
                  BrewLog(
                    method: BrewMethod.pourOver,
                    doseGrams: grams.fold<double>(
                      0,
                      (double sum, double g) => sum + g,
                    ),
                    brewedAt: at,
                    createdAt: at,
                    updatedAt: at,
                    beanUsages: <BeanUsage>[
                      BeanUsage(
                        beanId: a.beanId,
                        batchId: a.batchId,
                        doseGrams: grams[0],
                        position: 0,
                      ),
                      BeanUsage(
                        beanId: b.beanId,
                        batchId: b.batchId,
                        doseGrams: grams[1],
                        position: 1,
                      ),
                    ],
                  ),
                ))
            .brewLogId;
    return (
      logId: logId,
      aBatch: a.batchId,
      bBatch: b.batchId,
      aBean: a.beanId,
      bBean: b.beanId,
    );
  }

  /// 按 id 取回落库后的记录（保存被拦住时用它断言「库里没变」）。
  Future<BrewLog> stored(int logId) async =>
      (await harness.container.read(brewLogRepositoryProvider).getById(logId))!;

  testWidgets('两支豆子各填克数：总粉量自动求和，余量各扣各的', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
    final b = await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 100);

    await pumpForm(tester);
    await pickBean(tester, 0, '花魁');
    // 加一支 → 变成拼配：总粉量不再手填，每支直接填克数。
    await tester.tapKey('brew.addPick');
    await pickBean(tester, 1, '曼特宁');
    await tester.fillField('brew.beanGrams.0', '14');
    await tester.fillField('brew.beanGrams.1', '6');

    // 总粉量 = 各支克数之和（只读展示）；占比同样只是算出来的只读文字。
    expect(await totalDoseText(tester), '20 g');
    expect(await shareText(tester, 0), '占比 70%');
    expect(await shareText(tester, 1), '占比 30%');

    await tester.tapSaveButton();

    final BrewLog log = (await logs()).single;
    expect(log.doseGrams, 20);
    expect(log.beanUsages.length, 2);
    expect(log.beanUsages[0].doseGrams, 14);
    expect(log.beanUsages[1].doseGrams, 6);
    expect(log.isBlend, isTrue);
    // 余量按各自的粉量扣。
    expect((await batchOf(a.batchId)).remainingGrams, 186);
    expect((await batchOf(b.batchId)).remainingGrams, 94);

    await harness.finish(tester);
  });

  testWidgets('带小数的克数：各支粉量之和仍正好等于总粉量', (tester) async {
    await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
    await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 200);
    await harness.addBeanWithBatch(name: '耶加雪菲', remainingGrams: 200);

    await pumpForm(tester);
    await pickBean(tester, 0, '花魁');
    await tester.tapKey('brew.addPick');
    await pickBean(tester, 1, '曼特宁');
    await tester.tapKey('brew.addPick');
    await pickBean(tester, 2, '耶加雪菲');
    // 三支都写成两位小数：末支吃掉四舍五入的零头（3.33 → 3.3）。
    await tester.fillField('brew.beanGrams.0', '3.33');
    await tester.fillField('brew.beanGrams.1', '3.33');
    await tester.fillField('brew.beanGrams.2', '3.34');

    expect(await totalDoseText(tester), '10 g');
    await tester.tapSaveButton();

    final BrewLog log = (await logs()).single;
    expect(log.beanUsages.length, 3);
    expect(
      log.beanUsages.fold<double>(
        0,
        (double s, BeanUsage u) => s + u.doseGrams,
      ),
      10,
      reason: '各支粉量之和必须正好等于总粉量',
    );
    expect(log.beanUsages[2].doseGrams, 3.4);

    await harness.finish(tester);
  });

  testWidgets('拼配时某支克数留空或为 0，保存被拦下并提示', (tester) async {
    await harness.addBeanWithBatch(name: '花魁');
    await harness.addBeanWithBatch(name: '曼特宁');

    await pumpForm(tester);
    await pickBean(tester, 0, '花魁');
    await tester.tapKey('brew.addPick');
    await pickBean(tester, 1, '曼特宁');
    await tester.fillField('brew.beanGrams.0', '14');

    // 第二支填 0：新规则「每支都要填大于 0 的克数」，字段校验先拦下。
    await tester.fillField('brew.beanGrams.1', '0');
    await tester.tapSaveButton();

    expect(find.textContaining('克数应在 0.1–100 g 之间'), findsOneWidget);
    expect(await logs(), isEmpty, reason: '校验不通过时不应落库');

    // 第二支留空：字段校验放行，整体校验再拦一次。
    await tester.fillField('brew.beanGrams.1', '');
    await tester.tapSaveButton();

    expect(find.textContaining('每支豆子都要填大于 0 的克数'), findsOneWidget);
    expect(await logs(), isEmpty, reason: '校验不通过时不应落库');

    await harness.finish(tester);
  });

  testWidgets('同一支豆子不能在两行里各选一次', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    final b = await harness.addBeanWithBatch(name: '曼特宁');

    await pumpForm(tester);
    await pickBean(tester, 0, '花魁');
    await tester.tapKey('brew.addPick');

    // 第二行的候选里不该再出现第一行已选的花魁。
    expect(optionsOf(tester, 1), contains(b.beanId));
    expect(optionsOf(tester, 1), isNot(contains(a.beanId)));

    await harness.finish(tester);
  });

  testWidgets('编辑拼配记录：每支克数按库里的用量还原，改克数按差值补扣', (tester) async {
    final seeded = await seedBlend();
    // 20g 已按 14 / 6 扣过。
    expect((await batchOf(seeded.aBatch)).remainingGrams, 186);
    expect((await batchOf(seeded.bBatch)).remainingGrams, 94);

    final BrewLog existing = (await harness.container
        .read(brewLogRepositoryProvider)
        .getById(seeded.logId))!;
    await pumpForm(tester, existing: existing);

    // 14 / 6 直接还原成每支的克数；占比与总粉量都是算出来的只读展示。
    expect(await tester.readField('brew.beanGrams.0'), '14');
    expect(await tester.readField('brew.beanGrams.1'), '6');
    expect(await totalDoseText(tester), '20 g');
    expect(await shareText(tester, 0), '占比 70%');
    expect(await shareText(tester, 1), '占比 30%');

    // 改成 21 / 9（合计 30）：多出来的 7g / 3g 按差值补扣。
    await tester.fillField('brew.beanGrams.0', '21');
    await tester.fillField('brew.beanGrams.1', '9');
    expect(await totalDoseText(tester), '30 g');

    await tester.tapSaveButton();

    final BrewLog saved = (await logs()).single;
    expect(saved.doseGrams, 30);
    expect(saved.beanUsages[0].doseGrams, 21);
    expect(saved.beanUsages[1].doseGrams, 9);
    // 差值补扣：各支多用了 7g / 3g。
    expect((await batchOf(seeded.aBatch)).remainingGrams, 179);
    expect((await batchOf(seeded.bBatch)).remainingGrams, 91);

    await harness.finish(tester);
  });

  testWidgets('去掉一支豆子：它被回补，剩下那支的克数不变', (tester) async {
    final seeded = await seedBlend();

    final BrewLog existing = (await harness.container
        .read(brewLogRepositoryProvider)
        .getById(seeded.logId))!;
    await pumpForm(tester, existing: existing);

    // 删之前：拼配合计就是库里那 20 g（花魁 14 + 曼特宁 6）。
    expect(find.textContaining('各支合计 20 g'), findsOneWidget);

    // 删掉第二支（6 g）：总粉量（= 各支克数之和）跟着降到 14，
    // 花魁那支的克数不受影响。
    await tester.tap(find.byTooltip('删掉这一支').last);
    await tester.pumpAndSettle();
    expect(await tester.readField('brew.dose'), '14');

    await tester.tapSaveButton();

    final BrewLog saved = (await logs()).single;
    expect(saved.beanUsages, hasLength(1));
    expect(saved.beanUsages.single.beanId, seeded.aBean);
    expect(saved.beanUsages.single.doseGrams, 14);
    expect((await batchOf(seeded.aBatch)).remainingGrams, 186);
    expect(
      (await batchOf(seeded.bBatch)).remainingGrams,
      100,
      reason: '被去掉的豆子要回补',
    );

    await harness.finish(tester);
  });

  testWidgets('豆子列表还没加载出来时，下拉框不会因为选中值缺失而崩', (tester) async {
    final seeded = await seedBlend();
    final BrewLog existing = (await harness.container
        .read(brewLogRepositoryProvider)
        .getById(seeded.logId))!;

    // 故意只 pump 一帧：`beanListProvider` 是 StreamProvider，
    // 这一帧里豆子列表还是空的，而下拉框的初始值是真实存在的 id。
    await tester.pumpWidget(
      harness.app(MaterialApp(home: BrewLogFormPage(existing: existing))),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    // 列表到位后显示的是真名。
    expect(find.text('花魁'), findsWidgets);

    await harness.finish(tester);
  });

  testWidgets('表单里的「新增豆子 / 新增磨豆机」也是圆圈加号', (tester) async {
    await harness.addBeanWithBatch(name: '花魁');

    await pumpForm(tester);

    // 新增豆子 / 新增磨豆机这两个内联入口与豆库页的新增按钮用同一个图标。
    expect(
      find.descendant(
        of: find.byKey(const Key('brew.addBean')),
        matching: find.byIcon(addCircleIcon),
      ),
      findsOneWidget,
    );

    await harness.finish(tester);
  });

  testWidgets('记录页卡片显示拼配的两支豆子与各自粉量', (tester) async {
    await seedBlend();

    // RecordPage 是外壳里的一页，自己不带 Scaffold（TextField 需要 Material 祖先）。
    await tester.pumpWidget(
      harness.app(const MaterialApp(home: Scaffold(body: RecordPage()))),
    );
    // 记录列表来自 drift 的 stream：给一点真实时间让首次查询回来，再 settle。
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(find.text('花魁 + 曼特宁'), findsOneWidget);
    expect(find.text('拼配 14 g + 6 g'), findsOneWidget);

    await harness.finish(tester);
  });

  test('复制上次：拼配配方一起复制，但批次清空', () {
    final BrewLog source = BrewLog(
      beanId: 1,
      doseGrams: 20,
      brewedAt: DateTime(2026, 1, 1, 8),
      createdAt: DateTime(2026, 1, 1, 8),
      updatedAt: DateTime(2026, 1, 1, 8),
      beanUsages: <BeanUsage>[
        const BeanUsage(beanId: 1, batchId: 11, doseGrams: 14),
        const BeanUsage(beanId: 2, batchId: 22, doseGrams: 6),
      ],
    );

    final BrewLog copied = BrewLogFormPage.copyFrom(source);

    expect(copied.id, isNull);
    expect(copied.beanUsages, hasLength(2));
    expect(copied.beanUsages[0].beanId, 1);
    expect(copied.beanUsages[1].beanId, 2);
    expect(
      copied.beanUsages.every((BeanUsage u) => u.batchId == null),
      isTrue,
      reason: '那一袋可能已经用完，批次要交回给仓储重新挑',
    );
  });

  /// M3-T20 F3：**拼配总分**的上下限。
  ///
  /// M3-T15 在 `_validatePicks` 里加了「拼配总分必须落在 0.1–100 g」，
  /// 但逐字段校验只看得到单支：两支各填 60 g **每支都合法**，总分 120 g 却越界。
  /// 这条校验此前零覆盖，这里补上（与单支路径用同一个文案）。
  testWidgets('拼配两支各填 60 g：总分越界被拦下并提示，未落库', (tester) async {
    await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
    await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 200);

    await pumpForm(tester);
    await pickBean(tester, 0, '花魁');
    await tester.tapKey('brew.addPick');
    await pickBean(tester, 1, '曼特宁');
    // 60 g 单看每一支都在 0.1–100 之内，字段校验放行；越界的是**总分 120 g**。
    await tester.fillField('brew.beanGrams.0', '60');
    await tester.fillField('brew.beanGrams.1', '60');
    await tester.pumpAndSettle();
    expect(await totalDoseText(tester), '120 g');

    await tester.tapSaveButton();

    expect(
      find.textContaining('粉量应在 0.1–100 g 之间'),
      findsOneWidget,
      reason: '总分越界要与单支路径用同一个文案',
    );
    expect(await logs(), isEmpty, reason: '总分越界时不该落库');

    await harness.finish(tester);
  });

  /// M3-T22 S2：删支 / 拆半不能替用户写出他没填过的 `0`。
  ///
  /// `_removePick` 以前是 `numberToText(roundGrams(parseNumber(...) ?? 0))`，
  /// 克数框为空时就写出 `'0'` —— 用户看到一个自己没填过的 0，还立刻触发校验。
  /// `_addPick` / `_addPickSilently` 在极小粉量（如 0.1 g）1 → 2 拆半时，
  /// 也会把第二支预算成 0。
  testWidgets('删掉有克数那一支后，剩下那支克数为空时粉量框留空（不写 0）', (tester) async {
    await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
    await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 200);

    await pumpForm(tester);
    await pickBean(tester, 0, '花魁');
    await tester.tapKey('brew.addPick');
    await pickBean(tester, 1, '曼特宁');
    // 只填第二支：第一支的克数框始终是空的。
    await tester.fillField('brew.beanGrams.1', '6');
    // 输入框拿到焦点会带动列表自动滚动，等它停下来再点「删掉这一支」，
    // 否则 finder 算出来的位置是滚动动画中间那一帧的。
    await tester.pumpAndSettle();

    // 删掉有克数的那一支，剩下那支从没填过克数。
    await tester.tap(find.byTooltip('删掉这一支').last);
    await tester.pumpAndSettle();

    expect(
      await tester.readField('brew.dose'),
      '',
      reason: '空克数不能被写成 0：用户没填过这个数，还会立刻触发校验',
    );

    await harness.finish(tester);
  });

  testWidgets('0.1 g 加一支拆半：两支都不预填（更不该预填 0）', (tester) async {
    await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
    await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 200);

    await pumpForm(tester);
    await pickBean(tester, 0, '花魁');
    await tester.fillField('brew.dose', '0.1');
    await tester.tapKey('brew.addPick');

    expect(
      await tester.readField('brew.beanGrams.0'),
      '',
      reason: '0.1 g 拆半没有合法写法（0.05 g 不是 0.1 的整数倍），别预填',
    );
    expect(
      await tester.readField('brew.beanGrams.1'),
      '',
      reason: '拆半不能把第二支预填成 0',
    );

    await harness.finish(tester);
  });

  /// M3-T25 ①（G4 定点复核 F2）：**拼配路径也要有「原值放行」**。
  ///
  /// M3-T22 只给**单支**的粉量/水量/水温/总时间加了「等于打开时的值就放行」，
  /// 拼配没有：
  ///
  /// - 库里加限之前记下的 120 g（60 + 60）每支都 ≤ 100，打开不飘红，
  ///   但一点保存就撞上「总粉量 0.1–100 g」——连改个备注都存不回去；
  /// - 更旧的 250 g/250 g 则**一打开就行内飘红**（行内 validator 没带原值）。
  ///
  /// 这里按单支那套机制补上：总分对 `brew_logs.doseGrams`，每支对自己的
  /// `brew_log_uses.doseGrams`（`_BeanPick.originalGrams`）。
  group('M3-T25 拼配的原值放行与每支克数兜底', () {
    testWidgets('F2：旧 120 g 拼配（60/60）不飘红，直接保存仍是 120', (tester) async {
      useTallViewport(tester);
      final seeded = await seedBlendGrams(<double>[60, 60]);
      await pumpForm(tester, existing: await stored(seeded.logId));

      expect(await tester.readField('brew.beanGrams.0'), '60');
      expect(await tester.readField('brew.beanGrams.1'), '60');
      expect(await totalDoseText(tester), '120 g');

      expect(
        await formValidates(tester),
        isTrue,
        reason: '60 与 60 单看都在范围内，会飘红的只可能是总分 120 —— 原值要放行',
      );
      expect(find.textContaining('应在'), findsNothing, reason: '打开旧记录不该飘红');

      // 顺手改一个无关字段（滤杯）：只有保存真的落到这条记录上它才会变，
      // 「(await logs()).single」读的是库里那条旧记录，会假绿。
      await tester.fillField('brew.dripper', 'V60 02');
      await tester.tapSaveButton();

      final BrewLog saved = await stored(seeded.logId);
      expect(saved.dripper, 'V60 02', reason: '这条旧记录要真的能存回去（改备注也一样）');
      expect(saved.doseGrams, 120, reason: '原样存回，不能被新上限锁死');
      expect(saved.beanUsages[0].doseGrams, 60);
      expect(saved.beanUsages[1].doseGrams, 60);

      await harness.finish(tester);
    });

    testWidgets('F2：旧 250 g/250 g 拼配不飘红，原样存回 500', (tester) async {
      useTallViewport(tester);
      final seeded = await seedBlendGrams(<double>[250, 250]);
      await pumpForm(tester, existing: await stored(seeded.logId));

      expect(await tester.readField('brew.beanGrams.0'), '250');
      expect(await tester.readField('brew.beanGrams.1'), '250');

      expect(
        await formValidates(tester),
        isTrue,
        reason: '行内 validator 也必须带原值，否则一打开这两个框就红',
      );
      expect(find.textContaining('应在'), findsNothing, reason: '用户什么都没做，不该飘红');

      await tester.fillField('brew.dripper', 'V60 02');
      await tester.tapSaveButton();

      final BrewLog saved = await stored(seeded.logId);
      expect(saved.dripper, 'V60 02', reason: '原样保存要真的成功');
      expect(saved.doseGrams, 500, reason: '原样存回');
      expect(saved.beanUsages[0].doseGrams, 250);
      expect(saved.beanUsages[1].doseGrams, 250);

      await harness.finish(tester);
    });

    testWidgets('F2：把旧的 60/60 改成 70/60（总分 130）→ 拦住', (tester) async {
      final seeded = await seedBlendGrams(<double>[60, 60]);
      await pumpForm(tester, existing: await stored(seeded.logId));

      await tester.fillField('brew.beanGrams.0', '70');
      expect(await totalDoseText(tester), '130 g');

      await tester.tapSaveButton();

      expect(find.text('粉量应在 0.1–100 g 之间'), findsOneWidget);
      expect((await stored(seeded.logId)).doseGrams, 120, reason: '拦住就不该落库');

      await harness.finish(tester);
    });

    testWidgets('F2：把旧的 250/250 改成 150/150（总分 300）→ 拦住', (tester) async {
      final seeded = await seedBlendGrams(<double>[250, 250]);
      await pumpForm(tester, existing: await stored(seeded.logId));

      await tester.fillField('brew.beanGrams.0', '150');
      await tester.fillField('brew.beanGrams.1', '150');

      await tester.tapSaveButton();

      expect(find.textContaining('克数应在 0.1–100 g 之间'), findsWidgets);
      expect(
        (await stored(seeded.logId)).doseGrams,
        500,
        reason: '改过了就不再放行，拦住就不该落库',
      );

      await harness.finish(tester);
    });

    testWidgets('F1：某支填 0.05 后滚出视口，保存仍被兜底拦下', (tester) async {
      await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
      await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 200);

      await pumpForm(tester);
      await pickBean(tester, 0, '花魁');
      await tester.tapKey('brew.addPick');
      await pickBean(tester, 1, '曼特宁');
      // 0.05 g 低于行内那条「克数应在 0.1–100 g 之间」的下限。
      await tester.fillField('brew.beanGrams.0', '0.05');
      await tester.fillField('brew.beanGrams.1', '6');

      // ListView 只保活**有焦点**的输入框：先失焦，再往下滚，
      // 让那一行离开视口、从 Form 里反注册 —— 行内 validator 就看不到它了。
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('brew.beanGrams.0')),
        findsNothing,
        reason: '前提：这个框真的被销毁了，行内 validator 已经看不到它',
      );

      await tester.tapSaveButton();

      expect(
        find.textContaining('克数应在 0.1–100 g 之间'),
        findsOneWidget,
        reason: '_validatePicks 的保存兜底要与行内同口径',
      );
      expect(await logs(), isEmpty, reason: '不能静默存下 0.05 g');

      await harness.finish(tester);
    });

    testWidgets('回归护栏：新建拼配没有原值，60/60 总分 120 依旧被拦', (tester) async {
      await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
      await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 200);

      await pumpForm(tester);
      await pickBean(tester, 0, '花魁');
      await tester.tapKey('brew.addPick');
      await pickBean(tester, 1, '曼特宁');
      await tester.fillField('brew.beanGrams.0', '60');
      await tester.fillField('brew.beanGrams.1', '60');

      await tester.tapSaveButton();

      expect(
        find.text('粉量应在 0.1–100 g 之间'),
        findsOneWidget,
        reason: '原值豁免只对「打开时那个值」生效，新建记录不能被放宽',
      );
      expect(await logs(), isEmpty, reason: '新建记录的上下限不放宽');

      await harness.finish(tester);
    });
  });
}
