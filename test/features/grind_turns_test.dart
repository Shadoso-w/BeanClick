import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/features/record/brew_log_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

/// 测评反馈：研磨刻度改成「圈 + click」，提示里给**绝对刻度**。
///
/// 直接以 `existing` 打开编辑页来带出磨豆机快照，避免在 widget 测试里
/// 操作 `DropdownButtonFormField` 的浮层菜单（那层菜单不好稳定定位）。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  /// 表单要能按 id 查到磨豆机，所以先落一台真磨豆机，再打开编辑页。
  ///
  /// 记录里的**快照**才是换算依据（老研磨度关联老记录），所以快照值可以和
  /// 磨豆机当前的值不一样：这里特意让两者不同，用来证明读的是快照。
  Future<void> pumpForm(
    WidgetTester tester, {
    required double? zeroPoint,
    required int? clicksPerRevolution,
  }) async {
    final int grinderId = await harness.container
        .read(grinderRepositoryProvider)
        .save(
          Grinder(
            brand: 'Comandante',
            model: 'C40',
            scaleUnit: GrindScaleUnit.click,
            zeroPoint: 0,
            clicksPerRevolution: clicksPerRevolution,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
    await tester.pumpWidget(
      harness.app(
        MaterialApp(
          home: BrewLogFormPage(
            existing: BrewLog(
              method: BrewMethod.pourOver,
              grinderId: grinderId,
              grinderZeroPointSnapshot: zeroPoint,
              grinderClicksPerRevolutionSnapshot: clicksPerRevolution,
              brewedAt: DateTime(2026, 1, 1, 8),
              createdAt: DateTime(2026, 1, 1, 8),
              updatedAt: DateTime(2026, 1, 1, 8),
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// 填两个研磨框并读回提示行。
  Future<String> grindHelperAfter(
    WidgetTester tester,
    String turns,
    String clicks,
  ) async {
    await tester.fillField('brew.grindSetting', turns);
    await tester.fillField('brew.grindClicks', clicks);
    await tester.pumpAndSettle();
    final Finder helper = find.textContaining('绝对刻度');
    await tester.scrollTo(helper);
    return tester.widget<Text>(helper).data!;
  }

  testWidgets('知道每圈 click 时，第一个框是「圈」，提示给绝对刻度', (tester) async {
    await pumpForm(tester, zeroPoint: 0, clicksPerRevolution: 30);

    expect(find.text('圈'), findsOneWidget);

    // 1.5 圈 + 15 click，零点 0、每圈 30 → 绝对刻度 60。
    final String helper = await grindHelperAfter(tester, '1.5', '15');
    expect(helper, contains('绝对刻度 60'), reason: '0 + 1.5 × 30 + 15 = 60');

    await harness.finish(tester);
  });

  testWidgets('零点不为 0 时算进绝对刻度里', (tester) async {
    await pumpForm(tester, zeroPoint: 5, clicksPerRevolution: 30);

    // 5 + 1 × 30 + 5 = 40
    final String helper = await grindHelperAfter(tester, '1', '5');
    expect(helper, contains('绝对刻度 40'));

    await harness.finish(tester);
  });

  testWidgets('没填零点时按 0 算，并在提示里说明', (tester) async {
    await pumpForm(tester, zeroPoint: null, clicksPerRevolution: 30);

    final String helper = await grindHelperAfter(tester, '2', '3');
    expect(helper, contains('绝对刻度 63'), reason: '0 + 2 × 30 + 3 = 63');
    expect(helper, contains('未填零点'));

    await harness.finish(tester);
  });

  testWidgets('没有每圈 click 的磨豆机退回「研磨刻度」的展示格式', (tester) async {
    await pumpForm(tester, zeroPoint: 0, clicksPerRevolution: null);

    expect(find.text('圈'), findsNothing);
    expect(find.text('研磨刻度'), findsOneWidget);

    await tester.fillField('brew.grindSetting', '6.5');
    await tester.fillField('brew.grindClicks', '2');
    await tester.pumpAndSettle();

    // 退回手册 §7 的相对展示格式，不出现「绝对刻度」。
    expect(find.textContaining('绝对刻度'), findsNothing);
    expect(find.textContaining('6.5'), findsWidgets);

    await harness.finish(tester);
  });
}
