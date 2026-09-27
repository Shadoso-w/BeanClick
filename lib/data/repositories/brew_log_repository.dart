/// 冲煮记录仓储。
///
/// 这里承载手册 §6.2 的「余量自动扣减」规则：
/// - 新建记录 → 按粉量扣减
/// - 编辑记录 → 按粉量差值补扣
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
}

class BrewLogRepository {
  BrewLogRepository(this._db, this._beans);

  final AppDatabase _db;
  final BeanRepository _beans;

  /// 时间线：按冲煮时间倒序。
  Stream<List<BrewLog>> watchAll() {
    final query = _db.select(_db.brewLogs)
      ..orderBy([
        (t) => OrderingTerm(expression: t.brewedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
          (rows) => rows.map((row) => row.toEntity()).toList(growable: false),
        );
  }

  /// 调磨对比：同一支豆 + 同一台磨，按研磨刻度升序（手册 §8）。
  Stream<List<BrewLog>> watchByBeanAndGrinder(int beanId, int grinderId) {
    final query = _db.select(_db.brewLogs)
      ..where((t) => t.beanId.equals(beanId) & t.grinderId.equals(grinderId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.grindSetting, mode: OrderingMode.asc),
        (t) => OrderingTerm(expression: t.brewedAt, mode: OrderingMode.desc),
      ]);
    return query.watch().map(
          (rows) => rows.map((row) => row.toEntity()).toList(growable: false),
        );
  }

  Future<List<BrewLog>> getAll() async {
    final query = _db.select(_db.brewLogs)
      ..orderBy([
        (t) => OrderingTerm(expression: t.brewedAt, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  Future<BrewLog?> getById(int id) async {
    final row = await (_db.select(_db.brewLogs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toEntity();
  }

  /// 「复制上次」的数据来源（手册 §8）：最近一条记录。
  Future<BrewLog?> getLatest() async {
    final query = _db.select(_db.brewLogs)
      ..orderBy([
        (t) => OrderingTerm(expression: t.brewedAt, mode: OrderingMode.desc),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.toEntity();
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

    final rows = await select.get();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  /// 保存记录，并在开启自动扣减时同步调整豆子余量。
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
      final existingId = log.id;

      if (existingId == null) {
        // --- 新建 ---
        final id = await _db
            .into(logs)
            .insert(log.copyWith(updatedAt: now).toCompanion());
        final beanId = log.beanId;
        final dose = log.doseGrams;
        if (autoDeductStock && beanId != null && dose != null && dose != 0) {
          adjustments.add(await _beans.adjustStock(beanId, dose));
        }
        return SaveBrewLogResult(brewLogId: id, stockAdjustments: adjustments);
      }

      // --- 编辑 ---
      final previous = await (_db.select(logs)
            ..where((t) => t.id.equals(existingId)))
          .getSingleOrNull();
      await (_db.update(logs)..where((t) => t.id.equals(existingId)))
          .write(log.copyWith(updatedAt: now).toCompanion());

      if (autoDeductStock) {
        final previousBeanId = previous?.beanId;
        final newBeanId = log.beanId;
        final previousDose = previous?.doseGrams ?? 0;
        final newDose = log.doseGrams ?? 0;

        if (previousBeanId != null && previousBeanId == newBeanId) {
          // 同一支豆：只按差值补扣，不重算历史。
          final delta = newDose - previousDose;
          if (delta != 0) {
            adjustments.add(await _beans.adjustStock(previousBeanId, delta));
          }
        } else {
          // 换了豆子：旧豆回补原粉量，新豆扣减新粉量。
          if (previousBeanId != null && previousDose != 0) {
            adjustments
                .add(await _beans.adjustStock(previousBeanId, -previousDose));
          }
          if (newBeanId != null && newDose != 0) {
            adjustments.add(await _beans.adjustStock(newBeanId, newDose));
          }
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
}
