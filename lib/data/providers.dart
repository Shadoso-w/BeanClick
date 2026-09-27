/// Riverpod providers：数据库、仓储。
///
/// 约定：所有 provider 都定义在这里，UI 只从这里取依赖，
/// 不在 UI 层直接 new 数据库或仓储。
library;

import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/repositories/bean_repository.dart';
import 'package:beanclick/data/repositories/brew_log_repository.dart';
import 'package:beanclick/data/repositories/grinder_repository.dart';
import 'package:beanclick/data/repositories/settings_repository.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 数据库实例。整个应用生命周期内只有一个。
///
/// 测试里可以用 `databaseProvider.overrideWithValue(AppDatabase.memory())` 替换。
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider 必须在 main() 里被 override，'
    '或在测试中被 overrideWithValue 覆盖',
  );
});

final beanRepositoryProvider = Provider<BeanRepository>(
  (ref) => BeanRepository(ref.watch(databaseProvider)),
);

final grinderRepositoryProvider = Provider<GrinderRepository>(
  (ref) => GrinderRepository(ref.watch(databaseProvider)),
);

final brewLogRepositoryProvider = Provider<BrewLogRepository>(
  (ref) => BrewLogRepository(
    ref.watch(databaseProvider),
    ref.watch(beanRepositoryProvider),
  ),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

/// 主题模式：监听设置表，设置页改动后根 MaterialApp 会自动重建。
final themeModeProvider = StreamProvider(
  (ref) => ref.watch(settingsRepositoryProvider).watchThemeMode(),
);

/// 是否在冲煮后自动扣减余量（手册 §6.2），直接订阅设置表。
final autoDeductStockProvider = StreamProvider(
  (ref) => ref.watch(settingsRepositoryProvider).watchAutoDeductStock(),
);

// ---------------------------------------------------------------------------
// 列表数据源
//
// 集中定义，避免每个页面各自订阅一份 drift 流（同一份数据被订阅多次）。
// ---------------------------------------------------------------------------

/// 全部咖啡豆（按添加时间倒序）。
final beanListProvider = StreamProvider<List<CoffeeBean>>(
  (ref) => ref.watch(beanRepositoryProvider).watchAll(),
);

/// 全部磨豆机（按添加时间正序）。
final grinderListProvider = StreamProvider<List<Grinder>>(
  (ref) => ref.watch(grinderRepositoryProvider).watchAll(),
);

/// 全部冲煮记录（按冲煮时间倒序）。
final brewLogListProvider = StreamProvider<List<BrewLog>>(
  (ref) => ref.watch(brewLogRepositoryProvider).watchAll(),
);
