/// 第二批（B1 自定义冲煮方法 / B3 辅料）的**设计稿渲染**（mock，不是产品代码）。
///
/// 跑法（故意放 `tool/` 而不是 `test/`，免得被 CI 当 golden 比对）：
///
/// ```powershell
/// flutter test tool/design_preview/batch2_previews_test.dart --update-goldens
/// ```
///
/// 产物：`tool/design_preview/goldens/batch2_previews.png`
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'preview_support.dart';

void main() {
  setUpAll(loadPreviewFonts);

  testWidgets('第二批 UI 改稿', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(760, 12000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: previewTheme(Brightness.light),
        home: const _Batch2Sheet(),
      ),
    );
    await tester.pumpAndSettle();

    // 内容一旦高过**视口**，超出部分不会进图 —— golden 会**静默**变短
    // （本项目踩过：M2.10 稿的「⑧ 记录卡片」整段消失而测试全绿）。
    // 注意要跟真实视口高比，不能跟写死的画布常量比 —— 后者在画布被调小时
    // 依然会通过，等于没守住。见 previewSheetKey 的说明。
    expect(
      tester.getSize(find.byKey(previewSheetKey)).height,
      lessThanOrEqualTo(
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      ),
      reason: '内容已超过画布高度，请抬高 physicalSize —— 否则 golden 会被静默裁掉',
    );

    await expectLater(
      find.byKey(previewSheetKey),
      matchesGoldenFile('goldens/batch2_previews.png'),
    );
  });
}

class _Batch2Sheet extends StatelessWidget {
  const _Batch2Sheet();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: previewSheetKey,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _Title('① [B1] 冲煮方法：内置 + 自定义 + ＋新建'),
            const _Label('改前（只有内置预设，超出要展开）'),
            const _MockSection(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _MockChoiceChip(label: '手冲', selected: true),
                  _MockChoiceChip(label: '摩卡壶'),
                  _MockActionChip(label: '更多方法', icon: Icons.add),
                ],
              ),
            ),
            const _Label('改后（自定义排在内置之后，点 ＋ 新建）'),
            _MockSection(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _MockChoiceChip(label: '手冲', selected: true),
                  _MockChoiceChip(label: '摩卡壶'),
                  _MockChoiceChip(label: '拿铁', custom: true),
                  _MockChoiceChip(label: '榛果摩卡', custom: true),
                  const _MockActionChip(label: '＋'),
                  const _MockActionChip(label: '更多方法'),
                ],
              ),
            ),
            const _Label('点「＋」→ 新建（输入框对话框）'),
            const _MockDialog(
              title: '新的冲煮方法',
              hint: '例如：拿铁、摩卡、燕麦拿铁',
              confirm: '保存',
            ),
            const _Label('长按自定义 chip → 重命名 / 删除'),
            const _MockMenu(),

            const SizedBox(height: 28),
            const _Title('② [B3] 辅料：单开一栏'),
            const _Label('空态（只有一行提示，不占大块）'),
            _MockSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '辅料',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const _MockActionChip(label: '＋ 添加'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '还没有加辅料',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const _Label('有两条：名字 + 数量 + 单位 + 删除'),
            const _MockSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _MockAddInRow(name: '牛奶', amount: '150', unit: 'ml'),
                  SizedBox(height: 8),
                  _MockAddInRow(name: '榛果糖浆', amount: '1', unit: '泵'),
                ],
              ),
            ),
            const _Label('点名字或「＋ 添加」→ 选择面板（常用 / 最近用过 / 新建）'),
            const _MockPickerSheet(),

            const SizedBox(height: 28),
            const _Title('③ [B3-c] 记录卡片上显示辅料（最多两项，其余折叠）'),
            const _MockLogCardWithAddIns(addIns: '🥛 牛奶 150 ml · 榛果糖浆 1 泵'),
            const SizedBox(height: 12),
            const _MockLogCardWithAddIns(
              addIns: '🥛 牛奶 150 ml · 榛果糖浆 1 泵 · +2',
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}

class _MockSection extends StatelessWidget {
  const _MockSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

class _MockChoiceChip extends StatelessWidget {
  const _MockChoiceChip({
    required this.label,
    this.selected = false,
    this.custom = false,
  });

  final String label;
  final bool selected;
  final bool custom;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = selected
        ? colors.secondaryContainer
        : custom
        ? colors.surfaceContainerHighest
        : colors.surfaceContainerHigh;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: selected
            ? Border.all(color: colors.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (selected) ...<Widget>[
            Icon(Icons.check, size: 16, color: colors.onSecondaryContainer),
            const SizedBox(width: 4),
          ],
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _MockActionChip extends StatelessWidget {
  const _MockActionChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: colors.primary),
          ),
        ],
      ),
    );
  }
}

class _MockDialog extends StatelessWidget {
  const _MockDialog({
    required this.title,
    required this.hint,
    required this.confirm,
  });

  final String title;
  final String hint;
  final String confirm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                hint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(onPressed: () {}, child: const Text('取消')),
                FilledButton(onPressed: () {}, child: Text(confirm)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MockMenu extends StatelessWidget {
  const _MockMenu();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: <Widget>[
          ListTile(
            dense: true,
            leading: const Icon(Icons.edit_outlined),
            title: const Text('重命名「拿铁」'),
            subtitle: const Text('只改列表里的名字，历史记录保留原来的写法'),
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: Icon(Icons.delete_outline, color: colors.error),
            title: Text('从列表删除「拿铁」', style: TextStyle(color: colors.error)),
            subtitle: const Text('已有 3 条记录在用，删除后它们仍显示「拿铁」'),
          ),
        ],
      ),
    );
  }
}

class _MockAddInRow extends StatelessWidget {
  const _MockAddInRow({
    required this.name,
    required this.amount,
    required this.unit,
  });

  final String name;
  final String amount;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    Widget box(String text, {bool wide = false}) => Container(
      width: wide ? 92 : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );

    return Row(
      children: <Widget>[
        Expanded(flex: 4, child: box(name)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: box(amount, wide: true)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(unit, style: Theme.of(context).textTheme.bodyMedium),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          tooltip: '删掉这一项',
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    );
  }
}

class _MockPickerSheet extends StatelessWidget {
  const _MockPickerSheet();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    Widget group(String title, List<String> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.textTheme.labelMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String item in items) _MockActionChip(label: item),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '选择辅料',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            group('常用', <String>[
              '牛奶',
              '燕麦奶',
              '豆奶',
              '水',
              '冰块',
              '榛果糖浆',
              '焦糖酱',
              '糖',
            ]),
            group('最近用过', <String>['香草糖浆', '椰奶']),
            Text('新建', style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '输入辅料名…',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: () {}, child: const Text('添加')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 记录卡片（含辅料行）的 mock，结构与 record_page 的 `_BrewLogCard` 对齐。
class _MockLogCardWithAddIns extends StatelessWidget {
  const _MockLogCardWithAddIns({required this.addIns});

  final String addIns;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle? muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          '黑猫拼配',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const _MockChoiceChip(label: '拿铁'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (int i = 0; i < 5; i++)
                      Icon(
                        i < 4 ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 16,
                        color: colors.primary,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('C40 / 22 click', style: muted),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              children: <Widget>[
                _Metric(icon: Icons.scale_outlined, text: '15g / 240g'),
                _Metric(icon: Icons.thermostat_outlined, text: '92 ℃'),
                _Metric(icon: Icons.timer_outlined, text: '2:35'),
              ],
            ),
            const SizedBox(height: 10),
            Text(addIns, style: muted),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Icon(Icons.schedule, size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('3 天前 14:30', style: muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
