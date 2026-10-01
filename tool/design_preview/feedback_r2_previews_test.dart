/// 用户反馈第二轮修复的**渲染稿**（真页面 + 真数据库夹具，不是 mock）。
///
/// 与 `batch1_*` / `grind_scale_*` 那几稿的区别：那几稿是手工搭的版面示意，
/// 这一稿直接渲染**产品页面本身**（`BrewLogFormPage` / `RecordPage`）+
/// 内存 drift 库里的真实夹具，所以图上看到的就是用户会看到的。
///
/// 跑法（故意放 `tool/` 而不是 `test/`，免得被 CI 当 golden 比对）：
///
/// ```powershell
/// flutter test tool/design_preview/feedback_r2_previews_test.dart --update-goldens
/// ```
///
/// 产物：
/// - `tool/design_preview/goldens/feedback_r2_form.png`  —— 记录一杯（拼配填克数 / 总时间分秒 / 辅料行）
/// - `tool/design_preview/goldens/feedback_r2_card.png`  —— 记录卡片（相对刻度按**当前**零点算）
///
/// ⚠️ 本文件依赖 `test/helpers/*`（`test_harness.dart` 的 `makeLog`、
/// `widget_harness.dart` 的内存库与交互扩展）—— **改测试脚手架时这里要跟着改**。
/// 依赖是单向的（`test/` 下没有任何文件 import `tool/`），且 `flutter test` 默认只收集
/// `test/`，所以它不会被执行；但 `dart format` 与 `flutter analyze` 是**全仓**范围，会覆盖它。
///
/// ⚠️ 渲染真页面时**必须问一遍有没有挂钟/随机/网络依赖**：本稿第一版就是漏了
/// 「新建表单的冲煮时间取 `DateTime.now()`」，导致那张 golden 烙上渲染当时的那一分钟、
/// 换时间重跑必红。修法是给页面加 `initialBrewedAt` 注入缝。
library;

import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:beanclick/features/record/brew_log_form_page.dart';
import 'package:beanclick/features/record/record_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers/test_harness.dart' show makeLog;
import '../../test/helpers/widget_harness.dart';
import 'preview_support.dart';

