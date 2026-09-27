/// Riverpod providers：数据库、仓储。
///
/// 约定：所有 provider 都定义在这里，UI 只从这里取依赖，
/// 不在 UI 层直接 new 数据库或仓储。
library;

import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/repositories/bean_repository.dart';
import 'package:beanclick/data/repositories/brew_log_repository.dart';
import 'package:beanclick/data/repositories/extra_attribute_repository.dart';
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

/// 扩展属性仓储（豆子 / 磨豆机的任意附加信息）。
final extraAttributeRepositoryProvider = Provider<ExtraAttributeRepository>(
  (ref) => ExtraAttributeRepository(ref.watch(databaseProvider)),
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

/// 自定义冲煮方法库（有序）。
///
/// 存在设置表里，表单的方法 chip 行跟着它变；改完立刻生效，
/// 不需要重进表单。
final customBrewMethodsProvider = StreamProvider<List<String>>(
  (ref) => ref.watch(settingsRepositoryProvider).watchCustomBrewMethods(),
);

/// 全部批次，按豆子分组。
///
/// 豆库列表需要「总余量 / 批次数 / 最近烘焙日」，这些都在批次上。
/// 一次取回全部再在内存里分组，避免每支豆子各查一次（N+1）。
final batchesByBeanProvider = FutureProvider<Map<int, List<BeanBatch>>>((
  ref,
) async {
  // 依赖豆子列表，豆子变动时一起刷新。
  final List<CoffeeBean> beans = await ref.watch(beanListProvider.future);
  final Map<int, List<BeanBatch>> grouped = <int, List<BeanBatch>>{};
  for (final CoffeeBean bean in beans) {
    final int? id = bean.id;
    if (id == null) continue;
    grouped[id] = await ref.watch(beanRepositoryProvider).batchesOf(id);
  }
  return grouped;
});

/// 全部磨豆机（按添加时间正序）。
final grinderListProvider = StreamProvider<List<Grinder>>(
  (ref) => ref.watch(grinderRepositoryProvider).watchAll(),
);

/// 全部冲煮记录（按冲煮时间倒序）。
final brewLogListProvider = StreamProvider<List<BrewLog>>(
  (ref) => ref.watch(brewLogRepositoryProvider).watchAll(),
);
