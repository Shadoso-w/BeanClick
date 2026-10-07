import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_harness.dart';

/// 探针 provider：默认 0，被 `useOverrides` 覆盖后读到 42。
///
/// **必须在文件级、全程共用同一个实例**：下面「reset 后读到 0」的断言，成立
/// 的前提是「注册覆盖」与「读默认值」指向**同一个** Provider —— Riverpod 的
/// `Override` 是按 provider 的 **identity** 匹配的。若按「更干净」的直觉把它
/// 挪进各自的用例体，覆盖就落到另一个实例上，读数**恒为 0**，即使 `reset()`
/// 漏清也照样绿，回归网会静默失效。
///
/// 另外刻意用普通 `Provider<int>`（不是 Stream/Future provider）：读数完全同步，
/// 不依赖任何异步发射时序，用例不会因为「等发射」而飘。
final Provider<int> _probeProvider = Provider<int>((ref) => 0);

/// 钉住 [WidgetTestHarness.useOverrides] 的**按用例隔离**。
///
/// 第 1 条是**顺序无关**的闭环：注册 → 断言生效 → 直接调 `reset()` → 断言清理
/// 干净。无论 `--test-randomize-ordering-seed` 把它排到哪里，它都有判别力
/// （去掉 `reset()` 里的清理就必红）。
///
/// 第 2 条走**跨用例**这条路：`setUp`（由 [setUpWidgetTest] 注册）驱动的 reset
/// 把上一个用例的覆盖清掉。它靠「第 1 条先注册过覆盖」才有判别力，**依赖同文件
/// 内的声明序**——乱序跑且被排到最前时会退化成恒真的弱断言。所以判别力由第 1 条
/// 兜底，这条只作默认顺序下的补充覆盖。
void main() {
  final WidgetTestHarness harness = setUpWidgetTest();

  testWidgets('reset：注册的覆盖在本用例内生效，reset 后即被清掉（顺序无关）', (tester) async {
    harness.useOverrides(() => [_probeProvider.overrideWithValue(42)]);
    expect(
      harness.container.read(_probeProvider),
      42,
      reason: '覆盖必须立刻生效（useOverrides 内部会重建容器）',
    );

    await harness.reset();

    expect(
      harness.container.read(_probeProvider),
      0,
      reason: 'reset 必须清掉覆盖：清空只发生在 reset 开头，rebuild 里不清',
    );
  });

  testWidgets('setUp 驱动的 reset：上一个用例注册的覆盖不漏进本用例（依赖声明序）', (tester) async {
    expect(
      harness.container.read(_probeProvider),
      0,
      reason: '每个用例都应从「没有任何覆盖」开始，否则测试成败取决于它在文件里的位置',
    );
  });
}
