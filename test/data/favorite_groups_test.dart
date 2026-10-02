import 'package:beanclick/data/database.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

/// v8（T38）：自定义收藏夹分组 —— 数据层。
///
/// 分工（设计稿 §2「关键决定 1」、§6 裁决 C = ②）：
/// - `brew_logs.isFavorite` 仍是「是否收藏」的**唯一**判据；
/// - `favorite_groups` + `brew_log_favorite_groups` 只回答「这条收藏还放进了哪些夹」；
/// - **没有关联行 = 收藏了但没分组**，不是「没收藏」。
///
/// 所以这一组用例里有两条专门盯住「夹不改变收藏语义」，防止后来人把
/// `isFavorite` 与关联表耦合起来。
void main() {
  late TestHarness harness;

  setUp(() => harness = TestHarness());
  tearDown(() => harness.dispose());

  /// 造一条记录（带豆子），返回它的 id。
  Future<int> newLog() async {
    final a = await harness.addBeanWithBatch();
    return (await harness.logs.save(
      makeLog(beanId: a.beanId, batchId: a.batchId),
    )).brewLogId;
  }

  // -------------------------------------------------------------------------
  group('收藏夹 CRUD', () {
    test('建组后能读回，名与顺序都在', () async {
      final int id = await harness.logs.createFavoriteGroup('早餐配方');

      final List<FavoriteGroup> groups = await harness.logs
          .watchFavoriteGroups()
          .first;
      expect(groups, hasLength(1));
      expect(groups.single.id, id);
      expect(groups.single.name, '早餐配方');
      expect(groups.single.sortOrder, 0);
    });

    test('watchFavoriteGroups 会推送变化', () async {
      final List<List<FavoriteGroup>> emissions = <List<FavoriteGroup>>[];
      final subscription = harness.logs.watchFavoriteGroups().listen(
        emissions.add,
      );

      await harness.logs.createFavoriteGroup('早餐配方');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(emissions.last.single.name, '早餐配方');
    });

    test('改名', () async {
      final int id = await harness.logs.createFavoriteGroup('早餐');

      await harness.logs.renameFavoriteGroup(id, '早餐配方');

      final List<FavoriteGroup> groups = await harness.logs
          .watchFavoriteGroups()
          .first;
      expect(groups.single.name, '早餐配方');
      expect(groups.single.id, id, reason: '改名不该换一个 id');
    });

    test('删组：关联行随 CASCADE 一起消失', () async {
      final int logId = await newLog();
      final int groupId = await harness.logs.createFavoriteGroup('早餐');
      await harness.logs.setFavoriteGroups(logId, <int>{groupId});
      expect(await harness.logs.getFavoriteGroupIdsOf(logId), <int>{groupId});

      await harness.logs.deleteFavoriteGroup(groupId);

      expect(await harness.logs.watchFavoriteGroups().first, isEmpty);
      expect(
        await harness.logs.getFavoriteGroupIdsOf(logId),
        isEmpty,
        reason: '关联行应随组一起被 ON DELETE CASCADE 删掉',
      );
      expect(
        await harness.db.select(harness.db.brewLogFavoriteGroups).get(),
        isEmpty,
      );
    });
  });

  // -------------------------------------------------------------------------
  group('记录 ↔ 收藏夹（一条记录可进多个夹）', () {
    test('setFavoriteGroups 是替换语义，重复设同一组不会重复行', () async {
      final int logId = await newLog();
      final int g1 = await harness.logs.createFavoriteGroup('早餐');
      final int g2 = await harness.logs.createFavoriteGroup('手冲');

      await harness.logs.setFavoriteGroups(logId, <int>{g1, g2});
      expect(await harness.logs.getFavoriteGroupIdsOf(logId), <int>{g1, g2});

      // 再设一次（只留 g1）：替换式写入，既该清掉 g2 的行，也不该长出重复行。
      await harness.logs.setFavoriteGroups(logId, <int>{g1});
      expect(await harness.logs.getFavoriteGroupIdsOf(logId), <int>{g1});
      expect(
        await harness.db.select(harness.db.brewLogFavoriteGroups).get(),
        hasLength(1),
        reason: '替换式：不该残留 g2，也不该重复插 g1',
      );

      // 空集合 = 取消分组（但**不等于取消收藏**）。
      await harness.logs.setFavoriteGroups(logId, const <int>{});
      expect(await harness.logs.getFavoriteGroupIdsOf(logId), isEmpty);
    });

    test('读记录时附着 favoriteGroupIds；未分组是空列表不是 null', () async {
      final int logId = await newLog();
      final int g1 = await harness.logs.createFavoriteGroup('早餐');
      final int g2 = await harness.logs.createFavoriteGroup('手冲');
      await harness.logs.setFavoriteGroups(logId, <int>{g1, g2});

      final BrewLog log = (await harness.logs.getById(logId))!;
      expect(log.favoriteGroupIds.toSet(), <int>{g1, g2});

      final int plainLogId = await newLog();
      final BrewLog plain = (await harness.logs.getById(plainLogId))!;
      expect(plain.favoriteGroupIds, isEmpty);
    });

    test('唯一约束真的拒绝同一 (brewLogId, groupId) 重复插入', () async {
      final int logId = await newLog();
      final int groupId = await harness.logs.createFavoriteGroup('早餐');

      Future<void> rawInsert() => harness.db
          .into(harness.db.brewLogFavoriteGroups)
          .insert(
            BrewLogFavoriteGroupsCompanion.insert(
              brewLogId: logId,
              groupId: groupId,
            ),
          );

      await rawInsert();
      // 表层的唯一索引（`idx_brew_log_favorite_groups_unique`）必须真的挡下来，
      // 而不是只靠仓储"用 Set 传参"间接保证。
      await expectLater(rawInsert(), throwsA(anything));
      expect(
        await harness.db.select(harness.db.brewLogFavoriteGroups).get(),
        hasLength(1),
        reason: '第二次插入必须被唯一索引挡住，不能留下第二行',
      );
    });
  });

  // -------------------------------------------------------------------------
  group('isFavorite 语义不变（夹只是归类）', () {
    test('收藏但未分组仍是收藏：getFavorites 里有它', () async {
      final int logId = await newLog();
      await harness.logs.setFavorite(logId, true);

      final List<BrewLog> favorites = await harness.logs.getFavorites();
      expect(favorites.map((BrewLog log) => log.id), contains(logId));
      expect(favorites.single.favoriteGroupIds, isEmpty);
    });

    test('进夹不等于收藏；收藏也不要求先有夹', () async {
      final int logId = await newLog();
      final int groupId = await harness.logs.createFavoriteGroup('早餐');

      await harness.logs.setFavoriteGroups(logId, <int>{groupId});
      expect(
        (await harness.logs.getById(logId))!.isFavorite,
        isFalse,
        reason: '进了夹不等于收藏（isFavorite 是唯一判据）',
      );
      expect(await harness.logs.getFavorites(), isEmpty);

      await harness.logs.setFavorite(logId, true);
      final BrewLog log = (await harness.logs.getById(logId))!;
      expect(log.isFavorite, isTrue);
      expect(log.favoriteGroupIds, <int>[groupId]);
      expect(await harness.logs.getFavorites(), hasLength(1));
    });
  });
}
