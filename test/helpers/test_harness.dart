import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/data/repositories/bean_repository.dart';
import 'package:beanclick/data/repositories/brew_log_repository.dart';
import 'package:beanclick/data/repositories/grinder_repository.dart';
import 'package:beanclick/data/repositories/settings_repository.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试共用的内存数据库 + ProviderContainer。
///
/// 用 `AppDatabase.memory()`（SQLite 内存库），每个测试独立一份，互不影响。
class TestHarness {
  TestHarness() {
    db = AppDatabase.memory();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  }

  late final AppDatabase db;
  late final ProviderContainer container;

  BeanRepository get beans => container.read(beanRepositoryProvider);
  GrinderRepository get grinders => container.read(grinderRepositoryProvider);
  BrewLogRepository get logs => container.read(brewLogRepositoryProvider);
  SettingsRepository get settings => container.read(settingsRepositoryProvider);

  /// 建一支豆子 + 一个批次，返回两者的 id。
  ///
  /// 批次模型下这是最常见的准备动作，所以封装在这里避免每个测试重复写。
  Future<({int beanId, int batchId})> addBeanWithBatch({
    String name = '耶加雪菲',
    String? origin = '埃塞俄比亚',
    String? farm,
    List<ProcessMethod> processes = const <ProcessMethod>[ProcessMethod.washed],
    List<String> flavorTags = const ['柑橘', '花香'],
    bool isFavorite = false,
    RoastLevel? roastLevel = RoastLevel.light,
    DateTime? roastDate,
    double remainingGrams = 200,
    double? initialGrams = 200,
    double? price,
    DateTime? createdAt,
  }) async {
    final beanId = await beans.save(
      makeBean(
        name: name,
        origin: origin,
        farm: farm,
        processes: processes,
        flavorTags: flavorTags,
        isFavorite: isFavorite,
        createdAt: createdAt,
      ),
    );
    final batchId = await beans.saveBatch(
      makeBatch(
        beanId: beanId,
        roastDate: roastDate,
        roastLevel: roastLevel,
        remainingGrams: remainingGrams,
        initialGrams: initialGrams,
        price: price,
        createdAt: createdAt,
      ),
    );
    return (beanId: beanId, batchId: batchId);
  }

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}

/// 造一支豆子（只有身份信息，不含批次属性）。
CoffeeBean makeBean({
  String name = '耶加雪菲',
  String? origin = '埃塞俄比亚',
  String? farm,
  List<ProcessMethod> processes = const <ProcessMethod>[ProcessMethod.washed],
  List<String> flavorTags = const ['柑橘', '花香'],
  bool isFavorite = false,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 1, 1, 9);
  return CoffeeBean(
    name: name,
    origin: origin,
    farm: farm,
    processes: processes,
    flavorTags: flavorTags,
    isFavorite: isFavorite,
    createdAt: now,
    updatedAt: now,
  );
}

/// 造一个批次（烘焙日期、烘焙度、余量、价格都在这里）。
BeanBatch makeBatch({
  int beanId = 1,
  DateTime? roastDate,
  RoastLevel? roastLevel = RoastLevel.light,
  double remainingGrams = 200,
  double? initialGrams = 200,
  double? price,
  String? notes,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 1, 1, 9);
  return BeanBatch(
    beanId: beanId,
    roastDate: roastDate,
    roastLevel: roastLevel,
    remainingGrams: remainingGrams,
    initialGrams: initialGrams,
    price: price,
    notes: notes,
    createdAt: now,
    updatedAt: now,
  );
}

/// 造一台磨豆机。
Grinder makeGrinder({
  String brand = 'Comandante',
  String model = 'C40',
  double? zeroPoint = 0,
  int? clicksPerRevolution = 30,
}) {
  final now = DateTime(2026, 1, 1, 9);
  return Grinder(
    brand: brand,
    model: model,
    zeroPoint: zeroPoint,
    clicksPerRevolution: clicksPerRevolution,
    createdAt: now,
    updatedAt: now,
  );
}

/// 造一条冲煮记录。
///
/// [beanId] + [doseGrams] 是单支豆子的快捷写法；
/// 拼配用 [beanUsages]（此时 [doseGrams] 是总粉量）。
BrewLog makeLog({
  int? beanId,
  int? batchId,
  List<BeanUsage>? beanUsages,
  int? grinderId,
  BrewMethod method = BrewMethod.pourOver,
  double? grindSetting = 22,
  double? doseGrams = 15,
  double? waterGrams = 240,
  double? waterTemp = 92,
  int? totalTimeSeconds = 155,
  int? rating = 4,
  String? dripper,
  String? notes,
  bool isBest = false,
  bool isFavorite = false,
  String? methodLabel,
  List<BrewLogAddIn> addIns = const <BrewLogAddIn>[],
  DateTime? brewedAt,
}) {
  final now = brewedAt ?? DateTime(2026, 1, 1, 8);
  final usages =
      beanUsages ??
      (beanId == null
          ? const <BeanUsage>[]
          : <BeanUsage>[
              BeanUsage(
                beanId: beanId,
                batchId: batchId,
                doseGrams: doseGrams ?? 0,
              ),
            ]);
  return BrewLog(
    beanId: beanId,
    grinderId: grinderId,
    method: method,
    grindSetting: grindSetting,
    doseGrams: doseGrams,
    waterGrams: waterGrams,
    waterTemp: waterTemp,
    totalTimeSeconds: totalTimeSeconds,
    rating: rating,
    dripper: dripper,
    notes: notes,
    isBest: isBest,
    isFavorite: isFavorite,
    methodLabel: methodLabel,
    addIns: addIns,
    brewedAt: now,
    beanUsages: usages,
    createdAt: now,
    updatedAt: now,
  );
}
