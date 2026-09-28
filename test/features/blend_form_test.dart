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
/// 界面上的「占比」是**算出来的分摊比例**：一条记录只存总粉量
/// （`brew_logs.doseGrams`）和每支豆子的粉量（`brew_log_beans.doseGrams`）。
/// 各支粉量之和必须等于总粉量，余量按各支粉量扣。
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

  testWidgets('两支豆子按占比分摊总粉量，并各自扣自己的余量', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
    final b = await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 100);

    await pumpForm(tester);
    await pickBean(tester, 0, '花魁');
    await tester.fillField('brew.dose', '20');

    // 加一支 → 默认对半分，改成 70 / 30。
    await tester.tapKey('brew.addPick');
    await pickBean(tester, 1, '曼特宁');
    await tester.fillField('brew.share.0', '70');
    await tester.fillField('brew.share.1', '30');
    expect(find.textContaining('占比合计 100%'), findsOneWidget);

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

  testWidgets('带小数占比分摊时，各支粉量之和仍等于总粉量', (tester) async {
    await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
    await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 200);
    await harness.addBeanWithBatch(name: '耶加雪菲', remainingGrams: 200);

    await pumpForm(tester);
    await pickBean(tester, 0, '花魁');
    await tester.fillField('brew.dose', '10');
    await tester.tapKey('brew.addPick');
    await pickBean(tester, 1, '曼特宁');
    await tester.tapKey('brew.addPick');
    await pickBean(tester, 2, '耶加雪菲');
    // 33.3 / 33.3 / 33.4：四舍五入的零头归最后一支。
    await tester.fillField('brew.share.0', '33.3');
    await tester.fillField('brew.share.1', '33.3');
    await tester.fillField('brew.share.2', '33.4');
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

  testWidgets('占比合计不是 100% 时拦住保存并提示', (tester) async {
    await harness.addBeanWithBatch(name: '花魁');
    await harness.addBeanWithBatch(name: '曼特宁');

    await pumpForm(tester);
    await pickBean(tester, 0, '花魁');
    await tester.fillField('brew.dose', '20');
    await tester.tapKey('brew.addPick');
    await pickBean(tester, 1, '曼特宁');
    await tester.fillField('brew.share.0', '70');
    await tester.fillField('brew.share.1', '40');

    expect(find.textContaining('要凑成 100%'), findsOneWidget);
    await tester.tapSaveButton();

    expect(find.textContaining('占比合计要等于 100%'), findsOneWidget);
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

  testWidgets('编辑拼配记录：占比按各支粉量还原，改总粉量按差值补扣', (tester) async {
    final seeded = await seedBlend();
    // 20g 已按 14 / 6 扣过。
    expect((await batchOf(seeded.aBatch)).remainingGrams, 186);
    expect((await batchOf(seeded.bBatch)).remainingGrams, 94);

    final BrewLog existing = (await harness.container
        .read(brewLogRepositoryProvider)
        .getById(seeded.logId))!;
    await pumpForm(tester, existing: existing);

    // 14 / 20 = 70%，6 / 20 = 30%：占比是从各支粉量倒推出来的。
    expect(await tester.readField('brew.share.0'), '70');
    expect(await tester.readField('brew.share.1'), '30');

    await tester.fillField('brew.dose', '30');
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

    // 删掉第二支（6 g）：总粉量跟着降到 14，花魁那支的克数不受影响。
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
}
