import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/empty_state.dart';
import '../../data/providers.dart';
import '../../domain/entities.dart';
import '../stats/stats_page.dart';
import 'brew_log_form_page.dart';

/// 记录 tab：冲煮时间线（手册 §5.1）。
class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key});

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// 0 = 时间线，1 = 统计（统计已并入本页，用户确认的 dock 方案）。
  int _tab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 下拉刷新：数据本身是 Drift 实时流，这里重新订阅一次以保证手动刷新有反馈。
  Future<void> _handleRefresh() async {
    ref.invalidate(brewLogListProvider);
    try {
      await ref.read(brewLogListProvider.future);
    } catch (_) {
      // 读取失败时列表区域会显示错误状态，这里只负责收起刷新指示器。
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  /// 内存过滤：豆子名 / 磨豆机 / 方法 / 备注 / 评分。
  List<BrewLog> _applyFilter(
    List<BrewLog> logs,
    Map<int?, String> beanNames,
    Map<int?, Grinder> grinders,
  ) {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) return logs;
    final int? ratingQuery = int.tryParse(query);

    return logs
        .where((BrewLog log) {
          final Grinder? grinder = grinders[log.grinderId];
          final String haystack = <String>[
            // 拼配时 `beanLabel` 是「A + B」，只按主豆搜会漏掉第二支。
            log.beanLabel ?? beanNames[log.beanId] ?? '',
            log.method.label,
            if (grinder != null) grinder.brand,
            if (grinder != null) grinder.model,
            log.notes ?? '',
          ].join(' ').toLowerCase();

          if (haystack.contains(query)) return true;
          return ratingQuery != null && log.rating == ratingQuery;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<BrewLog>> logsAsync = ref.watch(brewLogListProvider);

    final Map<int?, String> beanNames = <int?, String>{
      for (final CoffeeBean bean
          in ref.watch(beanListProvider).value ?? const <CoffeeBean>[])
        bean.id: bean.name,
    };
    final Map<int?, Grinder> grinders = <int?, Grinder>{
      for (final Grinder grinder
          in ref.watch(grinderListProvider).value ?? const <Grinder>[])
        grinder.id: grinder,
    };

    return Column(
      children: <Widget>[
        _buildTabSelector(),
        if (_tab == 0) ...<Widget>[
          _buildSearchField(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: logsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace stackTrace) => _ErrorView(
                  message: '记录加载失败：$error',
                  onRetry: _handleRefresh,
                ),
                data: (List<BrewLog> logs) =>
                    _buildTimeline(logs, beanNames, grinders),
              ),
            ),
          ),
        ] else
          const Expanded(child: StatsView()),
      ],
    );
  }

  /// 时间线 / 统计 页签。
  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SegmentedButton<int>(
        expandedInsets: EdgeInsets.zero,
        showSelectedIcon: false,
        segments: const <ButtonSegment<int>>[
          ButtonSegment<int>(
            value: 0,
            label: Text('时间线'),
            icon: Icon(Icons.history),
          ),
          ButtonSegment<int>(
            value: 1,
            label: Text('统计'),
            icon: Icon(Icons.insights_outlined),
          ),
        ],
        selected: <int>{_tab},
        onSelectionChanged: (Set<int> selection) =>
            setState(() => _tab = selection.first),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (String value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: '搜索豆子 / 磨豆机 / 方法 / 评分',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  onPressed: _clearSearch,
                  tooltip: '清空搜索',
                  icon: const Icon(Icons.clear),
                ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(
    List<BrewLog> logs,
    Map<int?, String> beanNames,
    Map<int?, Grinder> grinders,
  ) {
    final List<BrewLog> visible = _applyFilter(logs, beanNames, grinders);

    if (visible.isEmpty) {
      // 空状态也要能下拉刷新，所以塞进可滚动区域而不是直接返回 Center。
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: logs.isEmpty
                ? const EmptyState(
                    icon: Icons.local_cafe_outlined,
                    title: '还没有冲煮记录',
                    message: '点击右下角 + 记录第一杯',
                  )
                : const EmptyState(
                    icon: Icons.search_off_outlined,
                    title: '没有匹配的记录',
                    message: '换个豆子名、方法或评分试试',
                  ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: visible.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final BrewLog log = visible[index];
        return _BrewLogCard(
          log: log,
          beanName: beanNames[log.beanId],
          grinder: grinders[log.grinderId],
          onTap: () => BrewLogFormPage.show(context, existing: log),
        );
      },
    );
  }
}

/// 单条冲煮记录卡片：豆子名、方法、刻度、粉水、水温、时间、评分、冲煮时间。
class _BrewLogCard extends StatelessWidget {
  const _BrewLogCard({
    required this.log,
    required this.beanName,
    required this.grinder,
    required this.onTap,
  });

  final BrewLog log;
  final String? beanName;
  final Grinder? grinder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle? mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final String doseWater = _doseWaterLabel(log);
    final double? waterTemp = log.waterTemp;
    final String? time = log.formattedTime;

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
                      // 拼配时用「A + B」，没有用量行才退回主豆名。
                      log.beanLabel ?? beanName ?? '未指定豆子',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RatingStars(rating: log.rating),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _MethodChip(label: log.method.label),
                  Text(_grindLabel(log, grinder), style: mutedStyle),
                ],
              ),
              if (log.isBlend) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  '拼配 ${log.beanUsages.map((BeanUsage u) => '${_formatNumber(u.doseGrams)} g').join(' + ')}',
                  style: mutedStyle,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: <Widget>[
                  _Metric(icon: Icons.scale_outlined, text: doseWater),
                  if (waterTemp != null)
                    _Metric(
                      icon: Icons.thermostat_outlined,
                      text: '${_formatNumber(waterTemp)} ℃',
                    ),
                  if (time != null)
                    _Metric(icon: Icons.timer_outlined, text: time),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(_formatBrewTime(log.brewedAt), style: mutedStyle),
                  if (log.isBest) ...<Widget>[
                    const SizedBox(width: 10),
                    _BestBadge(colors: colors),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 方法标签。
class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colors.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// 「最佳参数」标记（手册 §8 调磨对比）。
class _BestBadge extends StatelessWidget {
  const _BestBadge({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '最佳',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colors.onTertiaryContainer),
      ),
    );
  }
}

