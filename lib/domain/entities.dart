/// 领域实体。
///
/// 这些类**不依赖 Flutter、不依赖 Drift**，是纯粹的 Dart 值对象。
/// Drift 生成的表行对象与实体之间的映射在 `lib/data/mappers.dart`。
///
/// 约定：
/// - 全部字段 `final`，通过 `copyWith` 派生新实例。
/// - `id == null` 表示「尚未入库」。
/// - 数值字段用 `double`，时间用 `DateTime`（存库时由 Drift 转 Unix 秒）。
library;

import 'dart:convert';

import 'enums.dart';

/// 分段注水中的一段。
class PourStage {
  const PourStage({
    required this.order,
    required this.waterGrams,
    required this.atSecond,
    this.note,
  });

  /// 第几段（从 1 开始）。
  final int order;

  /// 本段注水量 g。
  final double waterGrams;

  /// 本段开始时间，相对冲煮开始的秒数。
  final int atSecond;

  /// 备注，例如「闷蒸」。
  final String? note;

  Map<String, Object?> toJson() => {
        'order': order,
        'waterGrams': waterGrams,
        'atSecond': atSecond,
        'note': note,
      };

  factory PourStage.fromJson(Map<String, Object?> json) => PourStage(
        order: (json['order'] as num).toInt(),
        waterGrams: (json['waterGrams'] as num).toDouble(),
        atSecond: (json['atSecond'] as num).toInt(),
        note: json['note'] as String?,
      );

