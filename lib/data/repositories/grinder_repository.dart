/// 磨豆机仓储。
library;

import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/mappers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:drift/drift.dart';

class GrinderRepository {
  GrinderRepository(this._db);

  final AppDatabase _db;

  Stream<List<Grinder>> watchAll() {
    final query = _db.select(_db.grinders)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
      ]);
    return query.watch().map(
      (rows) => rows.map((row) => row.toEntity()).toList(growable: false),
    );
  }

  Future<List<Grinder>> getAll() async {
    final query = _db.select(_db.grinders)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
      ]);
    final rows = await query.get();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  Future<Grinder?> getById(int id) async {
    final row = await (_db.select(
      _db.grinders,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.toEntity();
  }

  Future<int> save(Grinder grinder) async {
    final companion = grinder.copyWith(updatedAt: DateTime.now()).toCompanion();
    final id = await _db.into(_db.grinders).insertOnConflictUpdate(companion);
    return grinder.id ?? id;
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.grinders)..where((t) => t.id.equals(id))).go();
  }

  /// 按品牌/型号关键词搜索。
  Future<List<Grinder>> search(String query) async {
    final grinders = _db.grinders;
    final keyword = query.trim();
    final select = _db.select(grinders);
    if (keyword.isNotEmpty) {
      final like = '%$keyword%';
      select.where((t) => t.brand.like(like) | t.model.like(like));
    }
    select.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc),
    ]);
    final rows = await select.get();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }
}
