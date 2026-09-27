/// 冲煮记录仓储。
///
/// 一条记录可以关联**多支豆子**（拼配），每支豆子与各自粉量存在
/// `brew_log_beans` 表里；`brew_logs.beanId` 只是主豆的冗余字段。
///
/// 这里承载手册 §6.2 的「余量自动扣减」规则，按**每支豆子各自的粉量**扣：
/// - 新建记录 → 各支豆子按各自粉量扣减
/// - 编辑记录 → 按各支豆子的粉量差值补扣；换豆则旧豆回补、新豆扣减
/// - 删除记录 → **不回补**（避免历史余量漂移）
///
/// 规则实现在事务里，便于单元测试。
library;

import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/mappers.dart';
import 'package:beanclick/data/repositories/bean_repository.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:drift/drift.dart';

/// 保存记录的返回值，附带本次的余量变动信息。
class SaveBrewLogResult {
  const SaveBrewLogResult({
    required this.brewLogId,
    this.stockAdjustments = const [],
  });

  final int brewLogId;

  /// 本次因保存而产生的余量调整。关闭自动扣减时为空。
  final List<AdjustStockResult> stockAdjustments;

  /// 是否有任何一次调整因为库存不足被裁剪（UI 据此提示「余量不足」）。
  bool get hasStockShortage =>
      stockAdjustments.any((adjustment) => adjustment.clamped);

  /// 是否有记录里的批次已不存在、余量被扣到了别的批次上。
  ///
  /// UI 应当明确提示，而不是让用户以为扣的是那一袋。
  bool get hasBatchFallback =>
      stockAdjustments.any((adjustment) => adjustment.usedFallbackBatch);
}

class BrewLogRepository {
  BrewLogRepository(this._db, this._beans);

  final AppDatabase _db;
  final BeanRepository _beans;

