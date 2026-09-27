/// 咖啡豆仓储。
///
/// 数据分两层：
/// - **豆子**（[CoffeeBean]）：一款豆子的身份（名称、产地、处理法、风味、收藏）
/// - **批次**（[BeanBatch]）：这一次购买的信息（烘焙日期、烘焙度、余量、价格）
///
/// 余量永远记在批次上；豆子层面的「总余量」由各批次求和得到。
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
    required this.batchId,
    required this.requested,
    required this.applied,
    required this.before,
    required this.after,
    required this.clamped,
    this.batchFound = true,
    this.fallbackFromBatchId,
  });

  final int beanId;

  /// 实际调整的批次；批次不存在时为 null。
  final int? batchId;

  /// 请求调整的克数：正数为扣减，负数为回补。
  final double requested;

  /// 实际生效的克数。扣减为正、回补为负；被 0 下限裁剪时只反映真实变化量。
  final double applied;

  final double before;
  final double after;

  /// 是否因为库存不足被裁剪。
  final bool clamped;

  /// 请求的批次是否存在（可能已被删除）。
  final bool batchFound;

  /// 请求的批次没找到时，实际落到哪个批次上。
  ///
  /// 非 null 表示「发生了换批次扣减」，UI 应当明确提示用户，
  /// 而不是静默扣到别的袋子上。
  final int? fallbackFromBatchId;

  /// 是否发生了「指定批次不存在、改扣别的批次」。
  bool get usedFallbackBatch => fallbackFromBatchId != null;

  @override
  String toString() =>
      'AdjustStockResult(bean: $beanId, batch: $batchId, '
      'requested: $requested, applied: $applied, $before -> $after, '
      'clamped: $clamped, fallbackFrom: $fallbackFromBatchId)';
}

/// 豆子 + 它的批次，供 UI 一次拿到完整信息。
class BeanWithBatches {
  const BeanWithBatches({required this.bean, required this.batches});

  final CoffeeBean bean;
  final List<BeanBatch> batches;

  /// 各批次剩余之和。
  double get totalRemaining =>
      batches.fold<double>(0, (sum, b) => sum + b.remainingGrams);

  /// 最近的烘焙日期（用于展示「烘焙 N 天前」）。
  DateTime? get latestRoastDate {
    final dates = batches
        .map((b) => b.roastDate)
        .whereType<DateTime>()
        .toList(growable: false);
    if (dates.isEmpty) return null;
    dates.sort((a, b) => b.compareTo(a));
    return dates.first;
  }

  /// 还有余量的批次，烘焙日期新的在前。
  List<BeanBatch> get usableBatches {
    final list = batches.where((b) => !b.isEmpty).toList();
    list.sort((a, b) {
      final ad = a.roastDate, bd = b.roastDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return bd.compareTo(ad);
    });
    return list;
  }
}

class BeanRepository {
  BeanRepository(this._db);

  final AppDatabase _db;

  /// 监听全部豆子（按添加时间倒序），并聚合批次数量。
  Stream<List<CoffeeBean>> watchAll() {
    final query = _db.select(_db.coffeeBeans)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch().asyncMap(_withBatchCounts);
  }

  Future<List<CoffeeBean>> getAll() async =>
      _withBatchCounts(await _selectBeans().get());

  /// 只看收藏的豆子。
  Future<List<CoffeeBean>> getFavorites() async {
    final query = _db.select(_db.coffeeBeans)
      ..where((t) => t.isFavorite.equals(true))
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return _withBatchCounts(await query.get());
  }

