import 'package:beanclick/data/providers.dart';
import 'package:beanclick/features/beans/grinder_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

/// 磨豆机表单：保存被拦时必须有**看得见**的提示（M3-T39）。
///
/// 品牌 / 型号在数据库上有 `checkTextLength(min:1)`：若它们的 `FormField`
/// 因滚出视口而注销，`validate()` 会放行，空值会一路撞到 DB 上、用户看到的是
/// 一句 `保存失败：InvalidDataException…`，而不是「请填写品牌」。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> pumpGrinderForm(WidgetTester tester) async {
    await tester.pumpWidget(
      harness.app(const MaterialApp(home: GrinderFormPage())),
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

  testWidgets('品牌/型号留空且已被滚出销毁：给友好提示，不落到数据库异常', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpGrinderForm(tester);

    // 把其余必填项填好，只剩品牌 / 型号留空 —— 这样 `validate()` 的其它字段
    // 都通过，缺口才会暴露出来。
    await fill(tester, 'grinder.clicksPerRevolution', '30');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // 滚到底：整段「机型」（品牌 / 型号）离开视口。
    //
    // ⚠️ 下面那条前置断言依赖「构建窗口」的具体数值（窗口公式与实测余量写在
    // `bean_form_test.dart` 的 G5-S1 用例里）。**若它因前提变红，正确处置是
    // 重新测量并调整视口 / 拖拽量，不是删掉前置断言** —— 删了这条用例就不再
    // 覆盖「品牌/型号被回收 → validate() 放行 → 撞 DB」这个缺口
    // （会退化成一条永远绿的装饰）。
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
    await tester.pumpAndSettle();

    // **几何前提**（与动作无关，故钉在点保存之前）：品牌 / 型号真的已经被销毁
    // —— `validate()` 因此看不到它们，空值会一路走到数据库的
    // `checkTextLength(min:1)` 上。几何一漂移，这里会响亮变红、失败方向安全。
    expect(
      find.byKey(const Key('grinder.brand'), skipOffstage: false),
      findsNothing,
      reason: '前提：品牌框已被销毁，覆盖的才是「注册表缺项」这条缺口',
    );

    await tapSave(tester);

    // 被拦住的后置证据：页面没关、库没变（任何布局下都成立，不守护几何）。
    expect(find.text('新增磨豆机'), findsOneWidget, reason: '被拦下时表单不该被关掉');
    expect(
      await harness.container.read(grinderRepositoryProvider).getAll(),
      isEmpty,
      reason: '必填项没填时不该落库',
    );

    // 本卡要修的：用户必须看得到一条**友好**的提示，而不是数据库异常原文。
    expect(
      find.textContaining('保存失败'),
      findsNothing,
      reason: '数据库异常不该端到用户面前（M3-T39）',
    );
    expect(find.text('必填项还没填完，请检查标红提示'), findsOneWidget);

    await harness.finish(tester);
  });
}
