import 'dart:convert';
import 'dart:io';

import 'package:beanclick/data/export_service.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/domain/export/export_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  group('ExportEncoder JSON', () {
    test('完整备份包含全部表与计数', () {
      final ExportDocument document = _sampleDocument();

      final Map<String, Object?> payload =
          jsonDecode(ExportEncoder.encodeJson(document)) as Map<String, Object?>;

      expect(payload['schemaVersion'], ExportDocument.schemaVersion);
      expect(payload['appVersion'], '0.1.0');
      expect(payload['exportedAt'], isA<String>());
      expect(payload['counts'], <String, int>{
        'beans': 1,
        'grinders': 1,
        'brewLogs': 1,
        'recipes': 1,
      });
      expect((payload['coffeeBeans'] as List<Object?>), hasLength(1));
      expect((payload['grinders'] as List<Object?>), hasLength(1));
      expect((payload['brewLogs'] as List<Object?>), hasLength(1));
      expect((payload['recipes'] as List<Object?>), hasLength(1));
    });

    test('往返后数据完全一致（备份真的能读回来）', () {
      final ExportDocument source = _sampleDocument();

      final ExportDocument restored =
          ExportEncoder.decodeJson(ExportEncoder.encodeJson(source));

      expect(restored.beans, source.beans);
      expect(restored.grinders, source.grinders);
      expect(restored.brewLogs, source.brewLogs);
      expect(restored.recipes, source.recipes);
    });

    test('分段注水与专业字段在往返后保留', () {
      final ExportDocument source = _sampleDocument();

      final ExportDocument restored =
          ExportEncoder.decodeJson(ExportEncoder.encodeJson(source));

      final BrewLog log = restored.brewLogs.single;
      expect(log.tds, 1.35);
      expect(log.extractionYield, 20.1);
      expect(log.pourStages, hasLength(2));
      expect(log.pourStages!.first.note, '闷蒸');
      expect(log.isBest, isTrue);
    });

    test('缺少 schemaVersion 抛 FormatException', () {
      expect(
        () => ExportEncoder.decodeJson('{"coffeeBeans": []}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('来自更新版本的备份会被拒绝', () {
      final String json = jsonEncode(<String, Object?>{
        'schemaVersion': ExportDocument.schemaVersion + 1,
      });

      expect(
        () => ExportEncoder.decodeJson(json),
        throwsA(
          isA<FormatException>().having(
            (FormatException e) => e.message,
            'message',
            contains('更新的版本'),
          ),
        ),
      );
    });

    test('表为空时也能正常编解码', () {
      final ExportDocument empty = ExportDocument(
        exportedAt: DateTime(2026, 1, 1),
        beans: const [],
        grinders: const [],
        brewLogs: const [],
        recipes: const [],
      );

      final ExportDocument restored =
          ExportEncoder.decodeJson(ExportEncoder.encodeJson(empty));

      expect(restored.beans, isEmpty);
      expect(restored.brewLogs, isEmpty);
    });
  });

  group('ExportEncoder CSV', () {
    test('带 UTF-8 BOM（Excel 中文不乱码的前提）', () {
      final String csv = ExportEncoder.encodeCsv(_sampleDocument());

      expect(csv.startsWith(ExportEncoder.utf8Bom), isTrue);
      // BOM 的三字节序列必须是 EF BB BF。
      expect(utf8.encode(csv).take(3), <int>[0xEF, 0xBB, 0xBF]);
    });

    test('包含四张表与中文表头', () {
      final String csv = ExportEncoder.encodeCsv(_sampleDocument());

      expect(csv, contains('# 咖啡豆'));
      expect(csv, contains('# 磨豆机'));
      expect(csv, contains('# 冲煮记录'));
      expect(csv, contains('# 配方'));
      expect(csv, contains('名称,产地,庄园,处理法,烘焙度'));
      expect(csv, contains('粉量g,水量g,粉水比'));
    });

    test('冲煮记录带出豆子名与磨豆机名（人看得懂）', () {
      final String csv = ExportEncoder.encodeCsv(_sampleDocument());

      expect(csv, contains('花魁'));
      expect(csv, contains('Comandante C40'));
    });

    test('粉水比以 1:N 形式给出', () {
      final String csv = ExportEncoder.encodeCsv(_sampleDocument());

      // 15g 粉 / 240g 水 = 1:16
      expect(csv, contains('1:16'));
    });

    test('分段注水压成可读文本', () {
      final String csv = ExportEncoder.encodeCsv(_sampleDocument());

      expect(csv, contains('1@0s:30g(闷蒸)'));
      expect(csv, contains('2@30s:210g'));
    });

    group('csvCell 转义', () {
      test('含逗号的值加引号', () {
        expect(ExportEncoder.csvCell('耶加,雪菲'), '"耶加,雪菲"');
      });

      test('含引号的值双写引号并加引号', () {
        expect(ExportEncoder.csvCell('他说"好喝"'), '"他说""好喝"""');
      });

      test('含换行的值加引号', () {
        expect(ExportEncoder.csvCell('第一行\n第二行'), '"第一行\n第二行"');
      });

      test('普通值不加引号', () {
        expect(ExportEncoder.csvCell('耶加雪菲'), '耶加雪菲');
      });

      test('以 = 开头的值被破掉公式语义（CSV 注入防护）', () {
        final String cell = ExportEncoder.csvCell('=1+1');
        expect(cell.startsWith('='), isFalse);
        expect(cell, "'=1+1");
      });

      test('以 + - @ 开头的值同样处理', () {
        for (final String raw in <String>['+1', '-1', '@x']) {
          expect(ExportEncoder.csvCell(raw).startsWith("'"), isTrue);
        }
      });

      test('空值原样返回', () {
        expect(ExportEncoder.csvCell(''), '');
      });
    });

    test('用户输入里的逗号不会破坏列数', () {
      final ExportDocument document = _sampleDocument(
        note: '酸甜平衡,尾段微苦',
      );

      final String csv = ExportEncoder.encodeCsv(document);
      final List<String> logLines = csv
          .split('\n')
          .where((String line) => line.startsWith('1,2026') || line.contains('酸甜平衡'))
          .toList();

      expect(logLines, isNotEmpty);
      expect(logLines.first, contains('"酸甜平衡,尾段微苦"'));
    });
  });

  group('文件名与格式', () {
    test('JSON 文件名带时间戳且扩展名正确', () {
      final ExportResult result = ExportEncoder.build(
        _sampleDocument(),
        ExportFormat.json,
      );

      expect(result.fileName, startsWith('beanclick-backup-'));
      expect(result.fileName, endsWith('.json'));
      // 不能出现 Windows / 安卓都不接受的冒号。
      expect(result.fileName, isNot(contains(':')));
    });

    test('CSV 文件名带时间戳且扩展名正确', () {
      final ExportResult result = ExportEncoder.build(
        _sampleDocument(),
        ExportFormat.csv,
      );

      expect(result.fileName, startsWith('beanclick-export-'));
      expect(result.fileName, endsWith('.csv'));
    });

    test('时间戳格式为 yyyyMMdd-HHmm', () {
      expect(
        ExportEncoder.fileTimestamp(DateTime(2026, 3, 7, 9, 5)),
        '20260307-0905',
      );
    });

    test('bytes 就是 content 的 UTF-8 编码（含 BOM）', () {
      final ExportResult result = ExportEncoder.build(
        _sampleDocument(),
        ExportFormat.csv,
      );

      expect(result.bytes.take(3), <int>[0xEF, 0xBB, 0xBF]);
      // utf8.decode 会吃掉 BOM，所以去掉首字符再比。
      expect(utf8.decode(result.bytes), result.content.substring(1));
    });
  });

  group('ExportService', () {
    late TestHarness harness;

    setUp(() => harness = TestHarness());
    tearDown(() => harness.dispose());

    Future<ExportDocument> loadFromHarness() => loadExportDocument(harness.db);

    test('从数据库读出的快照包含全部表', () async {
      final int beanId = await harness.beans.save(makeBean(name: '花魁'));
      final int grinderId = await harness.grinders.save(makeGrinder());
      await harness.logs.save(
        makeLog(beanId: beanId, grinderId: grinderId, doseGrams: 15),
      );

      final ExportDocument document = await loadFromHarness();

      expect(document.beans, hasLength(1));
      expect(document.grinders, hasLength(1));
      expect(document.brewLogs, hasLength(1));
      expect(document.recipes, isEmpty);
      // 余量已被自动扣减，导出应反映当前值。
      expect(document.beans.single.remainingGrams, 185);
    });

    test('导出会落盘，且文件名与内容一致', () async {
      await harness.beans.save(makeBean(name: '花魁'));
      final Directory temp = await Directory.systemTemp.createTemp('beanclick');
      addTearDown(() => temp.delete(recursive: true));

      final ExportService service = ExportService(
        loadDocument: loadFromHarness,
        directoryResolver: () async => temp,
        sharer: (String path, String fileName) async {},
      );

      final ExportOutcome outcome =
          await service.exportAndShare(ExportFormat.json);

      final File file = File(outcome.path);
      expect(await file.exists(), isTrue);
      expect(outcome.fileName, file.uri.pathSegments.last);
      expect(outcome.shared, isTrue);
      expect(outcome.shareError, isNull);

      final Map<String, Object?> payload =
          jsonDecode(await file.readAsString()) as Map<String, Object?>;
      expect((payload['coffeeBeans'] as List<Object?>), hasLength(1));
    });

    test('分享失败时文件仍然写成功', () async {
      final Directory temp = await Directory.systemTemp.createTemp('beanclick');
      addTearDown(() => temp.delete(recursive: true));

      final ExportService service = ExportService(
        loadDocument: loadFromHarness,
        directoryResolver: () async => temp,
        sharer: (String path, String fileName) async {
          throw StateError('没有可用的分享目标');
        },
      );

      final ExportOutcome outcome =
          await service.exportAndShare(ExportFormat.csv);

      expect(await File(outcome.path).exists(), isTrue);
      expect(outcome.shared, isFalse);
      expect(outcome.shareError, contains('没有可用的分享目标'));
    });

    test('CSV 落盘后带 BOM，可被 Excel 正确识别', () async {
      final Directory temp = await Directory.systemTemp.createTemp('beanclick');
      addTearDown(() => temp.delete(recursive: true));

      final ExportService service = ExportService(
        loadDocument: loadFromHarness,
        directoryResolver: () async => temp,
        sharer: (String path, String fileName) async {},
      );

      final ExportOutcome outcome =
          await service.exportAndShare(ExportFormat.csv);
      final List<int> bytes = await File(outcome.path).readAsBytes();

      expect(bytes.take(3), <int>[0xEF, 0xBB, 0xBF]);
    });

    test('可以直接构建内容而不落盘（供预览/测试用）', () async {
      await harness.beans.save(makeBean(name: '花魁'));
      final ExportService service = ExportService(
        loadDocument: loadFromHarness,
      );

      final ExportResult result = await service.build(ExportFormat.json);

      expect(result.format, ExportFormat.json);
      expect(result.content, contains('花魁'));
    });
  });

  group('导出格式选项', () {
    test('JSON 是默认，且两种格式都有扩展名与说明', () {
      expect(ExportFormat.values.first, ExportFormat.json);
      expect(ExportFormat.json.extension, 'json');
      expect(ExportFormat.csv.extension, 'csv');
      for (final ExportFormat format in ExportFormat.values) {
        expect(format.label, isNotEmpty);
        expect(format.description, isNotEmpty);
      }
    });
  });
}

