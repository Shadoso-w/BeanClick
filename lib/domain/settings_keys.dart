/// 设置项的 key 常量。
///
/// 与手册 §6.3 一一对应。读取时统一按字符串解析，
/// 各 key 的默认值见 [SettingsDefaults]。
library;

abstract final class SettingsKeys {
  static const String themeMode = 'themeMode';
  static const String autoDeductStock = 'autoDeductStock';
  static const String defaultMethod = 'defaultMethod';
  static const String unitWeight = 'unitWeight';
  static const String unitTemp = 'unitTemp';
  static const String exportFormat = 'exportFormat';
  static const String firstLaunchDone = 'firstLaunchDone';

  /// 全部 key，用于「首次启动写入默认值」。
  static const List<String> all = [
    themeMode,
    autoDeductStock,
    defaultMethod,
    unitWeight,
    unitTemp,
    exportFormat,
    firstLaunchDone,
  ];
}

/// 设置项默认值（手册 §6.3）。
abstract final class SettingsDefaults {
  /// 浅色 / 深色 / 跟随系统，对应 `ThemeMode.name`。
  static const String themeMode = 'system';

  static const String autoDeductStock = 'true';
  static const String defaultMethod = 'pourOver';
  static const String unitWeight = 'g';
  static const String unitTemp = '℃';
  static const String exportFormat = 'json';
  static const String firstLaunchDone = 'false';

  static const Map<String, String> byKey = {
    SettingsKeys.themeMode: themeMode,
    SettingsKeys.autoDeductStock: autoDeductStock,
    SettingsKeys.defaultMethod: defaultMethod,
    SettingsKeys.unitWeight: unitWeight,
    SettingsKeys.unitTemp: unitTemp,
    SettingsKeys.exportFormat: exportFormat,
    SettingsKeys.firstLaunchDone: firstLaunchDone,
  };
}