  /// 时间线：按冲煮时间倒序，并联表带出豆子。
  Stream<List<BrewLog>> watchAll() {
    final query = _db.select(_db.brewLogs)
      ..orderBy([
        (t) => OrderingTerm(expression: t.brewedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().asyncMap(_attachBeans);
  }

  /// 调磨对比：同一支豆 + 同一台磨，按研磨刻度升序（手册 §8）。
  Stream<List<BrewLog>> watchByBeanAndGrinder(int beanId, int grinderId) {
    final query = _db.select(_db.brewLogs)
      ..where((t) => t.beanId.equals(beanId) & t.grinderId.equals(grinderId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.grindSetting, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.brewedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().asyncMap(_attachBeans);
  }

  Future<List<BrewLog>> getAll() async =>
      _attachBeans(await _selectLogs().get());

  Future<BrewLog?> getById(int id) async {
    final row = await (_db.select(
      _db.brewLogs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final attached = await _attachBeans(<BrewLogRow>[row]);
    return attached.isEmpty ? null : attached.first;
  }

  /// 「复制上次」的数据来源（手册 §8）：最近一条记录。
  Future<BrewLog?> getLatest() async {
    final query = _db.select(_db.brewLogs)
      ..orderBy([
        (t) => OrderingTerm(expression: t.brewedAt, mode: OrderingMode.desc),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    final attached = await _attachBeans(<BrewLogRow>[row]);
    return attached.isEmpty ? null : attached.first;
  }

  /// 搜索：关键词（备注/滤杯/风味标签）+ 方法 + 最低评分。
  Future<List<BrewLog>> search({
    String? query,
    BrewMethod? method,
    int? minRating,
  }) async {
    final logs = _db.brewLogs;
    final conditions = <Expression<bool>>[];

    final keyword = query?.trim() ?? '';
    if (keyword.isNotEmpty) {
      final like = '%$keyword%';
      conditions.add(
        logs.notes.like(like) |
            logs.dripper.like(like) |
            logs.flavorTags.like(like),
      );
    }
    if (method != null) {
      conditions.add(logs.method.equalsValue(method));
    }
    if (minRating != null) {
      conditions.add(logs.rating.isBiggerOrEqualValue(minRating));
    }

    final select = _db.select(logs);
    if (conditions.isNotEmpty) {
      select.where((_) => conditions.reduce((a, b) => a & b));
    }
    select.orderBy([
      (t) => OrderingTerm(expression: t.brewedAt, mode: OrderingMode.desc),
    ]);

    return _attachBeans(await select.get());
  }

  /// 保存记录（含多豆关联），并在开启自动扣减时同步调整各批次的余量。
  ///
  /// 整个过程在一个事务里，避免「记录写进去了但余量没扣」的不一致。
  Future<SaveBrewLogResult> save(
    BrewLog log, {
    bool autoDeductStock = true,
  }) async {
    final logs = _db.brewLogs;
    final now = DateTime.now();

    return _db.transaction(() async {
      final adjustments = <AdjustStockResult>[];
      final usages = _normalizeUsages(log);
      // 主豆取 position 最小的那支，冗余进 brew_logs.beanId。
      final primaryBeanId = usages.isEmpty ? null : usages.first.beanId;
      final existingId = log.id;

      if (existingId == null) {
        // --- 新建 ---
        final id = await _db
            .into(logs)
            .insert(
              log.copyWith(beanId: primaryBeanId, updatedAt: now).toCompanion(),
            );
        await _replaceUsages(id, usages);
        if (autoDeductStock) {
          for (final usage in usages) {
            final beanId = usage.beanId;
            // _normalizeUsages 已过滤掉没有 beanId 的行，这里只是类型收窄。
            if (beanId == null || usage.doseGrams == 0) continue;
            adjustments.add(
              await _beans.adjustStock(
                beanId,
                usage.doseGrams,
                batchId: usage.batchId,
              ),
            );
          }
        }
        return SaveBrewLogResult(brewLogId: id, stockAdjustments: adjustments);
      }

      // --- 编辑 ---
      final previous = await _usagesOf(existingId);
      await (_db.update(logs)..where((t) => t.id.equals(existingId))).write(
        log.copyWith(beanId: primaryBeanId, updatedAt: now).toCompanion(),
      );
      await _replaceUsages(existingId, usages);

      if (autoDeductStock) {
        // 按 beanId 聚合；被删除的豆子（beanId 为空）不参与扣减。
        final previousByBean = <int, double>{};
        for (final u in previous) {
          final id = u.beanId;
          if (id != null) previousByBean[id] = u.doseGrams;
        }
        final currentByBean = <int, double>{};
        for (final u in usages) {
          final id = u.beanId;
          if (id != null) currentByBean[id] = u.doseGrams;
        }

        // 回补被移除或减量的豆子。
        for (final entry in previousByBean.entries) {
          final now = currentByBean[entry.key] ?? 0;
          final delta = now - entry.value; // 负数 = 回补
          if (delta == 0) continue;
          adjustments.add(await _beans.adjustStock(entry.key, delta));
        }
        // 扣减新增或加量的豆子。
        for (final entry in currentByBean.entries) {
          if (previousByBean.containsKey(entry.key)) continue;
          if (entry.value == 0) continue;
          final usage = usages.firstWhere((u) => u.beanId == entry.key);
          adjustments.add(
            await _beans.adjustStock(
              entry.key,
              entry.value,
              batchId: usage.batchId,
            ),
          );
        }
      }

      return SaveBrewLogResult(
        brewLogId: existingId,
        stockAdjustments: adjustments,
      );
    });
  }

  /// 硬删除。按手册 §6.2，**不回补余量**。
  Future<void> delete(int id) async {
    await (_db.delete(_db.brewLogs)..where((t) => t.id.equals(id))).go();
  }

  /// 收藏 / 取消收藏一套参数。
  ///
  /// 只改标记，不碰余量，也不影响「最佳参数」标记。
  Future<void> setFavorite(int id, bool value) async {
    await (_db.update(_db.brewLogs)..where((t) => t.id.equals(id))).write(
      BrewLogsCompanion(
        isFavorite: Value(value),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 收藏过的参数，按冲煮时间倒序。
  ///
  /// 「新增一杯」右上角复制按钮长按后列出的就是这一份。
  Future<List<BrewLog>> getFavorites() async {
    final query = _db.select(_db.brewLogs)
      ..where((t) => t.isFavorite.equals(true))
      ..orderBy([
        (t) => OrderingTerm(expression: t.brewedAt, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ]);
    return _attachBeans(await query.get());
  }

  // -------------------------------------------------------------------------
  // 内部
  // -------------------------------------------------------------------------

  SimpleSelectStatement<$BrewLogsTable, BrewLogRow> _selectLogs() =>
      _db.select(_db.brewLogs)..orderBy([
        (t) => OrderingTerm(expression: t.brewedAt, mode: OrderingMode.desc),
      ]);

  /// 规范化豆子用量：丢掉没有 beanId 的行、按 position 排序、重排 position。
  ///
  /// `beanId` 为 null 的行是「豆子已被删除」的残留，不参与新的写入与扣减。
  List<BeanUsage> _normalizeUsages(BrewLog log) {
    final usages = log.beanUsages.where((u) => u.beanId != null).toList();
    usages.sort((a, b) => a.position.compareTo(b.position));
    return <BeanUsage>[
      for (var i = 0; i < usages.length; i++) usages[i].copyWith(position: i),
    ];
  }

  /// 覆写某条记录的豆子用量。
  ///
  /// 写入前补上**豆子名与烘焙日期快照**：豆子之后被删或改名，
  /// 这条记录仍能显示当时用的是什么豆。
  Future<void> _replaceUsages(int brewLogId, List<BeanUsage> usages) async {
    await (_db.delete(
      _db.brewLogBeans,
    )..where((t) => t.brewLogId.equals(brewLogId))).go();
    if (usages.isEmpty) return;

    // 一次性取回要写快照的信息。
    final beanIds = usages
        .map((u) => u.beanId)
        .whereType<int>()
        .toSet()
        .toList();
    final nameById = <int, String>{};
    if (beanIds.isNotEmpty) {
      final rows = await (_db.select(
        _db.coffeeBeans,
      )..where((t) => t.id.isIn(beanIds))).get();
      for (final row in rows) {
        nameById[row.id] = row.name;
      }
    }
    final batchIds = usages
        .map((u) => u.batchId)
        .whereType<int>()
        .toSet()
        .toList();
    final batchById = <int, BeanBatchRow>{};
    if (batchIds.isNotEmpty) {
      final rows = await (_db.select(
        _db.beanBatches,
      )..where((t) => t.id.isIn(batchIds))).get();
      for (final row in rows) {
        batchById[row.id] = row;
      }
    }

    for (final usage in usages) {
      final batch = usage.batchId == null ? null : batchById[usage.batchId];
      await _db
          .into(_db.brewLogBeans)
          .insert(
            usage
                .copyWith(
                  beanName: nameById[usage.beanId] ?? usage.beanName,
                  roastDate: batch?.roastDate ?? usage.roastDate,
                )
                .toCompanion(brewLogId, newBatchId: batch?.id),
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  Future<List<BeanUsage>> _usagesOf(int brewLogId) async {
    final rows =
        await (_db.select(_db.brewLogBeans)
              ..where((t) => t.brewLogId.equals(brewLogId))
              ..orderBy([(t) => OrderingTerm(expression: t.position)]))
            .get();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  /// 给一批记录补上各自的豆子用量（含豆子名），避免逐条查询。
  Future<List<BrewLog>> _attachBeans(List<BrewLogRow> rows) async {
    if (rows.isEmpty) return const <BrewLog>[];

    final ids = rows.map((row) => row.id).toList(growable: false);
    final usageRows =
        await (_db.select(_db.brewLogBeans)
              ..where((t) => t.brewLogId.isIn(ids))
              ..orderBy([(t) => OrderingTerm(expression: t.position)]))
            .get();

    // 一次查出用到的豆子名（已删除的豆子跳过，靠快照名显示）。
    final beanIds = usageRows
        .map((row) => row.beanId)
        .whereType<int>()
        .toSet()
        .toList();
    final nameById = <int, String>{};
    if (beanIds.isNotEmpty) {
      final beanRows = await (_db.select(
        _db.coffeeBeans,
      )..where((t) => t.id.isIn(beanIds))).get();
      for (final bean in beanRows) {
        nameById[bean.id] = bean.name;
      }
    }

    final usagesByLog = <int, List<BeanUsage>>{};
    for (final row in usageRows) {
      usagesByLog
          .putIfAbsent(row.brewLogId, () => <BeanUsage>[])
          .add(row.toEntity(beanName: nameById[row.beanId]));
    }

    return rows
        .map(
          (row) => row.toEntity(
            beanUsages: usagesByLog[row.id] ?? const <BeanUsage>[],
          ),
        )
        .toList(growable: false);
  }
}
