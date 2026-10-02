import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/icons.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/providers.dart';
import '../../domain/entities.dart';
import '../../domain/enums.dart';
import 'bean_form_page.dart';
import 'grinder_form_page.dart';

/// 咖啡豆段的排序键（M3-T36）。
///
/// `shortLabel` 给顶部入口按钮（≤4 字），`label` 给弹层行；
/// `hint` 是弹层小字（用户裁决 J：只给两个消耗类键留）；
/// `directionEnabled=false` 的键把方向控件**置灰**（不隐藏，用户裁决 I）。
enum BeanSortKey {
  defaultOrder(
    '默认',
    '默认（入库顺序）',
    defaultDescending: false,
    directionEnabled: false,
  ),
  purchaseTotal('购买总量', '购买总量'),
  consumedTotal('消耗总量', '消耗总量', hint: '冲煮累计'),
  netDecrease('净减少量', '净减少量', hint: '购入 − 余量'),
  spend('花费', '花费'),
  unitPrice('单价', '单价', defaultDescending: false),
  repurchaseCount('复购次数', '复购次数');

  const BeanSortKey(
    this.shortLabel,
    this.label, {
    this.hint,
    this.defaultDescending = true,
    this.directionEnabled = true,
  });

  /// 顶部入口按钮上的文字。
  final String shortLabel;

  /// 弹层里那一行的键名。
  final String label;

  /// 弹层小字（可空）。
  final String? hint;

  /// 选中这个键时的默认方向：数值键降序、单价升序。
  final bool defaultDescending;

  /// 是否允许改方向（默认键与型号：否）。
  final bool directionEnabled;
}

/// 磨豆机段的排序键（M3-T36）。
enum GrinderSortKey {
  defaultOrder(
    '默认',
    '默认（入库顺序）',
    defaultDescending: false,
    directionEnabled: false,
  ),
  model('型号', '型号', defaultDescending: false, directionEnabled: false),
  useCount('使用次数', '使用次数'),
  lastUsed('最近使用', '最近使用');

  const GrinderSortKey(
    this.shortLabel,
    this.label, {
    this.defaultDescending = true,
    this.directionEnabled = true,
  });

  final String shortLabel;
  final String label;
  final bool defaultDescending;
  final bool directionEnabled;
}

/// 豆库 tab：咖啡豆 / 磨豆机 分段（手册 §5.2）。
class BeansPage extends StatefulWidget {
  const BeansPage({super.key});

  @override
  State<BeansPage> createState() => _BeansPageState();
}

class _BeansPageState extends State<BeansPage> {
  /// 0 = 咖啡豆，1 = 磨豆机。
  int _segment = 0;

  // 排序状态（**不记住**：进页面回默认，用户裁决 F）。
  BeanSortKey _beanSort = BeanSortKey.defaultOrder;
  bool _beanDescending = BeanSortKey.defaultOrder.defaultDescending;
  GrinderSortKey _grinderSort = GrinderSortKey.defaultOrder;
  bool _grinderDescending = GrinderSortKey.defaultOrder.defaultDescending;

