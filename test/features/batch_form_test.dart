import 'package:beanclick/data/providers.dart';
import 'package:beanclick/features/beans/batch_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

/// 批次表单：保存被拦时必须有**看得见**的提示（M3-T39）。
///
/// 同族缺口见 `bean_form_page.dart` 的 `_blockingHint` 注释：
/// 表单在 `ListView` 里，视口外的控件可能整段被销毁 → 它的 `FormField`
/// 不再注册进 `Form` → `validate()` 放行；即使没被销毁，行内红字也可能
/// 渲染在首屏之外，用户只会觉得「点了没反应」。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> pumpBatchForm(WidgetTester tester, int beanId) async {
    await tester.pumpWidget(
      harness.app(MaterialApp(home: BatchFormPage(beanId: beanId))),
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
    final Finder save = find.widgetWithText(FilledButton, '添加批次');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('剩余 250 / 购入总重 200：滚到底后保存被拦，并给出可见提示', (tester) async {
    // 320×568 是常用机型里最小的一档（iPhone SE 一代的逻辑尺寸）。
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final a = await harness.addBeanWithBatch(
      name: '花魁',
      remainingGrams: 200,
      initialGrams: 200,
    );
    await pumpBatchForm(tester, a.beanId);

    await fill(tester, 'batch.initial', '200');
    await fill(tester, 'batch.remaining', '250');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // 滚到底：行内红字被推到视口之外（用户看不到）。
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
    await tester.pumpAndSettle();

    await tapSave(tester);

    // 场景钉（在结论断言之前）：**行内红字此刻在视口之上、用户看不到** ——
    // 本卡覆盖的是「看不见错误 → 无声 return」这条路径。
    //
    // 注意**不能**用 `findsNothing` 来钉：finder 的 onstage 粒度与回收粒度同源，
    // 都是**顶层 sliver child**；本页整段 `FormSection('这一次买的')` 始终有
    // 一部分落在窗口内 → 段内红字对 finder 永远"存在"（对用户却是看不见的）。
    // 所以这里改钉几何：红字底边必须落在列表视口顶边之上。
    final Rect inlineError = tester.getRect(
      find.textContaining('剩余克数不能大于购入总重（'),
    );
    final double listTop = tester.getTopLeft(find.byType(ListView)).dy;
    expect(
      inlineError.bottom,
      lessThan(listTop),
      reason: '前提：行内红字此刻在视口之上（用户看不到），本卡覆盖"看不见错误 → 无声 return"',
    );

    // 这不是几何前提，而是「被拦住」的**后置证据**：表单未关 + 未多出批次。
    // 它在任何布局下都成立，**不守护几何** —— 本页这一档（字段被回收 →
    // `validate()` 放行 → 越界值落库）今天不可达，而理由是**段级**的：
    // `ListView` 的回收粒度是**顶层 sliver child**，本页只有两个（整段
    // `FormSection('这一次买的')` + `ExtraAttributesEditor`），两个 `FormField`
    // 都是该段的后代 —— 段只要有一角落进构建窗口，整段子树就都活着。回收条件是
    // `maxScroll - cacheExtent > 该 FormSection 的底沿`：320×568 实测
    // `maxScroll=428`、`cacheExtent=250` ⇒ 最大可回收前沿只有 178px，而该段底沿
    // 远在其后（本仓段级先例：`bean_form_page.dart` 的「基本信息整段不在树上」）。
    //
    // ⚠️ 「今天不可达」是**数据相关**的：`maxScroll` 随 `extra_attributes`
    // 注册表增长（该注册表的设计目标就是「加属性只改注册表」）。将来这一段真被
    // 回收时，本用例仍会正确地红/绿，只是这句话不再成立 —— 那时要补的是
    // 「越界值落库」那档的断言，而不是删掉本用例。
    expect(find.text('再来一袋'), findsOneWidget, reason: '被拦下时表单不该被关掉');
    expect(
      await harness.container.read(beanRepositoryProvider).batchesOf(a.beanId),
      hasLength(1),
      reason: '校验不通过时不该多出一个批次',
    );

    // 本卡要修的：用户必须看得到一条提示。
    expect(find.text('剩余克数不能大于购入总重，请核对这两个数字'), findsOneWidget);

    await harness.finish(tester);
  });
}
