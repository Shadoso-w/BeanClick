import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/entities.dart';

/// 统计视图。
///
/// 已并入「记录」页的第二个页签（用户确认的 dock 方案），
/// 因此自身不带 Scaffold，只渲染内容。
///
/// M1 只给占位说明 + 几个内存里算得出的基础数字；
/// 真正的图表属 P1，按「评分趋势 → 参数对比 → 消耗」的顺序实现（手册 §6.1）。
class StatsView extends ConsumerWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<BrewLog> logs =
        ref.watch(brewLogListProvider).value ?? const <BrewLog>[];

    final List<BrewLog> ratedLogs = logs
        .where((BrewLog log) => log.rating != null)
        .toList(growable: false);
    final double? averageRating = ratedLogs.isEmpty
        ? null
        : ratedLogs.fold<int>(
                0,
                (int sum, BrewLog log) => sum + (log.rating ?? 0),
              ) /
              ratedLogs.length;
    final int beanCount = logs
        .map((BrewLog log) => log.beanId)
        .whereType<int>()
        .toSet()
        .length;
    final int grinderCount = logs
        .map((BrewLog log) => log.grinderId)
        .whereType<int>()
        .toSet()
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: <Widget>[
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 96,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          children: <Widget>[
            _StatCard(
              icon: Icons.receipt_long_outlined,
              label: '总记录数',
              value: '${logs.length}',
            ),
            _StatCard(
              icon: Icons.star_outline_rounded,
              label: '平均评分',
              value: averageRating == null
                  ? '—'
                  : averageRating.toStringAsFixed(1),
            ),
            _StatCard(
              icon: Icons.coffee_outlined,
              label: '使用过的豆子',
              value: '$beanCount',
            ),
            _StatCard(
              icon: Icons.tune_outlined,
              label: '使用过的磨豆机',
              value: '$grinderCount',
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (logs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '还没有冲煮记录，先去「记录」页冲第一杯。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const _StatsRoadmapCard(),
      ],
    );
  }
}

/// 单个统计数字。
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 16, color: colors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 统计实现顺序说明（手册 §6.1）。
class _StatsRoadmapCard extends StatelessWidget {
  const _StatsRoadmapCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.insights_outlined, size: 18, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  '统计蓝图（P1 实现）',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '统计整体属 P1。M1 只放基础计数，图表按固定顺序落地：'
              '先回答「好不好喝」，再回答「怎么调」，最后算「消耗了多少」。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            const _RoadmapStep(
              index: 1,
              title: '评分趋势',
              detail: '单折线图：X 轴时间、Y 轴评分。实现最轻，先落地。',
            ),
            const SizedBox(height: 12),
            const _RoadmapStep(
              index: 2,
              title: '参数对比',
              detail: '同一支豆 + 同一台磨豆机，按研磨刻度排序的对比表，对应「调磨对比」。',
            ),
            const SizedBox(height: 12),
            const _RoadmapStep(
              index: 3,
              title: '消耗',
              detail: '按时间区间的豆子消耗克数与花费估算。',
            ),
          ],
        ),
      ),
    );
  }
}

/// 蓝图里的一步。
class _RoadmapStep extends StatelessWidget {
  const _RoadmapStep({
    required this.index,
    required this.title,
    required this.detail,
  });

  final int index;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