  bool get _isBeans => _segment == 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SegmentedButton<int>(
                      expandedInsets: EdgeInsets.zero,
                      segments: const <ButtonSegment<int>>[
                        ButtonSegment<int>(
                          value: 0,
                          label: Text('咖啡豆'),
                          icon: Icon(Icons.coffee_outlined),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          label: Text('磨豆机'),
                          icon: Icon(Icons.tune_outlined),
                        ),
                      ],
                      selected: <int>{_segment},
                      onSelectionChanged: (Set<int> selection) =>
                          setState(() => _segment = selection.first),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 排序入口（M3-T36 方案 A）：显示**当前键**，宽度随内容撑开。
                  Consumer(
                    builder: (BuildContext context, WidgetRef ref, Widget? _) {
                      // 空态下**仍显示但置灰**（设计稿 §4）：避免控件忽隐忽现。
                      final List<Object?>? list = _isBeans
                          ? ref.watch(beanListProvider).value
                          : ref.watch(grinderListProvider).value;
                      final bool empty = list?.isEmpty ?? false;
                      return _SortButton(
                        label: _isBeans
                            ? _beanSort.shortLabel
                            : _grinderSort.shortLabel,
                        onPressed: empty
                            ? null
                            : (_isBeans
                                  ? _openBeanSortSheet
                                  : _openGrinderSortSheet),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isBeans
                  ? _BeanList(sortKey: _beanSort, descending: _beanDescending)
                  : _GrinderList(
                      sortKey: _grinderSort,
                      descending: _grinderDescending,
                    ),
            ),
          ],
        ),
        _AddFab(
          label: _isBeans ? '咖啡豆' : '磨豆机',
          onPressed: () => _isBeans
              ? BeanFormPage.show(context)
              : GrinderFormPage.show(context),
        ),
      ],
    );
  }

  /// 打开豆子段的排序弹层。
  Future<void> _openBeanSortSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return _SortSheet<BeanSortKey>(
            keys: BeanSortKey.values,
            selected: _beanSort,
            descending: _beanDescending,
            labelOf: (BeanSortKey key) => key.label,
            hintOf: (BeanSortKey key) => key.hint,
            directionEnabledOf: (BeanSortKey key) => key.directionEnabled,
            onKey: (BeanSortKey key) {
              setState(() {
                _beanSort = key;
                _beanDescending = key.defaultDescending;
              });
              setSheetState(() {});
            },
            onDescending: (bool value) {
              setState(() => _beanDescending = value);
              setSheetState(() {});
            },
            onReset: () {
              setState(() {
                _beanSort = BeanSortKey.defaultOrder;
                _beanDescending = BeanSortKey.defaultOrder.defaultDescending;
              });
              setSheetState(() {});
            },
          );
        },
      ),
    );
  }

  /// 打开磨豆机段的排序弹层。
  Future<void> _openGrinderSortSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return _SortSheet<GrinderSortKey>(
            keys: GrinderSortKey.values,
            selected: _grinderSort,
            descending: _grinderDescending,
            labelOf: (GrinderSortKey key) => key.label,
            hintOf: (GrinderSortKey key) => null,
            directionEnabledOf: (GrinderSortKey key) => key.directionEnabled,
            onKey: (GrinderSortKey key) {
              setState(() {
                _grinderSort = key;
                _grinderDescending = key.defaultDescending;
              });
              setSheetState(() {});
            },
            onDescending: (bool value) {
              setState(() => _grinderDescending = value);
              setSheetState(() {});
            },
            onReset: () {
              setState(() {
                _grinderSort = GrinderSortKey.defaultOrder;
                _grinderDescending =
                    GrinderSortKey.defaultOrder.defaultDescending;
              });
              setSheetState(() {});
            },
          );
        },
      ),
    );
  }
}

/// 豆库页右下角的新增按钮。
///
/// 中栏已被「新加一杯」占用，所以豆库的新增入口单独放这里；
/// 动作跟随当前分段：咖啡豆段新增豆子，磨豆机段新增磨豆机。
///
/// 图标统一用**圆圈加号**：全 App 里「新增一支豆子 / 一台磨豆机」的入口
/// 都长这样（见 `lib/core/icons.dart`）。
class _AddFab extends StatelessWidget {
  const _AddFab({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        child: FloatingActionButton.small(
          heroTag: 'beans.add',
          onPressed: onPressed,
          tooltip: '新增$label',
          child: const Icon(addCircleIcon),
        ),
      ),
    );
  }
}

/// 咖啡豆列表。
class _BeanList extends ConsumerWidget {
  const _BeanList({required this.sortKey, required this.descending});

