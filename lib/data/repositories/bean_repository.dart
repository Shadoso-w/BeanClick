/// 咖啡豆仓储。
library;

import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/mappers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:drift/drift.dart';

/// 余量调整的结果。
///
/// 自动扣减时如果库存不够，会扣到 0 并返回 [clamped] = true，
/// 由 UI 决定是否提示「余量不足」。
class AdjustStockResult {
  const AdjustStockResult({
    required this.beanId,
    required this.requested,
    required this.applied,
    required this.before,
    required this.after,
    required this.clamped,
    this.beanFound = true,
  });

  final int beanId;

  /// 请求调整的克数：正数为扣减，负数为回补。
  final double requested;

  /// 实际生效的克数：扣减为正、回补为负。
  ///
  /// 与 [requested] 的区别在于它**总是**表示真实变化量：
  /// 被 0 下限裁剪时（库存 10g 却要扣 15g），[applied] 只有 10。
  final double applied;

  final double before;
  final double after;

  /// 是否因为库存不足被裁剪。
  final bool clamped;

  /// 豆子是否还存在（可能已被删除）。
  final bool beanFound;

  @override
  String toString() =>
      'AdjustStockResult(bean: $beanId, requested: $requested, '
      'applied: $applied, $before -> $after, clamped: $clamped)';
}

class BeanRepository {
  BeanRepository(this._db);

  final AppDatabase _db;

  /// 按添加时间倒序监听全部豆子。
  Stream<List<CoffeeBean>> watchAll() {
    final query = _db.select(_db.coffeeBeans)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.toEntity()).toList(growable: false),
    );
  }

  Future<List<CoffeeBean>> getAll() async {
    final query = _db.select(_db.coffeeBeans)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  Future<CoffeeBean?> getById(int id) async {
    final row = await (_db.select(
      _db.coffeeBeans,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toEntity();
  }

  /// 新增或更新。`id == null` 为新增，返回实际写入的 id。
  Future<int> save(CoffeeBean bean) async {
    final companion = bean.copyWith(updatedAt: DateTime.now()).toCompanion();
    final id = await _db
        .into(_db.coffeeBeans)
        .insertOnConflictUpdate(companion);
    return bean.id ?? id;
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.coffeeBeans)..where((t) => t.id.equals(id))).go();
  }

  /// 关键词搜索：匹配名称、产地、庄园、风味标签。
  ///
  /// 风味标签存在 JSON 字符串里，用 LIKE 直接匹配即可满足 MVP
  /// （设计稿 §0 已说明：标签筛选不是 P0 的索引需求）。
  Future<List<CoffeeBean>> search(
    String query, {
    DateTime? roastedBefore,
  }) async {
    final beans = _db.coffeeBeans;
    final conditions = <Expression<bool>>[];

    final keyword = query.trim();
    if (keyword.isNotEmpty) {
      final like = '%$keyword%';
      conditions.add(
        beans.name.like(like) |
            beans.origin.like(like) |
            beans.farm.like(like) |
            beans.flavorTags.like(like),
      );
    }

    if (roastedBefore != null) {
      conditions.add(beans.roastDate.isSmallerOrEqualValue(roastedBefore));
    }

    final select = _db.select(beans);
    if (conditions.isNotEmpty) {
      select.where((_) => conditions.reduce((a, b) => a & b));
    }
    select.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);

    final rows = await select.get();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  /// 调整余量。
  ///
  /// [deltaGrams] 为正表示扣减，为负表示回补。余量下限为 0：
  /// 扣减到 0 以下时会被裁剪，并在返回值里标记 [AdjustStockResult.clamped]。
  ///
  /// 手册 §6.2 的边界规则由此方法统一保证，调用方不需要自己判边界。
  Future<AdjustStockResult> adjustStock(int beanId, double deltaGrams) async {
    final beans = _db.coffeeBeans;
    return _db.transaction(() async {
      final row = await (_db.select(
        beans,
      )..where((t) => t.id.equals(beanId))).getSingleOrNull();
      if (row == null) {
        return AdjustStockResult(
          beanId: beanId,
          requested: deltaGrams,
          applied: 0,
          before: 0,
          after: 0,
          clamped: false,
          beanFound: false,
        );
      }

      final before = row.remainingGrams;
      // 下限 0：扣多了就扣到 0。
      final after = (before - deltaGrams)
          .clamp(0.0, double.infinity)
          .toDouble();
      // 刻意用差值反推，而不是直接用 deltaGrams：
      // 被 0 下限裁剪时（例如 10g 库存要扣 15g），只有 10g 真正生效。
      final applied = before - after;
      final clamped = deltaGrams > 0 && before < deltaGrams;

      if (applied != 0) {
        await (_db.update(beans)..where((t) => t.id.equals(beanId))).write(
          CoffeeBeansCompanion(
            remainingGrams: Value(after),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      return AdjustStockResult(
        beanId: beanId,
        requested: deltaGrams,
        applied: applied,
        before: before,
        after: after,
        clamped: clamped,
      );
    });
  }
}