/// 评分 1–5 星；未评分时给出文字提示。
class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final int? rating;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int? value = rating;

    if (value == null) {
      return Text(
        '未评分',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: colors.onSurfaceVariant),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 1; i <= 5; i++)
          Icon(
            i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: i <= value ? colors.primary : colors.outlineVariant,
          ),
      ],
    );
  }
}

/// 图标 + 文字的小号指标。
class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 列表加载失败时的提示。
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: '出错了',
      message: message,
      actionLabel: '重试',
      onAction: onRetry,
    );
  }
}

/// 研磨刻度：有磨豆机时走 `Grinder.displayName`（手册 §7 展示格式）。
String _grindLabel(BrewLog log, Grinder? grinder) {
  final double? setting = log.grindSetting;
  final int? clicks = log.grindClicks;

  if (grinder != null) {
    if (setting == null && clicks == null) return grinder.displayName();
    return grinder.displayName(grindSetting: setting, clicks: clicks);
  }

  final List<String> parts = <String>[];
  if (setting != null) parts.add('刻度 ${_formatNumber(setting)}');
  if (clicks != null) parts.add('$clicks click');
  return parts.isEmpty ? '未记录研磨刻度' : parts.join(' · ');
}

/// 粉量 / 水量 / 粉水比。
String _doseWaterLabel(BrewLog log) {
  final double? dose = log.doseGrams;
  final double? water = log.waterGrams;
  if (dose == null && water == null) return '未记录粉水';

  final List<String> parts = <String>[];
  if (dose != null) parts.add('粉 ${_formatNumber(dose)} g');
  if (water != null) parts.add('水 ${_formatNumber(water)} g');
  final double? ratio = log.effectiveRatio;
  if (ratio != null) parts.add('1:${_formatNumber(ratio)}');
  return parts.join(' · ');
}

/// 冲煮时间：近 7 天用相对说法，更早用完整日期。
String _formatBrewTime(DateTime value) {
  final DateTime local = value.toLocal();
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(local.year, local.month, local.day);
  final int days = today.difference(day).inDays;
  final String time = DateFormat('HH:mm').format(local);

  if (days == 0) return '今天 $time';
  if (days == 1) return '昨天 $time';
  if (days > 1 && days < 7) return '$days 天前 $time';
  return DateFormat('yyyy-MM-dd HH:mm').format(local);
}

/// 整数不显示小数点，其余保留一位。
String _formatNumber(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1);
}
