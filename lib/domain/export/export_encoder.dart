/// 导出功能：JSON 完整备份与 CSV 表格。
///
/// 这里**只有纯 Dart 逻辑**（编码 / 解码），不碰文件系统与平台通道，
/// 因此可以被单元测试完整覆盖。写文件与分享在 `export_service.dart`。
///
/// 两个格式的定位（手册 §8「导出」）：
/// - **JSON**：完整备份，可用于恢复与迁移，是默认选项。
/// - **CSV**：表格分析，交给 Excel / 表格软件，多张表拼在一个文件里。
library;

import 'dart:convert';

import 'package:beanclick/domain/entities.dart';

/// 导出文件的类型。
enum ExportFormat {
  json('JSON 完整备份', '适合恢复与迁移，保留全部字段', 'json'),
  csv('CSV 表格', '适合用 Excel 分析，按表分段', 'csv');

  const ExportFormat(this.label, this.description, this.extension);

  final String label;
  final String description;
  final String extension;
}

/// 导出用的数据快照。
class ExportDocument {
  const ExportDocument({
    required this.exportedAt,
    required this.beans,
    required this.grinders,
    required this.brewLogs,
    required this.recipes,
    this.appVersion = '0.1.0',
  });

  final DateTime exportedAt;
  final String appVersion;
  final List<CoffeeBean> beans;
  final List<Grinder> grinders;
  final List<BrewLog> brewLogs;
  final List<Recipe> recipes;

  /// 当前 JSON 结构版本。将来结构变了要递增，导入时据此判断兼容性。
  static const int schemaVersion = 1;
}

/// 一次导出的产物：文件名 + 内容。
class ExportResult {
  const ExportResult({
    required this.fileName,
    required this.content,
    required this.format,
  });

  /// 建议的文件名（不含目录）。
  final String fileName;

  /// 文本内容。CSV 已带 UTF-8 BOM（见 [ExportEncoder.encodeCsv]）。
  final String content;

  final ExportFormat format;

  /// 写入磁盘时用的字节（CSV 的 BOM 在 [content] 里，这里统一按 UTF-8 编码）。
  List<int> get bytes => utf8.encode(content);

  /// 便于测试与调试：内容行数。
  int get lineCount => content.split('\n').length;
}

/// 编码器。
abstract final class ExportEncoder {
  /// UTF-8 BOM。Excel 打开无 BOM 的 UTF-8 CSV 时中文会乱码，必须加。
  static const String utf8Bom = '\uFEFF';

  /// 组装一次导出。
  static ExportResult build(ExportDocument document, ExportFormat format) {
    final String stamp = fileTimestamp(document.exportedAt);
    return switch (format) {
      ExportFormat.json => ExportResult(
          fileName: 'beanclick-backup-$stamp.json',
          content: encodeJson(document),
          format: format,
        ),
      ExportFormat.csv => ExportResult(
          fileName: 'beanclick-export-$stamp.csv',
          content: encodeCsv(document),
          format: format,
        ),
    };
  }

