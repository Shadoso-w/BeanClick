import 'package:beanclick/core/widgets/form_fields.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/features/beans/bean_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

/// 咖啡豆表单的一批修正验证。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> pumpBeanForm(WidgetTester tester, {CoffeeBean? bean}) async {
    await tester.pumpWidget(
      harness.app(MaterialApp(home: BeanFormPage(bean: bean))),
    );
    await tester.pumpAndSettle();
  }

  /// 按 key 滚入可视区并填值。
  Future<void> fill(WidgetTester tester, String key, String text) async {
    final Finder field = find.byKey(Key(key));
    await tester.scrollUntilVisible(
      field,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, text);
    await tester.pump();
  }

  Future<void> tapSave(WidgetTester tester) async {
    final Finder save = find.widgetWithText(FilledButton, '保存');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  /// 取这支豆子的唯一批次。
  ///
  /// 批次模型下余量/购入总重/价格都在批次上（见 `docs/M1-DATA-MODEL.md`），
  /// 服务端断言因此要落到批次，而不是豆子实体。
  Future<BeanBatch> onlyBatch(int beanId) async {
    final List<BeanBatch> batches = await harness.container
        .read(beanRepositoryProvider)
        .batchesOf(beanId);
    return batches.single;
  }

  Future<CoffeeBean> onlyBean() async {
    final List<CoffeeBean> beans = await harness.container
        .read(beanRepositoryProvider)
        .getAll();
    return beans.single;
  }

  group('烘焙日期改中文', () {
    test('formatDateChinese 输出 2026年1月1日', () {
      expect(formatDateChinese(DateTime(2026, 1, 1)), '2026年1月1日');
      expect(formatDateChinese(DateTime(2026, 12, 31)), '2026年12月31日');
    });

    test('formatDate 仍是 yyyy-MM-dd（其他日期字段不变）', () {
      expect(formatDate(DateTime(2026, 1, 1)), '2026-01-01');
    });

    testWidgets('表单里烘焙日期以中文显示', (tester) async {
      // 烘焙日期在批次上：先落一支带批次的豆，再打开它的编辑页。
      final a = await harness.addBeanWithBatch(
        name: '花魁',
        roastDate: DateTime(2026, 1, 1),
      );
      final CoffeeBean bean = (await harness.container
          .read(beanRepositoryProvider)
          .getById(a.beanId))!;

      await pumpBeanForm(tester, bean: bean);

      final Finder chinese = find.textContaining('2026年1月1日');
      await tester.scrollUntilVisible(
        chinese,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(chinese, findsWidgets);
      expect(find.text('2026-01-01'), findsNothing);

      await harness.finish(tester);
    });
  });

  group('库存校验：剩余不能大于购入总重', () {
    testWidgets('剩余 > 总量时报错且不保存', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await fill(tester, 'bean.initial', '100');
      await fill(tester, 'bean.remaining', '150');
      await tapSave(tester);

      expect(find.textContaining('剩余克数不能大于购入总重'), findsOneWidget);
      expect(
        await harness.container.read(beanRepositoryProvider).getAll(),
        isEmpty,
        reason: '校验不通过时不应落库',
      );

      await harness.finish(tester);
    });

    testWidgets('剩余 == 总量时允许保存（刚买满袋）', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await fill(tester, 'bean.initial', '200');
      await fill(tester, 'bean.remaining', '200');
      await tapSave(tester);

      final CoffeeBean bean = await onlyBean();
      expect((await onlyBatch(bean.id!)).remainingGrams, 200);

      await harness.finish(tester);
    });

    testWidgets('剩余 < 总量时正常保存', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await fill(tester, 'bean.initial', '200');
      await fill(tester, 'bean.remaining', '120');
      await tapSave(tester);

      final CoffeeBean bean = await onlyBean();
      expect((await onlyBatch(bean.id!)).remainingGrams, 120);

      await harness.finish(tester);
    });

    testWidgets('未填购入总重时不触发该校验', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      // 表单默认预填 200，这里显式清空才算「没填购入总重」。
      await fill(tester, 'bean.initial', '');
      await fill(tester, 'bean.remaining', '150');
      await tapSave(tester);

      final CoffeeBean bean = await onlyBean();
      final BeanBatch batch = await onlyBatch(bean.id!);
      expect(batch.remainingGrams, 150);
      expect(batch.initialGrams, isNull);

      await harness.finish(tester);
    });
  });

  group('价格最多两位小数', () {
    test('PriceInputFormatter 只放行两位小数', () {
      const PriceInputFormatter formatter = PriceInputFormatter();

      TextEditingValue apply(String text) => formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: text),
      );

      expect(apply('88').text, '88');
      expect(apply('88.5').text, '88.5');
      expect(apply('88.50').text, '88.50');
      // 三位小数被拒，保留旧值
      expect(apply('88.505').text, '');
      // 两个小数点被拒
      expect(apply('1.2.3').text, '');
      // 非数字被拒
      expect(apply('abc').text, '');
    });

    testWidgets('两位小数经表单保存后不丢精度', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await fill(tester, 'bean.price', '88.55');
      await tapSave(tester);

      final CoffeeBean bean = await onlyBean();
      expect((await onlyBatch(bean.id!)).price, 88.55);

      await harness.finish(tester);
    });

    testWidgets('输入三位小数时被拦下（保留旧值），最终存的是合法值', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      // 先输入合法值
      await fill(tester, 'bean.price', '88.50');
      // 再试第三个小数位：被 PriceInputFormatter 拒绝，值不变
      await fill(tester, 'bean.price', '88.505');
      await tapSave(tester);

      final CoffeeBean bean = await onlyBean();
      expect((await onlyBatch(bean.id!)).price, 88.50);

      await harness.finish(tester);
    });
  });

  group('风味标签过滤', () {
    test('filterTagInput 保留文字、数字与分隔符', () {
      expect(filterTagInput('柑橘、花香'), '柑橘、花香');
      expect(filterTagInput('草莓,奶油'), '草莓,奶油');
      expect(filterTagInput('莓果，蜂蜜'), '莓果，蜂蜜');
      expect(filterTagInput('Ethiopia 2024'), 'Ethiopia 2024');
    });

    test('filterTagInput 过滤表情与符号', () {
      expect(filterTagInput('柑橘😀花香'), '柑橘花香');
      expect(filterTagInput('花香🔥'), '花香');
      expect(filterTagInput('柑橘!!!'), '柑橘');
      expect(filterTagInput('a@b#c'), 'abc');
      expect(filterTagInput('柑橘（日晒）'), '柑橘日晒');
      expect(filterTagInput('花香·蜂蜜'), '花香蜂蜜');
    });

    test('filterTagInput 处理空串与纯符号', () {
      expect(filterTagInput(''), '');
      expect(filterTagInput('😀🎉'), '');
      expect(filterTagInput('，、,'), '，、,');
    });

    testWidgets('表单里粘贴含表情的标签会被过滤掉', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await fill(tester, 'bean.flavors', '柑橘😀、花香🔥');
      await tapSave(tester);

      final List<CoffeeBean> beans = await harness.container
          .read(beanRepositoryProvider)
          .getAll();
      expect(beans.single.flavorTags, <String>['柑橘', '花香']);

      await harness.finish(tester);
    });
  });

  group('庄园/处理厂为选填', () {
    testWidgets('不填庄园也能保存', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await tapSave(tester);

      final List<CoffeeBean> beans = await harness.container
          .read(beanRepositoryProvider)
          .getAll();
      expect(beans, hasLength(1));
      expect(beans.single.farm, isNull);

      await harness.finish(tester);
    });

    testWidgets('庄园字段标注了「选填」', (tester) async {
      await pumpBeanForm(tester);
      final Finder farm = find.byKey(const Key('bean.farm'));
      await tester.scrollUntilVisible(
        farm,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('选填'), findsWidgets);

      await harness.finish(tester);
    });
  });

  group('新增豆子：烘焙日期与剩余克数必填', () {
    /// 清掉表单预填的「今天」——不点一下「清除日期」就测不到「没选烘焙日期」。
    Future<void> clearRoastDate(WidgetTester tester) async {
      final Finder clear = find.byTooltip('清除日期');
      await tester.scrollTo(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
    }

    testWidgets('没选烘焙日期时保存被拦下', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await clearRoastDate(tester);
      await tapSave(tester);

      expect(find.text('请填写烘焙日期'), findsOneWidget);
      expect(
        await harness.container.read(beanRepositoryProvider).getAll(),
        isEmpty,
        reason: '校验不通过时不应落库',
      );

      await harness.finish(tester);
    });

    testWidgets('没填剩余克数时保存被拦下', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      // 表单默认预填 200，这里显式清空才算「没填剩余克数」。
      await fill(tester, 'bean.remaining', '');
      await tapSave(tester);

      expect(find.text('请填写剩余克数'), findsOneWidget);
      expect(
        await harness.container.read(beanRepositoryProvider).getAll(),
        isEmpty,
        reason: '校验不通过时不应落库',
      );

      await harness.finish(tester);
    });

    testWidgets('编辑既有豆子：没烘焙日期与余量也不拦（老数据仍能改别的字段）', (tester) async {
      // 老数据可能本来就没记烘焙日期、余量也见底。
      final a = await harness.addBeanWithBatch(
        name: '花魁',
        roastDate: null,
        remainingGrams: 0,
      );
      final CoffeeBean bean = (await harness.container
          .read(beanRepositoryProvider)
          .getById(a.beanId))!;

      await pumpBeanForm(tester, bean: bean);
      // 编辑页只有批次列表，没有「第一袋」那两个必填项。
      expect(find.byKey(const Key('bean.remaining')), findsNothing);

      await fill(tester, 'bean.name', '花魁（改）');
      await tapSave(tester);

      expect((await onlyBean()).name, '花魁（改）');

      await harness.finish(tester);
    });
  });
}
