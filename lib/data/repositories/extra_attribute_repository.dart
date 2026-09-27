/// 扩展属性仓储。
///
/// 给豆子 / 磨豆机读写任意附加信息。值的类型由 `ExtraValueType` 决定，
/// 统一以 JSON 存在 `extra_attributes` 表里。
///
/// 写入语义：`save` 是**只写传入的项**（upsert），不会清掉别的 key；
/// 未传值的项会被删除（视为「清空该项」）。
library;

import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/mappers.dart';
import 'package:beanclick/domain/extra_attributes.dart';
import 'package:drift/drift.dart';

class ExtraAttributeRepository {
  ExtraAttributeRepository(this._db);

  final AppDatabase _db;

  /// 内置定义的骨架：全部 `value = null`。
  ///
  /// 新增对象（还没入库、没有 id）时用它渲染表单，
  /// 这样表单不需要自己知道有哪些内置属性。
  List<ExtraAttribute> skeletonFor(ExtraOwnerType owner) =>
      ExtraAttributeRegistry.of(owner)
          .map((definition) => definition.toAttribute())
          .toList(growable: false);

  /// 读某个对象的全部扩展属性。
  ///
  /// 结果 = 内置定义（哪怕没填值，也会带 `value = null` 出现，便于表单渲染）
  /// + 用户自建的 key。
  /// 排序：`sortOrder` 升序，其次按 key 稳定排序。
  Future<List<ExtraAttribute>> getAll(ExtraOwnerType owner, int ownerId) async {
    final rows =
        await (_db.select(_db.extraAttributes)
              ..where(
                (t) =>
                    t.ownerType.equals(owner.storageKey) &
                    t.ownerId.equals(ownerId),
              )
              ..orderBy([
                (t) => OrderingTerm(expression: t.sortOrder),
                (t) => OrderingTerm(expression: t.key),
              ]))
            .get();

    final byKey = <String, ExtraAttribute>{
      for (final row in rows) row.key: row.toEntity(),
    };

    // 内置定义先铺底：即使库里没有该行，表单也要能显示这个字段。
    final result = <ExtraAttribute>[];
    for (final definition in ExtraAttributeRegistry.of(owner)) {
      final existing = byKey.remove(definition.key);
      result.add(existing ?? definition.toAttribute());
    }
    // 剩下的都是用户自建的。
    result.addAll(byKey.values);

    result.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
    });
    return result;
  }

  /// 实时监听某个对象的扩展属性。
  Stream<List<ExtraAttribute>> watch(ExtraOwnerType owner, int ownerId) {
    final query = _db.select(_db.extraAttributes)
      ..where(
        (t) => t.ownerType.equals(owner.storageKey) & t.ownerId.equals(ownerId),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.key),
      ]);
    return query.watch().map((rows) {
      final byKey = <String, ExtraAttribute>{
        for (final row in rows) row.key: row.toEntity(),
      };
      final result = <ExtraAttribute>[
        for (final definition in ExtraAttributeRegistry.of(owner))
          byKey.remove(definition.key) ?? definition.toAttribute(),
        ...byKey.values,
      ];
      result.sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.key.compareTo(b.key);
      });
      return result;
    });
  }

  /// 批量读多个对象的扩展属性（避免 N+1 查询）。
  Future<Map<int, List<ExtraAttribute>>> getAllFor(
    ExtraOwnerType owner,
    List<int> ownerIds,
  ) async {
    if (ownerIds.isEmpty) return const <int, List<ExtraAttribute>>{};
    final rows =
        await (_db.select(_db.extraAttributes)
              ..where(
                (t) =>
                    t.ownerType.equals(owner.storageKey) &
                    t.ownerId.isIn(ownerIds),
              )
              ..orderBy([
                (t) => OrderingTerm(expression: t.sortOrder),
                (t) => OrderingTerm(expression: t.key),
              ]))
            .get();

    final grouped = <int, List<ExtraAttribute>>{};
    for (final row in rows) {
      grouped
          .putIfAbsent(row.ownerId, () => <ExtraAttribute>[])
          .add(row.toEntity());
    }
    return grouped;
  }

  /// 写入若干扩展属性。
  ///
  /// - 值为 null / 空 → 删除该 key
  /// - 其余 upsert
  ///
  /// 只影响传入的 key，别的 key 原样保留。
  ///
  /// **内置性、展示名、排序都由注册表决定**，调用方不需要（也不应该）
  /// 自己填 `isBuiltin`——否则会存出「一个内置属性却被标成自定义」的脏数据。
  Future<void> save(
    ExtraOwnerType owner,
    int ownerId,
    List<ExtraAttribute> attributes,
  ) async {
    if (attributes.isEmpty) return;
    final now = DateTime.now();
    await _db.transaction(() async {
      for (final attribute in attributes) {
        final key = attribute.key.trim();
        if (key.isEmpty) continue;

        if (!attribute.hasValue) {
          await (_db.delete(_db.extraAttributes)..where(
                (t) =>
                    t.ownerType.equals(owner.storageKey) &
                    t.ownerId.equals(ownerId) &
                    t.key.equals(key),
              ))
              .go();
          continue;
        }

        // 以注册表为准补全元数据。
        final definition = ExtraAttributeRegistry.find(owner, key);
        final label = attribute.label ?? definition?.label;
        final sortOrder = definition?.sortOrder ?? attribute.sortOrder;

        await _db
            .into(_db.extraAttributes)
            .insertOnConflictUpdate(
              ExtraAttributesCompanion(
                ownerType: Value(owner.storageKey),
                ownerId: Value(ownerId),
                key: Value(key),
                value: Value(attribute.value),
                valueType: Value(attribute.valueType.storageKey),
                label: Value(label),
                isBuiltin: Value(definition != null),
                sortOrder: Value(sortOrder),
                updatedAt: Value(now),
              ),
            );
      }
    });
  }

  /// 删除一个扩展属性。
  Future<void> delete(ExtraOwnerType owner, int ownerId, String key) async {
    await (_db.delete(_db.extraAttributes)..where(
          (t) =>
              t.ownerType.equals(owner.storageKey) &
              t.ownerId.equals(ownerId) &
              t.key.equals(key),
        ))
        .go();
  }

  /// 删除某个对象的全部扩展属性。对象本身被删除时调用。
  Future<void> deleteAllFor(ExtraOwnerType owner, int ownerId) async {
    await (_db.delete(_db.extraAttributes)..where(
          (t) =>
              t.ownerType.equals(owner.storageKey) & t.ownerId.equals(ownerId),
        ))
        .go();
  }

  // -------------------------------------------------------------------------
  // 各实体的便捷入口
  //
  // 让调用方不必自己拼 (ownerType, ownerId)。新增一类可扩展对象时，
  // 在这里加一组三行的方法即可，仓库主体逻辑不用动。
  // -------------------------------------------------------------------------

  Future<List<ExtraAttribute>> getForBean(int beanId) =>
      getAll(ExtraOwnerType.bean, beanId);

  Future<void> saveForBean(int beanId, List<ExtraAttribute> attributes) =>
      save(ExtraOwnerType.bean, beanId, attributes);

  Future<List<ExtraAttribute>> getForGrinder(int grinderId) =>
      getAll(ExtraOwnerType.grinder, grinderId);

  Future<void> saveForGrinder(int grinderId, List<ExtraAttribute> attributes) =>
      save(ExtraOwnerType.grinder, grinderId, attributes);

  Future<List<ExtraAttribute>> getForBrewLog(int brewLogId) =>
      getAll(ExtraOwnerType.brewLog, brewLogId);

  Future<void> saveForBrewLog(int brewLogId, List<ExtraAttribute> attributes) =>
      save(ExtraOwnerType.brewLog, brewLogId, attributes);

  Future<List<ExtraAttribute>> getForBatch(int batchId) =>
      getAll(ExtraOwnerType.batch, batchId);

  Future<void> saveForBatch(int batchId, List<ExtraAttribute> attributes) =>
      save(ExtraOwnerType.batch, batchId, attributes);

  Future<List<ExtraAttribute>> getForRecipe(int recipeId) =>
      getAll(ExtraOwnerType.recipe, recipeId);

  Future<void> saveForRecipe(int recipeId, List<ExtraAttribute> attributes) =>
      save(ExtraOwnerType.recipe, recipeId, attributes);

  /// 复制一个对象的扩展属性到另一个对象（同类型内）。
  ///
  /// 用于「复制上次」「豆子复购」这类操作：附加信息跟着一起走。
  Future<void> copyTo(
    ExtraOwnerType owner,
    int fromId,
    int toId, {
    bool overwrite = false,
  }) async {
    if (fromId == toId) return;
    final source = await getAll(owner, fromId);
    final filled = source.where((a) => a.hasValue).toList(growable: false);
    if (filled.isEmpty) return;

    if (overwrite) {
      await save(owner, toId, filled);
      return;
    }

    // 不覆盖时只补目标缺失的项。
    final existing = await getAll(owner, toId);
    final existingKeys = <String>{
      for (final a in existing)
        if (a.hasValue) a.key,
    };
    final missing = filled
        .where((a) => !existingKeys.contains(a.key))
        .toList(growable: false);
    if (missing.isNotEmpty) await save(owner, toId, missing);
  }
}