  /// 文件名用的时间戳：`20260101-0830`（避免冒号，Windows 与安卓都不接受）。
  static String fileTimestamp(DateTime value) {
    final DateTime local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}${two(local.month)}${two(local.day)}'
        '-${two(local.hour)}${two(local.minute)}';
  }

  // -------------------------------------------------------------------------
  // JSON
  // -------------------------------------------------------------------------

  static String encodeJson(ExportDocument document) {
    final Map<String, Object?> payload = <String, Object?>{
      'schemaVersion': ExportDocument.schemaVersion,
      'appVersion': document.appVersion,
      'exportedAt': document.exportedAt.toIso8601String(),
      'counts': <String, int>{
        'beans': document.beans.length,
        'grinders': document.grinders.length,
        'brewLogs': document.brewLogs.length,
        'recipes': document.recipes.length,
      },
      'coffeeBeans': document.beans
          .map((CoffeeBean bean) => bean.toJson())
          .toList(growable: false),
      'grinders': document.grinders
          .map((Grinder grinder) => grinder.toJson())
          .toList(growable: false),
      'brewLogs': document.brewLogs
          .map((BrewLog log) => log.toJson())
          .toList(growable: false),
      'recipes': document.recipes
          .map((Recipe recipe) => recipe.toJson())
          .toList(growable: false),
    };
    // 缩进 2 空格：备份文件给人看也可读。
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// 解析 JSON 备份。
  ///
  /// 主要用途是**验证备份真的能读回来**（单元测试会做往返断言），
  /// 也让将来的「导入」有现成的落点。
  static ExportDocument decodeJson(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('备份文件结构不对：顶层不是对象');
    }
    final Map<String, Object?> map = decoded.cast<String, Object?>();

    final Object? version = map['schemaVersion'];
    if (version is! int) {
      throw const FormatException('备份文件缺少 schemaVersion');
    }
    if (version > ExportDocument.schemaVersion) {
      throw FormatException('备份来自更新的版本（schemaVersion=$version），请升级 App 后再导入');
    }

    return ExportDocument(
      exportedAt: DateTime.tryParse(map['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      appVersion: map['appVersion'] as String? ?? 'unknown',
      beans: _decodeList(map['coffeeBeans'], CoffeeBean.fromJson),
      grinders: _decodeList(map['grinders'], Grinder.fromJson),
      brewLogs: _decodeList(map['brewLogs'], BrewLog.fromJson),
      recipes: _decodeList(map['recipes'], Recipe.fromJson),
    );
  }

  static List<T> _decodeList<T>(
    Object? raw,
    T Function(Map<String, Object?>) fromJson,
  ) {
    if (raw is! List) return const <Never>[];
    return raw
        .map((Object? item) => fromJson((item as Map).cast<String, Object?>()))
        .toList(growable: false);
  }

  // -------------------------------------------------------------------------
  // CSV
  // -------------------------------------------------------------------------

  /// 生成 CSV。
  ///
  /// 4 张表依次拼接，每张表前有一行标题（如 `# 咖啡豆`）方便人读；
  /// 各表之间空一行。表头用中文，直接能在 Excel 里看懂。
  static String encodeCsv(ExportDocument document) {
    final Map<int?, CoffeeBean> beansById = <int?, CoffeeBean>{
      for (final CoffeeBean bean in document.beans) bean.id: bean,
    };
    final Map<int?, Grinder> grindersById = <int?, Grinder>{
      for (final Grinder grinder in document.grinders) grinder.id: grinder,
    };

    final StringBuffer buffer = StringBuffer(utf8Bom);

    void section(String title, List<List<String>> rows) {
      buffer.writeln('# $title');
      for (final List<String> row in rows) {
        buffer.writeln(row.map(csvCell).join(','));
      }
      buffer.writeln();
    }

    // --- 咖啡豆 ---
    section('# 导出于 ${document.exportedAt.toIso8601String()}', <List<String>>[]);
    section('咖啡豆', <List<String>>[
      <String>[
        'id', '名称', '产地', '庄园', '处理法', '烘焙度', '烘焙日期',
        '风味标签', '剩余克数', '购入总重', '价格', '备注',
      ],
      for (final CoffeeBean bean in document.beans)
        <String>[
          '${bean.id ?? ''}',
          bean.name,
          bean.origin ?? '',
          bean.farm ?? '',
          bean.process?.label ?? '',
          bean.roastLevel?.label ?? '',
          bean.roastDate == null ? '' : dateOnly(bean.roastDate!),
          bean.flavorTags.join('、'),
          number(bean.remainingGrams),
          number(bean.initialGrams),
          number(bean.price),
          bean.notes ?? '',
        ],
    ]);

    // --- 磨豆机 ---
    section('磨豆机', <List<String>>[
      <String>[
        'id', '品牌', '型号', '刀盘', '刻度单位', '零点',
        '每圈click', '校准说明', '备注',
      ],
      for (final Grinder grinder in document.grinders)
        <String>[
          '${grinder.id ?? ''}',
          grinder.brand,
          grinder.model,
          grinder.burrType ?? '',
          grinder.scaleUnit.label,
          number(grinder.zeroPoint),
          grinder.clicksPerRevolution?.toString() ?? '',
          grinder.calibrationNote ?? '',
          grinder.notes ?? '',
        ],
    ]);

    // --- 冲煮记录 ---
    section('冲煮记录', <List<String>>[
      <String>[
        'id', '冲煮时间', '方法', '豆子', '磨豆机', '研磨刻度', 'click',
        '粉量g', '水量g', '粉水比', '水温℃', '总时间秒', '滤杯',
        '评分', '风味', '最佳', 'TDS%', '萃取率%', '水质ppm',
        '环境温度℃', '环境湿度%', '豆温℃', '压力bar',
        '摩卡壶火力', '出液量g', '上壶预热', '分段注水', '备注',
      ],
      for (final BrewLog log in document.brewLogs)
        <String>[
          '${log.id ?? ''}',
          log.brewedAt.toLocal().toIso8601String(),
          log.method.label,
          beansById[log.beanId]?.name ?? '',
          _grinderName(grindersById[log.grinderId]),
          number(log.grindSetting),
          log.grindClicks?.toString() ?? '',
          number(log.doseGrams),
          number(log.waterGrams),
          log.effectiveRatio == null
              ? ''
              : '1:${number(log.effectiveRatio)}',
          number(log.waterTemp),
          log.totalTimeSeconds?.toString() ?? '',
          log.dripper ?? '',
          log.rating?.toString() ?? '',
          log.flavorTags.join('、'),
          log.isBest ? '是' : '',
          number(log.tds),
          number(log.extractionYield),
          log.waterPpm?.toString() ?? '',
          number(log.ambientTemp),
          number(log.ambientHumidity),
          number(log.beanTemp),
          number(log.pressure),
          log.heatLevel ?? '',
          number(log.yieldGrams),
          log.preheatUpperChamber == null
              ? ''
              : (log.preheatUpperChamber! ? '是' : '否'),
          _pourStages(log.pourStages),
          log.notes ?? '',
        ],
    ]);

    // --- 配方 ---
    section('配方', <List<String>>[
      <String>[
        'id', '名称', '方法', '粉量g', '水量g', '粉水比', '水温℃',
        '总时间秒', '研磨建议', '备注',
      ],
      for (final Recipe recipe in document.recipes)
        <String>[
          '${recipe.id ?? ''}',
          recipe.name,
          recipe.method.label,
          number(recipe.doseGrams),
          number(recipe.waterGrams),
          number(recipe.ratio),
          number(recipe.waterTemp),
          recipe.totalTimeSeconds?.toString() ?? '',
          recipe.grindSuggestion ?? '',
          recipe.notes ?? '',
        ],
    ]);

    return buffer.toString();
  }

  /// 单个 CSV 单元格：按 RFC 4180 转义，并防止表格软件把内容当公式执行。
  static String csvCell(String value) {
    String safe = value;
    // 以 = + - @ 开头的内容在 Excel / WPS 里会被当公式（CSV 注入）。
    // 备注与豆名都是用户自由输入，这里统一加一个单引号前缀破掉公式语义。
    if (safe.isNotEmpty && '=+-@'.contains(safe[0])) {
      safe = "'$safe";
    }
    if (safe.contains(',') || safe.contains('"') || safe.contains('\n') || safe.contains('\r')) {
      return '"${safe.replaceAll('"', '""')}"';
    }
    return safe;
  }

  static String _grinderName(Grinder? grinder) {
    if (grinder == null) return '';
    return '${grinder.brand} ${grinder.model}';
  }

  static String _pourStages(List<PourStage>? stages) {
    if (stages == null || stages.isEmpty) return '';
    return stages
        .map((PourStage stage) =>
            '${stage.order}@${stage.atSecond}s:${number(stage.waterGrams)}g'
            '${stage.note == null ? '' : '(${stage.note})'}')
        .join(' | ');
  }
}

/// `yyyy-MM-dd`。
String dateOnly(DateTime value) {
  final DateTime local = value.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}

/// 数字转文本：整数不带小数点，空值给空串。
String number(double? value) {
  if (value == null) return '';
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
