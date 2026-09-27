import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/features/record/brew_log_form_page.dart';
import 'package:beanclick/features/record/record_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart' show makeLog;
import '../helpers/widget_harness.dart';

/// M2.8 第二批的界面：B1 自定义方法 chip 行、B3 辅料区块、卡片上的辅料行。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> pumpForm(WidgetTester tester, {BrewLog? existing}) async {
    await tester.pumpWidget(
      harness.app(MaterialApp(home: BrewLogFormPage(existing: existing))),
    );
    // 自定义方法库与豆子列表都来自 drift 的 stream：给一点真实时间让首次查询回来，
    // 否则 provider 还是 loading，chip 行只有内置方法。
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// 自定义方法库（存在设置表里）。
  Future<List<String>> customMethods() =>
      harness.container.read(settingsRepositoryProvider).getCustomBrewMethods();

  Future<void> pumpRecordPage(WidgetTester tester) async {
    await tester.pumpWidget(
      harness.app(const MaterialApp(home: Scaffold(body: RecordPage()))),
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('B1：新建自定义方法后直接选中它，保存记录会带上 methodLabel', (tester) async {
    await pumpForm(tester);

    // 一开始只有内置 + 「＋」。
    expect(find.text('拿铁'), findsNothing);

    await tester.tapKey('brew.addMethod');
    await tester.pumpAndSettle();
    expect(find.text('新的冲煮方法'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('brew.methodName')), '拿铁');
    await tester.pumpAndSettle();
    // 对话框里的「保存」——表单底部也有一个「保存」，必须限定在对话框内。
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, '保存'),
      ),
    );
    await tester.pumpAndSettle();

    // 方法库写进去了。
    expect(await customMethods(), contains('拿铁'));

    // 新建的方法直接成为当前选中项：存下来的记录带着 methodLabel。
    // （chip 行会随方法库的 stream 刷新，这里只断言真正落地的东西，
    //   免得把 fake-async 下 stream 的推送时序测进用例里。）
    await tester.tapSaveButton();

    final List<BrewLog> logs = await harness.container
        .read(brewLogRepositoryProvider)
        .getAll();
    expect(logs.single.methodLabel, '拿铁');
    expect(logs.single.methodDisplay, '拿铁');
    expect(logs.single.method, BrewMethod.pourOver, reason: '内置列保持默认');

    await harness.finish(tester);
  });

  testWidgets('B1：方法库里的自定义方法会出现在 chip 行', (tester) async {
    await harness.container
        .read(settingsRepositoryProvider)
        .setCustomBrewMethods(<String>['拿铁', '摩卡']);

    await pumpForm(tester);

    expect(find.widgetWithText(ChoiceChip, '拿铁'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '摩卡'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('B1：编辑已有自定义方法的记录时，那个 chip 是选中的', (tester) async {
    await harness.container
        .read(settingsRepositoryProvider)
        .setCustomBrewMethods(<String>['拿铁']);
    final int logId =
        (await harness.container
                .read(brewLogRepositoryProvider)
                .save(makeLog(methodLabel: '拿铁', method: BrewMethod.espresso)))
            .brewLogId;
    final BrewLog existing = (await harness.container
        .read(brewLogRepositoryProvider)
        .getById(logId))!;

    await pumpForm(tester, existing: existing);

    final ChoiceChip chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '拿铁'),
    );
    expect(chip.selected, isTrue, reason: '编辑时应选中自定义方法');
    // 内置的方法都没被选中。
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '手冲')).selected,
      isFalse,
    );

    await harness.finish(tester);
  });

  testWidgets('B1：长按自定义 chip 可以重命名 / 删除', (tester) async {
    await harness.container
        .read(settingsRepositoryProvider)
        .setCustomBrewMethods(<String>['拿铁', '摩卡']);
    await pumpForm(tester);

    await tester.longPress(find.widgetWithText(ChoiceChip, '拿铁'));
    await tester.pumpAndSettle();
    expect(find.text('重命名「拿铁」'), findsOneWidget);
    expect(find.text('从列表删除「拿铁」'), findsOneWidget);

    await tester.tap(find.text('从列表删除「拿铁」'));
    await tester.pumpAndSettle();

    expect(await customMethods(), <String>['摩卡']);

    await harness.finish(tester);
  });

  testWidgets('B3：从面板加辅料（常用项）', (tester) async {
    await pumpForm(tester);

    expect(find.text('还没有加辅料'), findsOneWidget);

    await tester.tapKey('brew.addAddIn');
    await tester.pumpAndSettle();
    expect(find.text('选择辅料'), findsOneWidget);

    await tester.tap(find.byKey(const Key('brew.addInOption.牛奶')));
    await tester.pumpAndSettle();

    // 表单里出现这一行，且单位默认 ml。
    expect(find.text('牛奶'), findsWidgets);
    expect(find.text('ml'), findsWidgets);
    expect(find.text('还没有加辅料'), findsNothing);

    await harness.finish(tester);
  });

  testWidgets('B3：辅料面板的「新建」能加自定义项', (tester) async {
    await pumpForm(tester);

    await tester.tapKey('brew.addAddIn');
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('brew.addInName')), '椰奶');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '添加'));
    await tester.pumpAndSettle();

    expect(find.text('椰奶'), findsWidgets);

    await harness.finish(tester);
  });

  testWidgets('B3：辅料数量与单位能改，保存后落库', (tester) async {
    await pumpForm(tester);

    await tester.tapKey('brew.addAddIn');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('brew.addInOption.榛果糖浆')));
    await tester.pumpAndSettle();

    await tester.fillField('brew.addInAmount.0', '2');
    // 单位换成「泵」：点下拉（先滚进视口）再选菜单项。
    await tester.tapKey('brew.addInUnit.0');
    await tester.tap(find.text('泵').last);
    await tester.pumpAndSettle();

    await tester.tapSaveButton();

    final List<BrewLog> logs = await harness.container
        .read(brewLogRepositoryProvider)
        .getAll();
    expect(logs.single.addIns, hasLength(1));
    expect(logs.single.addIns.single.name, '榛果糖浆');
    expect(logs.single.addIns.single.amount, 2);
    expect(logs.single.addIns.single.unit, AddInUnit.pump);

    await harness.finish(tester);
  });

  testWidgets('B3：「最近用过」来自本机历史记录', (tester) async {
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          makeLog(
            addIns: const <BrewLogAddIn>[
              BrewLogAddIn(name: '香草糖浆', amount: 1, unit: AddInUnit.pump),
            ],
          ),
        );

    await pumpForm(tester);
    await tester.tapKey('brew.addAddIn');
    await tester.pumpAndSettle();

    expect(find.text('最近用过'), findsOneWidget);
    expect(find.byKey(const Key('brew.addInOption.香草糖浆')), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('B3-c：卡片上有辅料时多一行，超过两项折叠成 +N', (tester) async {
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          makeLog(
            addIns: const <BrewLogAddIn>[
              BrewLogAddIn(name: '牛奶', amount: 150, unit: AddInUnit.ml),
              BrewLogAddIn(name: '榛果糖浆', amount: 1, unit: AddInUnit.pump),
              BrewLogAddIn(name: '冰块'),
            ],
          ),
        );

    await pumpRecordPage(tester);

    // 只列前两项，其余的折叠成 +1。
    expect(find.text('牛奶 150 ml · 榛果糖浆 1 泵 · +1'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('B3-c：没有辅料时卡片不显示那一行', (tester) async {
    await harness.container.read(brewLogRepositoryProvider).save(makeLog());

    await pumpRecordPage(tester);

    expect(find.byIcon(Icons.local_drink_outlined), findsNothing);

    await harness.finish(tester);
  });
}
