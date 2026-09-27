import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/empty_state.dart';
import '../../data/providers.dart';
import '../../domain/entities.dart';
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
/// 用 [Align] 定位而不是 Scaffold 的 FAB 槽位，避免和外壳那个大 + 号冲突。
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
          child: const Icon(Icons.add),
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

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: beans.length,
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) => _BeanCard(
                bean: beans[index],
                onTap: () => BeanFormPage.show(context, bean: beans[index]),
              ),
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

/// 咖啡豆卡片：名称、产地、烘焙度、余量、烘焙距今天数。
class _BeanCard extends StatelessWidget {
  const _BeanCard({required this.bean, required this.onTap});

  final CoffeeBean bean;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle? mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    final List<String> originParts = <String>[
      if (bean.origin != null && bean.origin!.isNotEmpty) bean.origin!,
      if (bean.process != null) bean.process!.label,
      if (bean.roastLevel != null) bean.roastLevel!.label,
    ];
    final String roastText = _roastAgeText(bean);
    final bool outOfStock = bean.remainingGrams <= 0;
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
                    '余量 ${_formatNumber(bean.remainingGrams)} g',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: outOfStock ? colors.error : colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                originParts.isEmpty ? '暂无产地与烘焙信息' : originParts.join(' · '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.local_fire_department_outlined,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(roastText, style: mutedStyle),
                  if (outOfStock) ...<Widget>[
                    const SizedBox(width: 10),
                    Text(
                      '余量不足',
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
                grinder.displayName(
                  grindSetting: latest?.grindSetting,
                  clicks: latest?.grindClicks,
                ),
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

/// 烘焙日期距今天数（实体自带 `ageInDays`，无烘焙日期时返回 null）。
String _roastAgeText(CoffeeBean bean) {
  final int? days = bean.ageInDays();
  if (days == null) return '未记录烘焙日期';
  if (days < 0) return '烘焙日期在未来';
  if (days == 0) return '今天烘焙';
  if (days == 1) return '昨天烘焙';
  return '烘焙 $days 天前';
}

/// 整数不显示小数点，其余保留一位。
String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
