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

  /// 只看某个收藏夹（v8 / T38）；null = 没按夹过滤。
  ///
  /// 与 [_favoritesOnly] 互斥：点「收藏」清掉夹、点某个夹清掉「收藏」；
  /// 「全部」两个都清。**`is_favorite` 仍是"是否收藏"的唯一判据**，
  /// 夹只表达"这条收藏还放进了哪里"。
  int? _groupId;

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

  /// 收藏 / 取消收藏 / 加入收藏夹（v8 / T38 裁决 D=②）。
  ///
  /// 未收藏 → 先标收藏，再弹「加入哪个收藏夹」多选面板（可以一个都不选 =
  /// 收藏但未分组）；已收藏 → 取消收藏，**归属保留**，未收藏的记录靠读侧
  /// 不变量不再出现在夹里（见 [_applyFilter]）。
  Future<void> _toggleFavorite(BrewLog log) async {
    final int? id = log.id;
    if (id == null) return;
    final repo = ref.read(brewLogRepositoryProvider);

    if (log.isFavorite) {
      // **不清空归属**（B4）：`brew_logs.is_favorite` 与关联表是两套数据，
      // 空集合会不可撤销地丢掉用户的分组。读侧已守住不变量
      // （见 [_applyFilter]：夹筛选要求"收藏且在夹里"），所以这里不必破坏数据。
      await repo.setFavorite(id, false);
      if (!mounted) return;
      _showMessage('已取消收藏');
      return;
    }

    await repo.setFavorite(id, true);
    if (!mounted) return;
    await _pickGroupsFor(log);
    if (!mounted) return;
    _showMessage('已收藏这套参数');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  /// 「加入哪个收藏夹」：多选；返回 null = 用户直接关掉了面板（不改归属）。
  ///
  /// 三个入口共用：左滑「收藏」之后、左滑「分组」（已收藏）、点卡片星标（B3）。
  Future<void> _pickGroupsFor(BrewLog log) async {
    final int? brewLogId = log.id;
    if (brewLogId == null) return;
    final Set<int> selected = await ref
        .read(brewLogRepositoryProvider)
        .getFavoriteGroupIdsOf(brewLogId);
    if (!mounted) return;

    final Set<int>? result = await showModalBottomSheet<Set<int>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => _GroupPickSheet(initial: selected),
    );
    if (result == null || !mounted) return;
    await ref
        .read(brewLogRepositoryProvider)
        .setFavoriteGroups(brewLogId, result);
  }

  /// 「管理收藏夹」：建 / 改名 / 删。
  Future<void> _openManageGroups() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => _ManageGroupsSheet(
        onCreate: _createGroup,
        onRename: _renameGroup,
        onDelete: _deleteGroup,
      ),
    );
  }

  Future<void> _createGroup() async {
    await guardGroupWrite(context, () async {
      await createFavoriteGroupDialog(context, ref);
    });
  }

  Future<void> _renameGroup(FavoriteGroup group) async {
    final int? id = group.id;
    if (id == null) return;
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          _GroupNameDialog(title: '给收藏夹改名', initial: group.name),
    );
    if (name == null || !mounted) return;
    await guardGroupWrite(
      context,
      () => ref.read(brewLogRepositoryProvider).renameFavoriteGroup(id, name),
    );
  }

  Future<void> _deleteGroup(FavoriteGroup group) async {
    final int? id = group.id;
    if (id == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删掉这个收藏夹？'),
        content: const Text('只会删掉「夹」本身，记录还在、收藏状态也不变。'),
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
    await guardGroupWrite(
      context,
      () => ref.read(brewLogRepositoryProvider).deleteFavoriteGroup(id),
    );
    if (!mounted) return;
    // 删的正是当前筛选的夹 → 回到「全部」。
    if (_groupId == id) setState(() => _groupId = null);
  }

  /// 右滑删除：先确认（与表单里的删除文案保持一致）；删完会把已扣的余量按原批次回补。
  Future<void> _confirmDelete(BrewLog log) async {
    final int? id = log.id;
    if (id == null) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: const Text('删除后无法恢复。已扣减的豆子余量会自动回补。'),
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
          // 收藏夹筛选同理：`favoriteGroupIds` 由仓储附着，零新查询。
          //
          // **必须同时要求 `isFavorite`**（B4）：表单里的「收藏这套参数」开关走
          // `repo.save()`，而 `save()` 从不碰关联表 —— 于是"已分组 → 表单里关掉
          // 收藏 → 保存"会留下"未收藏但在夹里"的记录。这里在读侧守住不变量：
          // 夹里只显示**收藏且归属该夹**的记录。
          if (_groupId != null &&
              (!log.isFavorite || !log.favoriteGroupIds.contains(_groupId))) {
            return false;
          }
          if (query.isEmpty) return true;

          final Grinder? grinder = grinders[log.grinderId];
          final String haystack = <String>[
            // 拼配时 `beanLabel` 是「A + B」，只按主豆搜会漏掉第二支。
            log.beanLabel ?? beanNames[log.beanId] ?? '',
            // 必须用 `methodDisplay`：自定义方法（如「拿铁」）的枚举原始标签
            // 一律是「其他」，用 `label` 会让它搜不到（M3-T29）。
            log.methodDisplay,
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

  /// 记录页的筛选 chip 行：`全部 / 收藏 / 各收藏夹… / 管理`。
  ///
  /// v8 / T38 裁决 D=①：
  /// - **前两个 chip 的 key、文案、bool 语义一字不变**（`record.filter.all` /
  ///   `record.filter.favorite`）—— 收藏夹只是**追加**在后面，所以既有断言不受影响；
  /// - 夹多了要**能横滑**（`管理` 随行滚动，用户选定）。
  Widget _buildFilterChips() {
    final List<FavoriteGroup> groups =
        ref.watch(favoriteGroupsProvider).value ?? const <FavoriteGroup>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            FilterChip(
              key: const Key('record.filter.all'),
              label: const Text('全部'),
              selected: !_favoritesOnly && _groupId == null,
              showCheckmark: false,
              onSelected: (_) => setState(() {
                _favoritesOnly = false;
                _groupId = null;
              }),
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
              onSelected: (bool value) => setState(() {
                _favoritesOnly = value;
                _groupId = null;
              }),
            ),
            for (final FavoriteGroup group in groups) ...<Widget>[
              const SizedBox(width: 8),
              FilterChip(
                key: Key('record.filter.group.${group.id}'),
                avatar: Icon(
                  _groupId == group.id
                      ? Icons.folder_rounded
                      : Icons.folder_outlined,
                  size: 18,
                ),
                label: Text(group.name),
                selected: _groupId == group.id,
                showCheckmark: false,
                onSelected: (bool value) => setState(() {
                  _groupId = value ? group.id : null;
                  _favoritesOnly = false;
                }),
              ),
            ],
            const SizedBox(width: 8),
            ActionChip(
              key: const Key('record.filter.manage'),
              avatar: const Icon(Icons.create_new_folder_outlined, size: 18),
              label: const Text('管理'),
              onPressed: _openManageGroups,
            ),
          ],
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
      // 选中某个收藏夹时的空态（`_favoritesOnly` 的两种文案**保持原样**）。
      final FavoriteGroup? group = _groupId == null
          ? null
          : (ref.watch(favoriteGroupsProvider).value ?? const <FavoriteGroup>[])
                .where((FavoriteGroup g) => g.id == _groupId)
                .firstOrNull;
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
                        : (_groupId != null
                              ? Icons.folder_outlined
                              : Icons.search_off_outlined),
                    title: _favoritesOnly
                        ? '还没有收藏的参数'
                        : (group != null ? '「${group.name}」还是空的' : '没有匹配的记录'),
                    message: _favoritesOnly
                        ? '在记录上向左滑动，点「收藏」就能存下这套参数'
                        : (group != null
                              ? '在记录上向左滑动点「收藏」，就能把它放进这个收藏夹'
                              : '换个豆子名、方法或评分试试'),
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
            if (log.isFavorite)
              // B3：已收藏的记录也要能**不取消收藏**就改归属。
              SwipeAction(
                icon: Icons.create_new_folder_outlined,
                label: '分组',
                onPressed: () => _pickGroupsFor(log),
              ),
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
            onStarTap: () => _pickGroupsFor(log),
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
    required this.onStarTap,
  });

  final BrewLog log;
  final String? beanName;
  final Grinder? grinder;
  final VoidCallback onTap;

  /// 点星标 = 改这条记录的分组归属（B3：不取消收藏也能改）。
  final VoidCallback onStarTap;

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
                    // B3：星标可点 = 直接改归属（不必"取消收藏 → 再收藏 → 重选"）。
                    //
                    // 热区 48×48（Material 最小可点尺寸）：之前只有 Icon + 2dp padding
                    // ≈ 22dp，MIUI 上手指容易点不中。图标本身仍是 18dp、贴顶对齐，
                    // 所以**只有"已收藏"的卡片**第一行会因此变成 48dp 高。
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        key: Key('record.star.${log.id}'),
                        tooltip: '加入收藏夹',
                        padding: EdgeInsets.zero,
                        alignment: Alignment.topCenter,
                        onPressed: onStarTap,
                        icon: Icon(
                          favoriteFilledIcon,
                          size: 18,
                          color: colors.primary,
                        ),
                      ),
                    ),
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
                        _MethodChip(label: log.methodDisplay),
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
              if (log.addIns.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    // 用 Material 图标而不是 emoji：emoji 在中文字体里画不出来。
                    Icon(
                      Icons.local_drink_outlined,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _addInsLabel(log.addIns),
                        style: mutedStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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

/// 研磨刻度（卡片第二行，M2.10 / M3-T15）。
///
/// 磨豆机之后**只给一个值**：相对刻度（`圈 × 每圈 click + click − 零点`）。
///
/// 换算用的是这台磨豆机**现在**的校准（零点 / 每圈 click）——
/// 记录里的 `圈 / click` 不变，改刻度后卡片上的数字会跟着变，
/// 这样屏幕上的读数和机器上的实际刻度一致。磨豆机被删（或某个字段为空）
/// 时回落到**记录里的快照**，老记录即使机器没了也还读得出来。
/// 两处（卡片与表单提示）共用 [BrewLogFormPage.relativeClicks] 这一个规则。
/// 「每圈 click」当前值与快照都取不到时，退回原始读数的写法。
String _grindLabel(BrewLog log, Grinder? grinder) {
  final int? clicks = log.grindClicks;

  final double? relative = BrewLogFormPage.relativeClicks(
    turns: log.grindSetting,
    clicks: clicks,
    grinder: grinder,
    zeroPointSnapshot: log.grinderZeroPointSnapshot,
    clicksPerRevolutionSnapshot: log.grinderClicksPerRevolutionSnapshot,
  );
  if (relative != null) {
    // 磨豆机已被删：没有名字可写，只给算出来的相对刻度。
    final String prefix = grinder == null
        ? ''
        : '${grinder.brand} ${grinder.model} · ';
    return '$prefix相对刻度 ${_formatNumber(relative)} click';
  }

  // 没有每圈 click（存量旧机器，记录里也没有快照）：给原始读数，别瞎算。
  final List<String> parts = <String>[
    if (grinder != null) '${grinder.brand} ${grinder.model}',
    if (log.grindSetting != null) '刻度 ${_formatNumber(log.grindSetting!)}',
    if (clicks != null) '$clicks click',
  ];
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

/// 辅料那一行的文字：最多两项，其余折叠成 `+N`。
///
/// 卡片上只给一眼的印象，详细清单在详情/编辑页里。
String _addInsLabel(List<BrewLogAddIn> addIns, {int max = 2}) {
  String one(BrewLogAddIn addIn) {
    if (addIn.amount == null) return addIn.name;
    return '${addIn.name} ${_formatNumber(addIn.amount!)} ${addIn.unit.label}';
  }

  final List<String> shown = addIns.take(max).map(one).toList(growable: true);
  if (addIns.length > max) shown.add('+${addIns.length - max}');
  return shown.join(' · ');
}

/// 「加入哪个收藏夹」多选面板（v8 / T38 裁决 C=②、D=②）。
///
/// 返回选中的集合；用户直接关掉面板时返回 null（调用方就不改归属）。
/// 一个都不勾 + 点「完成」= 空集合 = **收藏但未分组**（合法状态）。
class _GroupPickSheet extends ConsumerStatefulWidget {
  const _GroupPickSheet({required this.initial});

  final Set<int> initial;

  @override
  ConsumerState<_GroupPickSheet> createState() => _GroupPickSheetState();
}

class _GroupPickSheetState extends ConsumerState<_GroupPickSheet> {
  late final Set<int> _selected = <int>{...widget.initial};

  Future<void> _createAndSelect() async {
    int? id;
    await guardGroupWrite(context, () async {
      id = await createFavoriteGroupDialog(context, ref);
    });
    if (id == null || !mounted) return;
    setState(() => _selected.add(id!));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<FavoriteGroup> groups =
        ref.watch(favoriteGroupsProvider).value ?? const <FavoriteGroup>[];

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
              child: Text(
                '加入哪个收藏夹？',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                '可以多选；一个都不选 = 只收藏、不分组。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Text(
                  '还没有收藏夹 —— 先建一个，或直接点「完成」。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final FavoriteGroup group in groups)
              CheckboxListTile(
                key: Key('record.groupPick.${group.id}'),
                value: _selected.contains(group.id),
                onChanged: (bool? value) => setState(() {
                  if (value == true) {
                    _selected.add(group.id!);
                  } else {
                    _selected.remove(group.id);
                  }
                }),
                dense: true,
                title: Text(group.name),
              ),
            const Divider(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextButton.icon(
                  key: const Key('record.groupPickNew'),
                  onPressed: _createAndSelect,
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  label: const Text('新建收藏夹'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: FilledButton(
                key: const Key('record.groupPickDone'),
                onPressed: () => Navigator.of(context).pop(_selected),
                child: const Text('完成'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 「管理收藏夹」：建 / 改名 / 删。
class _ManageGroupsSheet extends ConsumerWidget {
  const _ManageGroupsSheet({
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
  });

  final Future<void> Function() onCreate;
  final Future<void> Function(FavoriteGroup group) onRename;
  final Future<void> Function(FavoriteGroup group) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<FavoriteGroup> groups =
        ref.watch(favoriteGroupsProvider).value ?? const <FavoriteGroup>[];

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Text(
                '管理收藏夹',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Text(
                  '还没有收藏夹。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final FavoriteGroup group in groups)
              ListTile(
                key: Key('record.group.${group.id}'),
                dense: true,
                leading: const Icon(Icons.folder_outlined),
                title: Text(group.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      key: Key('record.groupRename.${group.id}'),
                      tooltip: '改名',
                      onPressed: () => onRename(group),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                    ),
                    IconButton(
                      key: Key('record.groupDelete.${group.id}'),
                      tooltip: '删除',
                      onPressed: () => onDelete(group),
                      icon: const Icon(Icons.delete_outline, size: 20),
                    ),
                  ],
                ),
              ),
            const Divider(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilledButton.tonalIcon(
                  key: const Key('record.groupNew'),
                  onPressed: onCreate,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新建收藏夹'),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// 收藏夹的「新建 / 改名」对话框。
///
/// **唯一的非空防线**：数据层故意不 trim（避免静默改用户数据），所以这里
/// `trim()` 后为空就**不提交**（照 `_MethodNameDialog._submit` 的既有写法）——
/// 否则空串会撞 DB 的 `min:1` 抛 `InvalidDataException`、纯空白会存出一个空白 chip。
///
/// 返回 trim 过的名字；取消返回 null。
class _GroupNameDialog extends StatefulWidget {
  const _GroupNameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_GroupNameDialog> createState() => _GroupNameDialogState();
}

class _GroupNameDialogState extends State<_GroupNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  /// 超长时的行内提示（见 [_submit] 的长度口径说明）。
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _controller.text.trim();
    if (name.isEmpty) return; // 空名不提交：对话框留在原地。
    // drift 的 `withLength(1..60)` 按 **UTF-16 code unit** 计，而 `TextField.maxLength`
    // 按**字素簇**计：60 个 emoji（每个 2 个 code unit）能过 UI，插入时才抛
    // `InvalidDataException`。这里按同一口径（`String.length`）先挡一下。
    if (name.length > 60) {
      setState(() => _error = '名字太长了，最多 60 个字符');
      return;
    }
    setState(() => _error = null);
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('record.groupName'),
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        decoration: InputDecoration(hintText: '例如：早餐配方', errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

/// 收藏夹写入的友好兜底（B-顺手项）：任何异常都给一句提示，
/// 不让它变成"未处理的异步异常"直接冒到用户面前。
Future<void> guardGroupWrite(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('收藏夹没保存成功，换个名字再试试'),
          duration: Duration(seconds: 3),
        ),
      );
  }
}

/// 弹「新建收藏夹」对话框并落库，返回新夹的 id（取消或空名返回 null）。
///
/// 抽成函数是因为两个入口（多选面板 / 管理面板）都要用，而对话框自己的
/// `TextEditingController` 必须由对话框持有并释放。
Future<int?> createFavoriteGroupDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final String? name = await showDialog<String>(
    context: context,
    builder: (BuildContext context) =>
        const _GroupNameDialog(title: '新建收藏夹', initial: ''),
  );
  if (name == null) return null;
  return ref.read(brewLogRepositoryProvider).createFavoriteGroup(name);
}
