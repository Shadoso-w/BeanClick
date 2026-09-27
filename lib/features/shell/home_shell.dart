import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/entities.dart';
import '../beans/beans_page.dart';
import '../record/brew_log_form_page.dart';
import '../record/record_page.dart';
import '../settings/settings_page.dart';

/// 应用外壳。
///
/// 导航为三栏（用户确认的 dock 方案）：
///
/// 1. **记录** —— 时间线 + 统计两个页签（统计从原来的独立 tab 并进来）
/// 2. **新加一杯** —— 底部正中常驻的大 + 号，点开直接进记录表单
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
  /// 中间那一栏是动作而不是页面，索引占位为 1。
  static const int _addCupIndex = 1;

  static const List<String> _titles = <String>['记录', '新加一杯', '豆库'];

  int _currentIndex = 0;

  void _onDestinationSelected(int index) {
    if (index == _addCupIndex) {
      _onAddCupPressed();
      return;
    }
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  /// 快速记录（手册 §8）：默认复制上次参数，直接进表单。
  ///
  /// 表单关闭后不切换 tab —— 中间栏只是动作入口。
  Future<void> _onAddCupPressed() async {
    final BrewLog? latest = await ref
        .read(brewLogRepositoryProvider)
        .getLatest();
    if (!mounted) return;

    await BrewLogFormPage.show(
      context,
      prefill: latest == null ? null : BrewLogFormPage.copyFrom(latest),
    );
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
        children: const <Widget>[
          RecordPage(),
          SizedBox.shrink(), // 中间栏是动作，不承载页面
          BeansPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: _onAddCupPressed,
        tooltip: '新加一杯',
        child: const Icon(Icons.add, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '记录',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: '新加一杯',
          ),
          NavigationDestination(
            icon: Icon(Icons.coffee_outlined),
            selectedIcon: Icon(Icons.coffee),
            label: '豆库',
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