/// 造一份有代表性的导出快照。
ExportDocument _sampleDocument({String? note}) {
  final DateTime at = DateTime(2026, 1, 1, 8);
  return ExportDocument(
    exportedAt: DateTime(2026, 3, 7, 9, 5),
    beans: <CoffeeBean>[
      CoffeeBean(
        id: 1,
        name: '花魁',
        origin: '埃塞俄比亚',
        farm: '科契尔',
        process: ProcessMethod.washed,
        roastLevel: RoastLevel.light,
        roastDate: DateTime(2025, 12, 20),
        flavorTags: const <String>['草莓', '奶油'],
        remainingGrams: 185,
        initialGrams: 200,
        price: 88,
        notes: note,
        createdAt: at,
        updatedAt: at,
      ),
    ],
    grinders: <Grinder>[
      Grinder(
        id: 1,
        brand: 'Comandante',
        model: 'C40',
        burrType: '锥刀',
        scaleUnit: GrindScaleUnit.click,
        zeroPoint: 0,
        clicksPerRevolution: 30,
        createdAt: at,
        updatedAt: at,
      ),
    ],
    brewLogs: <BrewLog>[
      BrewLog(
        id: 1,
        beanId: 1,
        grinderId: 1,
        method: BrewMethod.pourOver,
        grindSetting: 22,
        doseGrams: 15,
        waterGrams: 240,
        waterTemp: 92,
        totalTimeSeconds: 155,
        dripper: 'V60',
        rating: 5,
        flavorTags: const <String>['草莓'],
        brewedAt: at,
        isBest: true,
        tds: 1.35,
        extractionYield: 20.1,
        pourStages: const <PourStage>[
          PourStage(order: 1, waterGrams: 30, atSecond: 0, note: '闷蒸'),
          PourStage(order: 2, waterGrams: 210, atSecond: 30),
        ],
        createdAt: at,
        updatedAt: at,
      ),
    ],
    recipes: <Recipe>[
      Recipe(
        id: 1,
        name: 'V60 四六法',
        method: BrewMethod.pourOver,
        doseGrams: 20,
        waterGrams: 300,
        waterTemp: 92,
        totalTimeSeconds: 210,
        createdAt: at,
        updatedAt: at,
      ),
    ],
  );
}
