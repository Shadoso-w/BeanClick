/// 导出的文件写入与分享。
///
/// 编码逻辑在 `export_encoder.dart`（纯 Dart，可单测）；
/// 这里负责组装数据、落盘、调用系统分享——都是平台相关操作。
library;

import 'dart:io';

import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/mappers.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/export/export_encoder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 导出流程的结果。
class ExportOutcome {
  const ExportOutcome({
    required this.fileName,
    required this.path,
    required this.format,
    required this.shared,
    this.shareError,
  });

  final String fileName;

  /// 落盘的绝对路径。
  final String path;

  final ExportFormat format;

  /// 系统分享面板是否成功唤起。
  final bool shared;

  /// 分享失败时的原因（文件已经写成功，只是没能唤起分享）。
  final String? shareError;
}

/// 导出能力的抽象。
///
/// UI 只依赖这个接口，测试可以注入一个不落盘的假实现——
/// `testWidgets` 跑在 fake-async 里，真实文件 I/O 不会完成，
/// 所以 widget 测试必须替换掉写文件的部分。
abstract interface class Exporter {
  /// 读取数据并编码（不落盘）。
  Future<ExportResult> build(ExportFormat format);

  /// 导出到文件并唤起系统分享。
  Future<ExportOutcome> exportAndShare(ExportFormat format);
}

/// 导出服务。
class ExportService implements Exporter {
  ExportService({
    required Future<ExportDocument> Function() loadDocument,
    Future<Directory> Function()? directoryResolver,
    Future<void> Function(String path, String fileName)? sharer,
  })  : _resolveDirectory = directoryResolver ?? _defaultExportDirectory,
        _share = sharer,
        // ignore: prefer_initializing_formals
        _loadDocument = loadDocument;

  final Future<ExportDocument> Function() _loadDocument;
  final Future<Directory> Function() _resolveDirectory;

  /// 可注入的分享实现；为 null 时走 `share_plus`。
  final Future<void> Function(String path, String fileName)? _share;

  /// 读取全部数据并编码。
  @override
  Future<ExportResult> build(ExportFormat format) async {
    final ExportDocument document = await _loadDocument();
    return ExportEncoder.build(document, format);
  }

  /// 导出到文件并唤起系统分享。
  ///
  /// 文件落在应用文档目录（**不是**临时目录）：即使分享面板被取消，
  /// 用户仍然能在文件管理器里找到这份备份。
  @override
  Future<ExportOutcome> exportAndShare(ExportFormat format) async {
    final ExportResult result = await build(format);
    final Directory directory = await _resolveDirectory();
    final File file = File(p.join(directory.path, result.fileName));
    await file.writeAsBytes(result.bytes, flush: true);

    String? shareError;
    bool shared = false;
    try {
      await (_share ?? _defaultShare)(file.path, result.fileName);
      shared = true;
    } catch (error) {
      shareError = '$error';
    }

    return ExportOutcome(
      fileName: result.fileName,
      path: file.path,
      format: format,
      shared: shared,
      shareError: shareError,
    );
  }

  static Future<Directory> _defaultExportDirectory() =>
      getApplicationDocumentsDirectory();

  static Future<void> _defaultShare(String path, String fileName) async {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(path, mimeType: _mimeTypeFor(fileName))],
        fileNameOverrides: <String>[fileName],
        subject: '豆刻 BeanClick 导出',
      ),
    );
  }

  static String _mimeTypeFor(String fileName) =>
      fileName.endsWith('.csv') ? 'text/csv' : 'application/json';
}

/// 从数据库读取一份完整快照。
Future<ExportDocument> loadExportDocument(AppDatabase db) async {
  final beans = await db.select(db.coffeeBeans).get();
  final grinders = await db.select(db.grinders).get();
  final brewLogs = await db.select(db.brewLogs).get();
  final recipes = await db.select(db.recipes).get();

  return ExportDocument(
    exportedAt: DateTime.now(),
    beans: beans.map((row) => row.toEntity()).toList(growable: false),
    grinders: grinders.map((row) => row.toEntity()).toList(growable: false),
    brewLogs: brewLogs.map((row) => row.toEntity()).toList(growable: false),
    recipes: recipes.map((row) => row.toEntity()).toList(growable: false),
  );
}

/// 导出服务 provider。
final exportServiceProvider = Provider<Exporter>(
  (ref) => ExportService(
    loadDocument: () => loadExportDocument(ref.watch(databaseProvider)),
  ),
);
