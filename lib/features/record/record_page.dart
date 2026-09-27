import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/icons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/swipe_actions.dart';
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

  /// 只看收藏（记录页的「收藏」入口）。
  bool _favoritesOnly = false;

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

  /// 收藏 / 取消收藏一条记录的参数。
  Future<void> _toggleFavorite(BrewLog log) async {
    final int? id = log.id;
    if (id == null) return;
    final bool next = !log.isFavorite;
    await ref.read(brewLogRepositoryProvider).setFavorite(id, next);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(next ? '已收藏这套参数' : '已取消收藏'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// 右滑删除：先确认（与表单里的删除文案保持一致），删完不回补余量。
  Future<void> _confirmDelete(BrewLog log) async {
    final int? id = log.id;
    if (id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: const Text('删除后无法恢复。已扣减的豆子余量不会自动回补。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(brewLogRepositoryProvider).delete(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('已删除这条记录'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  /// 内存过滤：豆子名 / 磨豆机 / 方法 / 备注 / 评分。
  List<BrewLog> _applyFilter(
    List<BrewLog> logs,
    Map<int?, String> beanNames,
    Map<int?, Grinder> grinders,
  ) {
    final String query = _query.trim().toLowerCase();
    final int? ratingQuery = int.tryParse(query);

    return logs
        .where((BrewLog log) {
          // 收藏筛选要排在「搜索为空就全返回」的短路**前面**，
          // 否则切到「收藏」而搜索框是空的时候等于没过滤。
          if (_favoritesOnly && !log.isFavorite) return false;
          if (query.isEmpty) return true;

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
          _buildFilterChips(),
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

  /// 记录页的「收藏」入口：切到只看收藏。
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: <Widget>[
          FilterChip(
            key: const Key('record.filter.all'),
            label: const Text('全部'),
            selected: !_favoritesOnly,
            showCheckmark: false,
            onSelected: (_) => setState(() => _favoritesOnly = false),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const Key('record.filter.favorite'),
            avatar: Icon(
              _favoritesOnly ? favoriteFilledIcon : favoriteIcon,
              size: 18,
            ),
            label: const Text('收藏'),
            selected: _favoritesOnly,
            showCheckmark: false,
            onSelected: (bool value) => setState(() => _favoritesOnly = value),
          ),
        ],
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
                    message: '点击底部中间的 + 记录第一杯',
                  )
                : EmptyState(
                    icon: _favoritesOnly
                        ? favoriteIcon
                        : Icons.search_off_outlined,
                    title: _favoritesOnly ? '还没有收藏的参数' : '没有匹配的记录',
                    message: _favoritesOnly
                        ? '在记录上向左滑动，点「收藏」就能存下这套参数'
                        : '换个豆子名、方法或评分试试',
                  ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: visible.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final BrewLog log = visible[index];
        return SwipeActions(
          key: ValueKey<int?>(log.id),
          semanticLabel: '${log.beanLabel ?? '未指定豆子'} 的快捷操作',
          actions: <SwipeAction>[
            SwipeAction(
              icon: log.isFavorite ? favoriteFilledIcon : favoriteIcon,
              label: log.isFavorite ? '取消收藏' : '收藏',
              onPressed: () => _toggleFavorite(log),
            ),
            SwipeAction(
              icon: Icons.delete_outline,
              label: '删除',
              color: Theme.of(context).colorScheme.error,
              onPressed: () => _confirmDelete(log),
            ),
          ],
          child: _BrewLogCard(
            log: log,
            beanName: beanNames[log.beanId],
            grinder: grinders[log.grinderId],
            onTap: () => BrewLogFormPage.show(context, existing: log),
          ),
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
                  if (log.isFavorite) ...<Widget>[
                    Icon(favoriteFilledIcon, size: 18, color: colors.primary),
                    const SizedBox(width: 4),
                  ],
                  // 第一行 = 所有豆名 + 方法 chip + 评分星。
                  // chip 用 `Flexible` 紧跟在豆名之后（豆名太长就省略），
                  // 多余空白留在 chip 之后，星标因此仍在最右。
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Flexible(
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
                        const SizedBox(width: 6),
                        _MethodChip(label: log.method.label),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RatingStars(rating: log.rating),
                ],
              ),
              const SizedBox(height: 10),
              _grindLabel(log, grinder).isEmpty
                  ? const SizedBox.shrink()
                  : Text(_grindLabel(log, grinder), style: mutedStyle),
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