  Future<CoffeeBean?> getById(int id) async {
    final row = await (_db.select(
      _db.coffeeBeans,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return row.toEntity(batchCount: await _batchCount(id));
  }

  /// 豆子 + 它的全部批次。
  Future<BeanWithBatches?> getWithBatches(int id) async {
    final bean = await getById(id);
    if (bean == null) return null;
    return BeanWithBatches(bean: bean, batches: await batchesOf(id));
  }

  /// 某个豆子的全部批次（烘焙日期新的在前）。
  Future<List<BeanBatch>> batchesOf(int beanId) async {
    final query = _db.select(_db.beanBatches)
      ..where((t) => t.beanId.equals(beanId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.roastDate, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  /// 实时监听某个豆子的批次。
  Stream<List<BeanBatch>> watchBatchesOf(int beanId) {
    final query = _db.select(_db.beanBatches)
      ..where((t) => t.beanId.equals(beanId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.roastDate, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.toEntity()).toList(growable: false),
    );
  }

  /// 新增或更新豆子；`id == null` 为新增，返回实际写入的 id。
  Future<int> save(CoffeeBean bean) async {
    final companion = bean.copyWith(updatedAt: DateTime.now()).toCompanion();
    final id = await _db
        .into(_db.coffeeBeans)
        .insertOnConflictUpdate(companion);
    return bean.id ?? id;
  }

  /// 切换收藏。
  Future<void> setFavorite(int beanId, bool value) async {
    await (_db.update(
      _db.coffeeBeans,
    )..where((t) => t.id.equals(beanId))).write(
      CoffeeBeansCompanion(
        isFavorite: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 删除豆子（级联删除它的批次）。
  Future<void> delete(int id) async {
    await (_db.delete(_db.coffeeBeans)..where((t) => t.id.equals(id))).go();
  }

  /// 关键词搜索：匹配名称、产地、庄园、风味标签。
  Future<List<CoffeeBean>> search(String query) async {
    final beans = _db.coffeeBeans;
    final keyword = query.trim();
    final select = _db.select(beans);
    if (keyword.isNotEmpty) {
      final like = '%$keyword%';
      select.where(
        (t) =>
            t.name.like(like) |
            t.origin.like(like) |
            t.farm.like(like) |
            t.flavorTags.like(like),
      );
    }
    select.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);
    return _withBatchCounts(await select.get());
  }

  // -------------------------------------------------------------------------
  // 批次
  // -------------------------------------------------------------------------

  /// 新增或更新批次。
  Future<int> saveBatch(BeanBatch batch) async {
    final companion = batch.copyWith(updatedAt: DateTime.now()).toCompanion();
    final id = await _db
        .into(_db.beanBatches)
        .insertOnConflictUpdate(companion);
    return batch.id ?? id;
  }

  Future<void> deleteBatch(int batchId) async {
    await (_db.delete(
      _db.beanBatches,
    )..where((t) => t.id.equals(batchId))).go();
  }

  Future<BeanBatch?> getBatch(int batchId) async {
    final row = await (_db.select(
      _db.beanBatches,
    )..where((t) => t.id.equals(batchId))).getSingleOrNull();
    return row?.toEntity();
  }

  /// 某豆子当前用来冲煮的批次：余量大于 0 且烘焙日期最新的那个。
  Future<BeanBatch?> defaultBatchFor(int beanId) async {
    final query = _db.select(_db.beanBatches)
      ..where(
        (t) => t.beanId.equals(beanId) & t.remainingGrams.isBiggerThanValue(0),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.roastDate, mode: OrderingMode.desc),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.toEntity();
  }

  /// 调整批次余量。
  ///
  /// [deltaGrams] 为正表示扣减、为负表示回补。余量下限为 0：
  /// 扣减到 0 以下时会被裁剪，并在返回值里标记 [AdjustStockResult.clamped]。
  ///
  /// **指定了 [batchId] 但那个批次不存在时**（已被删除），会退回到自动挑批次，
  /// 并在返回值里通过 [AdjustStockResult.fallbackFromBatchId] 明确告知，
  /// 由 UI 提示「原批次已不在，改扣了别的批次」——不静默换扣。
  ///
  /// 未指定 [batchId] 时自动挑：优先「有余量 + 烘焙日期最新」的；
  /// 若全部用完则挑任意一个，好让扣减能落到 0。
  ///
  /// 克数按 0.1g 归一写入，避免反复加减累积浮点误差。
  ///
  /// 手册 §6.2 的边界规则由此方法统一保证，调用方不需要自己判边界。
  Future<AdjustStockResult> adjustStock(
    int beanId,
    double deltaGrams, {
    int? batchId,
  }) async {
    final batches = _db.beanBatches;
    return _db.transaction(() async {
      BeanBatchRow? row;
      int? fallbackFrom;
      var found = false;

      if (batchId != null) {
        row = await (_db.select(
          batches,
        )..where((t) => t.id.equals(batchId))).getSingleOrNull();
        found = row != null;
        if (row == null) {
          // 指定批次已不存在：退回到自动挑选，并记下来源以便提示。
          fallbackFrom = batchId;
        }
      }

      if (row == null) {
        // 优先「有余量 + 烘焙日期最新」的。
        //
        // 排序链：烘焙日期 → 创建时间 → id。
        // 后两级不是装饰：Drift 的 dateTime() 按 **Unix 秒** 存储，
        // 同一秒内建的两个批次 createdAt 会完全相同，只按它排序结果不确定。
        // id 是自增的，能保证「后建的批次」稳定胜出。
        row =
            await (_db.select(batches)
                  ..where(
                    (t) =>
                        t.beanId.equals(beanId) &
                        t.remainingGrams.isBiggerThanValue(0),
                  )
                  ..orderBy([
                    (t) => OrderingTerm(
                      expression: t.roastDate,
                      mode: OrderingMode.desc,
                    ),
                    (t) => OrderingTerm(
                      expression: t.createdAt,
                      mode: OrderingMode.desc,
                    ),
                    (t) =>
                        OrderingTerm(expression: t.id, mode: OrderingMode.desc),
                  ])
                  ..limit(1))
                .getSingleOrNull();
        found = row != null;
      }

      if (row == null) {
        // 全用完了：挑任意一个，好让扣减能落到 0。
        row =
            await (_db.select(batches)
                  ..where((t) => t.beanId.equals(beanId))
                  ..orderBy([
                    (t) => OrderingTerm(
                      expression: t.createdAt,
                      mode: OrderingMode.desc,
                    ),
                    (t) =>
                        OrderingTerm(expression: t.id, mode: OrderingMode.desc),
                  ])
                  ..limit(1))
                .getSingleOrNull();
        found = row != null;
      }

      if (row == null) {
        // 这支豆子根本没有批次。
        return AdjustStockResult(
          beanId: beanId,
          batchId: null,
          requested: deltaGrams,
          applied: 0,
          before: 0,
          after: 0,
          clamped: false,
          batchFound: false,
          fallbackFromBatchId: fallbackFrom,
        );
      }

      final batchRow = row;
      // 先归一，再做减法：`roundGrams(before - delta)` 之后还会残留
      // 二进制误差（例如 9.700000000000001），先归一就没有了。
      final before = roundGrams(batchRow.remainingGrams);
      final delta = roundGrams(deltaGrams);
      // 下限 0：扣多了就扣到 0。
      final after = roundGrams(
        (before - delta).clamp(0.0, double.infinity).toDouble(),
      );
      // 刻意用差值反推，而不是直接用 delta：
      // 被 0 下限裁剪时（例如 10g 库存要扣 15g），只有 10g 真正生效。
      final applied = roundGrams(before - after);
      final clamped = delta > 0 && before < delta;

      if (applied != 0) {
        await (_db.update(
          batches,
        )..where((t) => t.id.equals(batchRow.id))).write(
          BeanBatchesCompanion(
            remainingGrams: Value(after),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      return AdjustStockResult(
        beanId: beanId,
        batchId: batchRow.id,
        requested: deltaGrams,
        applied: applied,
        before: before,
        after: after,
        clamped: clamped,
        batchFound: found,
        fallbackFromBatchId: fallbackFrom,
      );
    });
  }

  // -------------------------------------------------------------------------
  // 内部
  // -------------------------------------------------------------------------

  SimpleSelectStatement<$CoffeeBeansTable, CoffeeBeanRow> _selectBeans() =>
      _db.select(_db.coffeeBeans)..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);

  Future<int> _batchCount(int beanId) async {
    final count = _db.beanBatches.id.count();
    final query = _db.selectOnly(_db.beanBatches)
      ..addColumns([count])
      ..where(_db.beanBatches.beanId.equals(beanId));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// 批量补上每个豆子的批次数量，避免逐条查询。
  Future<List<CoffeeBean>> _withBatchCounts(List<CoffeeBeanRow> rows) async {
    if (rows.isEmpty) return const <CoffeeBean>[];
    final count = _db.beanBatches.id.count();
    final query = _db.selectOnly(_db.beanBatches)
      ..addColumns([_db.beanBatches.beanId, count])
      ..groupBy([_db.beanBatches.beanId]);
    final grouped = await query.get();
    final counts = <int, int>{
      for (final row in grouped)
        row.read(_db.beanBatches.beanId)!: row.read(count) ?? 0,
    };
    return rows
        .map((row) => row.toEntity(batchCount: counts[row.id] ?? 0))
        .toList(growable: false);
  }
}
