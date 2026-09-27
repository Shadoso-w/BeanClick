import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/entities.dart';
import '../beans/beans_page.dart';
import '../record/brew_log_form_page.dart';
import '../record/record_page.dart';
import '../settings/settings_page.dart';
import '../stats/stats_page.dart';

/// 应用外壳：4 个 tab（记录 / 豆库 / 统计 / 我的）+ 中间 FAB（手册 §5）。
///
/// 用 [IndexedStack] 承载四个页面，切 tab 不丢滚动位置与搜索词。
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const List<String> _titles = <String>['记录', '豆库', '统计', '我的'];

  int _currentIndex = 0;

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  /// 快速记录（手册 §8）：默认复制上次参数，直接进表单。
  Future<void> _onQuickRecordPressed() async {
    final BrewLog? latest = await ref
        .read(brewLogRepositoryProvider)
        .getLatest();
    if (!mounted) return;

    await BrewLogFormPage.show(
      context,
      prefill: latest == null ? null : BrewLogFormPage.copyFrom(latest),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: IndexedStack(
        index: _currentIndex,
        children: const <Widget>[
          RecordPage(),
          BeansPage(),
          StatsPage(),
          SettingsPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onQuickRecordPressed,
        tooltip: '快速记录',
        child: const Icon(Icons.add),
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
            icon: Icon(Icons.coffee_outlined),
            selectedIcon: Icon(Icons.coffee),
            label: '豆库',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: '统计',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
