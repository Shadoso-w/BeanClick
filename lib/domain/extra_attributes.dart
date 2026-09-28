/// 扩展属性：给豆子 / 磨豆机挂任意附加信息。
///
/// ## 什么时候用它
///
/// 属性**只记录、只展示**，不需要按它筛选/排序/统计时，用扩展属性。
/// 加一个只需往 [ExtraAttributeRegistry.bean] 或 `.grinder` 里加一条定义，
/// 表单会自动出现对应控件、详情页自动展示、导出自动带上——
/// **不用改表结构、不用迁移、不用改测试**。
///
/// 需要参与查询的属性（例如「按烘焙商筛选豆子」）**不要**放这里：
/// key-value 参与 `WHERE` / `ORDER BY` 会退化成全表扫描 + 逐行解析 JSON。
/// 那种属性应当晋升为一等列，步骤见 `docs/添加新属性指南.md`。
library;

/// 扩展属性挂在哪类对象上。
///
/// **新增一类可扩展对象只需在这里加一个枚举值**，再在
/// [ExtraAttributeRegistry.of] 里加对应分支——表结构、仓库、编辑器都不用改。
enum ExtraOwnerType {
  bean('bean', '咖啡豆'),
  grinder('grinder', '磨豆机'),
  brewLog('brewLog', '冲煮记录'),
  batch('batch', '豆子批次'),
  recipe('recipe', '配方');

  const ExtraOwnerType(this.storageKey, this.label);

  /// 存库用的稳定标识（**不要改**，改了会读不到已有数据）。
  final String storageKey;

  final String label;

  static ExtraOwnerType? fromStorage(String? value) {
    if (value == null) return null;
    for (final type in values) {
      if (type.storageKey == value) return type;
    }
    return null;
  }
}

/// 扩展属性的值类型。决定表单用什么控件、展示怎么格式化。
enum ExtraValueType {
  text('text', '文本'),
  number('number', '数字'),
  integer('integer', '整数'),
  boolean('boolean', '是 / 否'),
  date('date', '日期'),

  /// 字符串列表（例如「购买渠道」多选）。
  tags('tags', '标签');

  const ExtraValueType(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static ExtraValueType fromStorage(String? value) {
    if (value == null) return ExtraValueType.text;
    for (final type in values) {
      if (type.storageKey == value) return type;
    }
    return ExtraValueType.text;
  }

  /// 把输入框里的原始文本解析成该类型的值；无法解析时返回 null。
  Object? parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    switch (this) {
      case ExtraValueType.text:
        return trimmed;
      case ExtraValueType.number:
        return double.tryParse(trimmed);
      case ExtraValueType.integer:
        return int.tryParse(trimmed);
      case ExtraValueType.boolean:
        final lower = trimmed.toLowerCase();
        if (lower == 'true' || lower == '是' || lower == '1') return true;
        if (lower == 'false' || lower == '否' || lower == '0') return false;
        return null;
      case ExtraValueType.date:
        return DateTime.tryParse(trimmed)?.toIso8601String();
      case ExtraValueType.tags:
        return trimmed
            .split(RegExp(r'[、,，\s]+'))
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList(growable: false);
    }
  }

  /// 把值格式化成展示 / 编辑用的文本。
  String format(Object? value) {
    if (value == null) return '';
    switch (this) {
      case ExtraValueType.text:
        return value.toString();
      case ExtraValueType.number:
        if (value is num) {
          return value == value.roundToDouble()
              ? value.toInt().toString()
              : value.toString();
        }
        return value.toString();
      case ExtraValueType.integer:
        return value.toString();
      case ExtraValueType.boolean:
        return value == true ? '是' : '否';
      case ExtraValueType.date:
        return value.toString();
      case ExtraValueType.tags:
        if (value is List) return value.join('、');
        return value.toString();
    }
  }
}

/// 一条扩展属性的值（不含归属信息，便于直接挂在实体上）。
class ExtraAttribute {
  const ExtraAttribute({
    required this.key,
    required this.valueType,
    this.value,
    this.label,
    this.isBuiltin = false,
    this.sortOrder = 0,
  });

  /// 稳定标识。
  final String key;

  final ExtraValueType valueType;