  final BeanSortKey sortKey;
  final bool descending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(beanListProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) => EmptyState(
            icon: Icons.error_outline,
            title: '出错了',
            message: '豆库加载失败：$error',
          ),
          data: (List<CoffeeBean> beans) {
            if (beans.isEmpty) {
              return EmptyState(
                icon: Icons.coffee_outlined,
                title: '还没有咖啡豆',
                message: '添加第一支豆子，记录产地、烘焙度与余量',
                actionLabel: '添加第一支豆子',
                onAction: () => BeanFormPage.show(context),
              );
            }

            final Map<int, List<BeanBatch>> batchesByBean =
                ref.watch(batchesByBeanProvider).value ??
                const <int, List<BeanBatch>>{};
            // M3-T36：「消耗总量」要冲煮记录里的 `beanUsages`（同一个 provider，
            // 不会多开 drift 流）。**只在需要时才订阅**：外壳用 `IndexedStack`，
            // 豆库页永远在树上 —— 无条件 watch 会让每记一杯都重排 / 重建豆库列表，
            // 即使用户正在记录页、即使当前键是花费或默认。
            final List<BrewLog> logs = sortKey == BeanSortKey.consumedTotal
                ? (ref.watch(brewLogListProvider).value ?? const <BrewLog>[])
                : const <BrewLog>[];

            final List<CoffeeBean> sorted = sortBeans(
              beans,
              batchesByBean,
              logs,
              sortKey,
              descending,
            );

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: sorted.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final CoffeeBean bean = sorted[index];
                final List<BeanBatch> batches =
                    batchesByBean[bean.id] ?? const <BeanBatch>[];
                return _BeanCard(
                  bean: bean,
                  batches: batches,
                  valueText: beanSortValueText(
                    sortKey,
                    _beanSortValue(sortKey, bean, batches, logs),
                  ),
                  onTap: () => BeanFormPage.show(context, bean: bean),
                );
              },
            );
          },
        );
  }
}

/// 磨豆机列表。
class _GrinderList extends ConsumerWidget {
  const _GrinderList({required this.sortKey, required this.descending});

  final GrinderSortKey sortKey;
  final bool descending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<BrewLog> logs =
        ref.watch(brewLogListProvider).value ?? const <BrewLog>[];
    final Map<int?, BrewLog> latestByGrinder = _latestLogByGrinder(logs);

    return ref
        .watch(grinderListProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) => EmptyState(
            icon: Icons.error_outline,
            title: '出错了',
            message: '磨豆机加载失败：$error',
          ),
          data: (List<Grinder> grinders) {
            if (grinders.isEmpty) {
              return EmptyState(
                icon: Icons.tune_outlined,
                title: '还没有磨豆机',
                message: '添加第一台磨豆机，记录刻度、click 与零点',
                actionLabel: '添加第一台磨豆机',
                onAction: () => GrinderFormPage.show(context),
              );
            }

            final List<Grinder> sorted = sortGrinders(
              grinders,
              logs,
              sortKey,
              descending,
            );

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: sorted.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final Grinder grinder = sorted[index];
                return _GrinderCard(
                  grinder: grinder,
                  latestLog: latestByGrinder[grinder.id],
                  useCount: logs
                      .where((BrewLog log) => log.grinderId == grinder.id)
                      .length,
                  onTap: () => GrinderFormPage.show(context, grinder: grinder),
                );
              },
            );
          },
        );
  }
}

/// 咖啡豆卡片。
///
/// 余量、烘焙日期、烘焙度都在批次上，所以这里展示的是**聚合结果**：
/// 总余量、批次数、最近一次烘焙距今天数。
class _BeanCard extends StatelessWidget {
  const _BeanCard({
    required this.bean,
    required this.batches,
    required this.valueText,
    required this.onTap,
  });

  final CoffeeBean bean;

  /// 这支豆子的全部批次（可能为空）。
  final List<BeanBatch> batches;

  /// 当前排序键那一行的文字（默认键时为空串 = 不显示这一行）。
  final String valueText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle? mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    final List<String> metaParts = <String>[
      if (bean.origin != null && bean.origin!.isNotEmpty) bean.origin!,
      if (bean.farm != null && bean.farm!.isNotEmpty) bean.farm!,
      ...bean.processes.map((ProcessMethod m) => m.label),
    ];

