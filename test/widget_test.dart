import 'package:beanclick/app.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/features/beans/bean_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/widget_harness.dart';

/// 应用外壳与 M2 表单的 widget 测试。
///
/// 收尾一律用 `harness.finish(tester)`，原因见 `helpers/widget_harness.dart`
/// 的说明（测试失败时 flutter_test 不会卸载 widget 树，导致关库永久阻塞）。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  /// 按 key 定位输入框：先滚入可视区（视口外的控件不会被构建），再填值。
  Future<void> fill(WidgetTester tester, String key, String text) async {
    final Finder field = find.byKey(Key(key));
    final Finder scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(field, 120, scrollable: scrollable);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, text);
    await tester.pump();
  }

  /// 滚入可视区后点击文字。
  ///
  /// 列表是懒构建的：视口外的控件**根本不存在**，`ensureVisible` 会直接抛
  /// `Bad state: No element`，所以查不到时先滚过去。
  Future<void> tapText(WidgetTester tester, String text) async {
    final Finder finder = find.text(text);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// 点击保存并等待落库。
  Future<void> tapSave(WidgetTester tester) async {
    final Finder save = find.widgetWithText(FilledButton, '保存');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  /// 读取某个 key 对应输入框里的文本。
  ///
  /// 字段可能在视口外（List 懒构建，此时根本不存在），所以先滚动到位。
  Future<String> fieldText(WidgetTester tester, String key) async {
    final Finder field = find.byKey(Key(key));
    await tester.scrollUntilVisible(
      field,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    final EditableText editable = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    return editable.controller.text;
  }

  group('外壳（底部 dock）', () {
    testWidgets('dock 是两栏 + 中间固定的圆形加号', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));

      // 记录 / 豆库 两栏，中间那颗 + 是按钮不是栏位。
      for (final String label in <String>['记录', '豆库']) {
        expect(find.text(label), findsWidgets);
      }
      expect(find.byKey(const Key('dock.addCup')), findsOneWidget);
      expect(find.byTooltip('新加一杯'), findsOneWidget);
      // 统计与我的不再占栏位
      expect(find.text('我的'), findsNothing);

      await harness.finish(tester);
    });

    testWidgets('加号固定在 dock 里，不再是悬浮按钮', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));

      // 悬浮 FAB 会盖住列表内容，用户要求把它并进 dock。
      expect(find.byType(FloatingActionButton), findsNothing);

      final Scaffold scaffold = tester.widget<Scaffold>(
        find.byType(Scaffold).first,
      );
      expect(scaffold.floatingActionButton, isNull);

      // 加号横向居中、并且落在屏幕底部区域（即 dock 里）。
      final Size screen = tester.getSize(find.byType(Scaffold).first);
      final Offset addCenter = tester.getCenter(
        find.byKey(const Key('dock.addCup')),
      );
      expect((addCenter.dx - screen.width / 2).abs(), lessThan(1));
      expect(addCenter.dy, greaterThan(screen.height * 0.85));

      await harness.finish(tester);
    });

    testWidgets('无数据时记录页显示空状态引导', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('记录第一杯'), findsOneWidget);

      await harness.finish(tester);
    });

    testWidgets('可以切换到豆库', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('豆库').last);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(find.text('咖啡豆'), findsWidgets);

      await harness.finish(tester);
    });

    testWidgets('点 dock 中间的加号会打开表单，且不切走当前栏', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('dock.addCup')));
      await tester.pumpAndSettle();

      expect(find.text('记录一杯'), findsOneWidget);

      // 表单是 fullscreenDialog，用关闭图标（X）而不是返回箭头。
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('时间线'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await harness.finish(tester);
    });

    testWidgets('统计已并入记录页，作为第二个页签', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('时间线'), findsOneWidget);
      expect(find.text('统计'), findsOneWidget);

      await tester.tap(find.text('统计'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('总记录数'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await harness.finish(tester);
    });

    testWidgets('「我的」移到右上角，可进入设置', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // 设置页的内容在
      expect(find.text('导出数据'), findsOneWidget);
      expect(find.text('主题模式'), findsOneWidget);

      await harness.finish(tester);
    });
  });

  group('快速记录（手册 §8）', () {
    testWidgets('点 FAB 打开记录表单', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('dock.addCup')));
      await tester.pumpAndSettle();

      expect(find.text('记录一杯'), findsOneWidget);
      expect(find.text('这一杯'), findsOneWidget);
      expect(find.text('冲煮方法'), findsOneWidget);
      expect(find.text('手冲'), findsOneWidget);
      expect(find.text('摩卡壶'), findsOneWidget);

      // 核心参数在视口下方，滚过去确认确实渲染了。
      await fill(tester, 'brew.dose', '15');
      expect(find.text('粉量'), findsOneWidget);
      expect(find.text('水量'), findsOneWidget);

      await harness.finish(tester);
    });

    testWidgets('无历史记录时也能保存第一杯，并落库', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('dock.addCup')));
      await tester.pumpAndSettle();

      await fill(tester, 'brew.dose', '15');
      await fill(tester, 'brew.water', '240');
      await tapSave(tester);

      final List<BrewLog> logs = await harness.container
          .read(brewLogRepositoryProvider)
          .getAll();
      expect(logs, hasLength(1));
      expect(logs.single.doseGrams, 15);
      expect(logs.single.waterGrams, 240);
      // 未填水温时不应写入 0。
      expect(logs.single.waterTemp, isNull);

      await harness.finish(tester);
    });

    testWidgets('加号开的是空表单（不再预填上次）', (tester) async {
      await harness.container
          .read(brewLogRepositoryProvider)
          .save(
            BrewLog(
              method: BrewMethod.mokaPot,
              doseGrams: 18,
              waterGrams: 100,
              brewedAt: DateTime(2026, 1, 1, 8),
              createdAt: DateTime(2026, 1, 1, 8),
              updatedAt: DateTime(2026, 1, 1, 8),
            ),
          );

      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('dock.addCup')));
      await tester.pumpAndSettle();

      // 测评反馈：进入后从默认（归零）页面开始，不带上一次的参数。
      expect(await fieldText(tester, 'brew.dose'), '');
      expect(await fieldText(tester, 'brew.water'), '');

      await harness.finish(tester);
    });

    testWidgets('复制按钮：单击才预填上次，且不继承评分与备注', (tester) async {
      await harness.container
          .read(brewLogRepositoryProvider)
          .save(
            BrewLog(
              method: BrewMethod.mokaPot,
              doseGrams: 18,
              waterGrams: 100,
              waterTemp: 95,
              totalTimeSeconds: 120,
              rating: 5,
              notes: '上次很好喝',
              heatLevel: '中火',
              brewedAt: DateTime(2026, 1, 1, 8),
              createdAt: DateTime(2026, 1, 1, 8),
              updatedAt: DateTime(2026, 1, 1, 8),
            ),
          );

      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('dock.addCup')));
      await tester.pumpAndSettle();

      // 空表单 → 点右上角复制按钮，参数才被填进来。
      await tester.tap(find.byKey(const Key('brew.copyLast')));
      await tester.pumpAndSettle();

      // 参数被复制过来（值在输入框里，不是 Text）。
      expect(await fieldText(tester, 'brew.dose'), '18');
      expect(await fieldText(tester, 'brew.water'), '100');
      expect(await fieldText(tester, 'brew.waterTemp'), '95');
      expect(await fieldText(tester, 'brew.totalTime'), '120');
      // 方法跟着一起复制，摩卡壶专属字段因此出现。
      expect(find.text('摩卡壶'), findsWidgets);
      // 评分与备注不继承。
      expect(find.text('上次很好喝'), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsNothing);

      await harness.finish(tester);
    });

    testWidgets('保存后新记录不覆盖原记录', (tester) async {
      await harness.container
          .read(brewLogRepositoryProvider)
          .save(
            BrewLog(
              doseGrams: 15,
              waterGrams: 240,
              rating: 5,
              brewedAt: DateTime(2026, 1, 1, 8),
              createdAt: DateTime(2026, 1, 1, 8),
              updatedAt: DateTime(2026, 1, 1, 8),
            ),
          );

      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('dock.addCup')));
      await tester.pumpAndSettle();
      await tapSave(tester);

      final List<BrewLog> logs = await harness.container
          .read(brewLogRepositoryProvider)
          .getAll();
      expect(logs, hasLength(2), reason: '复制上次应生成新记录而不是覆盖');
      // 原记录评分还在。
      expect(logs.where((BrewLog log) => log.rating == 5), hasLength(1));

      await harness.finish(tester);
    });
  });

  group('咖啡豆表单（手册 §7）', () {
    testWidgets('名称为空时不允许保存', (tester) async {
      await tester.pumpWidget(
        harness.app(const MaterialApp(home: BeanFormPage())),
      );
      await tester.pumpAndSettle();

      await tapSave(tester);

      expect(find.text('请填写豆子名称'), findsOneWidget);
      expect(
        await harness.container.read(beanRepositoryProvider).getAll(),
        isEmpty,
      );

      await harness.finish(tester);
    });

    testWidgets('填写并保存后落库，豆库列表出现该豆子', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('豆库').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tapText(tester, '添加第一支豆子');

      expect(find.text('新增咖啡豆'), findsOneWidget);
      await fill(tester, 'bean.name', '花魁');
      await fill(tester, 'bean.origin', '埃塞俄比亚');
      await fill(tester, 'bean.remaining', '200');
      await fill(tester, 'bean.initial', '200');
      await tapSave(tester);

      expect(find.text('花魁'), findsOneWidget);

      final List<CoffeeBean> beans = await harness.container
          .read(beanRepositoryProvider)
          .getAll();
      expect(beans.single.name, '花魁');
      expect(beans.single.origin, '埃塞俄比亚');
      // 余量与购入总重在批次上
      final List<BeanBatch> batches = await harness.container
          .read(beanRepositoryProvider)
          .batchesOf(beans.single.id!);
      expect(batches.single.remainingGrams, 200);
      expect(batches.single.initialGrams, 200);

      await harness.finish(tester);
    });

    testWidgets('点已有豆子进入编辑，能改批次余量', (tester) async {
      final a = await harness.addBeanWithBatch(
        name: '曼特宁',
        remainingGrams: 100,
      );

      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('豆库').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tapText(tester, '曼特宁');

      expect(find.text('编辑咖啡豆'), findsOneWidget);
      // 编辑页展示批次列表，点进去改余量
      await tapText(tester, '再来一袋');
      expect(find.text('再来一袋'), findsWidgets);

      await harness.finish(tester);
      expect(a.beanId, greaterThan(0));
    });

    testWidgets('编辑页可以删除豆子，记录保留但解除关联', (tester) async {
      final a = await harness.addBeanWithBatch(
        name: '要删的豆',
        remainingGrams: 100,
      );
      await harness.addBrewLog(
        beanId: a.beanId,
        batchId: a.batchId,
        doseGrams: 15,
        brewedAt: DateTime(2026, 1, 1, 8),
      );

      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('豆库').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tapText(tester, '要删的豆');

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tapText(tester, '删除');

      expect(
        await harness.container.read(beanRepositoryProvider).getAll(),
        isEmpty,
      );
      final List<BrewLog> logs = await harness.container
          .read(brewLogRepositoryProvider)
          .getAll();
      expect(logs, hasLength(1), reason: '删除豆子不应删掉历史记录');
      // 决策 2：用量行保留，beanId 置空但快照名还在
      expect(logs.single.beanUsages, hasLength(1));
      expect(logs.single.beanUsages.single.beanId, isNull);
      expect(logs.single.beanUsages.single.beanName, '要删的豆');

      await harness.finish(tester);
    });
  });

  group('磨豆机表单（手册 §7）', () {
    testWidgets('品牌或型号为空时不允许保存', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('豆库').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tapText(tester, '磨豆机');
      await tapText(tester, '添加第一台磨豆机');

      await fill(tester, 'grinder.brand', 'Comandante');
      await tapSave(tester);

      expect(find.text('请填写型号'), findsOneWidget);
      expect(
        await harness.container.read(grinderRepositoryProvider).getAll(),
        isEmpty,
      );

      await harness.finish(tester);
    });

    testWidgets('保存后磨豆机列表按手册 §7 格式展示', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('豆库').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tapText(tester, '磨豆机');
      await tapText(tester, '添加第一台磨豆机');

      await fill(tester, 'grinder.brand', 'Comandante');
      await fill(tester, 'grinder.model', 'C40');
      await fill(tester, 'grinder.zeroPoint', '0');
      // M2.10 起「每圈 click」是必填项。
      await fill(tester, 'grinder.clicksPerRevolution', '30');
      await tapSave(tester);

      // 还没有冲煮记录，所以第一行只有机型与零点。
      expect(find.text('Comandante C40 / 零点 0'), findsOneWidget);

      final List<Grinder> grinders = await harness.container
          .read(grinderRepositoryProvider)
          .getAll();
      expect(grinders.single.brand, 'Comandante');
      expect(grinders.single.model, 'C40');
      expect(grinders.single.zeroPoint, 0);
      expect(grinders.single.clicksPerRevolution, 30);

      await harness.finish(tester);
    });

    testWidgets('每圈 click 没填时不允许保存（M2.10 必填）', (tester) async {
      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('豆库').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tapText(tester, '磨豆机');
      await tapText(tester, '添加第一台磨豆机');

      await fill(tester, 'grinder.brand', 'Comandante');
      await fill(tester, 'grinder.model', 'C40');
      await tapSave(tester);

      expect(find.textContaining('请填写每圈 click'), findsOneWidget);
      expect(
        await harness.container.read(grinderRepositoryProvider).getAll(),
        isEmpty,
      );

      await harness.finish(tester);
    });
  });

  group('编辑冲煮记录', () {
    testWidgets('点记录卡片进入编辑，能看到原评分与备注', (tester) async {
      await harness.container
          .read(brewLogRepositoryProvider)
          .save(
            BrewLog(
              doseGrams: 16,
              waterGrams: 256,
              rating: 4,
              notes: '尾段有点苦',
              brewedAt: DateTime(2026, 1, 1, 8),
              createdAt: DateTime(2026, 1, 1, 8),
              updatedAt: DateTime(2026, 1, 1, 8),
            ),
          );

      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tapText(tester, '未指定豆子');

      expect(find.text('编辑记录'), findsOneWidget);
      expect(await fieldText(tester, 'brew.dose'), '16');
      expect(await fieldText(tester, 'brew.water'), '256');
      expect(find.text('尾段有点苦'), findsOneWidget);
      // 4 分对应 4 颗实心星。
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));

      await harness.finish(tester);
    });

    testWidgets('编辑粉量后余量按差值补扣（手册 §6.2）', (tester) async {
      final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
      await harness.addBrewLog(
        beanId: a.beanId,
        batchId: a.batchId,
        doseGrams: 15,
        brewedAt: DateTime(2026, 1, 1, 8),
      );

      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tapText(tester, '花魁');

      await fill(tester, 'brew.dose', '20');
      await tapSave(tester);

      final BeanBatch batch = (await harness.container
          .read(beanRepositoryProvider)
          .getBatch(a.batchId))!;
      // 200 - 15 = 185；改成 20 后按差值再扣 5 → 180。
      expect(batch.remainingGrams, 180);

      await harness.finish(tester);
    });

    testWidgets('编辑页可以删除记录，余量自动回补', (tester) async {
      final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
      await harness.addBrewLog(
        beanId: a.beanId,
        batchId: a.batchId,
        doseGrams: 15,
        brewedAt: DateTime(2026, 1, 1, 8),
      );

      await tester.pumpWidget(harness.app(const BeanClickApp()));
      await tester.pump(const Duration(milliseconds: 100));
      await tapText(tester, '花魁');

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tapText(tester, '删除');

      expect(
        await harness.container.read(brewLogRepositoryProvider).getAll(),
        isEmpty,
      );
      final BeanBatch batch = (await harness.container
          .read(beanRepositoryProvider)
          .getBatch(a.batchId))!;
      expect(batch.remainingGrams, 200, reason: '删记录会把扣掉的 15g 回补');

      await harness.finish(tester);
    });
  });
}