  /// 值。类型由 [valueType] 决定，可能为 null（未填写）。
  final Object? value;

  /// 展示名；为空时 UI 用 [key]。
  final String? label;

  /// App 内置（不可删除）。
  final bool isBuiltin;

  final int sortOrder;

  /// 展示名。
  String get displayLabel => (label == null || label!.isEmpty) ? key : label!;

  /// 是否有值（空字符串、空列表都算没有）。
  bool get hasValue {
    final v = value;
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is List) return v.isNotEmpty;
    return true;
  }

  /// 展示文本。
  String get displayValue => valueType.format(value);

  ExtraAttribute copyWith({
    String? key,
    ExtraValueType? valueType,
    Object? value,
    String? label,
    bool? isBuiltin,
    int? sortOrder,
    bool clearValue = false,
    bool clearLabel = false,
  }) => ExtraAttribute(
    key: key ?? this.key,
    valueType: valueType ?? this.valueType,
    value: clearValue ? null : (value ?? this.value),
    label: clearLabel ? null : (label ?? this.label),
    isBuiltin: isBuiltin ?? this.isBuiltin,
    sortOrder: sortOrder ?? this.sortOrder,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtraAttribute &&
          other.key == key &&
          other.valueType == valueType &&
          other.label == label &&
          other.isBuiltin == isBuiltin &&
          other.sortOrder == sortOrder &&
          _valueEquals(other.value, value);

  @override
  int get hashCode =>
      Object.hash(key, valueType, label, isBuiltin, sortOrder, value?.hashCode);

  @override
  String toString() =>
      'ExtraAttribute($key: ${valueType.storageKey} = ${valueType.format(value)})';
}

bool _valueEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  return a == b;
}

/// 内置扩展属性的定义（相当于「这个属性存在」的声明）。
class ExtraAttributeDefinition {
  const ExtraAttributeDefinition({
    required this.key,
    required this.type,
    required this.label,
    this.hint,
    this.sortOrder = 0,
  });

  final String key;
  final ExtraValueType type;
  final String label;

  /// 表单里的提示文案。
  final String? hint;

  final int sortOrder;

  ExtraAttribute toAttribute({Object? value}) => ExtraAttribute(
    key: key,
    valueType: type,
    value: value,
    label: label,
    isBuiltin: true,
    sortOrder: sortOrder,
  );
}

/// 内置扩展属性注册表。
///
/// **要加一个内置扩展属性，就在下面的列表里加一行**——表单、详情页、
/// 导出都会自动带上，不需要动表结构与迁移。
///
/// 注意这是「内置」的那部分；数据库里还允许存在用户自建的 key
/// （`isBuiltin = false`），它们同样会被展示与导出。
abstract final class ExtraAttributeRegistry {
  /// 咖啡豆的扩展属性。
  ///
  /// 刻意保持精简：只有确实常见、且不需要筛选的属性才值得内置。
  /// 其余交给用户自建或晋升为一等列。
  static const List<ExtraAttributeDefinition> bean = <ExtraAttributeDefinition>[
    ExtraAttributeDefinition(
      key: 'roaster',
      type: ExtraValueType.text,
      label: '烘焙商',
      hint: '例如：M2M、啟程拓殖',
      sortOrder: 10,
    ),
    ExtraAttributeDefinition(
      key: 'altitude',
      type: ExtraValueType.integer,
      label: '海拔',
      hint: '单位米，例如 1950',
      sortOrder: 20,
    ),
    ExtraAttributeDefinition(
      key: 'variety',
      type: ExtraValueType.text,
      label: '品种',
      hint: '例如：原生种、瑰夏、SL28',
      sortOrder: 30,
    ),
    ExtraAttributeDefinition(
      key: 'purchaseChannel',
      type: ExtraValueType.text,
      label: '购买渠道',
      hint: '例如：淘宝、线下店',
      sortOrder: 40,
    ),
    ExtraAttributeDefinition(
      key: 'packageSize',
      type: ExtraValueType.number,
      label: '包装规格',
      hint: '单位克，例如 200',
      sortOrder: 50,
    ),
  ];

