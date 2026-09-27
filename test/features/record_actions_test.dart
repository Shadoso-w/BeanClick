import 'package:beanclick/core/widgets/swipe_actions.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/features/record/brew_log_form_page.dart';
import 'package:beanclick/features/record/record_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart' show makeLog;
import '../helpers/widget_harness.dart';

/// 记录页的左滑操作（收藏 / 删除）、收藏筛选，以及表单里的复制按钮。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  /// 打开记录页（RecordPage 是外壳里的一页，自己不带 Scaffold）。
  Future<void> pumpRecordPage(WidgetTester tester) async {
    await tester.pumpWidget(
      harness.app(const MaterialApp(home: Scaffold(body: RecordPage()))),
    );
    // 记录来自 drift 的 stream：给一点真实时间让首次查询回来。
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// 打开新增记录的表单。
  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      harness.app(const MaterialApp(home: BrewLogFormPage())),
    );
    await tester.pumpAndSettle();
  }

  Future<List<BrewLog>> logs() =>
      harness.container.read(brewLogRepositoryProvider).getAll();

  Finder swipeAction(String label) => find.descendant(
    of: find.byType(SwipeActions),
    matching: find.text(label),
  );

  /// 左滑第一条记录，露出右侧的操作按钮。
  Future<void> swipeOpen(WidgetTester tester) async {
    await tester.drag(find.byType(SwipeActions), const Offset(-220, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('左滑露出「收藏」与「删除」，点收藏只改标记', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
    final int logId =
        (await harness.container
                .read(brewLogRepositoryProvider)
                .save(
                  makeLog(
                    beanId: a.beanId,
                    batchId: a.batchId,
                    doseGrams: 15,
                    brewedAt: DateTime(2026, 1, 1, 8),
                  ),
                ))
            .brewLogId;

    await pumpRecordPage(tester);
    expect(find.text('花魁'), findsOneWidget);

    await swipeOpen(tester);
    // 滑开后卡片被推到右边，操作按钮露出来。
    expect(swipeAction('收藏'), findsOneWidget);
    expect(swipeAction('删除'), findsOneWidget);
    // 滑开后卡片被推到左边（越出屏幕），操作按钮露在右侧。
    expect(tester.getRect(find.byType(Card).first).left, lessThan(0));

    await tester.tap(swipeAction('收藏'));
    await tester.pumpAndSettle();

    expect(
      (await harness.container.read(brewLogRepositoryProvider).getById(logId))!
          .isFavorite,
      isTrue,
    );
    // 收藏不动余量。
    expect(
      (await harness.container
              .read(beanRepositoryProvider)
              .getBatch(a.batchId))!
          .remainingGrams,
      185,
    );
    expect(find.text('已收藏这套参数'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('滑开后已收藏的那条，按钮变成「取消收藏」', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(makeLog(beanId: a.beanId, batchId: a.batchId, isFavorite: true));

    await pumpRecordPage(tester);
    await swipeOpen(tester);

    expect(swipeAction('取消收藏'), findsOneWidget);
    await tester.tap(swipeAction('取消收藏'));
    await tester.pumpAndSettle();

    expect((await logs()).single.isFavorite, isFalse);

    await harness.finish(tester);
  });

  testWidgets('左滑删除：先确认再删，且不回补余量', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁', remainingGrams: 200);
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(makeLog(beanId: a.beanId, batchId: a.batchId, doseGrams: 15));

    await pumpRecordPage(tester);
    await swipeOpen(tester);
    await tester.tap(swipeAction('删除'));
    await tester.pumpAndSettle();

    // 删除要二次确认（和表单里的删除同一套文案）。
    expect(find.text('删除这条记录？'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(await logs(), isEmpty);
    expect(
      (await harness.container
              .read(beanRepositoryProvider)
              .getBatch(a.batchId))!
          .remainingGrams,
      185,
      reason: '删记录不回补余量（手册 §6.2）',
    );
    expect(find.text('已删除这条记录'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('滑开后在卡片上点一下只会收起来，不会进详情页', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(makeLog(beanId: a.beanId, batchId: a.batchId));

    await pumpRecordPage(tester);
    await swipeOpen(tester);
    expect(swipeAction('收藏'), findsOneWidget);

    // 点卡片露在外面的部分（左滑后豆名已经滑出屏幕，所以点卡片中心而不是文字）
    await tester.tapAt(tester.getCenter(find.byType(Card).first));
    await tester.pumpAndSettle();

    expect(find.text('编辑记录'), findsNothing, reason: '滑开状态下不该误进详情');
    // 收起来了：卡片回到原位（左滑时会越出屏幕左侧）。
    expect(
      tester.getRect(find.byType(Card).first).left,
      greaterThanOrEqualTo(0),
    );

    await harness.finish(tester);
  });

  testWidgets('「收藏」入口：只看收藏的记录', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    final b = await harness.addBeanWithBatch(name: '曼特宁');
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          makeLog(
            beanId: a.beanId,
            batchId: a.batchId,
            brewedAt: DateTime(2026, 1, 1, 8),
            isFavorite: true,
          ),
        );
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          makeLog(
            beanId: b.beanId,
            batchId: b.batchId,
            brewedAt: DateTime(2026, 1, 2, 8),
          ),
        );

    await pumpRecordPage(tester);
    expect(find.text('花魁'), findsOneWidget);
    expect(find.text('曼特宁'), findsOneWidget);

    await tester.tap(find.byKey(const Key('record.filter.favorite')));
    await tester.pumpAndSettle();

    expect(find.text('花魁'), findsOneWidget);
    expect(find.text('曼特宁'), findsNothing);

    await tester.tap(find.byKey(const Key('record.filter.all')));
    await tester.pumpAndSettle();
    expect(find.text('曼特宁'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('一条收藏都没有时，收藏筛选给出引导', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(makeLog(beanId: a.beanId, batchId: a.batchId));

    await pumpRecordPage(tester);
    await tester.tap(find.byKey(const Key('record.filter.favorite')));
    await tester.pumpAndSettle();

    expect(find.text('还没有收藏的参数'), findsOneWidget);
    expect(find.textContaining('向左滑动'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('复制按钮：单击复制上次参数', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          makeLog(
            beanId: a.beanId,
            batchId: a.batchId,
            doseGrams: 18,
            waterGrams: 288,
            brewedAt: DateTime(2026, 1, 1, 8),
          ),
        );

    await pumpForm(tester);
    await tester.tap(find.byKey(const Key('brew.copyLast')));
    await tester.pumpAndSettle();

    expect(await tester.readField('brew.dose'), '18');
    expect(await tester.readField('brew.water'), '288');
    expect(find.text('已复制上次参数'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('复制按钮长按：从收藏里挑一条复制', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    final b = await harness.addBeanWithBatch(name: '曼特宁');
    // 最近一条是「上次」，但没收藏；收藏的是更早那条。
    final int favoriteId =
        (await harness.container
                .read(brewLogRepositoryProvider)
                .save(
                  makeLog(
                    beanId: b.beanId,
                    batchId: b.batchId,
                    doseGrams: 22,
                    waterGrams: 350,
                    brewedAt: DateTime(2026, 1, 1, 8),
                    isFavorite: true,
                  ),
                ))
            .brewLogId;
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          makeLog(
            beanId: a.beanId,
            batchId: a.batchId,
            doseGrams: 15,
            waterGrams: 240,
            brewedAt: DateTime(2026, 1, 5, 8),
          ),
        );

    await pumpForm(tester);
    await tester.longPress(find.byKey(const Key('brew.copyLast')));
    await tester.pumpAndSettle();

    // 面板里只有收藏的那条，且显示豆子与粉水，便于认。
    expect(find.text('复制收藏的参数'), findsOneWidget);
    expect(find.text('曼特宁'), findsWidgets);
    expect(find.byKey(Key('brew.favorite.$favoriteId')), findsOneWidget);

    await tester.tap(find.byKey(Key('brew.favorite.$favoriteId')));
    await tester.pumpAndSettle();

    // 复制的是收藏那条（22 / 350），不是最近那条（15 / 240）。
    expect(await tester.readField('brew.dose'), '22');
    expect(await tester.readField('brew.water'), '350');
    expect(find.text('已复制收藏的参数'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('复制按钮长按：没有收藏时说明怎么收藏', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(makeLog(beanId: a.beanId, batchId: a.batchId));

    await pumpForm(tester);
    await tester.longPress(find.byKey(const Key('brew.copyLast')));
    await tester.pumpAndSettle();

    expect(find.text('还没有收藏的参数'), findsOneWidget);
    expect(find.textContaining('点「收藏」'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('表单里的「收藏这套参数」开关会落库', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    final int logId =
        (await harness.container
                .read(brewLogRepositoryProvider)
                .save(makeLog(beanId: a.beanId, batchId: a.batchId)))
            .brewLogId;
    final BrewLog existing = (await harness.container
        .read(brewLogRepositoryProvider)
        .getById(logId))!;

    await tester.pumpWidget(
      harness.app(MaterialApp(home: BrewLogFormPage(existing: existing))),
    );
    await tester.pumpAndSettle();

    // 开关在表单靠下的位置（列表懒构建），先滚过去。
    await tester.scrollTo(find.byKey(const Key('brew.isFavorite')));
    await tester.tap(find.byKey(const Key('brew.isFavorite')));
    await tester.pumpAndSettle();
    await tester.tapSaveButton();

    expect((await logs()).single.isFavorite, isTrue);

    await harness.finish(tester);
  });
}
