import 'package:beanclick/core/widgets/swipe_actions.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/features/record/record_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart' show makeLog;
import '../helpers/widget_harness.dart';

/// M3-T38（v8）：自定义收藏夹 —— chip 行、多选加入、管理面板。
///
/// `is_favorite` 仍是「是否收藏」的**唯一**判据；夹只表达"这条收藏还放进了哪里"。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> pumpRecordPage(WidgetTester tester) async {
    await tester.pumpWidget(
      harness.app(const MaterialApp(home: Scaffold(body: RecordPage()))),
    );
    // 记录与收藏夹都来自 drift stream：给一点真实时间让首次查询回来。
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// 收藏夹列表。
  ///
  /// 必须走 [WidgetTester.runAsync]：`watchFavoriteGroups()` 是 **drift stream**，
  /// 在 `testWidgets` 的 fake-async 区里直接 `await ...first` 会让它永远等不到首个
  /// 事件（表现为 10 分钟超时 / guarded function conflict），`runAsync` 里才是真异步。
  Future<List<FavoriteGroup>> groups(WidgetTester tester) async {
    final repo = harness.container.read(brewLogRepositoryProvider);
    return (await tester.runAsync(() => repo.watchFavoriteGroups().first))!;
  }

  Future<int> seedGroup(String name) => harness.container
      .read(brewLogRepositoryProvider)
      .createFavoriteGroup(name);

  Future<int> seedLog(
    String beanName, {
    bool favorite = false,
    DateTime? at,
  }) async {
    final a = await harness.addBeanWithBatch(name: beanName);
    return (await harness.container
            .read(brewLogRepositoryProvider)
            .save(
              makeLog(
                beanId: a.beanId,
                batchId: a.batchId,
                isFavorite: favorite,
                brewedAt: at ?? DateTime(2026, 1, 1, 8),
              ),
            ))
        .brewLogId;
  }

  /// 左滑并点某个动作（「收藏」/「取消收藏」）。
  Future<void> swipeAndTap(WidgetTester tester, String label) async {
    await tester.drag(find.byType(SwipeActions), const Offset(-220, 0));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(SwipeActions),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('① 既有 chip 的 key / 文案 / 语义一字不变', (tester) async {
    await seedLog('花魁');
    await pumpRecordPage(tester);

    expect(find.byKey(const Key('record.filter.all')), findsOneWidget);
    expect(find.byKey(const Key('record.filter.favorite')), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
    // 注意：卡片左滑动作的 label 也叫「收藏」，所以要**限定在这个 chip 里**找。
    expect(
      find.descendant(
        of: find.byKey(const Key('record.filter.favorite')),
        matching: find.text('收藏'),
      ),
      findsOneWidget,
    );

    // 「收藏」仍是 bool 筛选：点它 → 只剩收藏过的。
    await tester.tap(find.byKey(const Key('record.filter.favorite')));
    await tester.pumpAndSettle();
    expect(find.text('还没有收藏的参数'), findsOneWidget);

    await tester.tap(find.byKey(const Key('record.filter.all')));
    await tester.pumpAndSettle();
    expect(find.text('花魁'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('② 有夹时追加 chip（按 sortOrder 排），点它只显示夹内记录', (tester) async {
    final int breakfast = await seedGroup('早餐配方');
    final int dark = await seedGroup('深烘试验');
    final int inside = await seedLog('花魁', favorite: true);
    await seedLog('曼特宁', favorite: true);
    await harness.container.read(brewLogRepositoryProvider).setFavoriteGroups(
      inside,
      <int>{breakfast},
    );

    await pumpRecordPage(tester);

    expect(find.byKey(Key('record.filter.group.$breakfast')), findsOneWidget);
    expect(find.byKey(Key('record.filter.group.$dark')), findsOneWidget);
    expect(find.byKey(const Key('record.filter.manage')), findsOneWidget);
    // 顺序 = sortOrder（先建的在前）。
    expect(
      tester.getTopLeft(find.text('早餐配方')).dx,
      lessThan(tester.getTopLeft(find.text('深烘试验')).dx),
    );

    await tester.tap(find.byKey(Key('record.filter.group.$breakfast')));
    await tester.pumpAndSettle();
    expect(find.text('花魁'), findsOneWidget);
    expect(find.text('曼特宁'), findsNothing, reason: '只显示这个夹里的记录');

    // 空夹的空态（文案与「收藏」的两种原样文案都不同）。
    await tester.tap(find.byKey(Key('record.filter.group.$dark')));
    await tester.pumpAndSettle();
    expect(find.text('「深烘试验」还是空的'), findsOneWidget);

    await tester.tap(find.byKey(const Key('record.filter.all')));
    await tester.pumpAndSettle();
    expect(find.text('曼特宁'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('③ 左滑收藏 → 多选面板 → 一条记录可进两个夹', (tester) async {
    final int breakfast = await seedGroup('早餐配方');
    final int dark = await seedGroup('深烘试验');
    final int id = await seedLog('花魁');
    final repo = harness.container.read(brewLogRepositoryProvider);

    await pumpRecordPage(tester);
    await swipeAndTap(tester, '收藏');

    // 裁决 D=②：收藏后弹「加入哪个收藏夹」多选面板。
    expect(find.text('加入哪个收藏夹？'), findsOneWidget);
    await tester.tap(find.byKey(Key('record.groupPick.$breakfast')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('record.groupPick.$dark')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record.groupPickDone')));
    await tester.pumpAndSettle();

    expect((await repo.getById(id))!.isFavorite, isTrue);
    expect(await repo.getFavoriteGroupIdsOf(id), <int>{breakfast, dark});
    expect(find.text('已收藏这套参数'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('④ 一个夹都不选 + 完成 = 收藏但未分组', (tester) async {
    await seedGroup('早餐配方');
    final int id = await seedLog('花魁');
    final repo = harness.container.read(brewLogRepositoryProvider);

    await pumpRecordPage(tester);
    await swipeAndTap(tester, '收藏');
    await tester.tap(find.byKey(const Key('record.groupPickDone')));
    await tester.pumpAndSettle();

    expect((await repo.getById(id))!.isFavorite, isTrue);
    expect(await repo.getFavoriteGroupIdsOf(id), isEmpty, reason: '没选夹不等于没收藏');

    await harness.finish(tester);
  });

  testWidgets('⑤ 已收藏：左滑「取消收藏」→ 归属**保留**、夹里不再显示（B4）', (tester) async {
    final int breakfast = await seedGroup('早餐配方');
    final int id = await seedLog('花魁', favorite: true);
    final repo = harness.container.read(brewLogRepositoryProvider);
    await repo.setFavoriteGroups(id, <int>{breakfast});

    await pumpRecordPage(tester);
    await swipeAndTap(tester, '取消收藏');

    expect((await repo.getById(id))!.isFavorite, isFalse);
    expect(await repo.getFavoriteGroupIdsOf(id), <int>{
      breakfast,
    }, reason: '取消收藏**不该**破坏性地清掉分组（B4：读侧守不变量即可）');
    expect(find.text('已取消收藏'), findsOneWidget);

    // 读侧不变量：未收藏的记录不再出现在夹 chip 下。
    await tester.tap(find.byKey(Key('record.filter.group.$breakfast')));
    await tester.pumpAndSettle();
    expect(find.text('花魁'), findsNothing, reason: '夹里只显示"收藏且在夹里"的记录');
    expect(find.text('「早餐配方」还是空的'), findsOneWidget);

    // 回到「全部」还在（取消收藏 ≠ 删记录）。
    await tester.tap(find.byKey(const Key('record.filter.all')));
    await tester.pumpAndSettle();
    expect(find.text('花魁'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('⑧ B3：点卡片星标就能改归属（不必先取消收藏）', (tester) async {
    final int breakfast = await seedGroup('早餐配方');
    final int dark = await seedGroup('深烘试验');
    final int id = await seedLog('花魁', favorite: true);
    final repo = harness.container.read(brewLogRepositoryProvider);
    await repo.setFavoriteGroups(id, <int>{breakfast});

    await pumpRecordPage(tester);
    expect(find.byKey(Key('record.star.$id')), findsOneWidget, reason: '星标要可点');

    await tester.tap(find.byKey(Key('record.star.$id')));
    await tester.pumpAndSettle();
    expect(find.text('加入哪个收藏夹？'), findsOneWidget);
    // 面板预勾了当前归属（早餐）→ 反选成「深烘」。
    await tester.tap(find.byKey(Key('record.groupPick.$breakfast')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('record.groupPick.$dark')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record.groupPickDone')));
    await tester.pumpAndSettle();

    expect(await repo.getFavoriteGroupIdsOf(id), <int>{dark});
    expect((await repo.getById(id))!.isFavorite, isTrue, reason: '改归属不该动收藏状态');

    // 左滑也提供「分组」这个直接入口（同一个面板）。
    await tester.drag(find.byType(SwipeActions), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(SwipeActions), matching: find.text('分组')),
      findsOneWidget,
      reason: '已收藏的记录左滑要能直接改归属',
    );

    await harness.finish(tester);
  });

  testWidgets('⑨ B4：表单里关掉收藏开关保存 → 该记录不再出现在夹 chip 下', (tester) async {
    final int breakfast = await seedGroup('早餐配方');
    final int id = await seedLog('花魁', favorite: true);
    final repo = harness.container.read(brewLogRepositoryProvider);
    await repo.setFavoriteGroups(id, <int>{breakfast});

    // 先在记录页确认它确实在该夹里可见。
    await pumpRecordPage(tester);
    await tester.tap(find.byKey(Key('record.filter.group.$breakfast')));
    await tester.pumpAndSettle();
    expect(find.text('花魁'), findsOneWidget);

    // 走真实路径进编辑表单：点卡片（**不要**再 pump 第二棵 MaterialApp ——
    // 替换 Navigator 时会踩 `_history.isNotEmpty` 断言，与业务无关）。
    await tester.tap(find.text('花魁'));
    await tester.pumpAndSettle();
    await tester.scrollTo(find.byKey(const Key('brew.isFavorite')));
    await tester.tap(find.byKey(const Key('brew.isFavorite')));
    await tester.pumpAndSettle();
    await tester.tapSaveButton();
    await tester.pumpAndSettle();
    // 保存是在**另一条路由**（表单）里完成的，记录页的列表是 drift 实时流 ——
    // 给一拍真实时间让流把新行重发过来，否则读到的还是旧的 isFavorite。
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect((await repo.getById(id))!.isFavorite, isFalse);
    expect(await repo.getFavoriteGroupIdsOf(id), <int>{
      breakfast,
    }, reason: 'save() 不碰关联表，归属行仍在（所以读侧必须守不变量）');

    // 读侧不变量：夹 chip 下不再显示这条"未收藏但在夹里"的记录。
    //
    // 进来时选中的那个夹在路由往返后**仍然选中**（chip 是开关：再点一次会把
    // 筛选取消掉，那是 test 的错，不是产品的），所以这里直接断言当前视图。
    expect(find.byKey(Key('record.filter.group.$breakfast')), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.byKey(Key('record.filter.group.$breakfast')))
          .selected,
      isTrue,
    );
    expect(find.text('花魁'), findsNothing);
    expect(find.text('「早餐配方」还是空的'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('⑥ 管理面板：空名不提交 → 新建 → 改名 → 删除', (tester) async {
    await seedLog('花魁');

    await pumpRecordPage(tester);
    await tester.tap(find.byKey(const Key('record.filter.manage')));
    await tester.pumpAndSettle();
    expect(find.text('管理收藏夹'), findsOneWidget);
    expect(find.text('还没有收藏夹。'), findsOneWidget);

    // 空名：数据层不 trim，所以 UI 这层 trim 后为空必须**不提交**。
    await tester.tap(find.byKey(const Key('record.groupNew')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('record.groupName')),
      findsOneWidget,
      reason: '空名不该提交，对话框要留在原地',
    );
    expect(await groups(tester), isEmpty);

    // 纯空白同样不提交。
    await tester.enterText(find.byKey(const Key('record.groupName')), '   ');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
    expect(await groups(tester), isEmpty);

    // 60 个 emoji：`TextField.maxLength` 按**字素**计（放行），drift 的
    // `withLength(1..60)` 按 **UTF-16 code unit** 计（120 → 会抛）——
    // 所以 UI 必须按同一口径拦下，并给出提示而不是崩。
    await tester.enterText(
      find.byKey(const Key('record.groupName')),
      '🍵' * 60,
    );
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
    expect(find.text('名字太长了，最多 60 个字符'), findsOneWidget);
    expect(find.byKey(const Key('record.groupName')), findsOneWidget);
    expect(await groups(tester), isEmpty);

    // 合法名 → 建出来（并自动出现在管理列表里）。
    await tester.enterText(find.byKey(const Key('record.groupName')), '早餐配方');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final FavoriteGroup group = (await groups(tester)).single;
    expect(group.name, '早餐配方');
    final int id = group.id!;
    expect(find.byKey(Key('record.group.$id')), findsOneWidget);

    // 改名。
    await tester.tap(find.byKey(Key('record.groupRename.$id')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('record.groupName')), '工作日早餐');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();
    expect((await groups(tester)).single.name, '工作日早餐');

    // 删除（先确认）。
    await tester.tap(find.byKey(Key('record.groupDelete.$id')));
    await tester.pumpAndSettle();
    expect(find.text('删掉这个收藏夹？'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();
    expect(await groups(tester), isEmpty);

    await harness.finish(tester);
  });

  testWidgets('⑦ 多选面板里也能新建并自动勾上', (tester) async {
    final int id = await seedLog('花魁');
    final repo = harness.container.read(brewLogRepositoryProvider);

    await pumpRecordPage(tester);
    await swipeAndTap(tester, '收藏');
    expect(find.text('加入哪个收藏夹？'), findsOneWidget);

    await tester.tap(find.byKey(const Key('record.groupPickNew')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('record.groupName')), '给朋友的');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final FavoriteGroup created = (await groups(tester)).single;
    // 新建后自动勾上 → 直接「完成」就该落一条归属。
    await tester.tap(find.byKey(const Key('record.groupPickDone')));
    await tester.pumpAndSettle();

    expect(await repo.getFavoriteGroupIdsOf(id), <int>{created.id!});

    await harness.finish(tester);
  });
}
