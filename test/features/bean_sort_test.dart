import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/features/beans/beans_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart' show makeLog;
import '../helpers/widget_harness.dart';

/// 豆库排序（M3-T36）：11 个键的顺序、默认方向、缺失态、卡片数值行。
///
/// 设计定稿：`docs/M3-T36-豆库排序设计稿.md`。
///
/// 收尾一律 `harness.finish(tester)`：本族用例每个都开过 `showModalBottomSheet`
/// （多一条路由 + 动画），失败时残留风险更高；约定见
/// `test/helpers/widget_harness.dart`（只卸载 widget 树，不 await 关库 ——
/// 后者会因流查询未归零永久阻塞）。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> pumpBeansPage(WidgetTester tester) async {
    await tester.pumpWidget(
      harness.app(const MaterialApp(home: Scaffold(body: BeansPage()))),
    );
    // 列表来自 drift 的 stream：给一点真实时间让首次查询回来。
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// 造一支豆子（可指定批次数量、购入总重、余量、价格）。
  Future<int> seedBean({
    required String name,
    double? initial,
    double remaining = 0,
    double? price,
    int batchCount = 1,
    DateTime? createdAt,
  }) async {
    final DateTime at = createdAt ?? DateTime(2026, 1, 1);
    final repo = harness.container.read(beanRepositoryProvider);
    final int id = await repo.save(
      CoffeeBean(name: name, createdAt: at, updatedAt: at),
    );
    for (int i = 0; i < batchCount; i++) {
      await repo.saveBatch(
        BeanBatch(
          beanId: id,
          initialGrams: initial,
          remainingGrams: i == 0 ? remaining : 0,
          price: price,
          createdAt: at,
          updatedAt: at,
        ),
      );
    }
    return id;
  }

  /// 造一台磨豆机。**两张卡要有不同的 `createdAt`**：`grinderRepository.watchAll()`
  /// 只按 `createdAt asc` 排、没有 id tiebreak，时间一样时"入库顺序"就靠 SQLite
  /// 扫描顺序兜底，换引擎可能偶发红。
  Future<int> seedGrinder(
    String brand,
    String model, {
    DateTime? createdAt,
  }) async {
    final DateTime at = createdAt ?? DateTime(2026, 1, 1);
    return harness.container
        .read(grinderRepositoryProvider)
        .save(
          Grinder(
            brand: brand,
            model: model,
            // 显式置空零点：卡片第一栏是 `brand model / 零点 X`，带上零点会让
            // 断言里的名字变长，也盖住「型号字典序」这件事。
            zeroPoint: null,
            createdAt: at,
            updatedAt: at,
          ),
        );
  }

  /// 卡片**从上到下**的顺序（按屏幕纵坐标排）。
  List<String> cardOrder(WidgetTester tester, List<String> names) {
    final List<String> shown = names
        .where((String n) => find.text(n).evaluate().isNotEmpty)
        .toList();
    shown.sort(
      (String a, String b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy),
    );
    return shown;
  }

  /// 打开排序弹层（点分段控件右侧那个按钮）。
  Future<void> openSortSheet(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();
  }

  /// 在弹层里选一个键，然后关闭弹层。
  Future<void> chooseSort(WidgetTester tester, String rowLabel) async {
    await tester.scrollTo(find.text(rowLabel));
    await tester.tap(find.text(rowLabel));
    await tester.pumpAndSettle();
    // 点遮罩关掉弹层（列表顺序此时已经生效）。
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
  }

  /// 在弹层里改方向，然后关闭弹层。
  Future<void> chooseDirection(WidgetTester tester, String label) async {
    await tester.scrollTo(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
  }

  /// 弹层里那个「升序 / 降序」控件。
  SegmentedButton<bool> orderControl(WidgetTester tester) =>
      tester.widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>));

  group('咖啡豆段', () {
    testWidgets('默认键 = 现状顺序（按添加时间倒序，新→旧）', (tester) async {
      await seedBean(name: '先加的', createdAt: DateTime(2026, 1, 1));
      await seedBean(name: '后加的', createdAt: DateTime(2026, 6, 1));
      await pumpBeansPage(tester);

      expect(cardOrder(tester, <String>['先加的', '后加的']), <String>['后加的', '先加的']);
      // 默认键卡片上**不显示**数值行。
      expect(find.textContaining('共 '), findsNothing);

      await harness.finish(tester);
    });

    testWidgets('购买总量：降序（默认方向）', (tester) async {
      await seedBean(name: '买得多', initial: 400, remaining: 300);
      await seedBean(name: '买得少', initial: 100, remaining: 80);
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      await chooseSort(tester, '购买总量');

      expect(cardOrder(tester, <String>['买得多', '买得少']), <String>['买得多', '买得少']);
      expect(find.text('共 400 g'), findsOneWidget);

      await harness.finish(tester);
    });

    testWidgets('消耗总量：降序（按冲煮累计，与购入总重无关）', (tester) async {
      final int a = await seedBean(name: '喝得多');
      final int b = await seedBean(name: '喝得少');
      await harness.addBrewLog(beanId: a, doseGrams: 120);
      await harness.addBrewLog(beanId: b, doseGrams: 20);
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      await chooseSort(tester, '消耗总量');

      expect(cardOrder(tester, <String>['喝得多', '喝得少']), <String>['喝得多', '喝得少']);
      expect(find.text('用了 120 g'), findsOneWidget);

      await harness.finish(tester);
    });

    testWidgets('消耗总量：拼配按**每支**归集，不是整条记录的总粉量', (tester) async {
      final int a = await seedBean(name: '主豆');
      final int b = await seedBean(name: '副豆');
      // 一条拼配记录：A 14 g + B 6 g，总粉量 20 g。
      await harness.container
          .read(brewLogRepositoryProvider)
          .save(
            makeLog(
              doseGrams: 20,
              beanUsages: <BeanUsage>[
                BeanUsage(beanId: a, doseGrams: 14, position: 0),
                BeanUsage(beanId: b, doseGrams: 6, position: 1),
              ],
            ),
          );
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      await chooseSort(tester, '消耗总量');

      expect(
        find.text('用了 14 g'),
        findsOneWidget,
        reason: '主豆的用量是 14 g —— 若实现读 `log.doseGrams` 会变成 20 g',
      );
      expect(
        find.text('用了 6 g'),
        findsOneWidget,
        reason: '副豆是**自己那一行**的 6 g（若按整条记录算，两支都会是 20 g）',
      );
      expect(cardOrder(tester, <String>['主豆', '副豆']), <String>['主豆', '副豆']);

      await harness.finish(tester);
    });

    testWidgets('净减少量：降序（只算填过购入总重的批次）', (tester) async {
      await seedBean(name: '少得多', initial: 400, remaining: 100);
      await seedBean(name: '少得少', initial: 200, remaining: 180);
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      await chooseSort(tester, '净减少量');

      expect(cardOrder(tester, <String>['少得多', '少得少']), <String>['少得多', '少得少']);
      expect(find.text('少了 300 g'), findsOneWidget);

      await harness.finish(tester);
    });

    testWidgets('净减少量：没填购入总重的批次不参与（不会算出负数）', (tester) async {
      await seedBean(name: '填了总重', initial: 400, remaining: 100);
      // 只填了余量、没填购入总重：若实现用 `initialGrams ?? 0`，这里会算出
      // `0 - 150 = -150` 的负值，而这支豆子本该是**缺失**。
      await seedBean(name: '没填总重', initial: null, remaining: 150);
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      await chooseSort(tester, '净减少量');

      expect(find.text('少了 — g'), findsOneWidget);
      expect(cardOrder(tester, <String>['填了总重', '没填总重']), <String>[
        '填了总重',
        '没填总重',
      ], reason: '缺失值排最后');

      await harness.finish(tester);
    });

    testWidgets('花费：降序，且数值行只显示当前键的值', (tester) async {
      await seedBean(name: '贵的', initial: 200, price: 168);
      await seedBean(name: '便宜的', initial: 200, price: 68);
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      await chooseSort(tester, '花费');

      expect(cardOrder(tester, <String>['贵的', '便宜的']), <String>['贵的', '便宜的']);
      // 数值行**恰好**是 `¥168`（用户裁决 H：不带余量）。若实现又把余量拼进来，
      // 精确匹配会落空；`¥168 · 余 0 g` 这种拼接形式则明确不许出现。
      expect(find.text('¥168'), findsOneWidget);
      expect(find.text('¥168 · 余 0 g'), findsNothing);

      await harness.finish(tester);
    });

    testWidgets('单价：默认升序（找便宜的），元 / 100 g', (tester) async {
      await seedBean(name: '划算', initial: 500, price: 100);
      await seedBean(name: '不划算', initial: 200, price: 200);
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      // 单价默认方向 = 升序。
      expect(orderControl(tester).selected, <bool>{false});
      await chooseSort(tester, '单价');

      expect(cardOrder(tester, <String>['划算', '不划算']), <String>['划算', '不划算']);
      expect(find.text('¥20 / 100g'), findsOneWidget);

      await harness.finish(tester);
    });

    testWidgets('复购次数：降序（批次数）', (tester) async {
      await seedBean(name: '买过三次', batchCount: 3);
      await seedBean(name: '买过一次', batchCount: 1);
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      await chooseSort(tester, '复购次数');

      expect(cardOrder(tester, <String>['买过三次', '买过一次']), <String>[
        '买过三次',
        '买过一次',
      ]);
      expect(find.text('买过 3 次'), findsOneWidget);

      await harness.finish(tester);
    });

    testWidgets('缺失值显示「—」且排最后（升序也排最后）', (tester) async {
      // 至少两个可比值，才能让"升序把缺失放最前"这种错法暴露出来。
      await seedBean(name: '更贵', initial: 200, price: 200);
      await seedBean(name: '有价', initial: 200, price: 100);
      await seedBean(name: '没价', initial: 200);
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      await chooseSort(tester, '花费');
      expect(cardOrder(tester, <String>['更贵', '有价', '没价']), <String>[
        '更贵',
        '有价',
        '没价',
      ], reason: '降序：200 > 100，没价的最后');
      expect(find.text('¥—'), findsOneWidget);

      // 切升序：两个可比值反序，缺失值仍在最后。
      await openSortSheet(tester);
      await chooseDirection(tester, '升序');
      expect(cardOrder(tester, <String>['更贵', '有价', '没价']), <String>[
        '有价',
        '更贵',
        '没价',
      ], reason: '升序：100 < 200，没价的仍最后');

      await harness.finish(tester);
    });

    testWidgets('方向：数值键默认降序；默认键禁用方向控件（置灰不隐藏）', (tester) async {
      await seedBean(name: '甲', initial: 100, price: 10);
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      expect(
        orderControl(tester).onSelectionChanged,
        isNull,
        reason: '默认键应禁用方向控件',
      );
      expect(find.text('升序'), findsOneWidget, reason: '禁用是置灰，不是隐藏');

      await chooseSort(tester, '花费');
      await openSortSheet(tester);
      expect(orderControl(tester).selected, <bool>{true}, reason: '数值键默认降序');
      expect(orderControl(tester).onSelectionChanged, isNotNull);

      await harness.finish(tester);
    });

    testWidgets('弹层：只有两个消耗类键带小字，且不出现评审批注', (tester) async {
      await seedBean(name: '甲');
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      expect(find.text('冲煮累计'), findsOneWidget);
      expect(find.text('购入 − 余量'), findsOneWidget);
      expect(find.textContaining('卡片上显示'), findsNothing);

      await chooseSort(tester, '默认（入库顺序）');

      await harness.finish(tester);
    });

    testWidgets('空列表：排序入口仍在，但置灰', (tester) async {
      await pumpBeansPage(tester);
      final OutlinedButton button = tester.widget<OutlinedButton>(
        find.byType(OutlinedButton),
      );
      expect(button.onPressed, isNull);

      await harness.finish(tester);
    });

    testWidgets('320 dp 窄屏：入口行不溢出，按钮文字仍单行', (tester) async {
      // 320 dp 是常用机型里最窄的一档；4 字键（购买总量 / 复购次数 / 使用次数 /
      // 最近使用）时按钮最宽，可能和分段控件抢宽度。
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await seedBean(name: '甲', initial: 100, price: 10);
      await pumpBeansPage(tester);

      await openSortSheet(tester);
      await chooseSort(tester, '购买总量');

      expect(tester.takeException(), isNull, reason: '320 dp 下入口行不该溢出');
      expect(
        tester.getSize(find.text('购买总量')).height,
        lessThan(30),
        reason: '按钮文字仍单行（没有被压成多行）',
      );

      await harness.finish(tester);
    });
  });

  group('磨豆机段', () {
    testWidgets('型号：字典序（默认方向升序）', (tester) async {
      await seedGrinder('Comandante', 'C40');
      await seedGrinder('1Zpresso', 'JX-Pro');
      await pumpBeansPage(tester);
      await tester.tap(find.text('磨豆机'));
      await tester.pumpAndSettle();

      await openSortSheet(tester);
      await chooseSort(tester, '型号');

      expect(
        cardOrder(tester, <String>['Comandante C40', '1Zpresso JX-Pro']),
        <String>['1Zpresso JX-Pro', 'Comandante C40'],
      );

      await harness.finish(tester);
    });

    testWidgets('使用次数：降序，且卡片常显「用过 N 次」', (tester) async {
      final int busy = await seedGrinder('Comandante', 'C40');
      final int idle = await seedGrinder('泰摩', 'C3');
      await harness.addBrewLog(grinderId: busy, doseGrams: 15);
      await harness.addBrewLog(grinderId: busy, doseGrams: 15);
      await harness.addBrewLog(grinderId: idle, doseGrams: 15);
      await pumpBeansPage(tester);
      await tester.tap(find.text('磨豆机'));
      await tester.pumpAndSettle();

      await openSortSheet(tester);
      await chooseSort(tester, '使用次数');

      expect(cardOrder(tester, <String>['Comandante C40', '泰摩 C3']), <String>[
        'Comandante C40',
        '泰摩 C3',
      ]);
      // 卡片的 meta 行是 `join(' · ')` 出来的一整条 Text，所以用子串匹配。
      expect(find.textContaining('用过 2 次'), findsOneWidget);
      expect(find.textContaining('用过 1 次'), findsOneWidget);

      await harness.finish(tester);
    });

    testWidgets('最近使用：降序（近→远）', (tester) async {
      final int old = await seedGrinder('Comandante', 'C40');
      final int recent = await seedGrinder('泰摩', 'C3');
      await harness.addBrewLog(
        grinderId: old,
        doseGrams: 15,
        brewedAt: DateTime(2026, 1, 1),
      );
      await harness.addBrewLog(
        grinderId: recent,
        doseGrams: 15,
        brewedAt: DateTime(2026, 9, 1),
      );
      await pumpBeansPage(tester);
      await tester.tap(find.text('磨豆机'));
      await tester.pumpAndSettle();

      await openSortSheet(tester);
      await chooseSort(tester, '最近使用');

      expect(cardOrder(tester, <String>['Comandante C40', '泰摩 C3']), <String>[
        '泰摩 C3',
        'Comandante C40',
      ]);

      await harness.finish(tester);
    });

    testWidgets('重置为默认：回到入库顺序', (tester) async {
      // 给不同的 createdAt：入库顺序 = `createdAt asc`，别靠 rowid 兜底。
      await seedGrinder('Comandante', 'C40', createdAt: DateTime(2026, 1, 1));
      await seedGrinder('1Zpresso', 'JX-Pro', createdAt: DateTime(2026, 6, 1));
      await pumpBeansPage(tester);
      await tester.tap(find.text('磨豆机'));
      await tester.pumpAndSettle();

      await openSortSheet(tester);
      await chooseSort(tester, '型号');
      expect(
        cardOrder(tester, <String>['Comandante C40', '1Zpresso JX-Pro']),
        <String>['1Zpresso JX-Pro', 'Comandante C40'],
      );

      await openSortSheet(tester);
      await tester.scrollTo(find.text('重置为默认'));
      await tester.tap(find.text('重置为默认'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(
        cardOrder(tester, <String>['Comandante C40', '1Zpresso JX-Pro']),
        <String>['Comandante C40', '1Zpresso JX-Pro'],
      );

      await harness.finish(tester);
    });

    testWidgets('缺失态：从没冲煮过的磨豆机显示「还没用过」且两个方向都排最后', (tester) async {
      final int used = await seedGrinder(
        'Comandante',
        'C40',
        createdAt: DateTime(2026, 1, 1),
      );
      await harness.addBrewLog(
        grinderId: used,
        doseGrams: 15,
        brewedAt: DateTime(2026, 9, 1),
      );
      // 两台从没冲煮过（使用次数 0 = 已知值「还没用过」，但对排序仍是缺失）。
      await seedGrinder('泰摩', 'C3', createdAt: DateTime(2026, 2, 1));
      await seedGrinder('1Zpresso', 'JX-Pro', createdAt: DateTime(2026, 3, 1));
      await pumpBeansPage(tester);
      await tester.tap(find.text('磨豆机'));
      await tester.pumpAndSettle();

      const List<String> all = <String>[
        'Comandante C40',
        '泰摩 C3',
        '1Zpresso JX-Pro',
      ];

      // 使用次数（默认降序）：用过的在前，两台没用过的排最后。
      await openSortSheet(tester);
      await chooseSort(tester, '使用次数');
      expect(cardOrder(tester, all), all);
      expect(find.textContaining('还没用过'), findsNWidgets(2));
      expect(find.textContaining('用过 1 次'), findsOneWidget);

      // 切升序：**仍**该是用过的在前、没用过的排最后 —— 这一条才判得出
      // 「0 到底有没有被当成参与比较的真实值」（若是真实值，升序会把它们顶到最前）。
      await openSortSheet(tester);
      await chooseDirection(tester, '升序');
      expect(cardOrder(tester, all), all, reason: '0 次按缺失处理：升序也排最后，不参与比较');

      // 最近使用：没有记录的两台同样排最后，卡片上写「还没有冲煮记录」。
      await openSortSheet(tester);
      await chooseSort(tester, '最近使用');
      expect(cardOrder(tester, all), all);
      expect(find.textContaining('还没有冲煮记录'), findsNWidgets(2));

      await harness.finish(tester);
    });
  });
}
