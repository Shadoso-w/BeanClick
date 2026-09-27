import 'package:beanclick/app.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

/// 豆库页的新增入口（用户反馈：列表非空时无法新增）。
///
/// 中栏被「新加一杯」占用后，这里用右下角的浮动小 + 补回入口，
/// 且动作跟随「咖啡豆 / 磨豆机」分段切换。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> gotoBeans(WidgetTester tester) async {
    await tester.pumpWidget(harness.app(const BeanClickApp()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('豆库').last);
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// 豆库页的新增按钮；外壳那个大的「新加一杯」要排除掉。
  Finder addButton() => find.byWidgetPredicate(
    (Widget widget) =>
        widget is FloatingActionButton && widget.tooltip == '新增咖啡豆',
  );

  Finder addGrinderButton() => find.byWidgetPredicate(
    (Widget widget) =>
        widget is FloatingActionButton && widget.tooltip == '新增磨豆机',
  );

  testWidgets('豆库页始终有新增咖啡豆入口', (tester) async {
    await gotoBeans(tester);

    expect(addButton(), findsOneWidget);
    expect(find.byIcon(Icons.add), findsWidgets);

    await harness.finish(tester);
  });

  testWidgets('列表非空时依然能新增咖啡豆', (tester) async {
    // 先放一支豆子，让列表非空（原来的 bug 就是这时没有入口）
    await harness.container
        .read(beanRepositoryProvider)
        .save(
          CoffeeBean(
            name: '花魁',
            remainingGrams: 200,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );

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

    final Finder save = find.widgetWithText(FilledButton, '保存');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('曼特宁'), findsOneWidget);

    await harness.finish(tester);
  });
}
