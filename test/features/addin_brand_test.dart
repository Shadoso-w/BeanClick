import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/features/record/brew_log_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart' show makeLog;
import '../helpers/widget_harness.dart';

/// M3-T37（v8）：辅料的**品牌** —— 两排行布局、行内输入框、面板「名字 · 品牌」。
///
/// 最关键的一条是 **S8**：`_AddIn` 若不带 brand，任何「编辑旧记录 → 保存」
/// 都会把品牌写回 null（见最后那条用例）。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  Future<void> pumpForm(WidgetTester tester, {BrewLog? existing}) async {
    await tester.pumpWidget(
      harness.app(
        MaterialApp(
          home: BrewLogFormPage(
            existing: existing,
            // 新建时注入固定时间：`DateTime.now()` 会让断言随渲染时刻变。
            initialBrewedAt: existing == null ? DateTime(2026, 1, 1, 8) : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<List<BrewLog>> logs() =>
      harness.container.read(brewLogRepositoryProvider).getAll();

  Future<void> addAddIn(WidgetTester tester, String name) async {
    await tester.tapKey('brew.addAddIn');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('brew.addInOption.$name')));
    await tester.pumpAndSettle();
  }

  Future<void> pickBean(WidgetTester tester, String name) async {
    await tester.tapKey('brew.bean.0');
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  testWidgets('辅料行两排：品牌在第一排、数量/单位在第二排，四个框仍等高', (tester) async {
    // 真机宽度（390dp）：默认 800dp 太宽，暴露不出第一排两框被挤扁。
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await pumpForm(tester);
    await addAddIn(tester, '牛奶');

    final Finder name = find.byKey(const Key('brew.addInName.0'));
    final Finder brand = find.byKey(const Key('brew.addInBrand.0'));
    final Finder amount = find.byKey(const Key('brew.addInAmount.0'));
    final Finder unit = find.ancestor(
      of: find.byKey(const Key('brew.addInUnit.0')),
      matching: find.byType(InputDecorator),
    );

    // 第一排：名字与品牌同一排（纵坐标基本一致）。
    expect(
      (tester.getCenter(name).dy - tester.getCenter(brand).dy).abs(),
      lessThan(4),
      reason: '名字与品牌该在同一排',
    );
    // 第二排：数量比第一排低一整行。
    expect(
      tester.getCenter(amount).dy,
      greaterThan(tester.getCenter(name).dy + 20),
      reason: '数量该换到第二排',
    );

    // 四个框仍共 48dp 等高；数量 88 / 单位 84 的既有契约不动。
    final Size nameSize = tester.getSize(name);
    expect(nameSize.height, closeTo(48, 1));
    expect(tester.getSize(brand).height, closeTo(nameSize.height, 1));
    expect(tester.getSize(amount).height, closeTo(nameSize.height, 1));
    expect(tester.getSize(unit).height, closeTo(nameSize.height, 1));
    expect(tester.getSize(amount).width, greaterThanOrEqualTo(80));
    expect(tester.getSize(unit).width, greaterThanOrEqualTo(84));
    // 名字框不再被挤扁（改前 320dp 下只剩 ≈28dp、三字名会被省略号吃空）。
    expect(nameSize.width, greaterThan(100), reason: '名字框应拿回可读宽度：$nameSize');

    await harness.finish(tester);
  });

  testWidgets('品牌框的 hint 是「品牌」', (tester) async {
    await pumpForm(tester);
    await addAddIn(tester, '牛奶');

    expect(find.byKey(const Key('brew.addInBrand.0')), findsOneWidget);
    expect(find.text('品牌'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('新增辅料填品牌 → 保存后落库', (tester) async {
    await harness.addBeanWithBatch(name: '花魁');
    await pumpForm(tester);
    await pickBean(tester, '花魁');
    await addAddIn(tester, '牛奶');
    await tester.fillField('brew.addInAmount.0', '150');
    await tester.fillField('brew.addInBrand.0', 'Oatly');
    await tester.tapSaveButton();

    final BrewLog log = (await logs()).single;
    expect(log.addIns.single.name, '牛奶');
    expect(log.addIns.single.brand, 'Oatly');

    await harness.finish(tester);
  });

  testWidgets('品牌留空 / 纯空白 → 落库为 null', (tester) async {
    await harness.addBeanWithBatch(name: '花魁');
    await pumpForm(tester);
    await pickBean(tester, '花魁');
    await addAddIn(tester, '牛奶');
    await tester.fillField('brew.addInBrand.0', '   ');
    await tester.tapSaveButton();

    expect((await logs()).single.addIns.single.brand, isNull);

    await harness.finish(tester);
  });

  testWidgets('面板「最近用过」显示「名字 · 品牌」；品牌为空只显示名字', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    final DateTime at = DateTime(2026, 1, 1, 8);
    final repo = harness.container.read(brewLogRepositoryProvider);
    // 用**不在常用表里**的名字，否则面板会把它们过滤掉（常用 8 个硬编码）。
    await repo.save(
      makeLog(
        beanId: a.beanId,
        batchId: a.batchId,
        brewedAt: at,
        addIns: <BrewLogAddIn>[
          const BrewLogAddIn(name: '香草糖浆', brand: 'Monin'),
        ],
      ),
    );
    await repo.save(
      makeLog(
        beanId: a.beanId,
        batchId: a.batchId,
        brewedAt: at.add(const Duration(hours: 1)),
        addIns: <BrewLogAddIn>[const BrewLogAddIn(name: '柠檬汁')],
      ),
    );

    await pumpForm(tester);
    await tester.tapKey('brew.addAddIn');
    await tester.pumpAndSettle();

    expect(find.text('最近用过'), findsOneWidget);
    expect(find.text('香草糖浆 · Monin'), findsOneWidget);
    expect(find.text('柠檬汁'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('常用名的品牌变体也要留在「最近用过」里（只挡同名同牌）', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    final DateTime at = DateTime(2026, 1, 1, 8);
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          makeLog(
            beanId: a.beanId,
            batchId: a.batchId,
            brewedAt: at,
            addIns: <BrewLogAddIn>[
              // 「牛奶」在常用表里，但「牛奶 · Oatly」是不同的东西，不该被过滤掉。
              const BrewLogAddIn(name: '牛奶', brand: 'Oatly'),
            ],
          ),
        );

    await pumpForm(tester);
    await tester.tapKey('brew.addAddIn');
    await tester.pumpAndSettle();

    expect(find.text('牛奶 · Oatly'), findsOneWidget);

    await harness.finish(tester);
  });

  testWidgets('B1：面板点「名字 · 品牌」→ 新行的品牌框里就是那个品牌', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    final DateTime at = DateTime(2026, 1, 1, 8);
    await harness.container
        .read(brewLogRepositoryProvider)
        .save(
          makeLog(
            beanId: a.beanId,
            batchId: a.batchId,
            brewedAt: at,
            addIns: <BrewLogAddIn>[
              const BrewLogAddIn(name: '香草糖浆', brand: 'Monin'),
            ],
          ),
        );

    await pumpForm(tester);
    await tester.tapKey('brew.addAddIn');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('brew.addInOption.香草糖浆·Monin')));
    await tester.pumpAndSettle();

    // 面板是新增辅料的唯一入口：只弹回名字的话这里会是空串（B1）。
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('brew.addInBrand.0')))
          .controller!
          .text,
      'Monin',
      reason: '面板选的品牌必须落到行内品牌框里',
    );

    await harness.finish(tester);
  });

  testWidgets('B2：同名不同牌同时出现在面板里 → 不崩、能分别点中', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    final DateTime at = DateTime(2026, 1, 1, 8);
    final repo = harness.container.read(brewLogRepositoryProvider);
    await repo.save(
      makeLog(
        beanId: a.beanId,
        batchId: a.batchId,
        brewedAt: at,
        addIns: <BrewLogAddIn>[const BrewLogAddIn(name: '抹茶粉', brand: 'A')],
      ),
    );
    await repo.save(
      makeLog(
        beanId: a.beanId,
        batchId: a.batchId,
        brewedAt: at.add(const Duration(hours: 1)),
        addIns: <BrewLogAddIn>[const BrewLogAddIn(name: '抹茶粉', brand: 'B')],
      ),
    );

    await pumpForm(tester);
    await tester.tapKey('brew.addAddIn');
    // 同层两个相同 key 会在这里抛 `Duplicate keys found`。
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('brew.addInOption.抹茶粉·A')), findsOneWidget);
    expect(find.byKey(const Key('brew.addInOption.抹茶粉·B')), findsOneWidget);

    // 两个 chip 语义可分：点 B 就该拿到 B。
    await tester.tap(find.byKey(const Key('brew.addInOption.抹茶粉·B')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('brew.addInBrand.0')))
          .controller!
          .text,
      'B',
    );

    await harness.finish(tester);
  });

  testWidgets('S8：编辑一条带品牌的旧记录 → 保存后品牌仍在', (tester) async {
    final a = await harness.addBeanWithBatch(name: '花魁');
    final DateTime at = DateTime(2026, 1, 1, 8);
    final repo = harness.container.read(brewLogRepositoryProvider);
    final int logId = (await repo.save(
      makeLog(
        beanId: a.beanId,
        batchId: a.batchId,
        brewedAt: at,
        addIns: <BrewLogAddIn>[
          const BrewLogAddIn(name: '牛奶', brand: 'Oatly', amount: 150),
        ],
      ),
    )).brewLogId;
    final BrewLog existing = (await repo.getById(logId))!;

    await pumpForm(tester, existing: existing);
    // 一个字都不改，直接保存 —— `_AddIn` 忘了带 brand 的话这里会写回 null。
    await tester.tapSaveButton();

    final BrewLog saved = (await logs()).single;
    expect(saved.addIns.single.name, '牛奶');
    expect(saved.addIns.single.brand, 'Oatly', reason: '编辑保存不该丢掉品牌（S8）');

    await harness.finish(tester);
  });
}
