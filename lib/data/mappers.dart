/// Drift 表行对象 ↔ 领域实体的映射。
///
/// 领域实体不依赖 Drift，因此每个方向都要显式转换一次。
library;

import 'package:beanclick/data/database.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/domain/extra_attributes.dart';
import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// 行 → 实体
// ---------------------------------------------------------------------------

extension CoffeeBeanRowMapper on CoffeeBeanRow {
  /// [batchCount] 由调用方聚合填充（需要跨表统计，不在本映射里查库）。
  CoffeeBean toEntity({int batchCount = 0}) => CoffeeBean(
    id: id,
    name: name,
    origin: origin,
    farm: farm,
    processes: process,
    flavorTags: flavorTags,
    isFavorite: isFavorite,
    photoPath: photoPath,
    notes: notes,
    batchCount: batchCount,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension BeanBatchRowMapper on BeanBatchRow {
  BeanBatch toEntity() => BeanBatch(
    id: id,
    beanId: beanId,
    roastDate: roastDate,
    roastLevel: roastLevel,
    remainingGrams: remainingGrams,
    initialGrams: initialGrams,
    price: price,
    notes: notes,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension GrinderRowMapper on GrinderRow {
  Grinder toEntity() => Grinder(
    id: id,
    brand: brand,
    model: model,
    burrType: burrType,
    // 认不出的刻度单位回落到 click（枚举是宽容解码，不会崩）。
    scaleUnit: scaleUnit ?? GrindScaleUnit.click,
    zeroPoint: zeroPoint,
    clicksPerRevolution: clicksPerRevolution,
    micronsPerClick: micronsPerClick,
    calibrationNote: calibrationNote,
    notes: notes,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension BrewLogRowMapper on BrewLogRow {
  /// [beanUsages] / [addIns] / [favoriteGroupIds] 由调用方联表填充；不传则视为未关联。
  BrewLog toEntity({
    List<BeanUsage> beanUsages = const [],
    List<BrewLogAddIn> addIns = const [],
    List<int> favoriteGroupIds = const <int>[],
  }) => BrewLog(
    id: id,
    beanId: beanId,
    grinderId: grinderId,
    recipeId: recipeId,
    // 认不出的方法回落到手冲（枚举是宽容解码，不会崩）。
    method: method ?? BrewMethod.pourOver,
    methodLabel: methodLabel,
    grinderZeroPointSnapshot: grinderZeroPointSnapshot,
    grinderClicksPerRevolutionSnapshot: grinderClicksPerRevolutionSnapshot,
    grindSetting: grindSetting,
    grindClicks: grindClicks,
    doseGrams: doseGrams,
    waterGrams: waterGrams,
    ratio: ratio,
    waterTemp: waterTemp,
    totalTimeSeconds: totalTimeSeconds,
    dripper: dripper,
    rating: rating,
    flavorTags: flavorTags,
    notes: notes,
    photoPath: photoPath,
    brewedAt: brewedAt,
    isBest: isBest,
    isFavorite: isFavorite,
    tds: tds,
    extractionYield: extractionYield,
    waterPpm: waterPpm,
    ambientTemp: ambientTemp,
    ambientHumidity: ambientHumidity,
    beanTemp: beanTemp,
    pressure: pressure,
    pourStages: pourStages,
    beanRoastDate: beanRoastDate,
    beanRoastLevel: beanRoastLevel,
    heatLevel: heatLevel,
    yieldGrams: yieldGrams,
    preheatUpperChamber: preheatUpperChamber,
    beanUsages: beanUsages,
    favoriteGroupIds: favoriteGroupIds,
    addIns: addIns,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension BrewLogAddInRowMapper on BrewLogAddInRow {
  BrewLogAddIn toEntity() => BrewLogAddIn(
    id: id,
    name: name,
    brand: brand,
    amount: amount,
    // 认不出的单位回落到 ml（宽容解码，不会崩）。
    unit: unit ?? AddInUnit.ml,
    position: position,
  );
}

extension BrewLogAddInCompanionMapper on BrewLogAddIn {
  /// [newId] 为空时由调用方给出（新建记录时列表才知道 brewLogId）。
  ///
  /// ⚠️ `brand` 必须过 [normalizeAddInBrand]：列是 `withLength(min: 1)`，
  /// 但 drift 的 `withLength` **不生成 SQL 约束**、只在 Dart 侧校验，
  /// `Value('')` 会在写入时抛 `InvalidDataException`。这里是**写入的唯一咽喉**，
  /// 所以归一放在这里，仓储的每条写入路径都自动受保护。
  BrewLogAddinsCompanion toCompanion(int brewLogId, {int? newId}) =>
      BrewLogAddinsCompanion(
        id: newId == null ? const Value.absent() : Value(newId),
        brewLogId: Value(brewLogId),
        name: Value(name),
        brand: Value(normalizeAddInBrand(brand)),
        amount: Value(amount),
        unit: Value(unit),
        position: Value(position),
      );
}

extension FavoriteGroupRowMapper on FavoriteGroupRow {
  FavoriteGroup toEntity() => FavoriteGroup(
    id: id,
    name: name,
    sortOrder: sortOrder,
    createdAt: createdAt,
  );
}

extension FavoriteGroupCompanionMapper on FavoriteGroup {
  /// 新建时 `id` 由数据库分配（`id == null` → 不下发），
  /// 显式带 id 的写入（导入 / 替换）才把 id 一起写下去。
  FavoriteGroupsCompanion toCompanion() => FavoriteGroupsCompanion(
    id: id == null ? const Value.absent() : Value(id!),
    name: Value(name),
    sortOrder: Value(sortOrder),
    createdAt: Value(createdAt),
  );
}

extension BeanUsageRowMapper on BeanUsageRow {
  BeanUsage toEntity({String? beanName}) => BeanUsage(
    beanId: beanId,
    batchId: batchId,
    doseGrams: doseGrams,
    position: position,
    // 优先用写入时的快照；快照为空时才回退到联表查到的当前豆子名。
    beanName: beanNameSnapshot ?? beanName,
    roastDate: roastDateSnapshot,
  );
}

extension RecipeRowMapper on RecipeRow {
  Recipe toEntity() => Recipe(
    id: id,
    name: name,
    // 认不出的方法回落到手冲（枚举是宽容解码，不会崩）。
    method: method ?? BrewMethod.pourOver,
    doseGrams: doseGrams,
    waterGrams: waterGrams,
    ratio: ratio,
    waterTemp: waterTemp,
    totalTimeSeconds: totalTimeSeconds,
    pourStages: pourStages,
    grindSuggestion: grindSuggestion,
    notes: notes,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension ExtraAttributeRowMapper on ExtraAttributeRow {
  ExtraAttribute toEntity() => ExtraAttribute(
    key: key,
    valueType: ExtraValueType.fromStorage(valueType),
    value: value,
    label: label,
    isBuiltin: isBuiltin,
    sortOrder: sortOrder,
  );
}

extension ExtraAttributeCompanionMapper on ExtraAttribute {
  ExtraAttributesCompanion toCompanion(ExtraOwnerType owner, int ownerId) =>
      ExtraAttributesCompanion(
        ownerType: Value(owner.storageKey),
        ownerId: Value(ownerId),
        key: Value(key),
        value: Value(value),
        valueType: Value(valueType.storageKey),
        label: Value(label),
        isBuiltin: Value(isBuiltin),
        sortOrder: Value(sortOrder),
        updatedAt: Value(DateTime.now()),
      );
}

// ---------------------------------------------------------------------------
// 实体 → Companion
// ---------------------------------------------------------------------------

extension CoffeeBeanCompanionMapper on CoffeeBean {
  CoffeeBeansCompanion toCompanion() => CoffeeBeansCompanion(
    id: id == null ? const Value.absent() : Value(id!),
    name: Value(name),
    origin: Value(origin),
    farm: Value(farm),
    process: Value(processes),
    flavorTags: Value(flavorTags),
    isFavorite: Value(isFavorite),
    photoPath: Value(photoPath),
    notes: Value(notes),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}

extension BeanBatchCompanionMapper on BeanBatch {
  BeanBatchesCompanion toCompanion() => BeanBatchesCompanion(
    id: id == null ? const Value.absent() : Value(id!),
    beanId: Value(beanId),
    roastDate: Value(roastDate),
    roastLevel: Value(roastLevel),
    remainingGrams: Value(remainingGrams),
    initialGrams: Value(initialGrams),
    price: Value(price),
    notes: Value(notes),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}

extension GrinderCompanionMapper on Grinder {
  GrindersCompanion toCompanion() => GrindersCompanion(
    id: id == null ? const Value.absent() : Value(id!),
    brand: Value(brand),
    model: Value(model),
    burrType: Value(burrType),
    scaleUnit: Value(scaleUnit),
    zeroPoint: Value(zeroPoint),
    clicksPerRevolution: Value(clicksPerRevolution),
    micronsPerClick: Value(micronsPerClick),
    calibrationNote: Value(calibrationNote),
    notes: Value(notes),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}

extension BrewLogCompanionMapper on BrewLog {
  BrewLogsCompanion toCompanion() => BrewLogsCompanion(
    id: id == null ? const Value.absent() : Value(id!),
    beanId: Value(beanId),
    grinderId: Value(grinderId),
    recipeId: Value(recipeId),
    method: Value(method),
    methodLabel: Value(methodLabel),
    grinderZeroPointSnapshot: Value(grinderZeroPointSnapshot),
    grinderClicksPerRevolutionSnapshot: Value(
      grinderClicksPerRevolutionSnapshot,
    ),
    grindSetting: Value(grindSetting),
    grindClicks: Value(grindClicks),
    doseGrams: Value(doseGrams),
    waterGrams: Value(waterGrams),
    ratio: Value(ratio),
    waterTemp: Value(waterTemp),
    totalTimeSeconds: Value(totalTimeSeconds),
    dripper: Value(dripper),
    rating: Value(rating),
    flavorTags: Value(flavorTags),
    notes: Value(notes),
    photoPath: Value(photoPath),
    brewedAt: Value(brewedAt),
    isBest: Value(isBest),
    isFavorite: Value(isFavorite),
    tds: Value(tds),
    extractionYield: Value(extractionYield),
    waterPpm: Value(waterPpm),
    ambientTemp: Value(ambientTemp),
    ambientHumidity: Value(ambientHumidity),
    beanTemp: Value(beanTemp),
    pressure: Value(pressure),
    pourStages: Value(pourStages),
    beanRoastDate: Value(beanRoastDate),
    beanRoastLevel: Value(beanRoastLevel),
    heatLevel: Value(heatLevel),
    yieldGrams: Value(yieldGrams),
    preheatUpperChamber: Value(preheatUpperChamber),
  );
}

extension BeanUsageCompanionMapper on BeanUsage {
  /// [brewLogId] 与 [newBatchId] 必须由调用方给出——
  /// 实体里的 [BeanUsage] 不知道自己属于哪条记录，也不知道该写回哪个批次
  /// （批次可能已被删除）。
  BrewLogBeansCompanion toCompanion(int brewLogId, {int? newBatchId}) =>
      BrewLogBeansCompanion(
        brewLogId: Value(brewLogId),
        beanId: Value(beanId),
        batchId: Value(newBatchId),
        beanNameSnapshot: Value(beanName),
        roastDateSnapshot: Value(roastDate),
        doseGrams: Value(doseGrams),
        position: Value(position),
      );
}

extension RecipeCompanionMapper on Recipe {
  RecipesCompanion toCompanion() => RecipesCompanion(
    id: id == null ? const Value.absent() : Value(id!),
    name: Value(name),
    method: Value(method),
    doseGrams: Value(doseGrams),
    waterGrams: Value(waterGrams),
    ratio: Value(ratio),
    waterTemp: Value(waterTemp),
    totalTimeSeconds: Value(totalTimeSeconds),
    pourStages: Value(pourStages),
    grindSuggestion: Value(grindSuggestion),
    notes: Value(notes),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}
