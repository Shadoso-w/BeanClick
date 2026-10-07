import 'package:beanclick/app.dart';
import 'package:beanclick/core/widgets/form_fields.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/features/record/brew_log_form_page.dart';
import 'package:beanclick/features/record/record_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart' show makeLog;
import '../helpers/widget_harness.dart';

/// M2.8 第一批：A2 日期弹窗中文化、A3 冲煮时间可选时分、B2 卡片第一行。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> pumpRecordPage(WidgetTester tester) async {
    await tester.pumpWidget(
      harness.app(const MaterialApp(home: Scaffold(body: RecordPage()))),
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  group('A3 日期/时分工具的纯函数', () {
    test('formatTime 是 24 小时制并补零', () {
      expect(formatTime(const TimeOfDay(hour: 8, minute: 5)), '08:05');
      expect(formatTime(const TimeOfDay(hour: 14, minute: 30)), '14:30');
      expect(formatTime(const TimeOfDay(hour: 0, minute: 0)), '00:00');
    });

    test('withDate 只换日期、保留时分', () {
      final DateTime original = DateTime(2026, 1, 1, 8, 5, 30);
      final DateTime changed = withDate(original, DateTime(2026, 3, 9));
      expect(changed, DateTime(2026, 3, 9, 8, 5, 30));
    });

    test('withTime 只换时分、保留日期（秒清零）', () {
      final DateTime original = DateTime(2026, 1, 1, 8, 5, 30);
      final DateTime changed = withTime(
        original,
        const TimeOfDay(hour: 15, minute: 42),
      );
      // 时间选择器只有分钟精度，秒会被清零。
      expect(changed, DateTime(2026, 1, 1, 15, 42));
      expect(changed.second, 0);
    });

    test('formatDateTimeChinese 拼出中文日期 + 时分', () {
      expect(
        formatDateTimeChinese(DateTime(2026, 9, 27, 14, 30)),
        '2026年9月27日 14:30',
      );
    });
  });

  testWidgets('A2：日期选择弹窗是中文的', (tester) async {
    // 必须走真实的 BeanClickApp（locale 与 localizationsDelegates 在那里配）。
    await tester.pumpWidget(harness.app(const BeanClickApp()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('dock.addCup')));
    await tester.pumpAndSettle();

    await tester.tapKey('brew.brewedDate');
    await tester.pumpAndSettle();

    // Material 的日期选择器在 zh_CN 下按钮是「取消 / 确定」，
    // 月份标题带「年」「月」，星期是单个汉字。
    expect(find.text('取消'), findsWidgets);
    expect(find.text('确定'), findsWidgets);
    expect(find.textContaining('年'), findsWidgets);
    expect(find.text('OK'), findsNothing);
    expect(find.text('Cancel'), findsNothing);

    await tester.tap(find.text('取消').last);
    await tester.pumpAndSettle();

    await harness.finish(tester);
  });

  testWidgets('A3：编辑记录时，时分按钮显示记录里的时分', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    final int logId =
        (await harness.container
                .read(brewLogRepositoryProvider)
                .save(
                  makeLog(
                    beanId: a.beanId,
                    batchId: a.batchId,
                    brewedAt: DateTime(2026, 1, 1, 8, 5),
                  ),
                ))
            .brewLogId;
    final BrewLog existing = (await harness.container
        .read(brewLogRepositoryProvider)
        .getById(logId))!;

    await tester.pumpWidget(
      harness.app(MaterialApp(home: BrewLogFormPage(existing: existing))),
    );
    await tester.pumpAndSettle();

    // 日期与时分是两个独立按钮。
    expect(find.byKey(const Key('brew.brewedDate')), findsOneWidget);
    expect(find.byKey(const Key('brew.brewedTime')), findsOneWidget);
    expect(find.text('08:05'), findsOneWidget);
    expect(find.text('2026年1月1日'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('B2：卡片第一行是「豆名 + 方法 chip」，第二行只剩刻度', (tester) async {
    final a = await harness.addBeanWithBatch(name: '黑猫拼配');
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          makeLog(
            beanId: a.beanId,
            batchId: a.batchId,
            method: BrewMethod.mokaPot,
            grindSetting: 22,
            brewedAt: DateTime(2026, 1, 1, 8),
          ),
        );

    await pumpRecordPage(tester);

    // 豆名与方法 chip 都在，且**同一行**（纵坐标基本一致）。
    final double beanDy = tester.getCenter(find.text('黑猫拼配')).dy;
    final double methodDy = tester.getCenter(find.text('摩卡壶')).dy;
    expect((beanDy - methodDy).abs(), lessThan(10), reason: 'chip 应该在第一行');

    // 刻度在下面一行（比第一行低）。
    final double grindDy = tester.getCenter(find.textContaining('22')).dy;
    expect(grindDy, greaterThan(beanDy + 10));

    await harness.finish(tester);
  });

  testWidgets('B2：拼配记录的第一行包含所有豆名，chip 在其后', (tester) async {
    final a = await harness.addBeanWithBatch(name: '黑猫拼配');
    final b = await harness.addBeanWithBatch(name: '花魁');
    final DateTime at = DateTime(2026, 1, 1, 8);
    await harness.container
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
        );

    await pumpRecordPage(tester);

    // 标题是「A + B」，chip 紧随其后（横坐标在标题右侧、同一行）。
    final Finder title = find.text('黑猫拼配 + 花魁');
    expect(title, findsOneWidget);
    final Rect titleRect = tester.getRect(title);
    final Rect chipRect = tester.getRect(find.text('手冲'));
    expect(chipRect.left, greaterThanOrEqualTo(titleRect.right - 1));
    expect((chipRect.center.dy - titleRect.center.dy).abs(), lessThan(10));

    await harness.finish(tester);
  });

  /// M3-T12：用户第二轮反馈的四项记录表单问题。
  ///
  /// ① 冲煮方法那行有两个「＋」（avatar 的 add 图标 + label 的「＋」）；
  /// ② 辅料行三个框不等高、数量框放不下四位数；
  /// ③ 豆子要必填（**豆库为空时放行**：首杯零阻力，见手册 §8「快速记录」）；
  /// ④ 核心参数要有保守上下限（留空仍合法）。
  group('M3-T12 第二轮反馈：记录表单', () {
    /// 直接打开记录表单（不走外壳导航）。
    Future<void> pumpForm(WidgetTester tester) async {
      await tester.pumpWidget(
        harness.app(const MaterialApp(home: BrewLogFormPage())),
      );
      // 豆子列表来自 drift 的 stream：给一点真实时间让首次查询回来。
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
    }

    Future<List<BrewLog>> logs() =>
        harness.container.read(brewLogRepositoryProvider).getAll();

    /// 选中第 index 行的豆子。
    Future<void> pickBean(WidgetTester tester, int index, String name) async {
      await tester.tapKey('brew.bean.$index');
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    testWidgets('冲煮方法那一行只画一个「＋」', (tester) async {
      await pumpForm(tester);

      final Finder addMethod = find.byKey(const Key('brew.addMethod'));
      expect(addMethod, findsOneWidget);
      expect(find.text('＋'), findsOneWidget, reason: '整行只能有一个加号');
      // 以前 chip 同时带 avatar 的 add 图标和 label 的「＋」，一个 chip 上两个加号。
      expect(
        find.descendant(of: addMethod, matching: find.byIcon(Icons.add)),
        findsNothing,
        reason: 'avatar 与 label 会画出两个加号，只留一个',
      );

      await harness.finish(tester);
    });

    testWidgets('辅料行三个框等高，数量框放得下四位数字', (tester) async {
      // 真机宽度（390dp）：默认 800dp 的测试视口太宽，暴露不出数量框被挤扁。
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await pumpForm(tester);
      await tester.tapKey('brew.addAddIn');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('brew.addInOption.牛奶')));
      await tester.pumpAndSettle();

      final Finder name = find.byKey(const Key('brew.addInName.0'));
      final Finder amount = find.byKey(const Key('brew.addInAmount.0'));
      final Finder unit = find.ancestor(
        of: find.byKey(const Key('brew.addInUnit.0')),
        matching: find.byType(InputDecorator),
      );

      final Size nameSize = tester.getSize(name);
      final Size amountSize = tester.getSize(amount);
      final Size unitSize = tester.getSize(unit);

      expect(
        amountSize.height,
        closeTo(nameSize.height, 1),
        reason: '数量框要和名称框等高：name=$nameSize amount=$amountSize',
      );
      expect(
        unitSize.height,
        closeTo(nameSize.height, 1),
        reason: '单位框要和名称框等高：name=$nameSize unit=$unitSize',
      );
      expect(
        amountSize.width,
        greaterThanOrEqualTo(80),
        reason: '数量框至少要放得下 1000：amount=$amountSize',
      );
      // 单位框不能为了给数量框腾地方而挤到放不下单位文字 + 下拉箭头：
      // 72dp 时 `ml` 会被截成 `m`（渲染稿抓到过这个回归），所以下限锁在 84。
      expect(
        unitSize.width,
        greaterThanOrEqualTo(84),
        reason: '单位框放不下「单位文字 + 下拉箭头」时会被截断：unit=$unitSize',
      );

      // 四位数要完整显示，不能换行或被截断。
      await tester.fillField('brew.addInAmount.0', '1000');
      expect(find.text('1000'), findsOneWidget);

      await harness.finish(tester);
    });

    testWidgets('豆库里有豆子、却一支都没选时，保存被拦下并提示', (tester) async {
      await harness.addBeanWithBatch(name: '花魁');
      await pumpForm(tester);

      await tester.tapSaveButton();

      expect(find.textContaining('请先选一支豆子'), findsOneWidget);
      expect(await logs(), isEmpty, reason: '有豆子可选却没选，就不该落库');

      await harness.finish(tester);
    });

    testWidgets('豆库一支豆子都没有时，以「未指定」保存成功并落库', (tester) async {
      // 空豆库是极端情形：没有豆子可选，不能因此拦死首杯（记录页仍可「+ 新增豆子」）。
      await pumpForm(tester);

      expect(
        find.descendant(
          of: find.byKey(const Key('brew.bean.0')),
          matching: find.text('未指定'),
        ),
        findsOneWidget,
        reason: '一支豆子都没有时，豆子那一栏只显示「未指定」',
      );

      await tester.tapSaveButton();

      final List<BrewLog> saved = await logs();
      expect(saved, hasLength(1), reason: '没有豆子可选时不该拦住记录');
      expect(saved.single.beanId, isNull, reason: '豆子显示为「未指定」');
      expect(saved.single.beanUsages, isEmpty);

      await harness.finish(tester);
    });

    testWidgets('核心参数超出上下限时报错并拦下保存', (tester) async {
      // 豆库非空且没选豆：这样最后那一步仍有「没选豆子」拦住保存。
      await harness.addBeanWithBatch(name: '花魁');
      await pumpForm(tester);

      await tester.fillField('brew.dose', '200');
      await tester.fillField('brew.water', '2001');
      await tester.fillField('brew.waterTemp', '101');
      // 分的上限是 60（M3-T22：60 分 = 3600 秒要合法），所以越界用 61。
      await tester.fillField('brew.totalTimeMin', '61');
      await tester.fillField('brew.totalTimeSec', '60');
      await tester.tapSaveButton();

      expect(find.text('粉量应在 0.1–100 g 之间'), findsOneWidget);
      expect(find.text('水量应在 0–2000 g 之间'), findsOneWidget);
      expect(find.text('水温应在 0–100 ℃ 之间'), findsOneWidget);
      expect(find.text('分应在 0–60 之间'), findsOneWidget);
      expect(find.text('秒应在 0–59 之间'), findsOneWidget);
      expect(await logs(), isEmpty, reason: '超范围时不应落库');

      // 边界内的值（含 0）不再报错：错误文案随下一次校验消失。
      await tester.fillField('brew.dose', '0.1');
      await tester.fillField('brew.water', '0');
      await tester.fillField('brew.waterTemp', '100');
      await tester.fillField('brew.totalTimeMin', '59');
      await tester.fillField('brew.totalTimeSec', '59');
      await tester.tapSaveButton();

      expect(find.textContaining('应在'), findsNothing, reason: '边界值不该报错');
      expect(
        find.textContaining('请先选一支豆子'),
        findsOneWidget,
        reason: '这次只剩「没选豆子」这一条拦住保存',
      );

      await harness.finish(tester);
    });

    testWidgets('核心参数留空仍可保存', (tester) async {
      final a = await harness.addBeanWithBatch(name: '花魁');
      await pumpForm(tester);
      await pickBean(tester, 0, '花魁');

      await tester.tapSaveButton();

      final List<BrewLog> saved = await logs();
      expect(saved, hasLength(1));
      expect(saved.single.doseGrams, isNull, reason: '留空仍然是合法的');
      expect(saved.single.beanUsages.single.beanId, a.beanId);

      await harness.finish(tester);
    });
  });

  /// M3-T15：拼配改成每支填**克数**（占比只读、总粉量自动求和），
  /// 总时间改成「分 + 秒」两个框（内部仍存总秒数）。
  group('M3-T15 拼配填克数与总时间分秒', () {
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

    Future<void> pickBean(WidgetTester tester, int index, String name) async {
      await tester.tapKey('brew.bean.$index');
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    Future<BeanBatch> batchOf(int batchId) async => (await harness.container
        .read(beanRepositoryProvider)
        .getBatch(batchId))!;

    /// 读某个 Key 下的文字（先滚进可视区：表单在 ListView 里，
    /// 视口外的控件根本不会被构建）。
    ///
    /// 只读展示有的把 Key 放在 `Text` 自己身上（占比），有的放在
    /// `InputDecorator` 上（总粉量），这里两种都能取到。
    Future<String> textOf(WidgetTester tester, String key) async {
      final Finder target = find.byKey(Key(key));
      await tester.scrollTo(target);
      final Finder inner = find.descendant(
        of: target,
        matching: find.byType(Text),
      );
      final Finder text = inner.evaluate().isEmpty ? target : inner.first;
      return tester.widget<Text>(text).data!;
    }

    testWidgets('拼配：每支填克数，占比只读、总粉量自动求和，余量按各支克数扣', (tester) async {
      final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
      final b = await harness.addBeanWithBatch(
        name: '曼特宁',
        remainingGrams: 100,
      );

      await pumpForm(tester);
      await pickBean(tester, 0, '花魁');
      await tester.tapKey('brew.addPick');
      await pickBean(tester, 1, '曼特宁');

      await tester.fillField('brew.beanGrams.0', '14');
      await tester.fillField('brew.beanGrams.1', '6');
      await tester.pumpAndSettle();

      // 占比是**算出来**的只读文字。
      expect(await textOf(tester, 'brew.share.0'), '占比 70%');
      expect(await textOf(tester, 'brew.share.1'), '占比 30%');
      // 总粉量 = 各支之和，且不再是可编辑输入框。
      expect(await textOf(tester, 'brew.dose'), '20 g');
      expect(
        find.descendant(
          of: find.byKey(const Key('brew.dose')),
          matching: find.byType(EditableText),
        ),
        findsNothing,
        reason: '拼配时总粉量是只读的',
      );

      await tester.tapSaveButton();

      final BrewLog log = (await logs()).single;
      expect(log.doseGrams, 20);
      expect(log.beanUsages, hasLength(2));
      expect(log.beanUsages[0].doseGrams, 14);
      expect(log.beanUsages[1].doseGrams, 6);
      // 余量继续按各支克数扣。
      expect((await batchOf(a.batchId)).remainingGrams, 186);
      expect((await batchOf(b.batchId)).remainingGrams, 94);

      await harness.finish(tester);
    });

    testWidgets('拼配：改一支克数，总粉量与两支占比跟着变', (tester) async {
      await harness.addBeanWithBatch(name: '花魁');
      await harness.addBeanWithBatch(name: '曼特宁');

      await pumpForm(tester);
      await pickBean(tester, 0, '花魁');
      await tester.tapKey('brew.addPick');
      await pickBean(tester, 1, '曼特宁');
      await tester.fillField('brew.beanGrams.0', '10');
      await tester.fillField('brew.beanGrams.1', '10');
      await tester.pumpAndSettle();
      expect(await textOf(tester, 'brew.dose'), '20 g');

      await tester.fillField('brew.beanGrams.1', '30');
      await tester.pumpAndSettle();

      expect(await textOf(tester, 'brew.dose'), '40 g');
      expect(await textOf(tester, 'brew.share.0'), '占比 25%');
      expect(await textOf(tester, 'brew.share.1'), '占比 75%');

      await harness.finish(tester);
    });

    testWidgets('拼配：小数克数之和仍正好等于总粉量', (tester) async {
      await harness.addBeanWithBatch(name: '花魁');
      await harness.addBeanWithBatch(name: '曼特宁');
      await harness.addBeanWithBatch(name: '耶加雪菲');

      await pumpForm(tester);
      await pickBean(tester, 0, '花魁');
      await tester.tapKey('brew.addPick');
      await pickBean(tester, 1, '曼特宁');
      await tester.tapKey('brew.addPick');
      await pickBean(tester, 2, '耶加雪菲');
      await tester.fillField('brew.beanGrams.0', '3.3');
      await tester.fillField('brew.beanGrams.1', '3.3');
      await tester.fillField('brew.beanGrams.2', '3.4');
      await tester.tapSaveButton();

      final BrewLog log = (await logs()).single;
      expect(log.doseGrams, 10);
      expect(
        log.beanUsages.fold<double>(
          0,
          (double s, BeanUsage u) => s + u.doseGrams,
        ),
        closeTo(10, 0.001),
        reason: '各支克数之和必须正好等于总粉量',
      );

      await harness.finish(tester);
    });

    testWidgets('拼配：有豆子没填克数时拦住保存', (tester) async {
      await harness.addBeanWithBatch(name: '花魁');
      await harness.addBeanWithBatch(name: '曼特宁');

      await pumpForm(tester);
      await pickBean(tester, 0, '花魁');
      await tester.tapKey('brew.addPick');
      await pickBean(tester, 1, '曼特宁');
      await tester.fillField('brew.beanGrams.0', '14');
      // 第二支留空。
      await tester.tapSaveButton();

      expect(find.textContaining('每支豆子都要填'), findsOneWidget);
      expect(await logs(), isEmpty, reason: '克数不全时不该落库');

      await harness.finish(tester);
    });

    testWidgets('单支路径不变：粉量仍是可编辑输入框，也没有占比行', (tester) async {
      await harness.addBeanWithBatch(name: '花魁');

      await pumpForm(tester);
      await pickBean(tester, 0, '花魁');

      expect(
        find.byKey(const Key('brew.beanGrams.0')),
        findsNothing,
        reason: '单支不显示每支克数',
      );
      expect(find.byKey(const Key('brew.share.0')), findsNothing);
      // 滚到「核心参数」再断言：视口外的控件不会被构建。
      await tester.scrollTo(find.byKey(const Key('brew.dose')));
      expect(
        find.descendant(
          of: find.byKey(const Key('brew.dose')),
          matching: find.byType(EditableText),
        ),
        findsOneWidget,
        reason: '单支时粉量仍是直接填',
      );

      await tester.fillField('brew.dose', '15');
      await tester.tapSaveButton();

      final BrewLog log = (await logs()).single;
      expect(log.doseGrams, 15);
      expect(log.beanUsages.single.doseGrams, 15);
      expect(log.isBlend, isFalse);

      await harness.finish(tester);
    });

    testWidgets('总时间是「分 + 秒」两框，内部存总秒数', (tester) async {
      await harness.addBeanWithBatch(name: '花魁');

      await pumpForm(tester);
      await pickBean(tester, 0, '花魁');
      await tester.fillField('brew.totalTimeMin', '2');
      await tester.fillField('brew.totalTimeSec', '35');
      await tester.pumpAndSettle();

      expect(find.textContaining('2:35'), findsOneWidget, reason: '提示行给出总时长');

      await tester.tapSaveButton();

      expect((await logs()).single.totalTimeSeconds, 155);

      await harness.finish(tester);
    });

    testWidgets('总时间两框都留空 = 未记录，不会变成 0 秒', (tester) async {
      await harness.addBeanWithBatch(name: '花魁');

      await pumpForm(tester);
      await pickBean(tester, 0, '花魁');
      await tester.tapSaveButton();

      expect(
        (await logs()).single.totalTimeSeconds,
        isNull,
        reason: '都留空仍是「没记」，不是 0 秒',
      );

      await harness.finish(tester);
    });

    testWidgets('总时间只填一个框也合法：另一个按 0 算', (tester) async {
      await harness.addBeanWithBatch(name: '花魁');

      await pumpForm(tester);
      await pickBean(tester, 0, '花魁');
      await tester.fillField('brew.totalTimeSec', '35');
      await tester.tapSaveButton();

      expect((await logs()).single.totalTimeSeconds, 35);

      await harness.finish(tester);
    });

    testWidgets('分/秒各自有上限；总分超过 3600 时按总分报错（文案没有多余空格）', (tester) async {
      await pumpForm(tester);

      // 分本身的越界值是 61：60 分是合法的（= 3600 秒，见 M3-T22）。
      await tester.fillField('brew.totalTimeMin', '61');
      await tester.tapSaveButton();
      expect(find.text('分应在 0–60 之间'), findsOneWidget);
      expect(find.text('总时间应在 0–3600 秒之间'), findsOneWidget);

      // 61 × 60 + 1 = 3661 > 3600：M3-T12 的上下限落到**总分**上。
      await tester.fillField('brew.totalTimeMin', '61');
      await tester.fillField('brew.totalTimeSec', '1');
      await tester.tapSaveButton();

      expect(find.text('总时间应在 0–3600 秒之间'), findsOneWidget);
      expect(
        find.text('总时间应在 0–3600 秒 之间'),
        findsNothing,
        reason: '「秒」后面那个多余空格要去掉',
      );

      await harness.finish(tester);
    });
  });

  /// M3-T20 F1（回归）：**整体 0 秒是一个真实记录过的值**。
  ///
  /// M3-T15 把 `_secondsText(0)` 写成了空串，而 `_minutesText(0)` 本来也是空串，
  /// 于是「分 + 秒」两框都空被 `_totalSecondsInput` 判成 `null`（未记录）。
  /// 结果：打开一条 `totalTimeSeconds == 0` 的旧记录、直接保存，
  /// 0 秒就被改写成「未记录」。这里把「0 秒原样往返」钉死。
  group('M3-T20 总时间的 0 秒往返', () {
    /// 造一条带单支豆子的记录（总时间由调用方指定），返回落库后的实体。
    Future<BrewLog> seedLog({required int? totalTimeSeconds}) async {
      final a = await harness.addBeanWithBatch(name: '花魁');
      final DateTime at = DateTime(2026, 1, 1, 8);
      final int logId =
          (await harness.container
                  .read(brewLogRepositoryProvider)
                  .save(
                    BrewLog(
                      beanId: a.beanId,
                      method: BrewMethod.pourOver,
                      doseGrams: 15,
                      totalTimeSeconds: totalTimeSeconds,
                      brewedAt: at,
                      createdAt: at,
                      updatedAt: at,
                      beanUsages: <BeanUsage>[
                        BeanUsage(
                          beanId: a.beanId,
                          batchId: a.batchId,
                          doseGrams: 15,
                        ),
                      ],
                    ),
                  ))
              .brewLogId;
      return (await harness.container
          .read(brewLogRepositoryProvider)
          .getById(logId))!;
    }

    /// 打开一条**已存在**的记录（豆子列表来自 drift 流：先给点真实时间）。
    Future<void> pumpEdit(WidgetTester tester, BrewLog existing) async {
      await tester.pumpWidget(
        harness.app(MaterialApp(home: BrewLogFormPage(existing: existing))),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
    }

    Future<List<BrewLog>> logs() =>
        harness.container.read(brewLogRepositoryProvider).getAll();

    testWidgets('打开 0 秒的记录直接保存：落库仍是 0 秒，不是「未记录」', (tester) async {
      final BrewLog existing = await seedLog(totalTimeSeconds: 0);
      await pumpEdit(tester, existing);

      // 整体 0 秒写进「秒」框（旧版本就是这个行为）；「分」框留空。
      expect(await tester.readField('brew.totalTimeSec'), '0');
      expect(await tester.readField('brew.totalTimeMin'), '');

      await tester.tapSaveButton();

      expect(
        (await logs()).single.totalTimeSeconds,
        0,
        reason: '整体 0 秒要能原样存回，不能被改写成「未记录」（null）',
      );

      await harness.finish(tester);
    });

    testWidgets('打开 120 秒的记录：分框 2、秒框留空，保存仍是 120 秒', (tester) async {
      final BrewLog existing = await seedLog(totalTimeSeconds: 120);
      await pumpEdit(tester, existing);

      expect(await tester.readField('brew.totalTimeMin'), '2');
      expect(
        await tester.readField('brew.totalTimeSec'),
        '',
        reason: '整体不是 0、只是被 60 整除的余数，才留空',
      );

      await tester.tapSaveButton();

      expect((await logs()).single.totalTimeSeconds, 120);

      await harness.finish(tester);
    });
  });

  /// M3-T20 F4：「豆子必填」不能被 **loading 窗口**绕过。
  ///
  /// `ref.read(beanListProvider).value ?? const <CoffeeBean>[]` 把
  /// **首次加载中（`.value == null`、`isLoading == true`）** 与
  /// **豆库真的为空**当成同一件事：在 StreamProvider 首次发射前点保存，
  /// 豆库非空也会被放行，落一条无豆记录 —— 正是「豆子必填」想避免的。
  ///
  /// 这里直接把 provider 覆盖成对应的 `AsyncValue`，避免依赖真实发射时序。
  group('M3-T20 豆子必填与加载窗口', () {
    /// 打开记录表单；豆子列表由 [beanListProvider] 的覆盖决定。
    Future<void> pumpForm(WidgetTester tester) async {
      await tester.pumpWidget(
        harness.app(const MaterialApp(home: BrewLogFormPage())),
      );
      await tester.pumpAndSettle();
    }

    Future<List<BrewLog>> logs() =>
        harness.container.read(brewLogRepositoryProvider).getAll();

    testWidgets('豆子列表还在首次加载时就点保存：拦下并提示，不落无豆记录', (tester) async {
      // 注意顺序：`useOverrides` 会重建数据库与容器，夹具必须在它之后造。
      harness.useOverrides(
        () => [
          // 首次发射前的真实状态：`.value` 是 null、`isLoading` 是 true。
          beanListProvider.overrideWithValue(
            const AsyncValue<List<CoffeeBean>>.loading(),
          ),
        ],
      );
      // 豆库**非空**：只是 provider 还没发射出来。
      await harness.addBeanWithBatch(name: '花魁');

      await pumpForm(tester);
      await tester.tapSaveButton();

      expect(find.textContaining('豆子列表还在加载'), findsOneWidget);
      expect(await logs(), isEmpty, reason: '加载中放行会落一条无豆记录，等于绕过了「豆子必填」');

      await harness.finish(tester);
    });

    testWidgets('豆子列表读取出错时仍然放行：数据库报错不该把用户锁死', (tester) async {
      harness.useOverrides(
        () => [
          beanListProvider.overrideWithValue(
            AsyncValue<List<CoffeeBean>>.error(
              Exception('豆库读取失败'),
              StackTrace.empty,
            ),
          ),
        ],
      );

      await pumpForm(tester);
      await tester.tapSaveButton();

      expect(find.textContaining('豆子列表还在加载'), findsNothing);
      expect(
        await logs(),
        hasLength(1),
        reason: 'hasError 不是 loading：按「豆库为空」处理，放行首杯',
      );

      await harness.finish(tester);
    });
  });

  /// M3-T22（G5 的阻断项 B1 与建议 S1 / S3）。
  ///
  /// **B1**：新加的上下限不能把历史记录锁死。库里可能存着越界值 —— 例如
  /// `totalTimeSeconds = 3600` 的旧记录，在「分/秒各 ≤ 59」下根本没有合法写法
  /// （最大 3599），`total > 3600` 那条成了死代码。所以：**等于打开时的原值
  /// 一律放行，改了才按新上下限拦**；同时把「分」的上限放到 60，让
  /// `60:00 = 3600` 真的可达。
  ///
  /// **S1**：`FormState.validate()` 只校验在册字段，而 `ListView` 会销毁滚出
  /// 视口的输入框（`EditableText.wantKeepAlive => hasFocus`），保存按钮却在
  /// 常驻的 `bottomNavigationBar` 上，所以 `_save()` 里还要有一层直接读控制器
  /// 文本的兜底复查。
  ///
  /// **S3**：ⓘ 弹窗里的「每圈 click / 零点」要按**各自**的来源措辞 ——
  /// 磨豆机字段为空时取的是记录里的快照，不能一概说成「这台磨豆机」的。
  group('M3-T22 越界历史值放行与 3600 可达', () {
    Future<void> pumpForm(WidgetTester tester, {BrewLog? existing}) async {
      await tester.pumpWidget(
        harness.app(MaterialApp(home: BrewLogFormPage(existing: existing))),
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();
    }

    Future<List<BrewLog>> logs() =>
        harness.container.read(brewLogRepositoryProvider).getAll();

    Future<void> pickBean(WidgetTester tester, String name) async {
      await tester.tapKey('brew.bean.0');
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    /// 行内校验的直接探针：`validate()` 为 true 就等于「不飘红、不拦保存」。
    /// 顺手 pump 一帧，让可能出现的错误文案真的渲染出来。
    Future<bool> formValidates(WidgetTester tester) async {
      final bool ok = tester.state<FormState>(find.byType(Form)).validate();
      await tester.pump();
      return ok;
    }

    /// 造一条带单支豆子的记录（越界值由调用方给），返回落库后的实体。
    Future<BrewLog> seedLog({
      double? doseGrams,
      double? waterGrams,
      double? waterTemp,
      int? totalTimeSeconds,
      int? grinderId,
      double? zeroPointSnapshot,
      int? clicksPerRevolutionSnapshot,
    }) async {
      final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 500);
      final DateTime at = DateTime(2026, 1, 1, 8);
      final int logId =
          (await harness.container
                  .read(brewLogRepositoryProvider)
                  .save(
                    BrewLog(
                      beanId: a.beanId,
                      grinderId: grinderId,
                      grinderZeroPointSnapshot: zeroPointSnapshot,
                      grinderClicksPerRevolutionSnapshot:
                          clicksPerRevolutionSnapshot,
                      method: BrewMethod.pourOver,
                      doseGrams: doseGrams,
                      waterGrams: waterGrams,
                      waterTemp: waterTemp,
                      totalTimeSeconds: totalTimeSeconds,
                      brewedAt: at,
                      createdAt: at,
                      updatedAt: at,
                      beanUsages: <BeanUsage>[
                        BeanUsage(
                          beanId: a.beanId,
                          batchId: a.batchId,
                          doseGrams: doseGrams ?? 0,
                        ),
                      ],
                    ),
                  ))
              .brewLogId;
      return (await harness.container
          .read(brewLogRepositoryProvider)
          .getById(logId))!;
    }

    /// 造一台磨豆机；「每圈 click / 零点」可以留空（存量旧机器就是这样）。
    Future<int> seedGrinder({
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

    testWidgets('60 分 + 空秒 = 3600 秒：合法，且真的能存下来', (tester) async {
      await harness.addBeanWithBatch(name: '花魁');
      await pumpForm(tester);
      await pickBean(tester, '花魁');

      await tester.fillField('brew.totalTimeMin', '60');

      expect(
        await formValidates(tester),
        isTrue,
        reason: '上限 59 时 60 分不合法，「总时间 ≤ 3600 秒」这个承诺就永远填不出来',
      );
      expect(find.textContaining('应在'), findsNothing, reason: '60 分不该飘红');

      await tester.tapSaveButton();

      expect(
        (await logs()).single.totalTimeSeconds,
        3600,
        reason: 'round-trip',
      );

      await harness.finish(tester);
    });

    testWidgets('60 分 01 秒 = 3601 秒：由总分那条拦住', (tester) async {
      await harness.addBeanWithBatch(name: '花魁');
      await pumpForm(tester);
      await pickBean(tester, '花魁');

      await tester.fillField('brew.totalTimeMin', '60');
      await tester.fillField('brew.totalTimeSec', '1');
      await tester.tapSaveButton();

      expect(find.text('总时间应在 0–3600 秒之间'), findsOneWidget);
      expect(
        find.textContaining('分应在'),
        findsNothing,
        reason: '分与秒各自都合法，越界的是总分',
      );
      expect(await logs(), isEmpty, reason: '越界不该落库');

      await harness.finish(tester);
    });

    testWidgets('打开 7200 秒的历史记录：不飘红、原样存回 7200', (tester) async {
      final BrewLog existing = await seedLog(totalTimeSeconds: 7200);
      await pumpForm(tester, existing: existing);

      // 7200 / 60 = 120 分：旧上限下这是个「一打开就报错」的值。
      expect(await tester.readField('brew.totalTimeMin'), '120');
      expect(
        await formValidates(tester),
        isTrue,
        reason: '没改动过的历史值，行内 validator 也要放行',
      );
      expect(find.textContaining('应在'), findsNothing, reason: '用户什么都没做，不该飘红');

      await tester.tapSaveButton();

      expect((await logs()).single.totalTimeSeconds, 7200, reason: '原样存回');

      await harness.finish(tester);
    });

    testWidgets('打开 dose/water/waterTemp 都越界的历史记录：不飘红、原样存回', (tester) async {
      // 视口放宽一点，保证这三个框都在册（在册才谈得上「行内 validator 放行」）。
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // 这三个字段在加上下限之前根本没有 validator，库里完全可能存着越界值。
      final BrewLog existing = await seedLog(
        doseGrams: 250,
        waterGrams: 3001,
        waterTemp: 120,
      );
      await pumpForm(tester, existing: existing);

      expect(await tester.readField('brew.dose'), '250');
      expect(await tester.readField('brew.water'), '3001');
      expect(await tester.readField('brew.waterTemp'), '120');
      expect(await formValidates(tester), isTrue, reason: '没改动过的历史值不能被新上下限锁死');
      expect(find.textContaining('应在'), findsNothing, reason: '不该飘红');

      await tester.tapSaveButton();

      final BrewLog saved = (await logs()).single;
      expect(saved.doseGrams, 250);
      expect(saved.waterGrams, 3001);
      expect(saved.waterTemp, 120);

      await harness.finish(tester);
    });

    testWidgets('把越界的历史值改成另一个越界值：这时要拦住', (tester) async {
      final BrewLog existing = await seedLog(
        waterGrams: 3001,
        totalTimeSeconds: 7200,
      );
      await pumpForm(tester, existing: existing);

      // 水量 3001 → 3002：改过了，就得按新上下限来。
      await tester.fillField('brew.water', '3002');
      await tester.tapSaveButton();

      expect(find.text('水量应在 0–2000 g 之间'), findsOneWidget);
      expect((await logs()).single.waterGrams, 3001, reason: '拦住就不该落库');

      // 总时间 7200 → 7260 秒同理。
      await tester.fillField('brew.totalTimeMin', '121');
      await tester.tapSaveButton();

      expect(find.text('总时间应在 0–3600 秒之间'), findsOneWidget);
      expect((await logs()).single.totalTimeSeconds, 7200);

      await harness.finish(tester);
    });

    testWidgets('S1：越界值随字段滚出视口、从 Form 反注册后，保存仍被兜底拦下', (tester) async {
      await harness.addBeanWithBatch(name: '花魁');
      await pumpForm(tester);
      await pickBean(tester, '花魁');

      await tester.fillField('brew.water', '3001');

      // ListView 只保活**有焦点**的输入框（`EditableText.wantKeepAlive`）：
      // 先让它失焦，再滚回顶部，核心参数那一段就会被销毁、从 Form 里反注册。
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('brew.water')),
        findsNothing,
        reason: '前提：这个框真的被销毁了，行内 validator 已经看不到它',
      );

      await tester.tapSaveButton();

      expect(
        find.text('水量应在 0–2000 g 之间'),
        findsOneWidget,
        reason: '_save() 的兜底复查要拦住',
      );
      expect(await logs(), isEmpty, reason: '不能静默存下越界数据');

      await harness.finish(tester);
    });

    testWidgets('S3：每圈 click 来自记录快照时，ⓘ 弹窗要说明来源', (tester) async {
      // 这台磨豆机没填「每圈几 click」：那个数来自记录里的快照，零点才是当前值。
      final int grinderId = await seedGrinder(
        clicksPerRevolution: null,
        zeroPoint: 0,
      );
      final BrewLog existing = await seedLog(
        grinderId: grinderId,
        zeroPointSnapshot: 0,
        clicksPerRevolutionSnapshot: 30,
      );
      await pumpForm(tester, existing: existing);

      await tester.tapKey('brew.grindInfo');

      expect(
        find.text('每圈 30 click（记录里的快照） · 零点 0（这台磨豆机）'),
        findsOneWidget,
        reason: '两个数来源不同就分别标注',
      );
      expect(
        find.textContaining('这台磨豆机：每圈 30 click'),
        findsNothing,
        reason: '把记录里的快照说成「这台磨豆机的值」是事实性错误',
      );

      await tester.tapTextScrolled('知道了');
      await harness.finish(tester);
    });

    testWidgets('S3：磨豆机两个字段都空时，ⓘ 弹窗整行写「记录里的快照」', (tester) async {
      final int grinderId = await seedGrinder(
        clicksPerRevolution: null,
        zeroPoint: null,
      );
      final BrewLog existing = await seedLog(
        grinderId: grinderId,
        zeroPointSnapshot: 12,
        clicksPerRevolutionSnapshot: 30,
      );
      await pumpForm(tester, existing: existing);

      await tester.tapKey('brew.grindInfo');

      expect(find.text('记录里的快照：每圈 30 click · 零点 12'), findsOneWidget);
      expect(
        find.textContaining('这台磨豆机'),
        findsNothing,
        reason: '两个数都来自记录，不能提「这台磨豆机」',
      );

      await tester.tapTextScrolled('知道了');
      await harness.finish(tester);
    });
  });
}
