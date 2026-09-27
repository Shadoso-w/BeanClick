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

  Future<void> dispose() async {
    container.dispose();
    await db.close();
  }
}

/// 造一支豆子。
CoffeeBean makeBean({
  String name = '耶加雪菲',
  String? origin = '埃塞俄比亚',
  String? farm,
  RoastLevel? roastLevel = RoastLevel.light,
  DateTime? roastDate,
  List<String> flavorTags = const ['柑橘', '花香'],
  double remainingGrams = 200,
  double? initialGrams = 200,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 1, 1, 9);
  return CoffeeBean(
    name: name,
    origin: origin,
    farm: farm,
    roastLevel: roastLevel,
    roastDate: roastDate,
    flavorTags: flavorTags,
    remainingGrams: remainingGrams,
    initialGrams: initialGrams,
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
BrewLog makeLog({
  int? beanId,
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
  DateTime? brewedAt,
}) {
  final now = brewedAt ?? DateTime(2026, 1, 1, 8);
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
    brewedAt: now,
    createdAt: now,
    updatedAt: now,
  );
}
