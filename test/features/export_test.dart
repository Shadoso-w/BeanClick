import 'package:beanclick/app.dart';
import 'package:beanclick/data/export_service.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/export/export_encoder.dart';
import 'package:beanclick/domain/settings_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

/// 导出功能的 widget 测试。
///
/// **注意测试策略**：`testWidgets` 跑在 fake-async 环境里，真实的文件 I/O
/// 不会真正完成（`await file.writeAsBytes` 之后回调不来），所以这里**不测落盘**，
/// 而是注入一个「记录型」导出服务，验证 UI 的接线：
/// 弹窗默认值、用户选择、传给服务的格式、以及选择是否被记住。
///
/// 真实的文件写入、BOM、JSON 可读回，由 `test/domain/export_encoder_test.dart`
/// 里的普通测试覆盖（那些不带 fake async，I/O 正常完成）。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();
  late _RecordingExportService service;

  setUp(() {
    service = _RecordingExportService();
    harness.useOverrides(
      () => [exportServiceProvider.overrideWithValue(service)],
    );
  });

  /// 进入设置页。三栏 dock 之后「我的」不再占栏位，改走右上角入口。
  Future<void> gotoSettings(WidgetTester tester) async {
    await tester.pumpWidget(harness.app(const BeanClickApp()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
  }

  Future<void> openExportDialog(WidgetTester tester) async {
    final Finder tile = find.text('导出数据');
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(tile);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  Future<void> tapDialogText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  /// 对话框里当前选中的格式。
  ExportFormat selectedFormat(WidgetTester tester) {
    final RadioGroup<ExportFormat> group = tester
        .widget<RadioGroup<ExportFormat>>(
          find.byType(RadioGroup<ExportFormat>),
        );
    return group.groupValue!;
  }

  /// 等待导出任务把结果抛出来（fake-async 下 I/O 由微任务驱动）。
  Future<void> settleExport(WidgetTester tester) async {
    for (int i = 0; i < 12 && service.calls.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('导出弹窗默认选中 JSON（手册 §17 决策 8）', (tester) async {
    await gotoSettings(tester);
    await openExportDialog(tester);

    expect(find.text('JSON 完整备份'), findsOneWidget);
    expect(find.text('CSV 表格'), findsOneWidget);
    expect(selectedFormat(tester), ExportFormat.json);

    await harness.finish(tester);
  });

  testWidgets('默认导出 JSON，且格式被传给了导出服务', (tester) async {
    await gotoSettings(tester);
    await openExportDialog(tester);
    await tapDialogText(tester, '导出');
    await settleExport(tester);

    expect(service.calls, hasLength(1));
    expect(service.calls.single, ExportFormat.json);

    await harness.finish(tester);
  });

  testWidgets('选择 CSV 后导出，传入的是 CSV', (tester) async {
    await gotoSettings(tester);
    await openExportDialog(tester);
    await tapDialogText(tester, 'CSV 表格');
    expect(selectedFormat(tester), ExportFormat.csv);

    await tapDialogText(tester, '导出');
    await settleExport(tester);

    expect(service.calls.single, ExportFormat.csv);

    await harness.finish(tester);
  });

  testWidgets('选择会被记住，下次默认选中上次的格式', (tester) async {
    await gotoSettings(tester);

    await openExportDialog(tester);
    await tapDialogText(tester, 'CSV 表格');
    await tapDialogText(tester, '导出');
    await settleExport(tester);

    expect(
      await harness.container
          .read(settingsRepositoryProvider)
          .get(SettingsKeys.exportFormat),
      'csv',
      reason: '默认格式应落库，下次默认选中',
    );

    // 再打开一次，应默认 CSV。
    await openExportDialog(tester);
    expect(selectedFormat(tester), ExportFormat.csv);

    await harness.finish(tester);
  });

  testWidgets('取消时不调用导出服务', (tester) async {
    await gotoSettings(tester);
    await openExportDialog(tester);
    await tapDialogText(tester, '取消');

    expect(service.calls, isEmpty);

    await harness.finish(tester);
  });

  testWidgets('导出后提示已导出', (tester) async {
    await gotoSettings(tester);
    await openExportDialog(tester);
    await tapDialogText(tester, '导出');
    await settleExport(tester);
    // 让 SnackBar 有机会显示出来。
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('已导出'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('导出失败时提示失败原因', (tester) async {
    service.failWith = StateError('磁盘已满');

    await gotoSettings(tester);
    await openExportDialog(tester);
    await tapDialogText(tester, '导出');
    await settleExport(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('导出失败'), findsOneWidget);
    expect(find.textContaining('磁盘已满'), findsOneWidget);

    await harness.finish(tester);
  });
}

/// 记录被要求导出的格式，不真的落盘。
class _RecordingExportService implements Exporter {
  final List<ExportFormat> calls = <ExportFormat>[];

  /// 非 null 时让导出抛错，用于测失败分支。
  Object? failWith;

  @override
  Future<ExportResult> build(ExportFormat format) async =>
      ExportEncoder.build(_emptyDocument(), format);

  @override
  Future<ExportOutcome> exportAndShare(ExportFormat format) async {
    calls.add(format);
    final Object? failure = failWith;
    if (failure != null) throw failure;
    return ExportOutcome(
      fileName: 'beanclick-backup-20260307-0905.${format.extension}',
      path: '/tmp/beanclick-backup-20260307-0905.${format.extension}',
      format: format,
      shared: true,
    );
  }

  static ExportDocument _emptyDocument() => ExportDocument(
    exportedAt: DateTime(2026, 3, 7, 9, 5),
    beans: const <CoffeeBean>[],
    grinders: const <Grinder>[],
    brewLogs: const <BrewLog>[],
    recipes: const <Recipe>[],
  );
}