  /// 磨豆机的扩展属性。
  static const List<ExtraAttributeDefinition> grinder =
      <ExtraAttributeDefinition>[
        ExtraAttributeDefinition(
          key: 'purchasedAt',
          type: ExtraValueType.date,
          label: '购入日期',
          sortOrder: 10,
        ),
        ExtraAttributeDefinition(
          key: 'serialNumber',
          type: ExtraValueType.text,
          label: '序列号',
          sortOrder: 20,
        ),
        ExtraAttributeDefinition(
          key: 'warrantyUntil',
          type: ExtraValueType.date,
          label: '保修到期',
          sortOrder: 30,
        ),
      ];

  /// 冲煮记录的扩展属性。
  ///
  /// 这里放的是**实验性、只记录不筛选**的参数。
  /// 常用的专业字段（TDS、水质、环境）已经是一等列，不走这里。
  ///
  /// 判断标准见 `docs/添加新属性指南.md`：
  /// 会出现在 `WHERE`/`ORDER BY`/聚合里的属性，应当晋升为一等列。
  static const List<ExtraAttributeDefinition> brewLog =
      <ExtraAttributeDefinition>[
        ExtraAttributeDefinition(
          key: 'filterPaper',
          type: ExtraValueType.text,
          label: '滤纸品牌',
          hint: '例如：Hario 漂白、Kalita',
          sortOrder: 10,
        ),
        ExtraAttributeDefinition(
          key: 'stirCount',
          type: ExtraValueType.integer,
          label: '搅拌次数',
          sortOrder: 20,
        ),
        ExtraAttributeDefinition(
          key: 'agitationNote',
          type: ExtraValueType.text,
          label: '扰流方式',
          hint: '例如：画圈、切角',
          sortOrder: 30,
        ),
        ExtraAttributeDefinition(
          key: 'waterRecipe',
          type: ExtraValueType.text,
          label: '水质配方',
          hint: '例如：70ppm，加 0.2g 小苏打',
          sortOrder: 40,
        ),
        ExtraAttributeDefinition(
          key: 'cupScore',
          type: ExtraValueType.number,
          label: '杯测分',
          hint: '例如：86.5',
          sortOrder: 50,
        ),
      ];

  /// 批次的扩展属性（同一款豆子不同批次可能不同的附加信息）。
  static const List<ExtraAttributeDefinition> batch =
      <ExtraAttributeDefinition>[
        ExtraAttributeDefinition(
          key: 'purchaseChannel',
          type: ExtraValueType.text,
          label: '购买渠道',
          sortOrder: 10,
        ),
        ExtraAttributeDefinition(
          key: 'storageMethod',
          type: ExtraValueType.text,
          label: '保存方式',
          hint: '例如：单向排气阀袋、密封罐',
          sortOrder: 20,
        ),
        ExtraAttributeDefinition(
          key: 'openedAt',
          type: ExtraValueType.date,
          label: '开袋日期',
          sortOrder: 30,
        ),
      ];

  /// 配方的扩展属性。
  static const List<ExtraAttributeDefinition> recipe =
      <ExtraAttributeDefinition>[
        ExtraAttributeDefinition(
          key: 'source',
          type: ExtraValueType.text,
          label: '配方来源',
          hint: '例如：自创、某视频、豆商建议',
          sortOrder: 10,
        ),
        ExtraAttributeDefinition(
          key: 'forBean',
          type: ExtraValueType.text,
          label: '适用豆子',
          sortOrder: 20,
        ),
      ];

  /// 取某类对象的内置定义。
  ///
  /// **新增 [ExtraOwnerType] 时这里必须补上分支**，否则该类型不会有内置属性
  /// （`switch` 是穷尽的，漏了编译不过，这一点由编译器兜底）。
  static List<ExtraAttributeDefinition> of(ExtraOwnerType owner) =>
      switch (owner) {
        ExtraOwnerType.bean => bean,
        ExtraOwnerType.grinder => grinder,
        ExtraOwnerType.brewLog => brewLog,
        ExtraOwnerType.batch => batch,
        ExtraOwnerType.recipe => recipe,
      };

  /// 按 key 找定义。
  static ExtraAttributeDefinition? find(ExtraOwnerType owner, String key) {
    for (final definition in of(owner)) {
      if (definition.key == key) return definition;
    }
    return null;
  }
}
