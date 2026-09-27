/// 领域枚举定义。
///
/// 存储约定：以枚举的 `name` 字符串存进 SQLite（如 `pourOver`），
/// 因此**不要随意重命名已有枚举值**，否则会破坏已有数据。
/// 需要改名时必须在 Drift 迁移里做数据转换。
library;

/// 冲煮方法。
///
/// 手册 §7 只要求「手冲 / 摩卡壶」，其余为扩展位：
/// UI 默认只展示手冲与摩卡壶，但枚举留位可以避免将来改 schema。
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

  /// UI 中默认展示的方法（MVP 范围）。
  static const List<BrewMethod> primary = [pourOver, mokaPot];

  static BrewMethod? fromName(String? name) {
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

  static GrindScaleUnit fromName(String? name) {
    if (name == null) return click;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return click;
  }
}
