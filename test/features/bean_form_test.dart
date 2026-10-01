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

  /// 主动确认烘焙日期：点开日历，再点「确定」。
  ///
  /// 本文件用的是裸 `MaterialApp`（没装中文本地化代理），
  /// 所以 `showDatePicker` 的确认按钮文案是英文 `OK`。
  Future<void> pickRoastDate(WidgetTester tester) async {
    final Finder open = find.text('选择日期');
    await tester.scrollTo(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
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
      await pickRoastDate(tester);
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
      await pickRoastDate(tester);
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
      await pickRoastDate(tester);
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
      await pickRoastDate(tester);
      // 购入总重本来就不预填（M3-T31 一并清掉了），这里显式留空以确保走「没填」那条分支。
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
      await pickRoastDate(tester);
      await fill(tester, 'bean.remaining', '200');
      await fill(tester, 'bean.price', '88.55');
      await tapSave(tester);

      final CoffeeBean bean = await onlyBean();
      expect((await onlyBatch(bean.id!)).price, 88.55);

      await harness.finish(tester);
    });

    testWidgets('输入三位小数时被拦下（保留旧值），最终存的是合法值', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await pickRoastDate(tester);
      await fill(tester, 'bean.remaining', '200');
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
      // 先填上面的风味标签，再往下走「第一袋」——`fill` 里的
      // `scrollUntilVisible` 只朝一个方向滚，顺序反了就回不去（脚手架已记的坑）。
      await fill(tester, 'bean.flavors', '柑橘😀、花香🔥');
      await pickRoastDate(tester);
      await fill(tester, 'bean.remaining', '200');
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
      await pickRoastDate(tester);
      await fill(tester, 'bean.remaining', '200');
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
    /// 主动确认日期后再点「清除日期」——M3-T31 起表单不再预填「今天」，
    /// 得先自己选一次，「清除日期」按钮才会出现。
    Future<void> clearRoastDate(WidgetTester tester) async {
      await pickRoastDate(tester);
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
      // 把余量框滚进视口并清空（新表单本来就没有预填，这一步是为了走**行内**
      // 校验那条路径）。
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

  group('保存路径的兜底要覆盖面（M3-T35 / M3-T33）', () {
    testWidgets('名称留空且名称框已被滚出销毁：被拦下、有提示、不落库、不出数据库异常', (tester) async {
      // 320×568 是 iPhone SE 一代的逻辑尺寸（常用机型里最小的一档）。
      // 这个尺寸下把表单滚到「第一袋」底部时，整段「基本信息」都落在 `ListView`
      // 的 cacheExtent 之外 → 名称框连同它的 `FormField` 一起被销毁、不再注册进
      // `Form`，`validate()` 直接放行（M3-T35 的复现条件）。
      //
      // ⚠️ 下面那条前置断言依赖「构建窗口」的具体数值（窗口公式与实测余量写在
      // 本文件 G5-S1 那条用例的注释里）。**若它因前提变红，正确处置是重新测量
      // 并调整视口 / 拖拽量，不是删掉前置断言** —— 删了这条用例就不再覆盖
      // M3-T35 的缺口（会退化成一条永远绿的装饰）。
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpBeanForm(tester);
      await pickRoastDate(tester);
      await fill(tester, 'bean.remaining', '200');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('bean.name'), skipOffstage: false),
        findsNothing,
        reason: '前置条件：名称框必须真的已被销毁，否则 validate() 会自己拦住',
      );

      await tapSave(tester);

      expect(
        find.textContaining('保存失败'),
        findsNothing,
        reason: '数据库异常不该端到用户面前（M3-T35）',
      );
      expect(find.text('请先填写豆子名称'), findsOneWidget);
      expect(find.text('新增咖啡豆'), findsOneWidget, reason: '被拦下时表单不该被关掉');
      expect(
        await harness.container.read(beanRepositoryProvider).getAll(),
        isEmpty,
        reason: '名称为空时不应落库',
      );

      await harness.finish(tester);
    });

    testWidgets('其它行内校验失败（余量 > 购入总重）：保存也要给看得见的提示', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await pickRoastDate(tester);
      await fill(tester, 'bean.initial', '200');
      await fill(tester, 'bean.remaining', '250');
      await tapSave(tester);

      // 行内错误照常渲染；但保存路径不能只是无声 `return` —— 行内错误可能落在
      // 视口之外，用户会以为「点了没反应」（M3-T33）。
      expect(find.textContaining('剩余克数不能大于购入总重'), findsOneWidget);
      expect(find.text('表单还有未通过的校验，请检查标红提示'), findsOneWidget);
      expect(
        await harness.container.read(beanRepositoryProvider).getAll(),
        isEmpty,
        reason: '校验不通过时不应落库',
      );

      await harness.finish(tester);
    });
  });

  group('新增豆子：烘焙日期与剩余克数必须主动确认（M3-T31）', () {
    testWidgets('只填名称就直接保存：被拦下并提示缺烘焙日期', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await tapSave(tester);

      expect(find.text('新增咖啡豆'), findsOneWidget, reason: '被拦下时表单不该被关掉');
      expect(
        await harness.container.read(beanRepositoryProvider).getAll(),
        isEmpty,
        reason: '没主动确认烘焙日期时不应落库',
      );
      // 这一条故意不把「第一袋」滚进视口：行内错误会落在首屏之外，用户看不到
      // ——保存路径必须自己给一条看得见的提示（M3-T31 的兜底）。
      // 此时日期与余量都没确认，提示按两条一起说。
      expect(find.text('请先填写第一袋的烘焙日期与剩余克数'), findsOneWidget);

      await harness.finish(tester);
    });

    testWidgets('主动选日期但不填余量：仍被拦下并提示缺剩余克数', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await pickRoastDate(tester);
      await tapSave(tester);

      expect(find.text('新增咖啡豆'), findsOneWidget, reason: '被拦下时表单不该被关掉');
      expect(
        await harness.container.read(beanRepositoryProvider).getAll(),
        isEmpty,
        reason: '没主动填写剩余克数时不应落库',
      );
      expect(find.text('请先填写第一袋的剩余克数'), findsOneWidget);
      // 精确匹配兜底文案，而不是 `textContaining('请填写第一袋的烘焙日期')`：
      // 后者在本仓**恒真**（兜底是「请**先**填写第一袋的烘焙日期」，`先` 插在
      // `请` 后，不构成子串；行内文案又是「请填写烘焙日期」）。改成精确匹配后，
      // 一旦兜底真把日期错报出来（`_firstBatchHint` 的 `noDate` 分支，
      // 见 `bean_form_page.dart`）这条就会红。
      expect(
        find.text('请先填写第一袋的烘焙日期'),
        findsNothing,
        reason: '日期已主动确认，不该被一起报出来',
      );

      await harness.finish(tester);
    });

    testWidgets('主动选日期 + 填余量后才能保存，批次记下这两项', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await pickRoastDate(tester);
      await fill(tester, 'bean.remaining', '180');
      await tapSave(tester);

      final CoffeeBean bean = await onlyBean();
      final BeanBatch batch = await onlyBatch(bean.id!);
      // 不断言具体日期：日历默认选中「今天」，断言它非空即可，
      // 免得测试在跨零点的一瞬间变红。
      expect(batch.roastDate, isNotNull);
      expect(batch.remainingGrams, 180);

      await harness.finish(tester);
    });

    testWidgets('余量 250 且不动购入总重也能存：购入总重不预填、不参与必填', (tester) async {
      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await pickRoastDate(tester);
      // 真实的 250 g 袋：购入总重一个字都不填。
      await fill(tester, 'bean.remaining', '250');
      await tapSave(tester);

      final CoffeeBean bean = await onlyBean();
      final BeanBatch batch = await onlyBatch(bean.id!);
      expect(batch.remainingGrams, 250);
      expect(batch.initialGrams, isNull, reason: '没确认过的「200 g」不该被当成购入总重落库');

      await harness.finish(tester);
    });
  });

  group('新增豆子：滚出视口后 cross-field 校验仍生效（G5-S1）', () {
    testWidgets('小屏把「第一袋」滚出 cacheExtent：购入总重 200 / 剩余 250 仍被拦下', (
      tester,
    ) async {
      // 320×568：小屏更容易把「第一袋」整段挤出 cacheExtent。
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpBeanForm(tester);
      await fill(tester, 'bean.name', '花魁');
      await pickRoastDate(tester);
      await fill(tester, 'bean.initial', '200');
      await fill(tester, 'bean.remaining', '250');

      // 取消焦点：聚焦中的 `EditableText` 会自己申请 keep-alive，那样这一段
      // 滚走之后仍会被保留（等于用户还停在那个框里，不是本用例要覆盖的状态）。
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // 精确回到 offset 0，让「第一袋」（`ListView` 的第 2 个 child）落到
      // cacheExtent 之外、连同它的 `FormField` 一起被销毁。
      //
      // 构建窗口（内容坐标，Flutter 3.47.5 实测）= `[offset - cacheExtent,
      // offset + 视口高 + cacheExtent]`；`SliverList` 的终点再叠加
      // `scrollOffset + cacheOrigin`，两者抵消后就是右端点表达式。
      // 左沿的实测依据：320×568 下 offset=920 时「基本信息」段仍在树上、
      // 1026（maxScroll）时已不在 → 左沿 1026-250=776 恰好越过该段底 ≈770。
      //
      // 两个必须注意的点：
      // - **不能**用「滚到底部」：**当**「更多信息」段高 < 视口高 + 250 时
      //   （当前 `extra_attributes` 注册表只有 5 个属性，实测成立），滚到
      //   maxScroll 那一段照样留在窗口内。这个前提是**数据相关**的 ——
      //   「加属性只改注册表」是设计目标，属性一多它就不成立了；
      // - **不能**用 `tester.scrollTo(name)`：它内部的 `ensureVisible` 会把列表
      //   停在 offset≈90；窗口下沿是 `offset + 视口高 + cacheExtent`，offset 一涨
      //   就把那一段圈回来（实测 offset=0 时不在树上、offset=90 时又在）。
      //   所以这里直接拖到顶。
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
      await tester.pumpAndSettle();

      // 前提（这条用例的意义所在）：那一段真的已经不在树上 —— 它挂着的
      // 「剩余 ≤ 购入总重」行内 validator 因此不参与 `validate()`。
      //
      // ⚠️ 前提余量很窄（320×568 实测）：`ListView` 视口高 **444**、cacheExtent
      // **250** → offset=0 时窗口右端点 = **694**；而「第一袋」那一段的起点在
      // 内容坐标 **770–786**（标题文字顶实测 786，减去段内上留白约 16 → 段顶
      // ≈770）→ **余量只有约 76–92px**。也就是说「基本信息」段只要再长这么多
      // （加一行说明、换更高的控件），这条前提断言就会翻红。
      // **变红时的正确处置：重新测量并调整视口 / 拖拽量，不是删掉前置断言**
      // —— 删了它，本用例就退化成一条永远绿的装饰。
      expect(
        find.byKey(const Key('bean.remaining'), skipOffstage: false),
        findsNothing,
        reason: '前提：第一袋已整段销毁，覆盖的才是「注册表缺项」这条缺口',
      );

      await tapSave(tester);

      expect(
        await harness.container.read(beanRepositoryProvider).getAll(),
        isEmpty,
        reason: '购入总重 200、剩余 250 不该落库',
      );
      expect(find.text('剩余克数不能大于购入总重，请核对第一袋的两个数字'), findsOneWidget);

      await harness.finish(tester);
    });
  });
}
