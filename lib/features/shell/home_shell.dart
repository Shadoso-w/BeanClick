import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../beans/beans_page.dart';
import '../record/brew_log_form_page.dart';
import '../record/record_page.dart';
import '../settings/settings_page.dart';

/// 应用外壳。
///
/// 底部 dock 三格：
///
/// 1. **记录** —— 时间线 + 统计两个页签（统计从原来的独立 tab 并进来）
/// 2. **新加一杯** —— 正中的圆形大 + 号。**固定在 dock 里**，不是悬浮按钮，
///    滚动列表也不会盖住内容。点开直接进记录表单
/// 3. **豆库**
///
/// 「我的」（设置与导出）整体移到右上角，不再占一栏。
///
/// 「新加一杯」不是页面而是动作：点它开表单，关掉后回到原来那一栏，
/// 因此不留空白页，也不会让用户迷失在当前 tab。
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const List<String> _titles = <String>['记录', '豆库'];

  int _currentIndex = 0;

  /// 快速记录：点 dock 正中的加号**开一张空表单**（归零页）。
  ///
  /// 不再预填「上次」的参数 —— 测评反馈要求「进入后从默认页面开始，
  /// 而非上一次记录」。想复用上次的参数，表单右上角的复制按钮单击即可
  /// （长按还能从收藏过的参数里挑）。
  Future<void> _onAddCupPressed() async {
    await BrewLogFormPage.show(context);
  }

  /// 「我的」：设置与导出，从右上角进入。
  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const _SettingsRoute(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: <Widget>[
          IconButton(
            onPressed: _openSettings,
            tooltip: '我的',
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const <Widget>[RecordPage(), BeansPage()],
      ),
      bottomNavigationBar: _BottomDock(
        currentIndex: _currentIndex,
        onSelect: (int index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
        },
        onAddCup: _onAddCupPressed,
      ),
    );
  }
}

/// 底部 dock：左「记录」、中间固定的圆形大 +、右「豆库」。
///
/// 中间那颗刻意不用 `FloatingActionButton`：悬浮按钮会盖住列表最后一条，
/// 而且滚动时位置会跟着动。放进 dock 里之后它永远是同一个位置，
/// 列表也只需要留普通的内边距。
class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.currentIndex,
    required this.onSelect,
    required this.onAddCup,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddCup;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      elevation: 3,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: <Widget>[
              Expanded(
                child: _DockItem(
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history,
                  label: '记录',
                  selected: currentIndex == 0,
                  onTap: () => onSelect(0),
                ),
              ),
              _AddCupButton(onPressed: onAddCup),
              Expanded(
                child: _DockItem(
                  icon: Icons.coffee_outlined,
                  selectedIcon: Icons.coffee,
                  label: '豆库',
                  selected: currentIndex == 1,
                  onTap: () => onSelect(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// dock 正中那颗固定的圆形加号。
class _AddCupButton extends StatelessWidget {
  const _AddCupButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: '新加一杯',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Material(
          color: colors.primary,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            key: const Key('dock.addCup'),
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.add, size: 30, color: colors.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

/// dock 里的一格（图标 + 文字，选中时换成实心图标并染色）。
class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color color = selected ? colors.primary : colors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(selected ? selectedIcon : icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// 设置页的独立路由：带自己的 AppBar 与返回按钮。
class _SettingsRoute extends StatelessWidget {
  const _SettingsRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: const SettingsPage(),
    );
  }
}
