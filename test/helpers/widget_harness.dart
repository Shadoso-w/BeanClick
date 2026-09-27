/// widget 测试脚手架。
///
/// ## 两个真实踩过的坑
///
/// **坑 1：测试失败时 flutter_test 不会卸载 widget 树。**
/// `_runTestBody` 里是这么写的：
///
/// ```dart
/// if (_pendingExceptionDetails == null) {
///   runApp(Container(key: UniqueKey(), child: _postTestMessage)); // 卸载 widget 树
///   await pump();
/// }
/// ```
///
/// 也就是说**只有测试没失败时它才卸载树**。而 `AppDatabase.close()` 内部是
/// `await streamQueries.close()`，drift 的流查询在订阅未全部取消前不会归零。
/// 于是「测试失败 → 树没卸 → close() 永久等待 → 整个 flutter test 进程卡死」。
///
/// **坑 2：`ProviderContainer.dispose()` 与 `AppDatabase.close()` 都可能永久等待。**
/// 它们在 widget 还订阅着的时候会等订阅取消，等不到就永远不返回。
///
/// ## 本脚手架的取舍
///
/// 收尾只做一件事：把 widget 树换成空树（这一步无论测试成败都能生效），
/// 让订阅取消。数据库与容器**不做 await 关闭**——
/// 每个测试各有一个内存库实例，进程结束时自然回收；
/// 用「泄漏一个几 KB 的内存库」换「绝不卡死」，这个交换是值得的。
library;

import 'package:beanclick/data/database.dart';
import 'package:beanclick/data/providers.dart';
import 'package:beanclick/domain/entities.dart';
import 'package:beanclick/domain/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 把 `Override` 放在 misc.dart 里，主库不再导出。
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// 单个测试用的环境：内存数据库 + 自持 ProviderContainer。
class WidgetTestHarness {
  WidgetTestHarness._();

  /// 创建一个空壳；真正的数据库与容器在 [reset] 里重建。
  factory WidgetTestHarness.create() => WidgetTestHarness._();

  late AppDatabase _db;
  late ProviderContainer _container;

  /// 每个测试额外的 provider 覆盖（例如把导出目录指向临时目录）。
  List<Override> _extraOverrides = const <Override>[];

  AppDatabase get db => _db;
  ProviderContainer get container => _container;

  /// 建一支豆子 + 一个批次，返回两者的 id。
  ///
  /// 批次模型下这是最常见的准备动作（余量、烘焙日期都在批次上），
  /// 放在脚手架里避免每个 widget 测试重复拼装实体。
  Future<({int beanId, int batchId})> addBeanWithBatch({
    String name = '耶加雪菲',
    String? origin = '埃塞俄比亚',
    double remainingGrams = 200,
    double? initialGrams = 200,
    DateTime? roastDate,
    List<String> flavorTags = const <String>['柑橘', '花香'],
    bool isFavorite = false,
    DateTime? createdAt,
  }) async {
    final DateTime now = createdAt ?? DateTime(2026, 1, 1, 9);
    final int beanId = await _container
        .read(beanRepositoryProvider)
        .save(
          CoffeeBean(
            name: name,
            origin: origin,
            flavorTags: flavorTags,
            isFavorite: isFavorite,
            createdAt: now,
            updatedAt: now,
          ),
        );
    final int batchId = await _container
        .read(beanRepositoryProvider)
        .saveBatch(
          BeanBatch(
            beanId: beanId,
            roastDate: roastDate,
            remainingGrams: remainingGrams,
            initialGrams: initialGrams,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return (beanId: beanId, batchId: batchId);
  }

  /// 建一条冲煮记录（可带单支豆子用量）。
  Future<int> addBrewLog({
    int? beanId,
    int? batchId,
    int? grinderId,
    double? doseGrams = 15,
    int? rating,
    String? notes,
    DateTime? brewedAt,
  }) async {
    final DateTime now = brewedAt ?? DateTime(2026, 1, 1, 8);
    final result = await _container
        .read(brewLogRepositoryProvider)
        .save(
          BrewLog(
            beanId: beanId,
            grinderId: grinderId,
            method: BrewMethod.pourOver,
            doseGrams: doseGrams,
            rating: rating,
            notes: notes,
            brewedAt: now,
            beanUsages: beanId == null
                ? const <BeanUsage>[]
                : <BeanUsage>[
                    BeanUsage(
                      beanId: beanId,
                      batchId: batchId,
                      doseGrams: doseGrams ?? 0,
                    ),
                  ],
            createdAt: now,
            updatedAt: now,
          ),
        );
    return result.brewLogId;
  }

  /// 设置额外覆盖（例如把导出目录指向临时目录）。
  ///
  /// 注意时序坑：flutter_test 里**先注册的 setUp 先执行**，而
  /// [setUpWidgetTest] 在 `main()` 顶部就注册了 [reset]，
  /// 所以业务测试里后注册的 `setUp` 一定在 reset **之后**才跑。
  /// 因此这里不能只把构造器存下来，必须**立刻重建容器**，
  /// 否则覆盖永远不生效（容器里已经是重建前的旧实例）。
  void useOverrides(List<Override> Function() build) {
    _extraOverridesBuilder = build;
    rebuild();
  }

  List<Override> Function()? _extraOverridesBuilder;

  /// 重建数据库与容器。
  ///
  /// 由 [setUpWidgetTest] 注册为 setUp（保证测试之间互相隔离），
  /// 也由 [useOverrides] 立即调用一次。
  Future<void> reset() async => rebuild();

  void rebuild() {
    _db = AppDatabase.memory();
    _extraOverrides = _extraOverridesBuilder?.call() ?? const <Override>[];
    _container = ProviderContainer(
      overrides: <Override>[
        databaseProvider.overrideWithValue(_db),
        ..._extraOverrides,
      ],
    );
  }

  /// 把 widget 包进当前测试的 ProviderScope。
  Widget app(Widget child) =>
      UncontrolledProviderScope(container: _container, child: child);

  /// 测试收尾：卸载 widget 树，让 drift 的订阅取消。
  ///
  /// 放在每个测试体最后一行。**不 await 任何关闭操作**（见文件头说明）。
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }
}

/// 在 `main()` 顶部调用一次，返回当前测试的 harness。
///
/// ```dart
/// void main() {
///   final WidgetTestHarness harness = setUpWidgetTest();
///   testWidgets('...', (tester) async {
///     await tester.pumpWidget(harness.app(const BeanClickApp()));
///     // ... 断言 ...
///     await harness.finish(tester);
///   });
/// }
/// ```
WidgetTestHarness setUpWidgetTest() {
  final WidgetTestHarness harness = WidgetTestHarness.create();
  setUp(harness.reset);
  return harness;
}