void main() {
  final WidgetTestHarness harness = setUpWidgetTest();
  setUpAll(loadPreviewFonts);

  /// 画布：高得离谱一点，配合下面的守卫断言 —— 内容一旦超过视口就会被静默裁掉。
  void useTallCanvas(WidgetTester tester) {
    tester.view.physicalSize = const Size(780, 16000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  void guardNoClipping(WidgetTester tester) {
    expect(
      tester.getSize(find.byKey(previewSheetKey)).height,
      lessThanOrEqualTo(
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      ),
      reason: '内容已超过画布高度，请抬高 physicalSize —— 否则 golden 会被静默裁掉',
    );
  }

  testWidgets('反馈第二轮：记录一杯（拼配填克数 / 总时间分秒 / 辅料行）', (WidgetTester tester) async {
    useTallCanvas(tester);

    // 夹具：三支豆子（拼配用）+ 一台磨豆机（零点 18、每圈 30 click）。
    final ({int beanId, int batchId}) a = await harness.addBeanWithBatch(
      name: '耶加雪菲',
      remainingGrams: 200,
    );
    await harness.addBeanWithBatch(name: '花魁', remainingGrams: 100);
    await harness.addBeanWithBatch(name: '曼特宁', remainingGrams: 100);
    await harness.container
        .read(grinderRepositoryProvider)
        .save(
          Grinder(
            brand: 'Comandante',
            model: 'C40',
            scaleUnit: GrindScaleUnit.click,
            zeroPoint: 18,
            clicksPerRevolution: 30,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );

    // 真页面，套草稿用的中文字体主题。
    await tester.pumpWidget(
      harness.app(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: previewTheme(Brightness.light),
          home: SingleChildScrollView(
            // 截图必须落在**内容自己**的 RepaintBoundary 上：只给 Column 挂 key 时，
            // golden 会沿树往上找到根边界、截出整屏（本稿第一版就是 390×8000 的整屏图）。
            child: RepaintBoundary(
              key: previewSheetKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _Title('记录一杯 · 用户反馈第二轮修复后的观感'),
                  const _Label(
                    '① 冲煮方法那一行只保留一个「＋」（原先一个 chip 里画了两个加号）'
                    '　② 辅料三框等高 48dp、数量框 88dp（可显示 1000）'
                    '　③ 拼配每支直接填克数、占比只读、总粉量自动求和'
                    '　④ 总时间拆成「分 + 秒」两框',
                  ),
                  SizedBox(
                    // 必须比表单完整内容高：否则表单自己的滚动条会停在别处
                    // （fillField 会让输入框获焦并自动滚动），你反馈的那两处
                    // ——方法行与辅料行——就会被滚出画面、静默不在图里。
                    height: 2400,
                    // **冲煮时间必须注入固定值**：表单新建时默认取 `DateTime.now()`，
                    // 不注入的话这张 golden 会烙上"渲染当时的那一分钟"，
                    // 换个时间重跑必然报红。
                    child: BrewLogFormPage(
                      existing: null,
                      initialBrewedAt: DateTime(2026, 1, 1, 13, 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    // —— 摆出要给人看的状态 ——
    await tester.tapKey('brew.bean.0');
    await tester.tap(find.text('耶加雪菲').last);
    await tester.pumpAndSettle();

    // 拼配：1 支 → 3 支（每支直接填克数）
    await tester.tapKey('brew.addPick');
    await tester.pumpAndSettle();
    await tester.tapKey('brew.addPick');
    await tester.pumpAndSettle();
    await tester.fillField('brew.beanGrams.0', '18');
    await tester.fillField('brew.beanGrams.1', '6');
    await tester.fillField('brew.beanGrams.2', '6');
    await tester.pumpAndSettle();

    // 辅料：从面板加一项，数量填四位数（反馈原话："超过两位数后无法完全显示"）
    await tester.tapKey('brew.addAddIn');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('brew.addInOption.牛奶')));
    await tester.pumpAndSettle();
    await tester.fillField('brew.addInAmount.0', '1000');
    await tester.pumpAndSettle();

    // 总时间：分 + 秒
    await tester.fillField('brew.totalTimeMin', '2');
    await tester.fillField('brew.totalTimeSec', '30');
    await tester.pumpAndSettle();

    // 研磨刻度：圈 + click（相对刻度提示会按**当前**零点 18 算）
    await tester.fillField('brew.grindSetting', '1');
    await tester.fillField('brew.grindClicks', '15');
    await tester.pumpAndSettle();

    guardNoClipping(tester);
    await expectLater(
      find.byKey(previewSheetKey),
      matchesGoldenFile('goldens/feedback_r2_form.png'),
    );

    await harness.finish(tester);
    expect(a.beanId, isPositive);
  });

  testWidgets('反馈第二轮：记录卡片（相对刻度按当前零点算，不再偏 +9）', (WidgetTester tester) async {
    useTallCanvas(tester);

    // 夹具：磨豆机**当前**零点 18 / 每圈 30 click；
    // 而记录里存的快照是**旧**零点 9 / 每圈 30 click。
    // 修复前：卡片按快照算 → 1×30 + 15 − 9 = 36 click（比真实值大 9）
    // 修复后：卡片按当前值算 → 1×30 + 15 − 18 = **27 click**
    final ({int beanId, int batchId}) a = await harness.addBeanWithBatch(
      name: '耶加雪菲',
      remainingGrams: 200,
    );
    final int grinderId = await harness.container
        .read(grinderRepositoryProvider)
        .save(
          Grinder(
            brand: 'Comandante',
            model: 'C40',
            scaleUnit: GrindScaleUnit.click,
            zeroPoint: 18,
            clicksPerRevolution: 30,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          makeLog(
            beanId: a.beanId,
            batchId: a.batchId,
            grinderId: grinderId,
            dripper: 'V60 02',
            notes: '改过零点之后，卡片上的相对刻度应该跟着变',
          ).copyWith(
            grindSetting: 1,
            grindClicks: 15,
            grinderZeroPointSnapshot: 9,
            grinderClicksPerRevolutionSnapshot: 30,
          ),
        );

    await tester.pumpWidget(
      harness.app(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: previewTheme(Brightness.light),
          home: SingleChildScrollView(
            child: RepaintBoundary(
              key: previewSheetKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _Title('记录卡片 · 相对刻度改用「当前校准」'),
                  const _Label(
                    '夹具：磨豆机现在零点 18；这条记录里的快照是旧零点 9。'
                    '修复前卡片按快照算 = 36 click（比真实值大 9）；'
                    '修复后按当前值算 = 27 click。',
                  ),
                  SizedBox(
                    height: 420,
                    // RecordPage 里有搜索框（TextField），需要 Material 祖先 ——
                    // 真实 App 里它是套在 shell 的 Scaffold 里的，这里照同样方式包。
                    child: const Scaffold(body: RecordPage()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    guardNoClipping(tester);
    await expectLater(
      find.byKey(previewSheetKey),
      matchesGoldenFile('goldens/feedback_r2_card.png'),
    );

    await harness.finish(tester);
  });
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
