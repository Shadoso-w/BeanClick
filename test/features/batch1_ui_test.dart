import 'package:beanclick/app.dart';
import 'package:beanclick/core/widgets/form_fields.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/features/record/brew_log_form_page.dart';
import 'package:beanclick/features/record/record_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart' show makeLog;
import '../helpers/widget_harness.dart';

/// M2.8 第一批：A2 日期弹窗中文化、A3 冲煮时间可选时分、B2 卡片第一行。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> pumpRecordPage(WidgetTester tester) async {
    await tester.pumpWidget(
      harness.app(const MaterialApp(home: Scaffold(body: RecordPage()))),
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  group('A3 日期/时分工具的纯函数', () {
    test('formatTime 是 24 小时制并补零', () {
      expect(formatTime(const TimeOfDay(hour: 8, minute: 5)), '08:05');
      expect(formatTime(const TimeOfDay(hour: 14, minute: 30)), '14:30');
      expect(formatTime(const TimeOfDay(hour: 0, minute: 0)), '00:00');
    });

    test('withDate 只换日期、保留时分', () {
      final DateTime original = DateTime(2026, 1, 1, 8, 5, 30);
      final DateTime changed = withDate(original, DateTime(2026, 3, 9));
      expect(changed, DateTime(2026, 3, 9, 8, 5, 30));
    });

    test('withTime 只换时分、保留日期（秒清零）', () {
      final DateTime original = DateTime(2026, 1, 1, 8, 5, 30);
      final DateTime changed = withTime(
        original,
        const TimeOfDay(hour: 15, minute: 42),
      );
      // 时间选择器只有分钟精度，秒会被清零。
      expect(changed, DateTime(2026, 1, 1, 15, 42));
      expect(changed.second, 0);
    });

    test('formatDateTimeChinese 拼出中文日期 + 时分', () {
      expect(
        formatDateTimeChinese(DateTime(2026, 9, 27, 14, 30)),
        '2026年9月27日 14:30',
      );
    });
  });

  testWidgets('A2：日期选择弹窗是中文的', (tester) async {
    // 必须走真实的 BeanClickApp（locale 与 localizationsDelegates 在那里配）。
    await tester.pumpWidget(harness.app(const BeanClickApp()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('dock.addCup')));
    await tester.pumpAndSettle();

    await tester.tapKey('brew.brewedDate');
    await tester.pumpAndSettle();

    // Material 的日期选择器在 zh_CN 下按钮是「取消 / 确定」，
    // 月份标题带「年」「月」，星期是单个汉字。
    expect(find.text('取消'), findsWidgets);
    expect(find.text('确定'), findsWidgets);
    expect(find.textContaining('年'), findsWidgets);
    expect(find.text('OK'), findsNothing);
    expect(find.text('Cancel'), findsNothing);

    await tester.tap(find.text('取消').last);
    await tester.pumpAndSettle();

    await harness.finish(tester);
  });

  testWidgets('A3：编辑记录时，时分按钮显示记录里的时分', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    final int logId =
        (await harness.container
                .read(brewLogRepositoryProvider)
                .save(
                  makeLog(
                    beanId: a.beanId,
                    batchId: a.batchId,
                    brewedAt: DateTime(2026, 1, 1, 8, 5),
                  ),
                ))
            .brewLogId;
    final BrewLog existing = (await harness.container
        .read(brewLogRepositoryProvider)
        .getById(logId))!;

    await tester.pumpWidget(
      harness.app(MaterialApp(home: BrewLogFormPage(existing: existing))),
    );
    await tester.pumpAndSettle();

    // 日期与时分是两个独立按钮。
    expect(find.byKey(const Key('brew.brewedDate')), findsOneWidget);
    expect(find.byKey(const Key('brew.brewedTime')), findsOneWidget);
    expect(find.text('08:05'), findsOneWidget);
    expect(find.text('2026年1月1日'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('B2：卡片第一行是「豆名 + 方法 chip」，第二行只剩刻度', (tester) async {
    final a = await harness.addBeanWithBatch(name: '黑猫拼配');
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          makeLog(
            beanId: a.beanId,
            batchId: a.batchId,
            method: BrewMethod.mokaPot,
            grindSetting: 22,
            brewedAt: DateTime(2026, 1, 1, 8),
          ),
        );

    await pumpRecordPage(tester);

    // 豆名与方法 chip 都在，且**同一行**（纵坐标基本一致）。
    final double beanDy = tester.getCenter(find.text('黑猫拼配')).dy;
    final double methodDy = tester.getCenter(find.text('摩卡壶')).dy;
    expect((beanDy - methodDy).abs(), lessThan(10), reason: 'chip 应该在第一行');

    // 刻度在下面一行（比第一行低）。
    final double grindDy = tester.getCenter(find.textContaining('22')).dy;
    expect(grindDy, greaterThan(beanDy + 10));

    await harness.finish(tester);
  });

  testWidgets('B2：拼配记录的第一行包含所有豆名，chip 在其后', (tester) async {
    final a = await harness.addBeanWithBatch(name: '黑猫拼配');
    final b = await harness.addBeanWithBatch(name: '花魁');
    final DateTime at = DateTime(2026, 1, 1, 8);
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          BrewLog(
            method: BrewMethod.pourOver,
            doseGrams: 20,
            brewedAt: at,
            createdAt: at,
            updatedAt: at,
            beanUsages: <BeanUsage>[
              BeanUsage(
                beanId: a.beanId,
                batchId: a.batchId,
                doseGrams: 14,
                position: 0,
              ),
              BeanUsage(
                beanId: b.beanId,
                batchId: b.batchId,
                doseGrams: 6,
                position: 1,
              ),
            ],
          ),
        );

    await pumpRecordPage(tester);

    // 标题是「A + B」，chip 紧随其后（横坐标在标题右侧、同一行）。
    final Finder title = find.text('黑猫拼配 + 花魁');
    expect(title, findsOneWidget);
    final Rect titleRect = tester.getRect(title);
    final Rect chipRect = tester.getRect(find.text('手冲'));
    expect(chipRect.left, greaterThanOrEqualTo(titleRect.right - 1));
    expect((chipRect.center.dy - titleRect.center.dy).abs(), lessThan(10));

    await harness.finish(tester);
  });
}
