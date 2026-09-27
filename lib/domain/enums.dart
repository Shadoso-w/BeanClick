/// 领域枚举定义。
///
/// ## 存储约定
///
/// 以枚举的 `name` 字符串存进 SQLite（如 `pourOver`），
/// 因此**不要随意重命名已有枚举值**，否则会破坏已有数据。
/// 需要改名时必须在 Drift 迁移里做数据转换。
///
/// ## 扩展约定（重要）
///
/// 每个枚举都区分**存储全集**（`values`，含预留值）与**表单可选子集**
/// （`selectable`）。这样：
///
/// - 想开放一个预留值 → 把它移进 `selectable`，**不动表结构、不迁移**
/// - 旧数据里已存在的未知值 → `fromName` 返回 null，由调用方回退，
///   不会抛异常
///
/// 因此「加一种冲煮方法 / 处理法 / 烘焙度」始终是**改一行**的事。
library;

/// 冲煮方法。
///
/// 手册 §7 只要求「手冲 / 摩卡壶」，其余为扩展位。
enum BrewMethod {
  pourOver('手冲'),
  mokaPot('摩卡壶'),
  frenchPress('法压壶'),
  aeropress('爱乐压'),
  espresso('意式浓缩'),
  other('其他');

  const BrewMethod(this.label);

  /// 中文显示名。
  final String label;

  /// 表单里可供选择的全部方法。
  static const List<BrewMethod> selectable = [
    pourOver,
    mokaPot,
    frenchPress,
    aeropress,
    espresso,
    other,
  ];

  /// MVP 的主力方法（界面上优先展示）。
  static const List<BrewMethod> primary = [pourOver, mokaPot];

  static BrewMethod? fromName(String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// 辅料单位（牛奶、糖浆这类「加了什么」的计量）。
///
/// 与冲煮参数无关，所以不并进其他枚举；存枚举 name、显示中文标签。
enum AddInUnit {
  ml('ml'),
  gram('g'),
  pump('泵'),
  serving('份');

  const AddInUnit(this.label);

  /// 显示名。
  final String label;

  static const List<AddInUnit> selectable = [ml, gram, pump, serving];

  static AddInUnit? fromName(String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// 烘焙度。
enum RoastLevel {
  light('浅烘'),
  mediumLight('中浅烘'),
  medium('中烘'),
  mediumDark('中深烘'),
  dark('深烘');

  const RoastLevel(this.label);

  final String label;

  /// 表单可选子集。
  static const List<RoastLevel> selectable = values;

  static RoastLevel? fromName(String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// 处理法。
enum ProcessMethod {
  washed('水洗'),
  natural('日晒'),
  honey('蜜处理'),
  anaerobic('厌氧'),
  wetHulled('湿刨'),
  other('其他');

  const ProcessMethod(this.label);

  final String label;

  /// 表单可选子集。
  static const List<ProcessMethod> selectable = values;

  static ProcessMethod? fromName(String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}

/// 磨豆机刻度单位。
enum GrindScaleUnit {
  /// C40 这类「click」标度。
  click('click'),

  /// 分段式标度（如 1 圈 4 段）。
  step('段'),

  /// 1–10 之类的数字标度。
  number('刻度'),

  /// 微米。
  micron('μm');

  const GrindScaleUnit(this.label);

  final String label;

  /// 表单可选子集。
  static const List<GrindScaleUnit> selectable = values;

  static GrindScaleUnit fromName(String? name) {
    if (name == null) return click;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return click;
  }
}