    final double total = batches.fold<double>(
      0,
      (sum, b) => sum + b.remainingGrams,
    );
    final bool outOfStock = total <= 0;
    final int? roastAge = _latestRoastAge(batches);
    final List<String> flavors = bean.flavorTags;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (bean.isFavorite) ...<Widget>[
                    Icon(Icons.star_rounded, size: 18, color: colors.primary),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      bean.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '余量 ${_formatNumber(total)} g',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: outOfStock ? colors.error : colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                metaParts.isEmpty ? '暂无产地与处理信息' : metaParts.join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              // M3-T36：排序键的数值行（只显示当前键的值，**不带余量** ——
              // 标题行已经有「余量 N g」了）。默认键时 `valueText` 是空串。
              if (valueText.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  valueText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(_batchText(batches.length, roastAge), style: mutedStyle),
                  if (outOfStock) ...<Widget>[
                    const SizedBox(width: 10),
                    Text(
                      '已用完',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              if (flavors.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  '风味：${flavors.join(' · ')}',
                  style: mutedStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// `2 个批次 · 最近烘焙 5 天前`。
  static String _batchText(int count, int? roastAge) {
    if (count == 0) return '还没有批次';
    final parts = <String>['$count 个批次'];
    if (roastAge != null) {
      if (roastAge < 0) {
        parts.add('烘焙日期在未来');
      } else if (roastAge == 0) {
        parts.add('今天烘焙');
      } else {
        parts.add('最近烘焙 $roastAge 天前');
      }
    }
    return parts.join(' · ');
  }
}

/// 磨豆机卡片（手册 §7）。
///
/// 第一行是 `型号 / 零点 0`（M2.9：当前刻度不再混进标题），
/// 第二行拼 `刀盘 · 每圈 N click · 每 click X µm · 最近使用 yyyy-MM-dd`，
/// 没填的项不占位。
class _GrinderCard extends StatelessWidget {
  const _GrinderCard({
    required this.grinder,
    required this.latestLog,
    required this.useCount,
    required this.onTap,
  });

  final Grinder grinder;

  /// 最近一次用这台磨豆机的记录，用来补上「当前刻度」那一段。
  final BrewLog? latestLog;

  /// 用这台磨豆机冲过几次（M3-T36：常显「用过 N 次」）。
  final int useCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final BrewLog? latest = latestLog;

    final List<String> meta = <String>[
      if (grinder.burrType != null && grinder.burrType!.isNotEmpty)
        grinder.burrType!,
      if (grinder.clicksPerRevolution != null)
        '每圈 ${grinder.clicksPerRevolution} click',
      if (grinder.micronsPerClick != null)
        '每 click ${_formatNumber(grinder.micronsPerClick!)} µm',
      // M3-T36：使用次数常显。0 次对磨豆机是**已知值**（「还没用过」），不是
      // 「没填价格」那种真缺失 —— 所以这里单独措辞，不像其它数值键那样显示 `—`。
      // 排序判据不受影响：`_grinderSortValue` 仍把 0 当缺失（排最后）。
      useCount == 0 ? '还没用过' : '用过 $useCount 次',
      if (latest == null)
        '还没有冲煮记录'
      else
        '最近使用 ${DateFormat('yyyy-MM-dd').format(latest.brewedAt.toLocal())}',
    ];

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                // 第一栏：名称 / 零点（测评反馈）。
                grinder.displayName(showCurrentSetting: false),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                meta.join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (grinder.calibrationNote != null &&
                  grinder.calibrationNote!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  '校准：${grinder.calibrationNote}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 顶部排序入口按钮（M3-T36 方案 A）。
///
/// 真实 `OutlinedButton.icon`：宽度随内容撑开（≈ 文字宽 + 24，含 MD3 最小点击
/// 尺寸），所以「复购次数」「使用次数」都放得下，不需要写死宽度。
class _SortButton extends StatelessWidget {
  const _SortButton({required this.label, required this.onPressed});

  final String label;

  /// null = 空态置灰（仍显示）。
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.swap_vert, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}

/// 排序弹层：单选键 + 升/降序 + 重置为默认。
class _SortSheet<T> extends StatelessWidget {
  const _SortSheet({
    required this.keys,
    required this.selected,
    required this.descending,
    required this.labelOf,
    required this.hintOf,
    required this.directionEnabledOf,
    required this.onKey,
    required this.onDescending,
    required this.onReset,
  });

  final List<T> keys;
  final T selected;
  final bool descending;
  final String Function(T key) labelOf;
  final String? Function(T key) hintOf;
  final bool Function(T key) directionEnabledOf;
  final ValueChanged<T> onKey;
  final ValueChanged<bool> onDescending;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool directionEnabled = directionEnabledOf(selected);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
              child: Text(
                '排序方式',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            RadioGroup<T>(
              groupValue: selected,
              onChanged: (T? value) {
                if (value != null) onKey(value);
              },
              child: Column(
                children: <Widget>[
                  for (final T key in keys)
                    RadioListTile<T>(
                      value: key,
                      title: Text(labelOf(key)),
                      subtitle: hintOf(key) == null ? null : Text(hintOf(key)!),
                      dense: true,
                    ),
                ],
              ),
            ),
            const Divider(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: Row(
                children: <Widget>[
                  Text('顺序', style: theme.textTheme.titleSmall),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<bool>(
                      expandedInsets: EdgeInsets.zero,
                      showSelectedIcon: false,
                      segments: const <ButtonSegment<bool>>[
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('升序'),
                          icon: Icon(Icons.arrow_upward, size: 16),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('降序'),
                          icon: Icon(Icons.arrow_downward, size: 16),
                        ),
                      ],
                      selected: <bool>{descending},
                      // null = 置灰（默认键与型号禁用方向）。
                      onSelectionChanged: directionEnabled
                          ? (Set<bool> selection) =>
                                onDescending(selection.first)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('重置为默认'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 整数的排序/显示数值；null 与 0 都算**缺失**（卡片显示 `—`，排序排最后）。
double? _beanSortValue(
  BeanSortKey key,
  CoffeeBean bean,
  List<BeanBatch> batches,
  List<BrewLog> logs,
) {
  switch (key) {
    case BeanSortKey.defaultOrder:
      return null;
    case BeanSortKey.purchaseTotal:
      return _nullIfZero(_sumOf(batches.map((BeanBatch b) => b.initialGrams)));
    case BeanSortKey.consumedTotal:
      return _nullIfZero(
        _sumOf(
          logs
              .expand((BrewLog log) => log.beanUsages)
              .where((BeanUsage u) => u.beanId == bean.id)
              .map((BeanUsage u) => u.doseGrams),
        ),
      );
    case BeanSortKey.netDecrease:
      return _nullIfZero(
        _sumOf(
          batches
              .where((BeanBatch b) => b.initialGrams != null)
              .map((BeanBatch b) => b.initialGrams! - b.remainingGrams),
        ),
      );
    case BeanSortKey.spend:
      return _nullIfZero(_sumOf(batches.map((BeanBatch b) => b.price)));
    case BeanSortKey.unitPrice:
      final double? spend = _nullIfZero(
        _sumOf(batches.map((BeanBatch b) => b.price)),
      );
      final double? goods = _nullIfZero(
        _sumOf(batches.map((BeanBatch b) => b.initialGrams)),
      );
      if (spend == null || goods == null) return null;
      return spend / goods * 100; // 元 / 100 g
    case BeanSortKey.repurchaseCount:
      return batches.isEmpty ? null : batches.length.toDouble();
  }
}

/// 卡片上那一行数值（只显示当前排序键的值，**不含余量** —— 用户裁决 H）。
String beanSortValueText(BeanSortKey key, double? value) {
  final String n = value == null ? '—' : _formatNumber(value);
  switch (key) {
    case BeanSortKey.defaultOrder:
      return '';
    case BeanSortKey.purchaseTotal:
      return '共 $n g';
    case BeanSortKey.consumedTotal:
      return '用了 $n g';
    case BeanSortKey.netDecrease:
      return '少了 $n g';
    case BeanSortKey.spend:
      return '¥$n';
    case BeanSortKey.unitPrice:
      return '¥$n / 100g';
    case BeanSortKey.repurchaseCount:
      return '买过 $n 次';
  }
}

/// 磨豆机排序用的数值（型号走字符串比较，不走这里）。
double? _grinderSortValue(
  GrinderSortKey key,
  Grinder grinder,
  List<BrewLog> logs,
) {
  switch (key) {
    case GrinderSortKey.defaultOrder:
    case GrinderSortKey.model:
      return null;
    case GrinderSortKey.useCount:
      final int count = logs
          .where((BrewLog log) => log.grinderId == grinder.id)
          .length;
      return count == 0 ? null : count.toDouble();
    case GrinderSortKey.lastUsed:
      DateTime? latest;
      for (final BrewLog log in logs) {
        if (log.grinderId != grinder.id) continue;
        if (latest == null || log.brewedAt.isAfter(latest)) {
          latest = log.brewedAt;
        }
      }
      return latest?.millisecondsSinceEpoch.toDouble();
  }
}

double _sumOf(Iterable<double?> values) {
  double sum = 0;
  for (final double? value in values) {
    if (value != null) sum += value;
  }
  return sum;
}

/// 0 与「没有任何数据」都归为缺失（卡片显示 `—`、排序排最后）。
double? _nullIfZero(double value) => value == 0 ? null : value;

/// 按当前键排序豆子；同值保持**仓储顺序**（稳定），缺失值永远排最后。
List<CoffeeBean> sortBeans(
  List<CoffeeBean> beans,
  Map<int, List<BeanBatch>> batchesByBean,
  List<BrewLog> logs,
  BeanSortKey key,
  bool descending,
) {
  if (key == BeanSortKey.defaultOrder) return beans;

  final List<({CoffeeBean bean, double? value, int index})> rows =
      <({CoffeeBean bean, double? value, int index})>[
        for (int i = 0; i < beans.length; i++)
          (
            bean: beans[i],
            value: _beanSortValue(
              key,
              beans[i],
              batchesByBean[beans[i].id] ?? const <BeanBatch>[],
              logs,
            ),
            index: i,
          ),
      ];

  rows.sort((a, b) {
    final bool aMissing = a.value == null;
    final bool bMissing = b.value == null;
    if (aMissing || bMissing) {
      if (aMissing && bMissing) return a.index.compareTo(b.index);
      return aMissing ? 1 : -1; // 缺失排最后（升序降序都一样）
    }
    final int cmp = a.value!.compareTo(b.value!);
    return cmp != 0 ? (descending ? -cmp : cmp) : a.index.compareTo(b.index);
  });

  return <CoffeeBean>[for (final row in rows) row.bean];
}

/// 按当前键排序磨豆机；型号走 `brand + model` 字典序。
List<Grinder> sortGrinders(
  List<Grinder> grinders,
  List<BrewLog> logs,
  GrinderSortKey key,
  bool descending,
) {
  if (key == GrinderSortKey.defaultOrder) return grinders;

  final List<({Grinder grinder, double? value, String text, int index})> rows =
      <({Grinder grinder, double? value, String text, int index})>[
        for (int i = 0; i < grinders.length; i++)
          (
            grinder: grinders[i],
            value: _grinderSortValue(key, grinders[i], logs),
            text: '${grinders[i].brand} ${grinders[i].model}',
            index: i,
          ),
      ];

  rows.sort((a, b) {
    if (key == GrinderSortKey.model) {
      final int cmp = a.text.compareTo(b.text);
      return cmp != 0 ? (descending ? -cmp : cmp) : a.index.compareTo(b.index);
    }
    final bool aMissing = a.value == null;
    final bool bMissing = b.value == null;
    if (aMissing || bMissing) {
      if (aMissing && bMissing) return a.index.compareTo(b.index);
      return aMissing ? 1 : -1;
    }
    final int cmp = a.value!.compareTo(b.value!);
    return cmp != 0 ? (descending ? -cmp : cmp) : a.index.compareTo(b.index);
  });

  return <Grinder>[for (final row in rows) row.grinder];
}

/// 每台磨豆机取最近一条记录。
Map<int?, BrewLog> _latestLogByGrinder(List<BrewLog> logs) {
  final Map<int?, BrewLog> latest = <int?, BrewLog>{};
  for (final BrewLog log in logs) {
    final int? grinderId = log.grinderId;
    if (grinderId == null) continue;
    final BrewLog? existing = latest[grinderId];
    if (existing == null || log.brewedAt.isAfter(existing.brewedAt)) {
      latest[grinderId] = log;
    }
  }
  return latest;
}

/// 最近一个批次的烘焙日期距今天数；没有烘焙日期时返回 null。
///
/// 烘焙日期在批次上，所以要从批次列表里取最新的那个。
int? _latestRoastAge(List<BeanBatch> batches) {
  final List<DateTime> dates = batches
      .map((b) => b.roastDate)
      .whereType<DateTime>()
      .toList(growable: false);
  if (dates.isEmpty) return null;
  dates.sort((a, b) => b.compareTo(a));
  return DateTime.now().difference(dates.first).inDays;
}

/// 整数不显示小数点，其余保留一位。
String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