  PourStage copyWith({
    int? order,
    double? waterGrams,
    int? atSecond,
    String? note,
    bool clearNote = false,
  }) =>
      PourStage(
        order: order ?? this.order,
        waterGrams: waterGrams ?? this.waterGrams,
        atSecond: atSecond ?? this.atSecond,
        note: clearNote ? null : (note ?? this.note),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PourStage &&
          other.order == order &&
          other.waterGrams == waterGrams &&
          other.atSecond == atSecond &&
          other.note == note;

  @override
  int get hashCode => Object.hash(order, waterGrams, atSecond, note);

  @override
  String toString() =>
      'PourStage(order: $order, waterGrams: $waterGrams, atSecond: $atSecond, note: $note)';
}

/// 咖啡豆。
class CoffeeBean {
  const CoffeeBean({
    this.id,
    required this.name,
    this.origin,
    this.farm,
    this.process,
    this.roastLevel,
    this.roastDate,
    this.flavorTags = const [],
    this.remainingGrams = 0,
    this.initialGrams,
    this.price,
    this.photoPath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String? origin;
  final String? farm;
  final ProcessMethod? process;
  final RoastLevel? roastLevel;
  final DateTime? roastDate;
  final List<String> flavorTags;

  /// 剩余克数，下限为 0。
  final double remainingGrams;

  /// 购入总重，用于计算消耗比例。
  final double? initialGrams;

  final double? price;
  final String? photoPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 养豆天数：从烘焙日期到今天。无烘焙日期时返回 null。
  int? ageInDays({DateTime? now}) {
    final date = roastDate;
    if (date == null) return null;
    final today = now ?? DateTime.now();
    return today.difference(date).inDays;
  }

  /// 消耗比例 0.0–1.0。缺少 [initialGrams] 或其为 0 时返回 null。
  double? consumedRatio() {
    final initial = initialGrams;
    if (initial == null || initial <= 0) return null;
    final ratio = (initial - remainingGrams) / initial;
    return ratio.clamp(0.0, 1.0);
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'origin': origin,
        'farm': farm,
        'process': process?.name,
        'roastLevel': roastLevel?.name,
        'roastDate': roastDate?.toIso8601String(),
        'flavorTags': flavorTags,
        'remainingGrams': remainingGrams,
        'initialGrams': initialGrams,
        'price': price,
        'photoPath': photoPath,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CoffeeBean.fromJson(Map<String, Object?> json) => CoffeeBean(
        id: (json['id'] as num?)?.toInt(),
        name: json['name'] as String,
        origin: json['origin'] as String?,
        farm: json['farm'] as String?,
        process: ProcessMethod.fromName(json['process'] as String?),
        roastLevel: RoastLevel.fromName(json['roastLevel'] as String?),
        roastDate: _date(json['roastDate']),
        flavorTags: (json['flavorTags'] as List<Object?>? ?? const [])
            .map((e) => e as String)
            .toList(growable: false),
        remainingGrams: (json['remainingGrams'] as num?)?.toDouble() ?? 0,
        initialGrams: (json['initialGrams'] as num?)?.toDouble(),
        price: (json['price'] as num?)?.toDouble(),
        photoPath: json['photoPath'] as String?,
        notes: json['notes'] as String?,
        createdAt: _date(json['createdAt']) ?? DateTime.now(),
        updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
      );

  CoffeeBean copyWith({
    int? id,
    String? name,
    String? origin,
    String? farm,
    ProcessMethod? process,
    RoastLevel? roastLevel,
    DateTime? roastDate,
    List<String>? flavorTags,
    double? remainingGrams,
    double? initialGrams,
    double? price,
    String? photoPath,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearOrigin = false,
    bool clearFarm = false,
    bool clearProcess = false,
    bool clearRoastLevel = false,
    bool clearRoastDate = false,
    bool clearInitialGrams = false,
    bool clearPrice = false,
    bool clearPhotoPath = false,
    bool clearNotes = false,
  }) =>
      CoffeeBean(
        id: id ?? this.id,
        name: name ?? this.name,
        origin: clearOrigin ? null : (origin ?? this.origin),
        farm: clearFarm ? null : (farm ?? this.farm),
        process: clearProcess ? null : (process ?? this.process),
        roastLevel: clearRoastLevel ? null : (roastLevel ?? this.roastLevel),
        roastDate: clearRoastDate ? null : (roastDate ?? this.roastDate),
        flavorTags: flavorTags ?? this.flavorTags,
        remainingGrams: remainingGrams ?? this.remainingGrams,
        initialGrams:
            clearInitialGrams ? null : (initialGrams ?? this.initialGrams),
        price: clearPrice ? null : (price ?? this.price),
        photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
        notes: clearNotes ? null : (notes ?? this.notes),
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoffeeBean &&
          other.id == id &&
          other.name == name &&
          other.origin == origin &&
          other.farm == farm &&
          other.process == process &&
          other.roastLevel == roastLevel &&
          other.roastDate == roastDate &&
          _listEquals(other.flavorTags, flavorTags) &&
          other.remainingGrams == remainingGrams &&
          other.initialGrams == initialGrams &&
          other.price == price &&
          other.photoPath == photoPath &&
          other.notes == notes &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        origin,
        farm,
        process,
        roastLevel,
        roastDate,
        Object.hashAll(flavorTags),
        remainingGrams,
        initialGrams,
        price,
        photoPath,
        notes,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'CoffeeBean(id: $id, name: $name, remaining: $remainingGrams g)';
}

/// 磨豆机。
class Grinder {
  const Grinder({
    this.id,
    required this.brand,
    required this.model,
    this.burrType,
    this.scaleUnit = GrindScaleUnit.click,
    this.zeroPoint = 0,
    this.clicksPerRevolution,
    this.calibrationNote,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String brand;
  final String model;
  final String? burrType;
  final GrindScaleUnit scaleUnit;
  final double? zeroPoint;
  final int? clicksPerRevolution;
  final String? calibrationNote;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 手册 §7 的展示格式：`C40 / 22 click / 零点 0`。
  ///
  /// [grindSetting] 为当前刻度，为空时只展示机型与零点。
  String displayName({double? grindSetting, int? clicks}) {
    final parts = <String>['$brand $model'];
    if (grindSetting != null) {
      final setting = grindSetting == grindSetting.roundToDouble()
          ? grindSetting.toInt().toString()
          : grindSetting.toString();
      parts.add(clicks == null ? '$setting ${scaleUnit.label}' : '$setting ${scaleUnit.label} + $clicks click');
    }
    if (zeroPoint != null) {
      final zero = zeroPoint == zeroPoint!.roundToDouble()
          ? zeroPoint!.toInt().toString()
          : zeroPoint.toString();
      parts.add('零点 $zero');
    }
    return parts.join(' / ');
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'burrType': burrType,
        'scaleUnit': scaleUnit.name,
        'zeroPoint': zeroPoint,
        'clicksPerRevolution': clicksPerRevolution,
        'calibrationNote': calibrationNote,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Grinder.fromJson(Map<String, Object?> json) => Grinder(
        id: (json['id'] as num?)?.toInt(),
        brand: json['brand'] as String,
        model: json['model'] as String,
        burrType: json['burrType'] as String?,
        scaleUnit: GrindScaleUnit.fromName(json['scaleUnit'] as String?),
        zeroPoint: (json['zeroPoint'] as num?)?.toDouble(),
        clicksPerRevolution: (json['clicksPerRevolution'] as num?)?.toInt(),
        calibrationNote: json['calibrationNote'] as String?,
        notes: json['notes'] as String?,
        createdAt: _date(json['createdAt']) ?? DateTime.now(),
        updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
      );

  Grinder copyWith({
    int? id,
    String? brand,
    String? model,
    String? burrType,
    GrindScaleUnit? scaleUnit,
    double? zeroPoint,
    int? clicksPerRevolution,
    String? calibrationNote,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBurrType = false,
    bool clearZeroPoint = false,
    bool clearClicksPerRevolution = false,
    bool clearCalibrationNote = false,
    bool clearNotes = false,
  }) =>
      Grinder(
        id: id ?? this.id,
        brand: brand ?? this.brand,
        model: model ?? this.model,
        burrType: clearBurrType ? null : (burrType ?? this.burrType),
        scaleUnit: scaleUnit ?? this.scaleUnit,
        zeroPoint: clearZeroPoint ? null : (zeroPoint ?? this.zeroPoint),
        clicksPerRevolution: clearClicksPerRevolution
            ? null
            : (clicksPerRevolution ?? this.clicksPerRevolution),
        calibrationNote:
            clearCalibrationNote ? null : (calibrationNote ?? this.calibrationNote),
        notes: clearNotes ? null : (notes ?? this.notes),
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Grinder &&
          other.id == id &&
          other.brand == brand &&
          other.model == model &&
          other.burrType == burrType &&
          other.scaleUnit == scaleUnit &&
          other.zeroPoint == zeroPoint &&
          other.clicksPerRevolution == clicksPerRevolution &&
          other.calibrationNote == calibrationNote &&
          other.notes == notes &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, brand, model, burrType, scaleUnit, zeroPoint,
      clicksPerRevolution, calibrationNote, notes, createdAt, updatedAt);

  @override
  String toString() => 'Grinder(id: $id, ${displayName()})';
}

/// 冲煮记录。
class BrewLog {
  const BrewLog({
    this.id,
    this.beanId,
    this.grinderId,
    this.recipeId,
    this.method = BrewMethod.pourOver,
    this.grindSetting,
    this.grindClicks,
    this.doseGrams,
    this.waterGrams,
    this.ratio,
    this.waterTemp,
    this.totalTimeSeconds,
    this.dripper,
    this.rating,
    this.flavorTags = const [],
    this.notes,
    this.photoPath,
    required this.brewedAt,
    this.isBest = false,
    this.tds,
    this.extractionYield,
    this.waterPpm,
    this.ambientTemp,
    this.ambientHumidity,
    this.beanTemp,
    this.pressure,
    this.pourStages,
    this.heatLevel,
    this.yieldGrams,
    this.preheatUpperChamber,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int? beanId;
  final int? grinderId;
  final int? recipeId;
  final BrewMethod method;
  final double? grindSetting;
  final int? grindClicks;
  final double? doseGrams;
  final double? waterGrams;

  /// 粉水比中「1 : N」的 N。
  final double? ratio;

  final double? waterTemp;
  final int? totalTimeSeconds;
  final String? dripper;

  /// 1–5 分。
  final int? rating;

  final List<String> flavorTags;
  final String? notes;
  final String? photoPath;
  final DateTime brewedAt;

  /// 「标记最佳参数」（手册 §8 调磨对比）。
  final bool isBest;

  // --- 专业字段（UI 折叠） ---
  final double? tds;
  final double? extractionYield;
  final int? waterPpm;
  final double? ambientTemp;
  final double? ambientHumidity;
  final double? beanTemp;
  final double? pressure;
  final List<PourStage>? pourStages;

  // --- 摩卡壶专属 ---
  final String? heatLevel;
  final double? yieldGrams;
  final bool? preheatUpperChamber;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// 粉水比：优先取已存的 [ratio]，否则用 水量/粉量 推算。
  double? get effectiveRatio {
    final stored = ratio;
    if (stored != null && stored > 0) return stored;
    final dose = doseGrams;
    final water = waterGrams;
    if (dose == null || water == null || dose <= 0) return null;
    return water / dose;
  }

  /// 总时长的显示格式：`2:35`。
  String? get formattedTime {
    final seconds = totalTimeSeconds;
    if (seconds == null) return null;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'beanId': beanId,
        'grinderId': grinderId,
        'recipeId': recipeId,
        'method': method.name,
        'grindSetting': grindSetting,
        'grindClicks': grindClicks,
        'doseGrams': doseGrams,
        'waterGrams': waterGrams,
        'ratio': ratio,
        'waterTemp': waterTemp,
        'totalTimeSeconds': totalTimeSeconds,
        'dripper': dripper,
        'rating': rating,
        'flavorTags': flavorTags,
        'notes': notes,
        'photoPath': photoPath,
        'brewedAt': brewedAt.toIso8601String(),
        'isBest': isBest,
        'tds': tds,
        'extractionYield': extractionYield,
        'waterPpm': waterPpm,
        'ambientTemp': ambientTemp,
        'ambientHumidity': ambientHumidity,
        'beanTemp': beanTemp,
        'pressure': pressure,
        'pourStages': pourStages?.map((e) => e.toJson()).toList(growable: false),
        'heatLevel': heatLevel,
        'yieldGrams': yieldGrams,
        'preheatUpperChamber': preheatUpperChamber,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BrewLog.fromJson(Map<String, Object?> json) => BrewLog(
        id: (json['id'] as num?)?.toInt(),
        beanId: (json['beanId'] as num?)?.toInt(),
        grinderId: (json['grinderId'] as num?)?.toInt(),
        recipeId: (json['recipeId'] as num?)?.toInt(),
        method: BrewMethod.fromName(json['method'] as String?) ?? BrewMethod.pourOver,
        grindSetting: (json['grindSetting'] as num?)?.toDouble(),
        grindClicks: (json['grindClicks'] as num?)?.toInt(),
        doseGrams: (json['doseGrams'] as num?)?.toDouble(),
        waterGrams: (json['waterGrams'] as num?)?.toDouble(),
        ratio: (json['ratio'] as num?)?.toDouble(),
        waterTemp: (json['waterTemp'] as num?)?.toDouble(),
        totalTimeSeconds: (json['totalTimeSeconds'] as num?)?.toInt(),
        dripper: json['dripper'] as String?,
        rating: (json['rating'] as num?)?.toInt(),
        flavorTags: (json['flavorTags'] as List<Object?>? ?? const [])
            .map((e) => e as String)
            .toList(growable: false),
        notes: json['notes'] as String?,
        photoPath: json['photoPath'] as String?,
        brewedAt: _date(json['brewedAt']) ?? DateTime.now(),
        isBest: json['isBest'] as bool? ?? false,
        tds: (json['tds'] as num?)?.toDouble(),
        extractionYield: (json['extractionYield'] as num?)?.toDouble(),
        waterPpm: (json['waterPpm'] as num?)?.toInt(),
        ambientTemp: (json['ambientTemp'] as num?)?.toDouble(),
        ambientHumidity: (json['ambientHumidity'] as num?)?.toDouble(),
        beanTemp: (json['beanTemp'] as num?)?.toDouble(),
        pressure: (json['pressure'] as num?)?.toDouble(),
        pourStages: (json['pourStages'] as List<Object?>?)
            ?.map((e) => PourStage.fromJson((e as Map).cast<String, Object?>()))
            .toList(growable: false),
        heatLevel: json['heatLevel'] as String?,
        yieldGrams: (json['yieldGrams'] as num?)?.toDouble(),
        preheatUpperChamber: json['preheatUpperChamber'] as bool?,
        createdAt: _date(json['createdAt']) ?? DateTime.now(),
        updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
      );

  BrewLog copyWith({
    int? id,
    int? beanId,
    int? grinderId,
    int? recipeId,
    BrewMethod? method,
    double? grindSetting,
    int? grindClicks,
    double? doseGrams,
    double? waterGrams,
    double? ratio,
    double? waterTemp,
    int? totalTimeSeconds,
    String? dripper,
    int? rating,
    List<String>? flavorTags,
    String? notes,
    String? photoPath,
    DateTime? brewedAt,
    bool? isBest,
    double? tds,
    double? extractionYield,
    int? waterPpm,
    double? ambientTemp,
    double? ambientHumidity,
    double? beanTemp,
    double? pressure,
    List<PourStage>? pourStages,
    String? heatLevel,
    double? yieldGrams,
    bool? preheatUpperChamber,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBeanId = false,
    bool clearGrinderId = false,
    bool clearRecipeId = false,
    bool clearGrindSetting = false,
    bool clearGrindClicks = false,
    bool clearDoseGrams = false,
    bool clearWaterGrams = false,
    bool clearRatio = false,
    bool clearWaterTemp = false,
    bool clearTotalTimeSeconds = false,
    bool clearDripper = false,
    bool clearRating = false,
    bool clearNotes = false,
    bool clearPhotoPath = false,
    bool clearTds = false,
    bool clearExtractionYield = false,
    bool clearWaterPpm = false,
    bool clearAmbientTemp = false,
    bool clearAmbientHumidity = false,
    bool clearBeanTemp = false,
    bool clearPressure = false,
    bool clearPourStages = false,
    bool clearHeatLevel = false,
    bool clearYieldGrams = false,
    bool clearPreheatUpperChamber = false,
  }) =>
      BrewLog(
        id: id ?? this.id,
        beanId: clearBeanId ? null : (beanId ?? this.beanId),
        grinderId: clearGrinderId ? null : (grinderId ?? this.grinderId),
        recipeId: clearRecipeId ? null : (recipeId ?? this.recipeId),
        method: method ?? this.method,
        grindSetting: clearGrindSetting ? null : (grindSetting ?? this.grindSetting),
        grindClicks: clearGrindClicks ? null : (grindClicks ?? this.grindClicks),
        doseGrams: clearDoseGrams ? null : (doseGrams ?? this.doseGrams),
        waterGrams: clearWaterGrams ? null : (waterGrams ?? this.waterGrams),
        ratio: clearRatio ? null : (ratio ?? this.ratio),
        waterTemp: clearWaterTemp ? null : (waterTemp ?? this.waterTemp),
        totalTimeSeconds:
            clearTotalTimeSeconds ? null : (totalTimeSeconds ?? this.totalTimeSeconds),
        dripper: clearDripper ? null : (dripper ?? this.dripper),
        rating: clearRating ? null : (rating ?? this.rating),
        flavorTags: flavorTags ?? this.flavorTags,
        notes: clearNotes ? null : (notes ?? this.notes),
        photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
        brewedAt: brewedAt ?? this.brewedAt,
        isBest: isBest ?? this.isBest,
        tds: clearTds ? null : (tds ?? this.tds),
        extractionYield:
            clearExtractionYield ? null : (extractionYield ?? this.extractionYield),
        waterPpm: clearWaterPpm ? null : (waterPpm ?? this.waterPpm),
        ambientTemp: clearAmbientTemp ? null : (ambientTemp ?? this.ambientTemp),
        ambientHumidity:
            clearAmbientHumidity ? null : (ambientHumidity ?? this.ambientHumidity),
        beanTemp: clearBeanTemp ? null : (beanTemp ?? this.beanTemp),
        pressure: clearPressure ? null : (pressure ?? this.pressure),
        pourStages: clearPourStages ? null : (pourStages ?? this.pourStages),
        heatLevel: clearHeatLevel ? null : (heatLevel ?? this.heatLevel),
        yieldGrams: clearYieldGrams ? null : (yieldGrams ?? this.yieldGrams),
        preheatUpperChamber: clearPreheatUpperChamber
            ? null
            : (preheatUpperChamber ?? this.preheatUpperChamber),
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrewLog &&
          other.id == id &&
          other.beanId == beanId &&
          other.grinderId == grinderId &&
          other.recipeId == recipeId &&
          other.method == method &&
          other.grindSetting == grindSetting &&
          other.grindClicks == grindClicks &&
          other.doseGrams == doseGrams &&
          other.waterGrams == waterGrams &&
          other.ratio == ratio &&
          other.waterTemp == waterTemp &&
          other.totalTimeSeconds == totalTimeSeconds &&
          other.dripper == dripper &&
          other.rating == rating &&
          _listEquals(other.flavorTags, flavorTags) &&
          other.notes == notes &&
          other.photoPath == photoPath &&
          other.brewedAt == brewedAt &&
          other.isBest == isBest &&
          other.tds == tds &&
          other.extractionYield == extractionYield &&
          other.waterPpm == waterPpm &&
          other.ambientTemp == ambientTemp &&
          other.ambientHumidity == ambientHumidity &&
          other.beanTemp == beanTemp &&
          other.pressure == pressure &&
          _listEquals(other.pourStages, pourStages) &&
          other.heatLevel == heatLevel &&
          other.yieldGrams == yieldGrams &&
          other.preheatUpperChamber == preheatUpperChamber &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hashAll([
        id,
        beanId,
        grinderId,
        recipeId,
        method,
        grindSetting,
        grindClicks,
        doseGrams,
        waterGrams,
        ratio,
        waterTemp,
        totalTimeSeconds,
        dripper,
        rating,
        Object.hashAll(flavorTags),
        notes,
        photoPath,
        brewedAt,
        isBest,
        tds,
        extractionYield,
        waterPpm,
        ambientTemp,
        ambientHumidity,
        beanTemp,
        pressure,
        pourStages == null ? null : Object.hashAll(pourStages!),
        heatLevel,
        yieldGrams,
        preheatUpperChamber,
        createdAt,
        updatedAt,
      ]);

  @override
  String toString() =>
      'BrewLog(id: $id, method: ${method.name}, bean: $beanId, dose: $doseGrams g)';
}

/// 配方。
class Recipe {
  const Recipe({
    this.id,
    required this.name,
    this.method = BrewMethod.pourOver,
    this.doseGrams,
    this.waterGrams,
    this.ratio,
    this.waterTemp,
    this.totalTimeSeconds,
    this.pourStages,
    this.grindSuggestion,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final BrewMethod method;
  final double? doseGrams;
  final double? waterGrams;
  final double? ratio;
  final double? waterTemp;
  final int? totalTimeSeconds;
  final List<PourStage>? pourStages;
  final String? grindSuggestion;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'method': method.name,
        'doseGrams': doseGrams,
        'waterGrams': waterGrams,
        'ratio': ratio,
        'waterTemp': waterTemp,
        'totalTimeSeconds': totalTimeSeconds,
        'pourStages': pourStages?.map((e) => e.toJson()).toList(growable: false),
        'grindSuggestion': grindSuggestion,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Recipe.fromJson(Map<String, Object?> json) => Recipe(
        id: (json['id'] as num?)?.toInt(),
        name: json['name'] as String,
        method: BrewMethod.fromName(json['method'] as String?) ?? BrewMethod.pourOver,
        doseGrams: (json['doseGrams'] as num?)?.toDouble(),
        waterGrams: (json['waterGrams'] as num?)?.toDouble(),
        ratio: (json['ratio'] as num?)?.toDouble(),
        waterTemp: (json['waterTemp'] as num?)?.toDouble(),
        totalTimeSeconds: (json['totalTimeSeconds'] as num?)?.toInt(),
        pourStages: (json['pourStages'] as List<Object?>?)
            ?.map((e) => PourStage.fromJson((e as Map).cast<String, Object?>()))
            .toList(growable: false),
        grindSuggestion: json['grindSuggestion'] as String?,
        notes: json['notes'] as String?,
        createdAt: _date(json['createdAt']) ?? DateTime.now(),
        updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
      );

  Recipe copyWith({
    int? id,
    String? name,
    BrewMethod? method,
    double? doseGrams,
    double? waterGrams,
    double? ratio,
    double? waterTemp,
    int? totalTimeSeconds,
    List<PourStage>? pourStages,
    String? grindSuggestion,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Recipe(
        id: id ?? this.id,
        name: name ?? this.name,
        method: method ?? this.method,
        doseGrams: doseGrams ?? this.doseGrams,
        waterGrams: waterGrams ?? this.waterGrams,
        ratio: ratio ?? this.ratio,
        waterTemp: waterTemp ?? this.waterTemp,
        totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
        pourStages: pourStages ?? this.pourStages,
        grindSuggestion: grindSuggestion ?? this.grindSuggestion,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe &&
          other.id == id &&
          other.name == name &&
          other.method == method &&
          other.doseGrams == doseGrams &&
          other.waterGrams == waterGrams &&
          other.ratio == ratio &&
          other.waterTemp == waterTemp &&
          other.totalTimeSeconds == totalTimeSeconds &&
          _listEquals(other.pourStages, pourStages) &&
          other.grindSuggestion == grindSuggestion &&
          other.notes == notes &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, name, method, doseGrams, waterGrams, ratio,
      waterTemp, totalTimeSeconds, pourStages == null ? null : Object.hashAll(pourStages!),
      grindSuggestion, notes, createdAt, updatedAt);

  @override
  String toString() => 'Recipe(id: $id, name: $name)';
}

/// `List` 的逐元素比较，供各实体的 `==` 使用。
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 宽松解析 ISO8601 时间字符串；解析失败返回 null 而不是抛异常。
DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// 供导出功能使用的 JSON 编解码快捷方法。
String encodeJsonList(List<Map<String, Object?>> items) => jsonEncode(items);
