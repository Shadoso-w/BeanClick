import 'package:beanclick/app.dart';
import 'package:beanclick/core/icons.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

/// 豆库页的新增入口（用户反馈：列表非空时无法新增）。
///
/// 中栏被「新加一杯」占用后，这里用右下角的浮动按钮补回入口，
/// 且动作跟随「咖啡豆 / 磨豆机」分段切换。
/// 图标统一是**圆圈加号**（见 `lib/core/icons.dart`）。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> gotoBeans(WidgetTester tester) async {
    await tester.pumpWidget(harness.app(const BeanClickApp()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('豆库').last);
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder addButton() => find.byWidgetPredicate(
    (Widget widget) =>
        widget is FloatingActionButton && widget.tooltip == '新增咖啡豆',
  );

  Finder addGrinderButton() => find.byWidgetPredicate(
    (Widget widget) =>
        widget is FloatingActionButton && widget.tooltip == '新增磨豆机',
  );

  testWidgets('豆库页始终有新增咖啡豆入口，图标是圆圈加号', (tester) async {
    await gotoBeans(tester);

    expect(addButton(), findsOneWidget);
    expect(
      find.descendant(of: addButton(), matching: find.byIcon(addCircleIcon)),
      findsOneWidget,
    );

    await harness.finish(tester);
  });

  testWidgets('列表非空时依然能新增咖啡豆', (tester) async {
    // 先放一支豆子，让列表非空（原来的 bug 就是这时没有入口）
    await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);

    await gotoBeans(tester);
    expect(find.text('花魁'), findsOneWidget);

    await tester.tap(addButton());
    await tester.pumpAndSettle();

    expect(find.text('新增咖啡豆'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('切到磨豆机分段后入口变成新增磨豆机', (tester) async {
    await gotoBeans(tester);
    expect(addButton(), findsOneWidget);

    await tester.tap(find.text('磨豆机'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(addGrinderButton(), findsOneWidget);
    expect(
      find.descendant(
        of: addGrinderButton(),
        matching: find.byIcon(addCircleIcon),
      ),
      findsOneWidget,
    );
    expect(addButton(), findsNothing);

    await tester.tap(addGrinderButton());
    await tester.pumpAndSettle();

    expect(find.text('新增磨豆机'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('新增后列表出现新豆子', (tester) async {
    await gotoBeans(tester);
    await tester.tap(addButton());
    await tester.pumpAndSettle();

    final Finder nameField = find.byKey(const Key('bean.name'));
    await tester.scrollUntilVisible(
      nameField,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(nameField);
    await tester.pumpAndSettle();
    await tester.enterText(nameField, '曼特宁');
    await tester.pump();

    // M3-T31：新增豆子必须主动确认烘焙日期、填剩余克数，否则保存被拦下。
    // `BeanClickApp` 锁 zh-CN，日历确认按钮是「确定」而不是 OK。
    await tester.scrollTo(find.text('选择日期'));
    await tester.tap(find.text('选择日期'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.fillField('bean.remaining', '200');

    final Finder save = find.widgetWithText(FilledButton, '保存');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    // 断言必须落库、且表单已关掉。
    // `find.text` 会连 `EditableText.controller.text` 一起匹配：表单没关时，
    // 它命中的是那个**没提交**的名称输入框——这正是这条用例以前假绿的原因。
    expect(find.text('新增咖啡豆'), findsNothing, reason: '保存成功才会关掉表单');
    final List<CoffeeBean> beans = await harness.container
        .read(beanRepositoryProvider)
        .getAll();
    expect(beans.single.name, '曼特宁');
    expect(find.text('曼特宁'), findsOneWidget, reason: '列表里应出现新豆子');

    await harness.finish(tester);
  });
}
