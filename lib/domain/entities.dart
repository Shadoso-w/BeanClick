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
  }) => PourStage(
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

/// 咖啡豆的**一款**（不区分批次）。
///
/// 「一款豆子」= 名称 + 产地 + 庄园 + 处理法 + 风味 + 收藏状态。
/// 烘焙日期、烘焙度、余量、价格这些**每次购买都可能不同**的信息挂在
/// [BeanBatch] 上，复购同一款豆子时加一个批次即可，不必新建重复的豆子。
class CoffeeBean {
  const CoffeeBean({
    this.id,
    required this.name,
    this.origin,
    this.farm,
    this.processes = const [],
    this.flavorTags = const [],
    this.isFavorite = false,
    this.photoPath,
    this.notes,
    this.batchCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String? origin;
  final String? farm;

  /// 处理法，**可以多选**（如「水洗 + 厌氧」）。空列表 = 没填。
  final List<ProcessMethod> processes;

  /// 风味标签，属于这款豆子。
  final List<String> flavorTags;

  /// 收藏标记。豆库可只看收藏，复购时也先从这里挑。
  final bool isFavorite;

  final String? photoPath;
  final String? notes;

  /// 批次数量。由 Repository 聚合填充，不直接存储。
  final int batchCount;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// 展示用：`产地 · 处理法`；都没有时返回 null。
  String? get originLabel {
    final parts = <String>[
      if (origin != null && origin!.isNotEmpty) origin!,
      ...processes.map((ProcessMethod method) => method.label),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'origin': origin,
    'farm': farm,
    'processes': processes
        .map((ProcessMethod method) => method.name)
        .toList(growable: false),
    'flavorTags': flavorTags,
    'isFavorite': isFavorite,
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
    // `processes` 是 v7 起的数组；兼容老备份里的单值 `process`。
    processes: <ProcessMethod>[
      ...(json['processes'] as List<Object?>? ?? const <Object?>[])
          .map((Object? e) => ProcessMethod.fromName(e?.toString()))
          .whereType<ProcessMethod>(),
      if (json['processes'] == null) ...<ProcessMethod>[
        ?ProcessMethod.fromName(json['process'] as String?),
      ],
    ],
    flavorTags: (json['flavorTags'] as List<Object?>? ?? const [])
        .map((e) => e as String)
        .toList(growable: false),
    isFavorite: json['isFavorite'] as bool? ?? false,
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
    List<ProcessMethod>? processes,
    List<String>? flavorTags,
    bool? isFavorite,
    String? photoPath,
    String? notes,
    int? batchCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearOrigin = false,
    bool clearFarm = false,
    bool clearPhotoPath = false,
    bool clearNotes = false,
  }) => CoffeeBean(
    id: id ?? this.id,
    name: name ?? this.name,
    origin: clearOrigin ? null : (origin ?? this.origin),
    farm: clearFarm ? null : (farm ?? this.farm),
    processes: processes ?? this.processes,
    flavorTags: flavorTags ?? this.flavorTags,
    isFavorite: isFavorite ?? this.isFavorite,
    photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
    notes: clearNotes ? null : (notes ?? this.notes),
    batchCount: batchCount ?? this.batchCount,
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
          _listEquals(other.processes, processes) &&
          _listEquals(other.flavorTags, flavorTags) &&
          other.isFavorite == isFavorite &&
          other.photoPath == photoPath &&
          other.notes == notes &&
          other.batchCount == batchCount &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    origin,
    farm,
    Object.hashAll(processes),
    Object.hashAll(flavorTags),
    isFavorite,
    photoPath,
    notes,
    batchCount,
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'CoffeeBean(id: $id, name: $name, batches: $batchCount)';
}

/// 咖啡豆批次：同一款豆子的每一次购买。
class BeanBatch {
  const BeanBatch({
    this.id,
    required this.beanId,
    this.roastDate,
    this.roastLevel,
    this.remainingGrams = 0,
    this.initialGrams,
    this.price,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final int beanId;
  final DateTime? roastDate;
  final RoastLevel? roastLevel;

  /// 剩余克数（g），下限 0。
  final double remainingGrams;

  /// 购入总重（g）。
  final double? initialGrams;

  final double? price;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 养豆天数；无烘焙日期时返回 null。
  int? ageInDays({DateTime? now}) {
    final date = roastDate;
    if (date == null) return null;
    return (now ?? DateTime.now()).difference(date).inDays;
  }

  /// 消耗比例 0.0–1.0；缺少 [initialGrams] 或为 0 时返回 null。
  double? consumedRatio() {
    final initial = initialGrams;
    if (initial == null || initial <= 0) return null;
    return ((initial - remainingGrams) / initial).clamp(0.0, 1.0);
  }

  /// 是否已用完。
  bool get isEmpty => remainingGrams <= 0;

  Map<String, Object?> toJson() => {
    'id': id,
    'beanId': beanId,
    'roastDate': roastDate?.toIso8601String(),
    'roastLevel': roastLevel?.name,
    'remainingGrams': remainingGrams,
    'initialGrams': initialGrams,
    'price': price,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BeanBatch.fromJson(Map<String, Object?> json) => BeanBatch(
    id: (json['id'] as num?)?.toInt(),
    beanId: (json['beanId'] as num).toInt(),
    roastDate: _date(json['roastDate']),
    roastLevel: RoastLevel.fromName(json['roastLevel'] as String?),
    remainingGrams: (json['remainingGrams'] as num?)?.toDouble() ?? 0,
    initialGrams: (json['initialGrams'] as num?)?.toDouble(),
    price: (json['price'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
    createdAt: _date(json['createdAt']) ?? DateTime.now(),
    updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
  );

  BeanBatch copyWith({
    int? id,
    int? beanId,
    DateTime? roastDate,
    RoastLevel? roastLevel,
    double? remainingGrams,
    double? initialGrams,
    double? price,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearRoastDate = false,
    bool clearRoastLevel = false,
    bool clearInitialGrams = false,
    bool clearPrice = false,
    bool clearNotes = false,
  }) => BeanBatch(
    id: id ?? this.id,
    beanId: beanId ?? this.beanId,
    roastDate: clearRoastDate ? null : (roastDate ?? this.roastDate),
    roastLevel: clearRoastLevel ? null : (roastLevel ?? this.roastLevel),
    remainingGrams: remainingGrams ?? this.remainingGrams,
    initialGrams: clearInitialGrams
        ? null
        : (initialGrams ?? this.initialGrams),
    price: clearPrice ? null : (price ?? this.price),
    notes: clearNotes ? null : (notes ?? this.notes),
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeanBatch &&
          other.id == id &&
          other.beanId == beanId &&
          other.roastDate == roastDate &&
          other.roastLevel == roastLevel &&
          other.remainingGrams == remainingGrams &&
          other.initialGrams == initialGrams &&
          other.price == price &&
          other.notes == notes &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    beanId,
    roastDate,
    roastLevel,
    remainingGrams,
    initialGrams,
    price,
    notes,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'BeanBatch(id: $id, bean: $beanId, remaining: $remainingGrams g)';
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
    this.micronsPerClick,
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

  /// 每 click 约等于多少微米（刀盘每格的位移量）。可空 = 没量过。
  final double? micronsPerClick;
  final String? calibrationNote;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 相对刻度：把「几圈 + 几个 click」换算成一个 click 值（M2.10 公式、M3-T15 定稿取值规则）。
  ///
  /// ```
  /// 相对刻度 = 圈 × 每圈 click + click − 零点
  /// ```
  ///
  /// 「每圈 click」与「零点」都**优先用磨豆机当前的值**；磨豆机被删或该字段为空时，
  /// 才回落到**记录里的快照**（[BrewLog.grinderClicksPerRevolutionSnapshot] /
  /// [BrewLog.grinderZeroPointSnapshot]）。两个值**各判各的**：当前值缺一个，不会连带
  /// 另一个也回落，所以算出来的数可能一个来自当前值、一个来自快照。取舍由调用方做，
  /// 本方法只接算好的两个参数——唯一调用点是 `BrewLogFormPage.relativeClicks`
  /// （表单页静态方法，记录卡片与表单提示共用，两处必须算同一个数）。
  ///
  /// 行为后果：改磨豆机零点后，**历史记录卡片上显示的数字会跟着变**（记录里的圈 /
  /// click 不变），屏幕上的读数因此和机器上的实际刻度一致；磨豆机被删的老记录
  /// 也仍然读得出来。两个校准值当前值与快照都取不到时按 0 参与计算。
  ///
  /// [clicksPerRevolution] 为空或 ≤ 0 时返回 null；`turns` 与 `clicks` 都为空时也返回
  /// null（存量旧机器没填「每圈 click」）：宁可不显示，也不瞎算。
  static double? relativeClicksWith({
    double? turns,
    int? clicks,
    int? clicksPerRevolution,
    double? zeroPoint,
  }) {
    if (clicksPerRevolution == null || clicksPerRevolution <= 0) return null;
    if (turns == null && clicks == null) return null;
    return (turns ?? 0) * clicksPerRevolution +
        (clicks ?? 0) -
        (zeroPoint ?? 0);
  }

  /// 手册 §7 的展示格式：`C40 / 22 click / 零点 0`。
  ///
  /// [showCurrentSetting] 为 false 时只给「名称 / 零点」——
  /// 豆库卡片第一栏要的就是这两项（测评反馈），当前刻度放在别处展示。
  String displayName({
    double? grindSetting,
    int? clicks,
    bool showCurrentSetting = true,
  }) {
    final parts = <String>['$brand $model'];
    if (showCurrentSetting && grindSetting != null) {
      final setting = grindSetting == grindSetting.roundToDouble()
          ? grindSetting.toInt().toString()
          : grindSetting.toString();
      parts.add(
        clicks == null
            ? '$setting ${scaleUnit.label}'
            : '$setting ${scaleUnit.label} + $clicks click',
      );
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
    'micronsPerClick': micronsPerClick,
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
    micronsPerClick: (json['micronsPerClick'] as num?)?.toDouble(),
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
    double? micronsPerClick,
    String? calibrationNote,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearBurrType = false,
    bool clearZeroPoint = false,
    bool clearClicksPerRevolution = false,
    bool clearMicronsPerClick = false,
    bool clearCalibrationNote = false,
    bool clearNotes = false,
  }) => Grinder(
    id: id ?? this.id,
    brand: brand ?? this.brand,
    model: model ?? this.model,
    burrType: clearBurrType ? null : (burrType ?? this.burrType),
    scaleUnit: scaleUnit ?? this.scaleUnit,
    zeroPoint: clearZeroPoint ? null : (zeroPoint ?? this.zeroPoint),
    clicksPerRevolution: clearClicksPerRevolution
        ? null
        : (clicksPerRevolution ?? this.clicksPerRevolution),
    micronsPerClick: clearMicronsPerClick
        ? null
        : (micronsPerClick ?? this.micronsPerClick),
    calibrationNote: clearCalibrationNote
        ? null
        : (calibrationNote ?? this.calibrationNote),
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
          other.micronsPerClick == micronsPerClick &&
          other.calibrationNote == calibrationNote &&
          other.notes == notes &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    brand,
    model,
    burrType,
    scaleUnit,
    zeroPoint,
    clicksPerRevolution,
    micronsPerClick,
    calibrationNote,
    notes,
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'Grinder(id: $id, ${displayName()})';
}

/// 把「辅料牌子」归一：**空串 / 纯空白 → null**。
///
/// 为什么必须归一：库里 `brew_log_addins.brand` 是
/// `text().withLength(min: 1, max: 60).nullable()()`，而 drift 的 `withLength`
/// **不生成 SQL 约束**、只在 Dart 侧校验 —— 写入 `Value('')` 会抛
/// `InvalidDataException`，`Value(null)` 不会。所以写入前必须过这里。
///
/// 只把「空」变 null，**不动其它值**（`' Oatly '` 原样存：改用户数据要有理由）。
String? normalizeAddInBrand(String? brand) {
  if (brand == null) return null;
  return brand.trim().isEmpty ? null : brand;
}

/// 「最近用过」的一条辅料：名字 + 牌子（v8 / T37，裁决 B）。
///
/// 去重口径是 `(name, brand)`：同名不同牌是两条，同名同牌合并成一条。
/// 用记录类型而不是小类，是为了让仓储与 UI 都不必为一个投影多引一个类型。
typedef RecentAddIn = ({String name, String? brand});

/// 一条记录里加的一种辅料（牛奶、榛果糖浆、冰块…）。
///
/// 与 [BeanUsage] 同构：**每条记录多行**，名字存文本快照（不建名字表），
/// 所以删掉或改名都不影响历史记录的可读性。
class BrewLogAddIn {
  const BrewLogAddIn({
    this.id,
    required this.name,
    this.brand,
    this.amount,
    this.unit = AddInUnit.ml,
    this.position = 0,
  });

  final int? id;

  /// 辅料名，如「牛奶」。
  final String name;

  /// 牌子（v8 / T37），如「Oatly」。可空 = 没记牌子。
  ///
  /// 空串会被 [normalizeAddInBrand] 在写入前归一成 null。
  final String? brand;

  /// 数量；**可以为空**，表示「只记加了什么、没量」。
  final double? amount;

  final AddInUnit unit;
  final int position;

  BrewLogAddIn copyWith({
    int? id,
    String? name,
    String? brand,
    double? amount,
    AddInUnit? unit,
    int? position,
    bool clearAmount = false,
    bool clearBrand = false,
  }) => BrewLogAddIn(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: clearBrand ? null : (brand ?? this.brand),
    amount: clearAmount ? null : (amount ?? this.amount),
    unit: unit ?? this.unit,
    position: position ?? this.position,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'amount': amount,
    'unit': unit.name,
    'position': position,
  };

  factory BrewLogAddIn.fromJson(Map<String, Object?> json) => BrewLogAddIn(
    id: (json['id'] as num?)?.toInt(),
    name: (json['name'] as String?) ?? '',
    // 备份里可能是空串（清过牌子的记录），统一归一成 null。
    brand: normalizeAddInBrand(json['brand'] as String?),
    amount: (json['amount'] as num?)?.toDouble(),
    unit: AddInUnit.fromName(json['unit'] as String?) ?? AddInUnit.ml,
    position: (json['position'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrewLogAddIn &&
          other.id == id &&
          other.name == name &&
          other.brand == brand &&
          other.amount == amount &&
          other.unit == unit &&
          other.position == position;

  @override
  int get hashCode => Object.hash(id, name, brand, amount, unit, position);

  @override
  String toString() =>
      'BrewLogAddIn(${brand == null ? name : '$brand $name'}, '
      '$amount ${unit.name})';
}

/// 一条冲煮记录用到的其中一支豆子。
///
/// [beanId] 在豆子被删除后会变成 null，但 [beanName] 是**写入时的快照**，
/// 因此记录永远能显示「当时用的是什么豆」。
class BeanUsage {
  const BeanUsage({
    this.beanId,
    this.batchId,
    this.doseGrams = 0,
    this.position = 0,
    this.beanName,
    this.roastDate,
  });

  /// 豆子 id；豆子被删后为 null。
  final int? beanId;

  final int? batchId;
  final double doseGrams;
  final int position;

  /// 豆子名。写入时存快照；从库里读出来时由 Repository 联表补全。
  final String? beanName;

  /// 当时的烘焙日期快照。
  final DateTime? roastDate;

  /// 展示名：优先用名称，其次退化成 id。
  String get label {
    final name = beanName;
    if (name != null && name.isNotEmpty) return name;
    final id = beanId;
    return id == null ? '已删除的豆子' : '豆子#$id';
  }

  BeanUsage copyWith({
    int? beanId,
    int? batchId,
    double? doseGrams,
    int? position,
    String? beanName,
    DateTime? roastDate,
    bool clearBeanId = false,
    bool clearBatchId = false,
    bool clearBeanName = false,
    bool clearRoastDate = false,
  }) => BeanUsage(
    beanId: clearBeanId ? null : (beanId ?? this.beanId),
    batchId: clearBatchId ? null : (batchId ?? this.batchId),
    doseGrams: doseGrams ?? this.doseGrams,
    position: position ?? this.position,
    beanName: clearBeanName ? null : (beanName ?? this.beanName),
    roastDate: clearRoastDate ? null : (roastDate ?? this.roastDate),
  );

  Map<String, Object?> toJson() => {
    'beanId': beanId,
    'batchId': batchId,
    'doseGrams': doseGrams,
    'position': position,
    'beanName': beanName,
    'roastDate': roastDate?.toIso8601String(),
  };

  factory BeanUsage.fromJson(Map<String, Object?> json) => BeanUsage(
    beanId: (json['beanId'] as num?)?.toInt(),
    batchId: (json['batchId'] as num?)?.toInt(),
    doseGrams: (json['doseGrams'] as num?)?.toDouble() ?? 0,
    position: (json['position'] as num?)?.toInt() ?? 0,
    beanName: json['beanName'] as String?,
    roastDate: _date(json['roastDate']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeanUsage &&
          other.beanId == beanId &&
          other.batchId == batchId &&
          other.doseGrams == doseGrams &&
          other.position == position &&
          other.beanName == beanName &&
          other.roastDate == roastDate;

  @override
  int get hashCode =>
      Object.hash(beanId, batchId, doseGrams, position, beanName, roastDate);

  @override
  String toString() =>
      'BeanUsage(bean: $beanId, batch: $batchId, dose: $doseGrams g, '
      'name: $beanName)';
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
    this.grinderZeroPointSnapshot,
    this.grinderClicksPerRevolutionSnapshot,
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
    this.isFavorite = false,
    this.tds,
    this.extractionYield,
    this.waterPpm,
    this.ambientTemp,
    this.ambientHumidity,
    this.beanTemp,
    this.pressure,
    this.pourStages,
    this.beanRoastDate,
    this.beanRoastLevel,
    this.heatLevel,
    this.yieldGrams,
    this.preheatUpperChamber,
    this.beanUsages = const [],
    this.favoriteGroupIds = const <int>[],
    this.addIns = const [],
    this.methodLabel,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;

  /// 主豆，冗余字段（= [beanUsages] 里 position 最小的那支）。
  final int? beanId;

  final int? grinderId;
  final int? recipeId;
  final BrewMethod method;
  final double? grindSetting;
  final int? grindClicks;

  /// 写入时的磨豆机零点 / 每圈 click 快照（Grinder 之后改校准也不影响历史）。
  final double? grinderZeroPointSnapshot;
  final int? grinderClicksPerRevolutionSnapshot;

  /// 总粉量（拼配时是各支之和）。
  final double? doseGrams;

  final double? waterGrams;

  /// 粉水比中「1 : N」的 N。
  final double? ratio;

  final double? waterTemp;
  final int? totalTimeSeconds;
  final String? dripper;

  /// 评分 1–5。
  final int? rating;

  final List<String> flavorTags;
  final String? notes;
  final String? photoPath;
  final DateTime brewedAt;

  /// 「标记最佳参数」。
  final bool isBest;

  /// 收藏这套参数：记录页右滑可切换，方便以后复制出来照冲。
  ///
  /// 与 [isBest] 不同——最佳是「这杯最好喝」，收藏是「这套参数我要留着再用」。
  final bool isFavorite;

  // --- 专业字段（UI 折叠） ---
  final double? tds;
  final double? extractionYield;
  final int? waterPpm;
  final double? ambientTemp;
  final double? ambientHumidity;
  final double? beanTemp;
  final double? pressure;
  final List<PourStage>? pourStages;

  // --- 豆子的烘焙信息（随记录快照，豆子信息被改也不影响历史） ---
  final DateTime? beanRoastDate;
  final RoastLevel? beanRoastLevel;

  // --- 摩卡壶专属 ---
  final String? heatLevel;
  final double? yieldGrams;
  final bool? preheatUpperChamber;

  /// 这条记录用到的豆子（多支 = 拼配）。由 Repository 联表填充。
  final List<BeanUsage> beanUsages;

  /// 这条记录被放进了哪些收藏夹（v8 / T38）。
  ///
  /// **附着字段**（与 [beanUsages] 同风格）：由 Repository 联表填充；
  /// 成员关系**不走 `save()`**，走 `BrewLogRepository.setFavoriteGroups`。
  /// 空列表 = 收藏了但没分组 —— 不是「没收藏」，那看 [isFavorite]。
  final List<int> favoriteGroupIds;

  /// 这条记录加的辅料（牛奶、糖浆…）。可以没有。
  final List<BrewLogAddIn> addIns;

  /// 自定义冲煮方法的原文（如「拿铁」）。为空表示用内置的 [method]。
  ///
  /// 单独一列而不是塞进 [method]：`method` 存的是枚举 name，
  /// 认不出的值会被容忍转换器回退掉，直接写自定义名字会**丢方法**。
  final String? methodLabel;

  /// 方法显示名：自定义的用原文，否则用内置枚举的中文标签。
  ///
  /// 卡片、统计、导出都用它，保证三处一致。
  String get methodDisplay => methodLabel ?? method.label;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// 是否拼配（两支及以上）。
  bool get isBlend => beanUsages.length > 1;

  /// 豆子展示名：单支直接返回，多支用 ` + ` 连接。已删除的豆子用快照名。
  String? get beanLabel {
    if (beanUsages.isEmpty) return null;
    return beanUsages.map((u) => u.label).join(' + ');
  }

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
    'grinderZeroPointSnapshot': grinderZeroPointSnapshot,
    'grinderClicksPerRevolutionSnapshot': grinderClicksPerRevolutionSnapshot,
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
    'isFavorite': isFavorite,
    'tds': tds,
    'extractionYield': extractionYield,
    'waterPpm': waterPpm,
    'ambientTemp': ambientTemp,
    'ambientHumidity': ambientHumidity,
    'beanTemp': beanTemp,
    'pressure': pressure,
    'pourStages': pourStages?.map((e) => e.toJson()).toList(growable: false),
    'beanRoastDate': beanRoastDate?.toIso8601String(),
    'beanRoastLevel': beanRoastLevel?.name,
    'heatLevel': heatLevel,
    'yieldGrams': yieldGrams,
    'preheatUpperChamber': preheatUpperChamber,
    'beanUsages': beanUsages.map((e) => e.toJson()).toList(growable: false),
    'favoriteGroupIds': favoriteGroupIds,
    'addIns': addIns.map((e) => e.toJson()).toList(growable: false),
    'methodLabel': methodLabel,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BrewLog.fromJson(Map<String, Object?> json) => BrewLog(
    id: (json['id'] as num?)?.toInt(),
    beanId: (json['beanId'] as num?)?.toInt(),
    grinderId: (json['grinderId'] as num?)?.toInt(),
    recipeId: (json['recipeId'] as num?)?.toInt(),
    method:
        BrewMethod.fromName(json['method'] as String?) ?? BrewMethod.pourOver,
    grindSetting: (json['grindSetting'] as num?)?.toDouble(),
    grindClicks: (json['grindClicks'] as num?)?.toInt(),
    grinderZeroPointSnapshot: (json['grinderZeroPointSnapshot'] as num?)
        ?.toDouble(),
    grinderClicksPerRevolutionSnapshot:
        (json['grinderClicksPerRevolutionSnapshot'] as num?)?.toInt(),
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
    isFavorite: json['isFavorite'] as bool? ?? false,
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
    beanRoastDate: _date(json['beanRoastDate']),
    beanRoastLevel: RoastLevel.fromName(json['beanRoastLevel'] as String?),
    heatLevel: json['heatLevel'] as String?,
    yieldGrams: (json['yieldGrams'] as num?)?.toDouble(),
    preheatUpperChamber: json['preheatUpperChamber'] as bool?,
    beanUsages: (json['beanUsages'] as List<Object?>? ?? const [])
        .map((e) => BeanUsage.fromJson((e as Map).cast<String, Object?>()))
        .toList(growable: false),
    favoriteGroupIds: (json['favoriteGroupIds'] as List<Object?>? ?? const [])
        .map((e) => (e as num).toInt())
        .toList(growable: false),
    addIns: (json['addIns'] as List<Object?>? ?? const [])
        .map((e) => BrewLogAddIn.fromJson((e as Map).cast<String, Object?>()))
        .toList(growable: false),
    methodLabel: json['methodLabel'] as String?,
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
    double? grinderZeroPointSnapshot,
    int? grinderClicksPerRevolutionSnapshot,
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
    bool? isFavorite,
    double? tds,
    double? extractionYield,
    int? waterPpm,
    double? ambientTemp,
    double? ambientHumidity,
    double? beanTemp,
    double? pressure,
    List<PourStage>? pourStages,
    DateTime? beanRoastDate,
    RoastLevel? beanRoastLevel,
    String? heatLevel,
    double? yieldGrams,
    bool? preheatUpperChamber,
    List<BeanUsage>? beanUsages,
    List<int>? favoriteGroupIds,
    List<BrewLogAddIn>? addIns,
    String? methodLabel,
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
    bool clearBeanRoastDate = false,
    bool clearBeanRoastLevel = false,
    bool clearHeatLevel = false,
    bool clearYieldGrams = false,
    bool clearPreheatUpperChamber = false,
    bool clearMethodLabel = false,
  }) => BrewLog(
    id: id ?? this.id,
    beanId: clearBeanId ? null : (beanId ?? this.beanId),
    grinderId: clearGrinderId ? null : (grinderId ?? this.grinderId),
    recipeId: clearRecipeId ? null : (recipeId ?? this.recipeId),
    method: method ?? this.method,
    grindSetting: clearGrindSetting
        ? null
        : (grindSetting ?? this.grindSetting),
    grindClicks: clearGrindClicks ? null : (grindClicks ?? this.grindClicks),
    grinderZeroPointSnapshot:
        grinderZeroPointSnapshot ?? this.grinderZeroPointSnapshot,
    grinderClicksPerRevolutionSnapshot:
        grinderClicksPerRevolutionSnapshot ??
        this.grinderClicksPerRevolutionSnapshot,
    doseGrams: clearDoseGrams ? null : (doseGrams ?? this.doseGrams),
    waterGrams: clearWaterGrams ? null : (waterGrams ?? this.waterGrams),
    ratio: clearRatio ? null : (ratio ?? this.ratio),
    waterTemp: clearWaterTemp ? null : (waterTemp ?? this.waterTemp),
    totalTimeSeconds: clearTotalTimeSeconds
        ? null
        : (totalTimeSeconds ?? this.totalTimeSeconds),
    dripper: clearDripper ? null : (dripper ?? this.dripper),
    rating: clearRating ? null : (rating ?? this.rating),
    flavorTags: flavorTags ?? this.flavorTags,
    notes: clearNotes ? null : (notes ?? this.notes),
    photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
    brewedAt: brewedAt ?? this.brewedAt,
    isBest: isBest ?? this.isBest,
    isFavorite: isFavorite ?? this.isFavorite,
    tds: clearTds ? null : (tds ?? this.tds),
    extractionYield: clearExtractionYield
        ? null
        : (extractionYield ?? this.extractionYield),
    waterPpm: clearWaterPpm ? null : (waterPpm ?? this.waterPpm),
    ambientTemp: clearAmbientTemp ? null : (ambientTemp ?? this.ambientTemp),
    ambientHumidity: clearAmbientHumidity
        ? null
        : (ambientHumidity ?? this.ambientHumidity),
    beanTemp: clearBeanTemp ? null : (beanTemp ?? this.beanTemp),
    pressure: clearPressure ? null : (pressure ?? this.pressure),
    pourStages: clearPourStages ? null : (pourStages ?? this.pourStages),
    beanRoastDate: clearBeanRoastDate
        ? null
        : (beanRoastDate ?? this.beanRoastDate),
    beanRoastLevel: clearBeanRoastLevel
        ? null
        : (beanRoastLevel ?? this.beanRoastLevel),
    heatLevel: clearHeatLevel ? null : (heatLevel ?? this.heatLevel),
    yieldGrams: clearYieldGrams ? null : (yieldGrams ?? this.yieldGrams),
    preheatUpperChamber: clearPreheatUpperChamber
        ? null
        : (preheatUpperChamber ?? this.preheatUpperChamber),
    beanUsages: beanUsages ?? this.beanUsages,
    favoriteGroupIds: favoriteGroupIds ?? this.favoriteGroupIds,
    addIns: addIns ?? this.addIns,
    methodLabel: clearMethodLabel ? null : (methodLabel ?? this.methodLabel),
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
          other.grinderZeroPointSnapshot == grinderZeroPointSnapshot &&
          other.grinderClicksPerRevolutionSnapshot ==
              grinderClicksPerRevolutionSnapshot &&
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
          other.isFavorite == isFavorite &&
          other.tds == tds &&
          other.extractionYield == extractionYield &&
          other.waterPpm == waterPpm &&
          other.ambientTemp == ambientTemp &&
          other.ambientHumidity == ambientHumidity &&
          other.beanTemp == beanTemp &&
          other.pressure == pressure &&
          _listEquals(other.pourStages, pourStages) &&
          other.beanRoastDate == beanRoastDate &&
          other.beanRoastLevel == beanRoastLevel &&
          other.heatLevel == heatLevel &&
          other.yieldGrams == yieldGrams &&
          other.preheatUpperChamber == preheatUpperChamber &&
          _listEquals(other.beanUsages, beanUsages) &&
          _listEquals(other.favoriteGroupIds, favoriteGroupIds) &&
          _listEquals(other.addIns, addIns) &&
          other.methodLabel == methodLabel &&
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
    isFavorite,
    tds,
    extractionYield,
    waterPpm,
    ambientTemp,
    ambientHumidity,
    beanTemp,
    pressure,
    pourStages == null ? null : Object.hashAll(pourStages!),
    beanRoastDate,
    beanRoastLevel,
    heatLevel,
    yieldGrams,
    preheatUpperChamber,
    Object.hashAll(beanUsages),
    Object.hashAll(favoriteGroupIds),
    Object.hashAll(addIns),
    methodLabel,
    createdAt,
    updatedAt,
  ]);

  @override
  String toString() =>
      'BrewLog(id: $id, method: ${method.name}, beans: ${beanUsages.length}, '
      'dose: $doseGrams g)';
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
    method:
        BrewMethod.fromName(json['method'] as String?) ?? BrewMethod.pourOver,
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
  }) => Recipe(
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
  int get hashCode => Object.hash(
    id,
    name,
    method,
    doseGrams,
    waterGrams,
    ratio,
    waterTemp,
    totalTimeSeconds,
    pourStages == null ? null : Object.hashAll(pourStages!),
    grindSuggestion,
    notes,
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'Recipe(id: $id, name: $name)';
}

/// 一个自定义收藏夹（组）—— 把「收藏的记录」归类（v8 / T38）。
///
/// 与 [BrewLog.isFavorite] 的分工（设计稿 §2「关键决定 1」）：
/// `isFavorite` 仍然是「是否收藏」的**唯一**判据；本实体只回答
/// 「这条收藏还放进了哪些夹」。**不属于任何夹 ≠ 没收藏。**
class FavoriteGroup {
  const FavoriteGroup({
    this.id,
    required this.name,
    this.sortOrder = 0,
    required this.createdAt,
  });

  final int? id;

  /// 用户起的组名，如「早餐配方」。
  final String name;

  /// 展示顺序，越小越靠前。
  final int sortOrder;

  final DateTime createdAt;

  FavoriteGroup copyWith({
    int? id,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
  }) => FavoriteGroup(
    id: id ?? this.id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'sortOrder': sortOrder,
    'createdAt': createdAt.toIso8601String(),
  };

  factory FavoriteGroup.fromJson(Map<String, Object?> json) => FavoriteGroup(
    id: (json['id'] as num?)?.toInt(),
    name: (json['name'] as String?) ?? '',
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    // 时间坏掉时不抛，回落到纪元（与其它实体的宽容解码一致）。
    createdAt:
        _date(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteGroup &&
          other.id == id &&
          other.name == name &&
          other.sortOrder == sortOrder &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, sortOrder, createdAt);

  @override
  String toString() => 'FavoriteGroup(id: $id, name: $name)';
}

/// 克数的存储精度：0.1g。
///
/// 余量走的是反复加减（每冲一杯扣一次），浮点误差会累积成
/// `9.700000000000001` 这种值。**写入前统一按 0.1g 归一**，
/// 让库里存的就是规整值，而不是只在展示时四舍五入。
const int gramsDecimals = 1;

/// 把克数归一到 0.1g 精度。
///
/// 实现要点：**不能用 `(value / 0.1).round() * 0.1`**。
/// 因为 `97 * 0.1` 得到的是 `9.700000000000001` 而不是 `9.7`
/// （两个是不同的 double），这么写等于把误差又引回来了。
///
/// 正确做法是走十进制字符串：`toStringAsFixed(1)` 会输出 `"9.7"`，
/// 再 `double.parse` 得到的就是 `9.7` 这个 double 本身。
double roundGrams(double value) =>
    double.parse(value.toStringAsFixed(gramsDecimals));

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
