/// Drift 表行对象 ↔ 领域实体的映射。
///
/// 领域实体不依赖 Drift，因此每个方向都要显式转换一次。
library;

import 'package:beanclick/data/database.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// 行 → 实体
// ---------------------------------------------------------------------------

extension CoffeeBeanRowMapper on CoffeeBeanRow {
  CoffeeBean toEntity() => CoffeeBean(
        id: id,
        name: name,
        origin: origin,
        farm: farm,
        process: process,
        roastLevel: roastLevel,
        roastDate: roastDate,
        flavorTags: flavorTags,
        remainingGrams: remainingGrams,
        initialGrams: initialGrams,
        price: price,
        photoPath: photoPath,
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
        scaleUnit: scaleUnit,
        zeroPoint: zeroPoint,
        clicksPerRevolution: clicksPerRevolution,
        calibrationNote: calibrationNote,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension BrewLogRowMapper on BrewLogRow {
  BrewLog toEntity() => BrewLog(
        id: id,
        beanId: beanId,
        grinderId: grinderId,
        recipeId: recipeId,
        method: method,
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
        tds: tds,
        extractionYield: extractionYield,
        waterPpm: waterPpm,
        ambientTemp: ambientTemp,
        ambientHumidity: ambientHumidity,
        beanTemp: beanTemp,
        pressure: pressure,
        pourStages: pourStages,
        heatLevel: heatLevel,
        yieldGrams: yieldGrams,
        preheatUpperChamber: preheatUpperChamber,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension RecipeRowMapper on RecipeRow {
  Recipe toEntity() => Recipe(
        id: id,
        name: name,
        method: method,
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

// ---------------------------------------------------------------------------
// 实体 → Companion
// ---------------------------------------------------------------------------

extension CoffeeBeanCompanionMapper on CoffeeBean {
  CoffeeBeansCompanion toCompanion() => CoffeeBeansCompanion(
        id: id == null ? const Value.absent() : Value(id!),
        name: Value(name),
        origin: Value(origin),
        farm: Value(farm),
        process: Value(process),
        roastLevel: Value(roastLevel),
        roastDate: Value(roastDate),
        flavorTags: Value(flavorTags),
        remainingGrams: Value(remainingGrams),
        initialGrams: Value(initialGrams),
        price: Value(price),
        photoPath: Value(photoPath),
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
        tds: Value(tds),
        extractionYield: Value(extractionYield),
        waterPpm: Value(waterPpm),
        ambientTemp: Value(ambientTemp),
        ambientHumidity: Value(ambientHumidity),
        beanTemp: Value(beanTemp),
        pressure: Value(pressure),
        pourStages: Value(pourStages),
        heatLevel: Value(heatLevel),
        yieldGrams: Value(yieldGrams),
        preheatUpperChamber: Value(preheatUpperChamber),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
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
