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

/// 豆库 tab：咖啡豆 / 磨豆机 分段（手册 §5.2）。
class BeansPage extends StatefulWidget {
  const BeansPage({super.key});

  @override
  State<BeansPage> createState() => _BeansPageState();
}

class _BeansPageState extends State<BeansPage> {
  /// 0 = 咖啡豆，1 = 磨豆机。
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final bool isBeans = _segment == 0;

    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
            Expanded(child: isBeans ? const _BeanList() : const _GrinderList()),
          ],
        ),
        _AddFab(
          label: isBeans ? '咖啡豆' : '磨豆机',
          onPressed: () => isBeans
              ? BeanFormPage.show(context)
              : GrinderFormPage.show(context),
        ),
      ],
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
  const _BeanList();

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

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: beans.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final CoffeeBean bean = beans[index];
                return _BeanCard(
                  bean: bean,
                  batches: batchesByBean[bean.id] ?? const <BeanBatch>[],
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
  const _GrinderList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<int?, BrewLog> latestByGrinder = _latestLogByGrinder(
      ref.watch(brewLogListProvider).value ?? const <BrewLog>[],
    );

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

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: grinders.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final Grinder grinder = grinders[index];
                return _GrinderCard(
                  grinder: grinder,
                  latestLog: latestByGrinder[grinder.id],
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
    required this.onTap,
  });

  final CoffeeBean bean;

  /// 这支豆子的全部批次（可能为空）。
  final List<BeanBatch> batches;
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

/// 磨豆机卡片：手册 §7 展示格式 `C40 / 22 click / 零点 0`。
class _GrinderCard extends StatelessWidget {
  const _GrinderCard({
    required this.grinder,
    required this.latestLog,
    required this.onTap,
  });

  final Grinder grinder;

  /// 最近一次用这台磨豆机的记录，用来补上「当前刻度」那一段。
  final BrewLog? latestLog;
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
